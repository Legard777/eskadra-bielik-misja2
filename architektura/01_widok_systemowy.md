# Architektura — Widok systemowy

Pełna mapa komponentów systemu RAG "Eskadra Bielik Misja 2" wdrożonego w Google Cloud Platform.

```mermaid
graph TB
    subgraph USER["👤 Użytkownik"]
        BR[Przeglądarka / curl]
    end

    subgraph GCP["☁️ Google Cloud Platform"]
        subgraph CR_ORCH["Cloud Run — Orchestration API"]
            ORCH["🐍 FastAPI (uvicorn :8080)\norchestration/main.py\n\n• GET  /          → Web UI\n• POST /ingest     → zasilanie bazy\n• POST /ask        → zapytanie RAG\n• POST /ask_direct → bez RAG\n• GET  /records    → przeglądarka BQ"]
        end

        subgraph CR_LLM["Cloud Run — LLM Bielik"]
            LLM["🦙 Ollama\nSpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0\n8 vCPU · 16 GB RAM · GPU NVIDIA L4\nPOST /api/chat"]
        end

        subgraph CR_EMB["Cloud Run — Embedding Gemma"]
            EMB["🦙 Ollama\nembeddinggemma:latest\nPOST /api/embed"]
        end

        subgraph BQ["BigQuery — Vector Store"]
            DB[("rag_dataset.hotel_rules\n─────────────────────\nid        STRING REQUIRED\ncontent   STRING REQUIRED\nembedding FLOAT64 REPEATED\n─────────────────────\nVECTOR_SEARCH COSINE")]
        end
    end

    BR -->|"HTTP/S (Bearer token IAM)"| ORCH
    ORCH -->|"POST /api/embed\ntext → [float64 x N]"| EMB
    ORCH -->|"VECTOR_SEARCH top_k=3\nCOSINE distance"| DB
    ORCH -->|"POST /api/chat\nprompt + kontekst RAG"| LLM
    EMB -->|"embeddings[]"| ORCH
    DB -->|"id, content, distance"| ORCH
    LLM -->|"message.content"| ORCH
    ORCH -->|"JSON answer + context_scores"| BR
```

## Kluczowe właściwości architektury

| Właściwość | Wartość |
|---|---|
| Typ architektury | Serverless (bezserwerowa) |
| Platforma | Google Cloud Platform |
| Punkt wejścia użytkownika | Orchestration API (Cloud Run) |
| Model LLM | SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0 |
| Model Embedding | embeddinggemma:latest |
| Baza wektorów | BigQuery Vector Search (COSINE) |
| Liczba dokumentów kontekstu (top_k) | 3 |
| Uwierzytelnianie między serwisami | Google IAM Bearer token |
| Izolacja modeli | `--no-allow-unauthenticated` na Cloud Run |
