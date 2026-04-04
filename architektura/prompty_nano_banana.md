# Prompty dla "nano banana 2" — spójność architektoniczna

Prompty do przekazywania w kolejnych sesjach AI (agentach, modelach), aby zachować pełną spójność z głównym obrazem architektonicznym systemu RAG "Eskadra Bielik Misja 2".

---

## Prompt 1 — Kontekst bazowy (wklej na początku każdej sesji)

Używaj jako pierwszej wiadomości, gdy chcesz rozmawiać o architekturze lub ją rozszerzać.

```
KONTEKST ARCHITEKTONICZNY — Eskadra Bielik Misja 2 (RAG na Google Cloud):

System składa się z 4 komponentów wdrożonych w GCP:

1. ORCHESTRATION API (Cloud Run, Python FastAPI, uvicorn :8080)
   - Główny hub spinający cały system
   - Endpointy: GET /, POST /ingest, POST /ask, POST /ask_direct, GET /records
   - Kod: orchestration/main.py

2. BIELIK LLM (Cloud Run, Ollama, SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0)
   - Endpoint: POST /api/chat
   - 8 vCPU, 16 GB RAM, GPU NVIDIA L4
   - Zabezpieczony IAM (--no-allow-unauthenticated), Bearer token

3. EMBEDDING GEMMA (Cloud Run, Ollama, embeddinggemma:latest)
   - Endpoint: POST /api/embed
   - Zwraca wektory FLOAT64[]

4. BIGQUERY VECTOR STORE
   - Tabela: rag_dataset.hotel_rules (id STRING, content STRING, embedding FLOAT64 REPEATED)
   - Wyszukiwanie: VECTOR_SEARCH top_k=3, COSINE distance

PRZEPŁYW RAG (/ask):
  query → EmbeddingGemma → [wektor] → BigQuery VECTOR_SEARCH (top 3)
  → prompt z kontekstem → Bielik LLM → odpowiedź + confidence score
  confidence = avg( (1 - cosine_distance) × 100% )

PRZEPŁYW INGESTION (/ingest):
  CSV(id, text) → EmbeddingGemma (per wiersz) → BigQuery insert_rows_json

KROKI WARSZTATU (z punktacją):
  1: GCP project (+5) | 2: Env+Services (+10) | 3: LLM+Embedding deploy (+20)
  4: BigQuery init (+5) | 5: Orchestration deploy (+10) | 6: API test (+10)
  7: Code review (+5)  | 8: Web UI (+10)       | 9: Certyfikat | MAX: 75 pkt

NIEZMIENNE ZAŁOŻENIA PROJEKTOWE:
- Wszystkie modele działają na Ollama w kontenerach Docker na Cloud Run
- Komunikacja model↔orchestration przez Bearer token (Google IAM id_token)
- BigQuery jako jedyna warstwa persystencji (brak relacyjnej bazy danych)
- Orchestration API jest jedynym punktem wejścia dla użytkownika
- Architektura serverless — brak maszyn wirtualnych
- Wszystkie kontenery Cloud Run nasłuchują na porcie 8080
```

---

## Prompt 2 — Rozszerzenie architektury

Używaj gdy chcesz dodać nowy komponent lub endpoint, zachowując spójność z istniejącą architekturą.

```
Rozszerzasz architekturę systemu RAG "Eskadra Bielik Misja 2".

[WKLEJ TUTAJ PROMPT 1 — KONTEKST BAZOWY]

Zachowaj następujące zasady przy rozszerzaniu:
- Nowe komponenty wdrażaj jako usługi Cloud Run (serverless)
- Nowe endpointy dodawaj do Orchestration API (main.py), nie twórz osobnych serwerów
- Zachowaj uwierzytelnianie IAM Bearer token między serwisami
- BigQuery pozostaje jedyną warstwą persystencji
- Nowe diagramy rysuj w Mermaid (graph TB lub sequenceDiagram)
- Każdy nowy diagram opatrz tabelą z kluczowymi właściwościami

ZADANIE: [WSTAW TUTAJ CO CHCESZ DODAĆ]
```

---

## Prompt 3 — Generowanie diagramu Mermaid

Używaj gdy chcesz wygenerować nowy diagram spójny z istniejącymi (np. dla nowego endpointu lub kroku).

```
Narysuj diagram Mermaid dla systemu RAG "Eskadra Bielik Misja 2".

Komponenty systemu (użyj tych samych nazw i opisów):
- Orchestration API: FastAPI, Cloud Run, orchestration/main.py
- Bielik LLM: Ollama, Cloud Run, POST /api/chat, GPU L4
- EmbeddingGemma: Ollama, Cloud Run, POST /api/embed
- BigQuery: rag_dataset.hotel_rules, VECTOR_SEARCH COSINE, top_k=3

Konwencje diagramów w tym projekcie:
- Widoki systemowe: graph TB z subgraph dla GCP i użytkownika
- Przepływy danych: sequenceDiagram z Note over dla etapów
- Kroki wdrożenia: graph LR z emoji i punktacją w węzłach
- Styl węzłów krytycznych: fill:#ff9900,color:#000

ZADANIE: [OPISZ JAKI DIAGRAM CHCESZ WYGENEROWAĆ]
```

---

## Prompt 4 — Weryfikacja stanu wdrożenia

Używaj na początku każdego kroku warsztatu, aby sprawdzić czy poprzednie kroki zostały poprawnie zakończone.

```
Weryfikujesz stan wdrożenia systemu RAG "Eskadra Bielik Misja 2".

Ukończone kroki: [WSTAW NR I NAZWY, np. "1 (GCP Project), 2 (Env Setup)"]

Aktualny stan komponentów:
- Bielik LLM na Cloud Run:       [URL: https://... / BRAK]
- EmbeddingGemma na Cloud Run:   [URL: https://... / BRAK]
- BigQuery rag_dataset.hotel_rules: [GOTOWE / BRAK]
- Orchestration API na Cloud Run: [URL: https://... / BRAK]

Następny krok do wykonania: [WSTAW NR I NAZWĘ KROKU]

Na podstawie powyższego stanu:
1. Oceń czy wszystkie wymagane zależności dla następnego kroku są spełnione
2. Wskaż ewentualne blokery
3. Przypomnij kluczowe komendy dla następnego kroku
```

---

## Prompt 5 — Code review endpointu

Używaj gdy chcesz przeanalizować lub zmodyfikować kod endpointu, zachowując spójność z architekturą.

```
Analizujesz kod endpointu w systemie RAG "Eskadra Bielik Misja 2".

[WKLEJ TUTAJ PROMPT 1 — KONTEKST BAZOWY]

Plik do analizy: orchestration/main.py
Framework: FastAPI + uvicorn
Biblioteki: google-cloud-bigquery, google-auth, requests, pydantic

Endpoint do analizy:
[WKLEJ KOD ENDPOINTU]

Przeanalizuj pod kątem:
1. Zgodności z przepływem danych opisanym w kontekście bazowym
2. Poprawności obsługi tokenów IAM (get_id_token)
3. Struktury odpowiedzi JSON
4. Potencjalnych błędów w komunikacji z EmbeddingGemma i Bielikiem
```
