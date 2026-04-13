# Architektura — Mapa repozytorium

Struktura plików w repozytorium i ich rola w architekturze.

```mermaid
graph TD
    subgraph REPO["📁 eskadra-bielik-misja2/"]
        SE["⚙️ setup_env.sh\nZmienne środowiskowe:\nPROJECT_ID, REGION,\nLLM_SERVICE, EMBEDDING_URL..."]
        DA["🔓 decode_artifact.py\nDeszyfrowanie certyfikatu\ndo weryfikacji punktacji"]

        subgraph LLM_DIR["📁 llm/  [Krok 3]"]
            L_DF["Dockerfile\nFROM ollama/ollama:latest\nbielik-4.5b-v3.0-instruct:Q8_0"]
            L_CR["cloud_run.sh\n8 vCPU · 16 GB · GPU L4\n--no-allow-unauthenticated"]
            L_CRN["cloud_run_no_gpu.sh\nDeploy bez GPU\n(fallback)"]
            L_T["llm_test1.sh\nTest: POST /api/chat"]
        end

        subgraph EMB_DIR["📁 embedding_model/  [Krok 3]"]
            E_DF["Dockerfile\nFROM ollama/ollama:latest\nembeddinggemma:latest"]
            E_CR["cloud_run.sh\nDeploy bez GPU"]
            E_T["embedding_test1.sh\nTest: POST /api/embed"]
        end

        subgraph VS_DIR["📁 vector_store/  [Krok 4]"]
            V_DB["init_db.py\nTworzy BigQuery dataset\ni tabelę hotel_rules"]
            V_CSV["hotel_rules.csv\nDane testowe\n(zasady hotelowe PL)"]
            V_SD["show_data.sh\nPodgląd danych w BQ"]
        end

        subgraph ORC_DIR["📁 orchestration/  [Krok 5]"]
            O_M["main.py\nFastAPI: /ingest /ask\n/ask_direct /records"]
            O_CR["cloud_run.sh\nDeploy z env vars:\nEMBEDDING_URL + LLM_URL"]
            O_ST["static/index.html\nWeb UI (porównanie\nRAG vs bez RAG)"]
        end

        subgraph CP_DIR["📁 checkpoints/  [Kroki 1–8]"]
            CP1["checkpoint_1..8.sh\nWeryfikacja każdego kroku\n+ zapis zaszyfrowanego artefaktu"]
            CP2["certyfikat_generate.sh\nGenerowanie certyfikatu\nz 8 artefaktów"]
            CP3["_encrypt.sh\nSzyfrowanie artefaktów\n(wewnętrzny helper)"]
        end

        subgraph SK_DIR["📁 skrypty/  [narzędzia]"]
            SK1["cleanup.sh\nUsunięcie wszystkich zasobów GCP"]
            SK2["cleanup_minimal.sh\nUsunięcie wybranych zasobów"]
            SK3["protect_files.sh\nOchrona plików źródłowych\nprzed edycją"]
            SK4["make_scripts_executable.sh\nNadanie uprawnień +x"]
            SK5["request_access.sh\nWniosek o dostęp"]
        end

        subgraph AD_DIR["📁 assets/diagrams/  [wizualizacje]"]
            AD1["architektura_interaktywna.html\nGłówny diagram systemu"]
            AD2["architektura_interaktywna_ingestion.html\nPipeline ingestion"]
            AD3["architektura_interaktywna_rag.html\nPipeline RAG"]
            AD4["serve.sh\nLokalny serwer HTTP\n(port 8080)"]
        end

        subgraph ARCH_DIR["📁 architektura/  [dokumentacja]"]
            A1["01_widok_systemowy.md"]
            A2["02_pipeline_rag.md"]
            A3["03_pipeline_ingestion.md"]
            A4["04_kroki_warsztatu.md"]
            A5["05_mapa_repozytorium.md"]
            A6["prompty_nano_banana.md"]
        end
    end
```

## Pliki konfiguracyjne środowiska

| Plik | Rola | Kiedy uruchamiać |
|---|---|---|
| `setup_env.sh` | Ustawia zmienne środowiskowe | Na początku każdej sesji terminala (`source`) |
| `skrypty/protect_files.sh` | Chroni pliki źródłowe przed edycją | Raz, po sklonowaniu repo |
| `skrypty/cleanup.sh` | Usuwa wszystkie zasoby GCP | Po zakończeniu warsztatu |
| `skrypty/cleanup_minimal.sh` | Usuwa wybrane zasoby GCP | Selektywne czyszczenie |

## Pliki Dockerfile — porównanie

| Komponent | Base image | Model | GPU |
|---|---|---|---|
| `llm/Dockerfile` | `ollama/ollama:latest` | `bielik-4.5b-v3.0-instruct:Q8_0` | Tak (L4) |
| `embedding_model/Dockerfile` | `ollama/ollama:latest` | `embeddinggemma:latest` | Nie |
| `orchestration/Dockerfile` | `python:3.11-slim` | — | Nie |

Wszystkie kontenery nasłuchują na porcie `8080` (wymaganie Cloud Run).
