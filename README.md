# Solace: Bible reading plans and Biblical advice tailored to your life problems

A Christian counseling web application that provides Biblical guidance for life problems using AI.

## Architecture

### Tech Stack
- **Frontend**: Next.js 16 + React 19 + TypeScript + Tailwind CSS
- **Backend**: Next.js API Routes + Supabase
- **Database**: PostgreSQL with pgvector extension
- **Runtime**: Bun (fast JavaScript runtime and package manager)
- **AI Services**:
  - OpenAI text-embedding-3-small for verse similarity search
  - OpenRouter (arcee-ai/trinity-large-preview:free) for advice generation

### Features
- User authentication via Supabase Auth
- Submit life problems and receive AI-generated Biblical advice
- Vector similarity search to find relevant Bible verses
- Personalized reading plans with progress tracking
- Full-text search fallback for verses

## Getting Started

### Prerequisites
- [Bun](https://bun.sh) runtime (v1.0+)
- Supabase account
- OpenAI API key
- OpenRouter API key (free tier available)

### Install Bun

```bash
# macOS/Linux
curl -fsSL https://bun.sh/install | bash

# Windows (via PowerShell)
powershell -c "irm bun.sh/install.ps1 | iex"
```

### 1. Install Dependencies

```bash
cd web
bun install
```

### 2. Set Up Environment Variables

Copy the example environment file:

```bash
cp .env.local.example .env.local
```

Fill in your environment variables:

```env
# Supabase (Required)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Server-side Database (Required for API routes)
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DIRECT_DATABASE_URL=postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres

# AI Services (Required)
OPENAI_API_KEY=sk-...                    # For text embeddings
OPENROUTER_API_KEY=sk-or-v1-...          # For AI advice (FREE)
```

### 3. Set Up Supabase

1. Create a new Supabase project
2. Run the database migrations:
   ```bash
   cd supabase
   supabase link --project-ref your-project-ref
   supabase db push
   ```

3. Import Bible verses:
   ```bash
   supabase db reset
   ```

### 4. Run the Development Server

```bash
cd web
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser.

## Database Schema

### Tables
- **auth.users** - Supabase Auth users (use email as username)
- **verses** - Bible verses with vector embeddings
- **problems** - User-submitted problems with AI advice
- **reading_plans** - Generated reading plans
- **reading_plan_items** - Individual verses in plans
- **advice_feedback** - User feedback on advice
- **plan_revisions** - Reading plan modification history
- **verse_topics** - AI-classified verse topics

### RLS Policies
All tables have Row Level Security enabled:
- Users can only access their own data
- Verses are public read-only
- Reading plans/items accessible through problem ownership

## API Routes

| Route | Method | Description |
|-------|--------|-------------|
| `/api/problems` | GET | List user's problems |
| `/api/problems` | POST | Create problem + AI advice |
| `/api/problems/[id]` | GET | Get specific problem |
| `/api/problems/[id]` | DELETE | Delete problem |
| `/api/problems/[id]/advice` | POST | Regenerate AI advice |
| `/api/reading-plans` | POST | Create reading plan |
| `/api/reading-plans/[id]/items` | PATCH | Update reading progress |
| `/api/verses` | GET | Get verses by book/chapter |
| `/api/verses/search` | POST | Vector similarity search |
| `/api/feedback` | POST | Submit feedback |

## AI Integration

### Vector Search Flow
1. User submits problem description
2. Generate embedding via OpenAI API ($0.02/M tokens)
3. Search similar verses using pgvector cosine similarity
4. Return top 5 most relevant verses

### Advice Generation Flow
1. Pass problem + verses to OpenRouter API
2. Use `arcee-ai/trinity-large-preview:free` model (FREE)
3. Generate compassionate, Biblical advice
4. Store in problem record

### Cost Estimates
- **Embeddings**: ~$0.03 one-time to pre-compute all 31,000 Bible verses
- **Advice**: FREE using OpenRouter free tier
- **Total monthly**: ~$0-5 depending on usage

## Project Structure

```
solace/
├── web/                          # Next.js frontend + API
│   ├── src/
│   │   ├── app/
│   │   │   ├── api/              # API routes
│   │   │   ├── login/
│   │   │   ├── register/
│   │   │   ├── problems/
│   │   │   ├── verses/
│   │   │   └── page.tsx
│   │   ├── components/
│   │   ├── lib/
│   │   │   ├── ai/               # AI clients
│   │   │   ├── db/               # Database clients
│   │   │   └── supabase/
│   │   └── ...
│   ├── package.json
│   └── bun.lockb                 # Bun lockfile
├── supabase/
│   ├── migrations/               # Database migrations
│   └── ASV.csv                   # Bible verses data
└── README.md
```

## Scripts

- `bun dev` - Start development server
- `bun build` - Build for production
- `bun lint` - Run ESLint
- `supabase start` - Start local Supabase
- `supabase db reset` - Reset database with migrations

## Bun Commands Reference

```bash
# Install dependencies
bun install

# Add a package
bun add <package>

# Add a dev dependency
bun add -d <package>

# Remove a package
bun remove <package>

# Update packages
bun update

# Run scripts
bun run <script>

# Start development server
bun dev

# Build for production
bun build

# Run TypeScript files directly
bun run <file.ts>
```

## License

MIT
