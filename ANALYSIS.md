# Smart Support AI - Project Analysis

## Project Overview
Smart Support AI is a multi-tenant SaaS platform that allows businesses to deploy intelligent AI-powered chatbots on their websites and mobile apps. It features a rule-based matching system, a machine learning classifier, and a Retrieval-Augmented Generation (RAG) system using Google Gemini.

## Project Structure
The repository is organized into four main components:

- **`flutter_app/`**: A Flutter-based admin dashboard where companies can manage their intents, upload knowledge base documents, and view analytics.
- **`ml_api/`**: A FastAPI-based machine learning service that provides intent classification (using Scikit-learn) and text embeddings (using Sentence-Transformers) for RAG.
- **`supabase/`**: The backend infrastructure, including the database schema (SQL), Row Level Security (RLS) policies, and Edge Functions (Deno) for AI chat and email notifications.
- **`website/`**: The public-facing landing page and the JavaScript-based chatbot widget that can be embedded on any site.

## Core Chatbot Logic
The chatbot uses a multi-stage approach to answer user queries, as implemented in `ChatLogicService.dart` and `chat.html`:

1.  **Stage 1: Rule-based Matching (Exact & Similarity)**
    - Performs exact string matching and Levenshtein similarity checks against defined training phrases.
2.  **Stage 2: Keyword Overlap**
    - Checks for word intersection between the user's message and the training phrases.
3.  **Stage 3: ML Classifier**
    - Calls the `ml_api`'s `/predict` endpoint, which uses a Multinomial Naive Bayes classifier trained on the company's specific intents.
4.  **Stage 4: Generative AI with RAG**
    - If no intent is matched, it calls the `ai-chat` Supabase Edge Function.
    - This function uses RAG to search for relevant document chunks in the database using vector similarity (`pgvector`).
    - The retrieved context is then passed to **Google Gemini 2.0 Flash** to generate a natural language response.

## RAG Implementation
- **Embedding**: The `ml_api` uses the `paraphrase-multilingual-MiniLM-L12-v2` model to generate 384-dimensional vectors.
- **Storage**: Document chunks and their embeddings are stored in the `document_chunks` table in Supabase.
- **Search**: The `search_company_docs` RPC in PostgreSQL performs a cosine similarity search using the `<=>` operator.
- **Generation**: The `ai-chat` Edge Function combines the retrieved context, company-defined personality, and conversation history to prompt Gemini.

## Tech Stack
- **Frontend (Dashboard)**: Flutter (v3.3.0+), Riverpod, GoRouter, Supabase Flutter SDK.
- **Backend**: Supabase (PostgreSQL, pgvector, Edge Functions, Auth, Storage).
- **ML API**: Python, FastAPI, Scikit-learn, Sentence-Transformers, Joblib.
- **AI Models**: Google Gemini 2.0 Flash, Multilingual MiniLM.
- **Web**: Vanilla JS (Chat Widget), HTML/CSS (Landing Page).

## Key Features
- **Multi-tenancy**: Isolated data for each company using Supabase RLS.
- **Multilingual Support**: Handles English, French, and Arabic out of the box.
- **Human Handoff**: Automatically suggests WhatsApp or email contact when the bot fails to answer repeatedly.
- **Real-time Analytics**: Tracks sessions, message counts, and customer satisfaction ratings.
