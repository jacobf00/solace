# Design Document — Solace

## 1) Product overview

Solace is a web app that lets users submit life problems (title, description, context). The system embeds the problem, runs a similarity search over embedded Bible verses, generates a reading plan + concise Biblical advice via an LLM, and returns structured results to the user.

**Core features** (current scope): problem submission, AI-driven verse selection + advice, reading plan tracking, user accounts and progress.

**Baseline stack from README**:  
Frontend Svelte (+ Apollo Client), Backend Go + GraphQL, Postgres + pgvector, embeddings using `all-MiniLM-L6-v2`, LLM small open-source or cloud, JWT auth.

---

## 2) Architecture (high level)

```mermaid
flowchart LR
  subgraph Client
    UI[Svelte UI]
    Apollo[Apollo Client]
  end

  subgraph Backend (Go)
    GQL[GraphQL Server (gqlgen)]
    Auth[Auth Layer (JWT/OAuth2)]
    BL[Domain Services]
    AI[AI Orchestrator]
    Jobs[Background Workers]
    Cache[(Redis)]
    Logger[Logging/Tracing]
  end

  subgraph Data
    PG[(Postgres + pgvector)]
    Storage[(Object Storage for logs/exports)]
  end

  UI --> Apollo --> GQL
  GQL --> Auth
  GQL --> BL
  BL --> PG
  BL --> Cache
  BL --> Jobs
  AI --> PG
  AI --> Jobs
  Jobs --> PG
  Logger --> Storage
```

**Key runtime flow (Submit Problem):**  
1) User submits a problem via GraphQL mutation (auth required).  
2) Backend embeds the problem description; runs a pgvector cosine similarity query over pre-embedded verses; selects top-K.  
3) Backend prompts LLM with problem + selected verses to generate advice; constructs a reading plan (ordered verses).  
4) Results saved to DB and returned.

---

## 3) Detailed components

### 3.1 Frontend (Svelte)
- Svelte app with routes for Auth, Dashboard, Submit Problem, Reading Plan, Problem Detail.  
- Apollo Client for GraphQL requests, optimistic updates on reading progress, and cache normalization.  
- Form validation (zod or superstruct), UI library (Skeleton/Tailwind), and accessibility checks.

### 3.2 Backend (Go + GraphQL)
- **GraphQL** with `gqlgen` (schema-first).  
- **DB** access using `pgx` + `sqlc` (typed queries).  
- **Auth**: JWT access tokens + refresh tokens. Optional OAuth sign-in.  
- **AI orchestration**:  
  - Embeddings: `all-MiniLM-L6-v2` (384-dim), matching schema.  
  - Similarity: pgvector cosine + IVFFLAT index.  
  - LLM: provider abstraction (open-source/local vs. hosted).  
- **Background jobs** with Redis + asynq.  
- **Validation & policy**: resolver authz, rate limiting.

### 3.3 Data (Postgres + pgvector)
Existing schema: `users`, `problems`, `verses`, `reading_plans`, `reading_plan_items`.  
Recommended additions: `sessions`, `refresh_tokens`, `oauth_identities`, `password_resets`, `email_verifications`, `audit_logs`, `ai_events`, `advice_feedback`, `plan_revisions`, `verse_topics`.

### 3.4 GraphQL API design
(Simplified excerpt)

```graphql
type Problem {
  id: ID!
  title: String!
  description: String!
  context: String
  advice: String
  readingPlan: ReadingPlan
}

type Query {
  myProblems(limit: Int, offset: Int): [Problem!]!
  searchVerses(query: String!, k: Int = 10): [Verse!]!
}

type Mutation {
  submitProblem(input: SubmitProblemInput!): SubmitProblemPayload!
  updateReadState(input: UpdateReadStateInput!): ReadingPlanItem!
}
```

### 3.5 Authentication & authorization
- Argon2id password hashing.  
- JWT + rotating refresh tokens.  
- OAuth2 optional.  
- Email verification + reset flows.  
- Resolver-level authorization.

### 3.6 AI pipeline
- Offline: embed all WEB verses → `verses.embedding`.  
- Online: embed problem, top-K cosine similarity search, LLM advice generation, reading plan construction.  
- Logs in `ai_events`.

### 3.7 Infrastructure
- Dockerized services.  
- Managed Postgres w/ pgvector.  
- Redis for jobs/rate limiting.  
- GitHub Actions CI/CD.  
- Monitoring: OpenTelemetry, Prometheus, Grafana.  
- CDN for frontend assets.  
- S3 for log/exports.

---

## 4) Non-functional requirements
- p95 latency < 300ms simple queries; advice < 3s sync, >5s async.  
- OWASP ASVS L2.  
- 99.5% uptime target.  
- Minimal data collection.

---

## 5) Risks & mitigations
- **LLM drift** → feedback loop.  
- **Embedding mismatch** → migration planning.  
- **Query costs** → IVFFLAT indexing, possible HNSW.
