# Solace

A Bible reading plan and guidance application built with Next.js 16, React 19, and Bun.

## Tech Stack

- **Framework**: Next.js 16.x (App Router)
- **Runtime**: Bun
- **UI**: React 19, Tailwind CSS 4
- **Auth**: Supabase SSR
- **Data**: GraphQL
- **Package Manager**: Bun

## Getting Started

### Prerequisites

- [Bun](https://bun.sh/) installed
- Supabase account and project
- GraphQL backend running (default: http://localhost:8080)

### Installation

```bash
# Install dependencies
bun install

# Set up environment variables
cp .env.local.example .env.local
# Edit .env.local with your Supabase credentials

# Run development server
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser.

## Available Scripts

- `bun dev` - Start development server with Turbopack
- `bun build` - Build for production
- `bun start` - Start production server
- `bun lint` - Run ESLint

## Project Structure

```
web/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── layout.tsx         # Root layout with auth
│   │   ├── page.tsx           # Home page
│   │   ├── login/             # Login page
│   │   ├── register/          # Register page
│   │   ├── problems/          # Problems list & new problem
│   │   └── verses/            # Bible verse browser
│   ├── components/
│   │   ├── layout/navbar.tsx  # Navigation bar
│   │   └── providers/         # Auth provider
│   ├── lib/
│   │   ├── supabase/          # Supabase clients
│   │   └── graphql/           # GraphQL client
│   └── types/                 # TypeScript types
├── public/                    # Static assets
└── middleware.ts              # Auth session management
```

## Features

- **Authentication**: Email/password login with Supabase
- **Problem Submission**: Submit life problems for Biblical guidance
- **Reading Plans**: Get personalized Bible verse reading plans
- **Verse Browser**: Search and browse Bible verses

## Environment Variables

```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_GRAPHQL_ENDPOINT=http://localhost:8080/query
```

## License

MIT
