# Solace Frontend Rewrite: Next.js 15 + Bun

## Overview

The existing SvelteKit frontend is non-functional and will be completely replaced with a fresh **Next.js 15.2+** application using **Bun** as the runtime and package manager. This is a complete rewrite from scratch to leverage the latest Next.js best practices and the performance of Bun.

### Tech Stack
- **Framework**: Next.js 15.2+ (App Router)
- **Runtime/PM**: Bun 1.x
- **Styling**: Tailwind CSS 4.0
- **Auth**: Supabase (@supabase/ssr)
- **Data**: GraphQL (External backend at localhost:8080)
- **Components**: React 19 (Server & Client Components)

---

## Phase 1: Cleanup & Initialization

### 1.1 Cleanup
Delete the non-functional SvelteKit directory:
```bash
rm -rf /Users/jacobfoulds/projects/solace/client
```

### 1.2 Initialization
Initialize a fresh Next.js project in the `client` directory using Bun:
```bash
cd /Users/jacobfoulds/projects/solace
bunx create-next-app@latest client --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-bun
```

### 1.3 Dependencies
```bash
cd client
bun add @supabase/ssr @supabase/supabase-js graphql
bun add -d prettier
```

---

## Phase 2: Core Infrastructure

### 2.1 Supabase Auth (SSR)
Implement the Supabase SSR pattern with Middleware for session management.
- `src/lib/supabase/server.ts` (Server client)
- `src/lib/supabase/client.ts` (Browser client)
- `src/middleware.ts` (Session refresh & protection)

### 2.2 GraphQL Client
Build a robust GraphQL fetcher for both Server and Client components.
- `src/lib/graphql/client.ts`

### 2.3 Global Layout & Auth Provider
Create the root layout and an `AuthProvider` context for client-side auth state.

---

## Phase 3: Feature Implementation

### 3.1 Authentication (Login/Register)
Implement Login and Registration pages using **Next.js Server Actions**.

### 3.2 Home Page
Rebuild the landing page with feature cards and CTAs.

### 3.3 Problems Management
- **List View**: Fetch and display user problems (Server Component initial load).
- **New Problem Form**: Submit problems via Server Actions.

### 3.4 Bible Verses
- Browser with book/chapter navigation.
- Keyword search.
- Client-side interactivity with streaming data.

---

## Phase 4: Styling & Polish

### 4.1 Tailwind v4
Configure Tailwind v4 using the new CSS-based configuration in `app/globals.css`.

### 4.2 UI Components
Extract reusable components:
- `Button`
- `Input` / `Textarea`
- `Card`
- `Navbar`

---

## Key Best Practices

1. **Server First**: Use Server Components by default for better performance and SEO.
2. **Server Actions**: Handle all form submissions and mutations server-side.
3. **Streaming**: Use `loading.tsx` and React Suspense for data-heavy sections.
4. **Colocation**: Keep components, hooks, and types close to where they are used.
5. **Bun Runtime**: Use Bun for all scripts and testing.
