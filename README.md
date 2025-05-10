# Solace: Bible reading plans and Biblical advice tailored to your life problems

## Application Design and Architecture Plan

### Overview
The application is a web-based platform designed to assist users in addressing life problems by leveraging AI to provide tailored Bible reading plans and Biblical advice. Users can input their problems and context, and the system will analyze these inputs using a Large Language Model (LLM) and similarity search techniques to suggest relevant Bible verses and generate advice. The initial focus is on a web application, with potential mobile support in the future.

### Core Features
User Input: A form to submit life problems with title, description, and context.
AI-Driven Analysis: Use AI to identify relevant Bible verses and generate advice.
Bible Reading Plan: A structured list of suggested verses based on user input.
Biblical Advice: AI-generated advice contextualized to the user's problem and selected verses.
User Management: Account creation, problem saving, and reading progress tracking.

### Tech Stack
Frontend: Svelte (web framework for a responsive UI).
Backend: Go (server-side logic) with GraphQL (API layer).
Database: Postgres with pgvector extension (for storing Bible text and vector embeddings).
AI Components:
Sentence Transformer (e.g., all-MiniLM-L6-v2) for embedding generation and similarity search.
LLM (e.g., a smaller open-source model) for advice generation.

## Architecture

### Components
1. Frontend (Svelte)
- Purpose: Provides an intuitive interface for user interaction.
- Key Components:
    - Login/Register: Forms for user authentication.
    - Problem Submission: Form with fields for title, description, context, and optional category.
    - Dashboard: Displays user’s problems, reading plans, and advice.
    - Reading Plan Viewer: Shows suggested verses with options to mark them as read.
    - API Interaction: Uses Apollo Client to communicate with the GraphQL backend.

2. Backend (Go with GraphQL)
- Purpose: Handles business logic, API requests, and AI integration.
- GraphQL API:
    - Queries: Retrieve user data, problems, reading plans, and verses.
    - Mutations: Create users, submit problems, update reading progress.
    - Authentication: JWT-based for secure user sessions.
- Workflow:
    - Receive problem input from the frontend.
    - Embed the problem description using a sentence transformer.
    - Perform a similarity search to find relevant Bible verses.
    - Generate a reading plan and advice using an LLM.
    - Store and return results to the frontend.

3. Database (Postgres with pgvector)
- Purpose: Stores user data, problems, reading plans, and Bible text with embeddings.
- Schema:
    - users: id, username, email, password_hash
    - problems: id, user_id, title, description, context, category, created_at, advice
    - reading_plans: id, problem_id, created_at
    - reading_plan_items: id, reading_plan_id, verse_id, order, is_read
    - verses: id, book, chapter, verse, text, embedding (vector)
- Bible Text: Use the World English Bible (WEB), a public domain translation, loaded into the verses table.

4. AI Integration
Embedding and Similarity Search:
- Use a sentence transformer to generate embeddings for Bible verses (offline) and user problem descriptions (on-demand).
- Store verse embeddings in the verses table with pgvector.
- Perform cosine similarity searches to find the top K relevant verses.
- Advice Generation:
- Pass the top K verses and problem description to an LLM as context.
- Generate concise, Biblically sound advice (e.g., limited to 200 words).

### Model Choices:
Sentence Transformer: all-MiniLM-L6-v2 (lightweight and efficient).
LLM: A smaller open-source model (e.g., distilled GPT-2) or a cloud service if needed.