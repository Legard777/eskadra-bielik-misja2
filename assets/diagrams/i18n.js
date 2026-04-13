/* ══════════════════════════════════════════════════════
   Eskadra Bielik — Architektura RAG | Misja 2
   Plik tłumaczeń i18n — PL / EN
   ══════════════════════════════════════════════════════ */
window.I18N = {

  /* ─────────────── POLSKI ─────────────── */
  pl: {
    ui: {
      splash: {
        title: "MISJA 2",
        sub:   "Eskadra Bielik · RAG · Google Cloud",
        hint:  "→ naciśnij strzałkę"
      },
      badge: "Misja 2 · RAG · Google Cloud · Bielik + BigQuery",
      nav: {
        prev:  "← Wstecz",
        next:  "Dalej →",
        step:  "Krok",
        of:    "z"
      },
      panel: {
        stepOf:           "Krok {n} z {total}",
        activeComponents: "Aktywne komponenty"
      },
      svgLabels: {
        user: "Użytkownik / Browser"
      },
      progressDot: "Krok {i}"
    },

    steps: [
      {
        title: "Architektura RAG — start",
        desc:  "Pełna architektura systemu RAG zbudowanego w Google Cloud. Każdy krok warsztatu aktywuje kolejne komponenty.",
        pts:   null,
        items: []
      },
      {
        title: "Krok 1 — Google Cloud Project",
        desc:  "Aktywacja konta z kredytami OnRamp, utworzenie projektu Google Cloud i otwarcie Cloud Shell z repozytorium.",
        pts:   "+5 pkt",
        items: [
          "Google Cloud Project",
          "Konto rozliczeniowe (OnRamp)",
          "Cloud Shell",
          "Gemini CLI"
        ]
      },
      {
        title: "Krok 2 — Konfiguracja usług",
        desc:  "Włączenie wymaganych API: Cloud Run, Cloud Build, Artifact Registry, BigQuery. Przyznanie uprawnień IAM.",
        pts:   "+10 pkt",
        items: [
          "Cloud Run API",
          "BigQuery API",
          "Artifact Registry API",
          "Cloud Build API",
          "IAM roles/run.invoker"
        ]
      },
      {
        title: "Krok 3 — Bielik LLM + EmbeddingGemma",
        desc:  "Kopiowanie modeli do Cloud Storage, budowanie obrazu Docker z Ollama, wdrożenie obu modeli na Cloud Run.",
        pts:   "+20 pkt",
        items: [
          "Cloud Storage (modele GGUF)",
          "Artifact Registry (Ollama Docker)",
          "Bielik LLM (Cloud Run #1 + GPU L4 + Ollama)",
          "EmbeddingGemma (Cloud Run #2 + Ollama, CPU)"
        ]
      },
      {
        title: "Krok 4 — BigQuery Vector Search",
        desc:  "Inicjalizacja bazy wektorowej: dataset rag_dataset i tabela hotel_rules z kolumną embedding (FLOAT64 REPEATED).",
        pts:   "+5 pkt",
        items: [
          "BigQuery dataset: rag_dataset",
          "Tabela: hotel_rules",
          "Kolumna embedding FLOAT64 REPEATED",
          "Vector Search COSINE"
        ]
      },
      {
        title: "Krok 5 — Orchestration API",
        desc:  "Wdrożenie aplikacji FastAPI na Cloud Run. Orchestration łączy EmbeddingGemma, BigQuery i Bielik w jeden przepływ RAG.",
        pts:   "+10 pkt",
        items: [
          "Orchestration API (FastAPI)",
          "POST /ingest — zasilanie bazy",
          "POST /ask — zapytanie RAG",
          "POST /ask_direct — bez RAG",
          "GET /records — przeglądarka"
        ]
      },
      {
        title: "Krok 6 — Testowanie API (curl z Cloud Shell)",
        desc:  "Wysyłanie danych CSV przez curl z Cloud Shell: /ingest (embed + BigQuery) i /ask (RAG pipeline).",
        pts:   "+10 pkt",
        items: [
          "curl z Cloud Shell → /ingest",
          "POST /ingest → EmbeddingGemma → BigQuery",
          "curl z Cloud Shell → /ask",
          "POST /ask → embed → VECTOR_SEARCH → Bielik",
          "Brak Web UI — tylko terminal"
        ]
      },
      {
        title: "Krok 7 — Interfejs API (Swagger)",
        desc:  "Dokumentacja i testowanie API przez Swagger UI (/docs) otwierane w przeglądarce.",
        pts:   "+5 pkt",
        items: [
          "Swagger UI (GET /docs)",
          "ReDoc (GET /redoc)",
          "Interaktywne testowanie endpointów",
          "OpenAPI schema"
        ]
      },
      {
        title: "Krok 8 — Interfejs Użytkownika (Web UI)",
        desc:  "Użytkownik otwiera Web UI w przeglądarce. Porównanie: Bielik bez RAG vs Bielik + RAG z BigQuery.",
        pts:   "+10 pkt",
        items: [
          "Web UI (GET /) — otwarta w przeglądarce",
          "Lewa: Bielik bez RAG (/ask_direct)",
          "Prawa: Bielik + RAG (/ask)",
          "Sekcja 'Użyty kontekst' z BigQuery",
          "Eksperymenty z motywem kolorów (Gemini CLI)"
        ]
      },
      {
        title: "Krok 9 — Certyfikat Ukończenia 🏆",
        desc:  "Gratulacje! Pełna architektura RAG wdrożona i działająca. Generuj zaszyfrowany certyfikat i wyślij prowadzącemu.",
        pts:   "75 pkt łącznie!",
        items: [
          "Certyfikat: cert_artifacts/checkpoint_N.enc",
          "./checkpoints/certyfikat_generate.sh",
          "cloudshell dl checkpoint_certyfikat.enc",
          "Misja 2 zakończona! 🦅"
        ]
      }
    ],

    tooltips: {
      'c-orch':     { title: "Orchestration API",        desc: "Centralny serwis FastAPI koordynujący pipeline RAG. Odbiera żądania HTTP, wyzwala embedding w Gemmie, odpytuje BigQuery i przekazuje kontekst do Bielika." },
      'c-bielik':   { title: "Bielik LLM",               desc: "Polski model językowy SpeakLeash/Bielik-4.5B serwowany przez Ollama na GPU L4. Generuje odpowiedzi po polsku na podstawie zapytania i kontekstu z BigQuery." },
      'c-gemma':    { title: "EmbeddingGemma",            desc: "Model embeddingów zamieniający tekst na wektory liczbowe. Używany dwukrotnie: przy /ingest (zasilanie bazy) i /ask (wyszukiwanie podobnych fragmentów)." },
      'c-bigquery': { title: "BigQuery Vector Search",    desc: "Wektorowa baza wiedzy w Google BigQuery. Przechowuje reguły hotelowe jako embeddingi i zwraca top-3 najbardziej zbliżone fragmenty metodą cosinus." },
      'c-storage':  { title: "Cloud Storage",             desc: "Bucket GCS z plikami modeli GGUF. Kontenery Ollama pobierają model przy starcie — dzięki temu obraz Docker pozostaje mały i wielokrotnie używalny." },
      'c-registry': { title: "Artifact Registry",         desc: "Prywatne repozytorium Docker w GCP. Przechowuje obraz z Ollama budowany przez Cloud Build. Cloud Run pobiera obraz stąd przy każdym wdrożeniu." },
      'c-shell':    { title: "Cloud Shell + Gemini CLI",  desc: "Przeglądarkowy terminal z dostępem do GCP i preinstalowanym Gemini CLI. Punkt startowy warsztatów — wszystkie skrypty checkpointowe uruchamiane są tutaj." },
      'c-user':     { title: "Użytkownik / Browser",      desc: "Uczestnik korzystający z Web UI. Wysyła pytania do Orchestration API i porównuje jakość odpowiedzi Bielika z RAG i bez RAG w czasie rzeczywistym." },
      'c-swagger':  { title: "Swagger UI",                desc: "Interaktywna dokumentacja API generowana przez FastAPI. Dostępna pod /docs — pozwala testować każdy endpoint bezpośrednio w przeglądarce." },
      'c-webui':    { title: "Web UI",                    desc: "Prosty interfejs HTML serwowany przez Orchestration API. Porównuje obok siebie odpowiedzi Bielika z RAG (/ask) i bez RAG (/ask_direct)." }
    }
  },

  /* ─────────────── ENGLISH ─────────────── */
  en: {
    ui: {
      splash: {
        title: "MISSION 2",
        sub:   "Eskadra Bielik · RAG · Google Cloud",
        hint:  "→ press arrow key"
      },
      badge: "Mission 2 · RAG · Google Cloud · Bielik + BigQuery",
      nav: {
        prev:  "← Back",
        next:  "Next →",
        step:  "Step",
        of:    "of"
      },
      panel: {
        stepOf:           "Step {n} of {total}",
        activeComponents: "Active components"
      },
      svgLabels: {
        user: "User / Browser"
      },
      progressDot: "Step {i}"
    },

    steps: [
      {
        title: "RAG Architecture — overview",
        desc:  "Full architecture of the RAG system built on Google Cloud. Each workshop step activates the next set of components.",
        pts:   null,
        items: []
      },
      {
        title: "Step 1 — Google Cloud Project",
        desc:  "Activate account with OnRamp credits, create a Google Cloud project and open Cloud Shell with the repository.",
        pts:   "+5 pts",
        items: [
          "Google Cloud Project",
          "Billing account (OnRamp)",
          "Cloud Shell",
          "Gemini CLI"
        ]
      },
      {
        title: "Step 2 — Service Configuration",
        desc:  "Enable required APIs: Cloud Run, Cloud Build, Artifact Registry, BigQuery. Grant IAM permissions.",
        pts:   "+10 pts",
        items: [
          "Cloud Run API",
          "BigQuery API",
          "Artifact Registry API",
          "Cloud Build API",
          "IAM roles/run.invoker"
        ]
      },
      {
        title: "Step 3 — Bielik LLM + EmbeddingGemma",
        desc:  "Copy models to Cloud Storage, build Docker image with Ollama, deploy both models to Cloud Run.",
        pts:   "+20 pts",
        items: [
          "Cloud Storage (GGUF models)",
          "Artifact Registry (Ollama Docker)",
          "Bielik LLM (Cloud Run #1 + GPU L4 + Ollama)",
          "EmbeddingGemma (Cloud Run #2 + Ollama, CPU)"
        ]
      },
      {
        title: "Step 4 — BigQuery Vector Search",
        desc:  "Initialize vector database: rag_dataset dataset and hotel_rules table with embedding column (FLOAT64 REPEATED).",
        pts:   "+5 pts",
        items: [
          "BigQuery dataset: rag_dataset",
          "Table: hotel_rules",
          "Column embedding FLOAT64 REPEATED",
          "Vector Search COSINE"
        ]
      },
      {
        title: "Step 5 — Orchestration API",
        desc:  "Deploy FastAPI application to Cloud Run. Orchestration connects EmbeddingGemma, BigQuery and Bielik into a single RAG pipeline.",
        pts:   "+10 pts",
        items: [
          "Orchestration API (FastAPI)",
          "POST /ingest — feed the database",
          "POST /ask — RAG query",
          "POST /ask_direct — without RAG",
          "GET /records — record browser"
        ]
      },
      {
        title: "Step 6 — API Testing (curl from Cloud Shell)",
        desc:  "Send CSV data via curl from Cloud Shell: /ingest (embed + BigQuery) and /ask (RAG pipeline).",
        pts:   "+10 pts",
        items: [
          "curl from Cloud Shell → /ingest",
          "POST /ingest → EmbeddingGemma → BigQuery",
          "curl from Cloud Shell → /ask",
          "POST /ask → embed → VECTOR_SEARCH → Bielik",
          "No Web UI — terminal only"
        ]
      },
      {
        title: "Step 7 — API Interface (Swagger)",
        desc:  "API documentation and interactive testing via Swagger UI (/docs) opened in the browser.",
        pts:   "+5 pts",
        items: [
          "Swagger UI (GET /docs)",
          "ReDoc (GET /redoc)",
          "Interactive endpoint testing",
          "OpenAPI schema"
        ]
      },
      {
        title: "Step 8 — User Interface (Web UI)",
        desc:  "User opens the Web UI in the browser. Side-by-side comparison: Bielik without RAG vs Bielik + RAG with BigQuery.",
        pts:   "+10 pts",
        items: [
          "Web UI (GET /) — open in browser",
          "Left: Bielik without RAG (/ask_direct)",
          "Right: Bielik + RAG (/ask)",
          "'Used context' section from BigQuery",
          "Colour theme experiments (Gemini CLI)"
        ]
      },
      {
        title: "Step 9 — Completion Certificate 🏆",
        desc:  "Congratulations! Full RAG architecture deployed and running. Generate the encrypted certificate and send it to the instructor.",
        pts:   "75 pts total!",
        items: [
          "Certificate: cert_artifacts/checkpoint_N.enc",
          "./checkpoints/certyfikat_generate.sh",
          "cloudshell dl checkpoint_certyfikat.enc",
          "Mission 2 complete! 🦅"
        ]
      }
    ],

    tooltips: {
      'c-orch':     { title: "Orchestration API",        desc: "Central FastAPI service coordinating the RAG pipeline. Accepts HTTP requests, triggers Gemma embedding, queries BigQuery and passes context to Bielik." },
      'c-bielik':   { title: "Bielik LLM",               desc: "Polish LLM SpeakLeash/Bielik-4.5B served via Ollama on a GPU L4. Generates Polish-language responses based on the query and context from BigQuery." },
      'c-gemma':    { title: "EmbeddingGemma",            desc: "Embedding model converting text to numerical vectors. Used twice: at /ingest (feeding the database) and /ask (similarity search against stored embeddings)." },
      'c-bigquery': { title: "BigQuery Vector Search",    desc: "Vector knowledge base in Google BigQuery. Stores hotel rules as embeddings and returns the top-3 most similar chunks using cosine similarity." },
      'c-storage':  { title: "Cloud Storage",             desc: "GCS bucket holding GGUF model files. Ollama containers download the model on startup — keeping Docker images small and reusable across deployments." },
      'c-registry': { title: "Artifact Registry",         desc: "Private Docker registry in GCP. Stores the Ollama-based image built by Cloud Build. Cloud Run pulls the image from here on every deployment." },
      'c-shell':    { title: "Cloud Shell + Gemini CLI",  desc: "Browser-based terminal with full GCP access and Gemini CLI pre-installed. Starting point of the workshop — all checkpoint scripts are run here." },
      'c-user':     { title: "User / Browser",            desc: "Workshop participant using the Web UI. Sends queries to the Orchestration API and compares Bielik response quality with and without RAG in real time." },
      'c-swagger':  { title: "Swagger UI",                desc: "Interactive API documentation auto-generated by FastAPI. Available at /docs — test every endpoint directly in the browser without any extra tools." },
      'c-webui':    { title: "Web UI",                    desc: "Simple HTML interface served by the Orchestration API. Shows Bielik responses with RAG (/ask) and without RAG (/ask_direct) side by side in real time." }
    }
  }

};
