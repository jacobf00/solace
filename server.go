package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/99designs/gqlgen/graphql"
	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
	"github.com/jacobf00/solace/database"
	"github.com/jacobf00/solace/graph"
	"github.com/jacobf00/solace/internal/ai"
	"github.com/vektah/gqlparser/v2/ast"
)

const defaultPort = "8080"

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	if err := database.InitDB(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.CloseDB()

	db := database.NewDB()

	apiKey := os.Getenv("OPENROUTER_API_KEY")
	if apiKey == "" {
		log.Fatal("OPENROUTER_API_KEY environment variable is required")
	}
	aiClient := ai.NewClient(apiKey)

	resolver := graph.NewResolver(db, aiClient)

	srv := handler.New(graph.NewExecutableSchema(graph.Config{Resolvers: resolver}))

	srv.AddTransport(transport.Options{})
	srv.AddTransport(transport.GET{})
	srv.AddTransport(transport.POST{})

	srv.SetQueryCache(lru.New[*ast.QueryDocument](1000))

	srv.Use(extension.Introspection{})
	srv.Use(extension.AutomaticPersistedQuery{
		Cache: lru.New[string](100),
	})

	srv.AroundResponses(func(ctx context.Context, next graphql.ResponseHandler) *graphql.Response {
		ctx = setRequestStart(ctx)
		return next(ctx)
	})

	http.Handle("/", playground.Handler("GraphQL playground", "/query"))
	http.Handle("/query", authMiddleware(srv))

	log.Printf("connect to http://localhost:%s/ for GraphQL playground", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func setRequestStart(ctx context.Context) context.Context {
	return context.WithValue(ctx, "requestStart", time.Now())
}

func authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		authHeader := r.Header.Get("Authorization")
		if authHeader != "" {
			token := authHeader
			if len(token) > 7 && token[:7] == "Bearer " {
				token = token[7:]
			}
			if token != "" {
				// Parse JWT to get user ID from 'sub' claim (without signature verification for now)
				// TODO: Add proper JWT verification using Supabase JWKS
				tokenObj, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
					return []byte("dummy"), nil // Not verifying signature
				})
				if err == nil {
					if claims, ok := tokenObj.Claims.(jwt.MapClaims); ok {
						if sub, ok := claims["sub"].(string); ok {
							userID, err := uuid.Parse(sub)
							if err == nil {
								ctx = context.WithValue(ctx, "userID", userID)
							}
						}
					}
				}
			}
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
