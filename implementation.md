# Implementation Plan — Solace

## Phase 0 — Repo & tooling (1–2 days)
- Create mono-repo (`frontend/`, `backend/`, `infra/`).  
- Setup CI/CD (GitHub Actions).  
- Pre-commit hooks for Go, JS, SQL.  
- Secrets via SOPS/cloud secrets.

## Phase 1 — Database & migrations (1 day)
- Apply base schema (users/problems/verses/reading_plans/reading_plan_items).  
- Add migrations for sessions, refresh_tokens, oauth_identities, audit_logs, ai_events, advice_feedback.  
- Seed initial admin user/test data.

## Phase 2 — Verse ingestion & embeddings (1–2 days)
- Load WEB into `verses`.  
- Batch embed verses with `all-MiniLM-L6-v2`.  
- Store 384-dim vectors; build IVFFLAT index.

## Phase 3 — Backend scaffolding (2–3 days)
- Init Go project with gqlgen, pgx, sqlc, zerolog.  
- Define GraphQL SDL + generate resolvers.  
- Add DB access layer.  
- Error model & tracing.

## Phase 4 — Auth (2–3 days)
- Implement register/login with Argon2id.  
- JWT access + rotating refresh tokens.  
- Sessions tracking.  
- Optional OAuth2.  
- Rate limiting.

## Phase 5 — Problems & plans (2–3 days)
- `submitProblem` mutation inserts into `problems`.  
- Generate reading plans with vector search.  
- Insert into `reading_plans` + `reading_plan_items`.  
- Queries: `myProblems`, `problem`, `readingPlan`.  
- Mutation: `updateReadState`.

## Phase 6 — LLM advice (2 days)
- Abstract LLM provider.  
- Prompt templates (~200 words).  
- Record `ai_events` (tokens, latency, errors).  
- Optionally queue long jobs with asynq.

## Phase 7 — Frontend app (3–5 days)
- Svelte + Tailwind + Apollo.  
- Auth flows (Register/Login).  
- Dashboard: list problems.  
- Problem detail: advice + plan.  
- Toggle read state.  
- Search verses UI (optional).

## Phase 8 — Observability & ops (1–2 days)
- Logging, tracing, Prometheus metrics.  
- Health checks.  
- DB backups.

## Phase 9 — QA & security (2–4 days)
- Unit + integration tests.  
- E2E tests (Playwright).  
- Threat model pass (authz, CSRF, SSRF).  
- Load test submitProblem.

## Phase 10 — Launch & iterate
- Staging validation.  
- Production deploy.  
- Collect feedback (advice_feedback).  
- Roadmap: mobile polish, topical plans, plan sharing.

---

## GraphQL ↔ SQL mapping cheatsheet
- `Problem.readingPlan` → `reading_plans` by `problem_id`.  
- `updateReadState` → update `reading_plan_items.is_read`.  
- `searchVerses` → vector similarity search with IVFFLAT.

---

## Backlog / Nice-to-have
- Streaming advice to UI.  
- Admin console for re-embedding/plan rebuild.  
- Multi-translation support.  
- Feature flags.  
- Export plan as PDF/Markdown.
