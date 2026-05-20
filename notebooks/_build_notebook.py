"""Generator notebooka warsztatowego dla Colab.

Uruchom: python3 _build_notebook.py
Produkt: warsztat_colab.ipynb obok tego pliku.

Ten skrypt jest narzędziem deweloperskim — nie należy do warsztatu.
"""

import json
import pathlib

OUT = pathlib.Path(__file__).parent / "warsztat_colab.ipynb"


def md(*lines):
    return {
        "cell_type": "markdown",
        "metadata": {},
        "source": [l if l.endswith("\n") else l + "\n" for l in lines][:-1]
        + [lines[-1]],
    }


def code(*lines):
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": [l if l.endswith("\n") else l + "\n" for l in lines][:-1]
        + [lines[-1]],
    }


cells = []

# ------------------------------ NAGŁÓWEK ------------------------------

cells.append(md(
    "# Eskadra Bielik — Misja 2 — wariant Google Colab\n",
    "\n",
    "**RAG w oparciu o model Bielik i lokalną bazę wektorową — pełny warsztat na Colab z GPU.**\n",
    "\n",
    "Ten notebook jest *kompletnym ekwiwalentem* 8-krokowego warsztatu z `README.md`, przeniesionym na Colab. "
    "Zachowuje strukturę, checkpointy i certyfikat — z tą różnicą, że zamiast Cloud Run + BigQuery używamy:\n",
    "\n",
    "| Element warsztatu | Wariant GCP (oryginalny) | Wariant Colab (ten notebook) |\n",
    "|---|---|---|\n",
    "| Silnik LLM/embedding | Cloud Run + Ollama (GPU L4) | Ollama lokalnie + GPU T4 |\n",
    "| Model LLM | SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0 | **bez zmian** |\n",
    "| Model embedding | embeddinggemma | **bez zmian** |\n",
    "| Vector store | BigQuery + VECTOR_SEARCH | ChromaDB lokalnie |\n",
    "| Orchestrator | Cloud Run + FastAPI | FastAPI w wątku notebooka |\n",
    "| Web UI | URL z Cloud Run | iframe z `serve_kernel_port_as_iframe` |\n",
    "| Autoryzacja JWT | Google ID Token | brak (Ollama lokalnie) |\n",
    "| Checkpointy/certyfikat | format `.enc` AES-256-CBC | **bez zmian** (ten sam openssl) |\n",
    "\n",
    "## Co dostajesz\n",
    "\n",
    "- Pełny system RAG po polsku z modelem Bielik 4.5B\n",
    "- 8 checkpointów + certyfikat ukończenia (75 pkt) zgodne z wariantem GCP\n",
    "- Web UI porównujący odpowiedź z RAG vs. bez RAG — w komórce notebooka\n",
    "\n",
    "## Czego nie ma w wariancie Colab\n",
    "\n",
    "- **Dashboard prowadzącego (Pub/Sub)** — wymaga GCP. Postępy widzisz lokalnie w punktach.\n",
    "- **Zadania `🤖 Gemini CLI`** — odpadają, bo Gemini CLI to narzędzie Cloud Shell. Zastąpione komórkami Markdown z pytaniami otwartymi.\n",
    "- **Skrypty `gcloud`** — nie są potrzebne. Wszystko lokalnie.\n"
))

cells.append(md(
    "## Agenda warsztatu\n",
    "\n",
    "| # | Temat | Czas | Punkty |\n",
    "|---|---|---|:---:|\n",
    "| 0 | Setup Colab i weryfikacja GPU | 3 min | **5** |\n",
    "| 1 | Konfiguracja środowiska | 1 min | **10** |\n",
    "| 2 | Ollama + Bielik + EmbeddingGemma | 10 min | **20** |\n",
    "| 3 | Inicjalizacja lokalnej bazy wektorowej (ChromaDB) | 1 min | **5** |\n",
    "| 4 | Orchestrator FastAPI (lokalny) | 2 min | **10** |\n",
    "| 5 | Zasilanie bazy i pierwsze zapytania RAG | 5 min | **10** |\n",
    "| 6 | Przegląd API — Swagger /docs | 3 min | **5** |\n",
    "| 7 | Web UI w komórce notebooka | 5 min | **10** |\n",
    "| 8 | Checkpointy + certyfikat ukończenia | 5 min | — |\n",
    "| 9 | Sprzątanie | 1 min | — |\n",
    "| | **Łącznie** | **~36 min** | **75 pkt** |\n",
    "\n",
    "> 📌 **Punkty są przyznawane przez 8 checkpointów w sekcji 8.** "
    "Każdy checkpoint waliduje konkretną sekcję (CP1 → sekcja 0, CP2 → sekcja 1, CP3 → sekcja 2 itd.) "
    "i tworzy zaszyfrowany artefakt `cert_artifacts/checkpoint_N.enc` zgodny z wariantem GCP warsztatu.\n",
    "\n",
    "> ⏱️ **Czasy są szacunkowe i zakładają pierwsze uruchomienie**: pobieranie modelu Bielik ~3–5 min, "
    "EmbeddingGemma poniżej minuty, pojedyncze zapytanie do Bielika 5–15 s na T4. "
    "Przy kolejnych uruchomieniach modele są cache'owane na dysku Colab."
))

cells.append(md(
    "> ⚠️ **WAŻNE — zanim ruszysz dalej:**\n",
    ">\n",
    "> 1. **Włącz GPU**: `Środowisko wykonawcze → Zmień typ środowiska → GPU (T4)`. Bez GPU model Bielik będzie odpowiadał kilka minut na zapytanie.\n",
    "> 2. **Sesja Colab kończy się po ~12 h aktywnej pracy lub ~90 min bezczynności**. Modele Ollama (~5 GB) zostaną pobrane do `/root/.ollama/` i znikną po restarcie kernela — przejdź notebook za jednym posiedzeniem.\n",
    "> 3. **Zaplanuj ~45 min**: pierwsze pobranie modelu Bielik trwa 3–5 min, EmbeddingGemma poniżej minuty, każde zapytanie do Bielika 5–15 s.\n",
    ">\n",
    "> Jeśli zobaczysz, że `nvidia-smi` w kroku 0 zwraca błąd — wróć do menu i włącz GPU."
))

# ------------------------------ SEKCJA 0 ------------------------------

cells.append(md(
    "## 0. Setup Colab i weryfikacja GPU `~3 min`\n",
    "\n",
    "Odpowiednik kroku 1 warsztatu (Przygotowanie projektu Google Cloud) — w wariancie Colab tym co weryfikujemy jest GPU runtime i klon repo z hotel_rules.csv."
))

cells.append(code(
    "# [0.1] Czy GPU jest aktywny?\n",
    "!nvidia-smi"
))

cells.append(md(
    "Spodziewany wynik: tabela z `Tesla T4` (lub `L4`/`A100` jeśli Colab Pro) i informacją o pamięci ~15 GB. "
    "Jeśli widzisz `command not found` lub `No devices` — wróć do menu i włącz GPU."
))

cells.append(code(
    "# [0.2] Zależności systemowe Ollamy (wykrycie GPU + rozpakowanie instalatora)\n",
    "!sudo apt-get install -y -qq pciutils lshw zstd"
))

cells.append(code(
    "# [0.3] Klon repo warsztatowego — potrzebujemy hotel_rules.csv, static/index.html, checkpointów\n",
    "import os, pathlib\n",
    "\n",
    "REPO_DIR = '/content/eskadra-bielik-misja2'\n",
    "if not pathlib.Path(REPO_DIR).exists():\n",
    "    !git clone --depth 1 https://github.com/Legard777/eskadra-bielik-misja2.git {REPO_DIR}\n",
    "else:\n",
    "    print(f'Repo już sklonowane w {REPO_DIR}')\n",
    "\n",
    "os.chdir(REPO_DIR)\n",
    "!ls -la"
))

# ------------------------------ SEKCJA 1 ------------------------------

cells.append(md(
    "## 1. Konfiguracja środowiska `~1 min`\n",
    "\n",
    "Odpowiednik kroku 2 (`source setup_env.sh`). Zmienne pythonowe zamiast bash exportów."
))

cells.append(code(
    "# [1.1] Konfiguracja warsztatu\n",
    "# WORKSHOP_EMAIL i WORKSHOP_PROJECT są używane jako materiał do klucza szyfrującego\n",
    "# checkpointy — taki sam mechanizm jak w wariancie GCP (gcloud account + project).\n",
    "\n",
    "WORKSHOP_EMAIL = 'uczestnik@example.com'   # ⬅️ ZMIEŃ na swój email\n",
    "WORKSHOP_PROJECT = 'colab-warsztat-bielik' # placeholder zamiast project_id z GCP\n",
    "\n",
    "MODEL_LLM = 'SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0'\n",
    "MODEL_EMB = 'embeddinggemma'\n",
    "OLLAMA_URL = 'http://localhost:11434'\n",
    "ORCH_PORT = 8080\n",
    "CHROMA_DIR = '/content/chroma_db'\n",
    "COLLECTION_NAME = 'hotel_rules'\n",
    "STATIC_DIR = f'{REPO_DIR}/orchestration/static'\n",
    "CSV_PATH = f'{REPO_DIR}/vector_store/hotel_rules.csv'\n",
    "CERT_DIR = f'{REPO_DIR}/cert_artifacts'\n",
    "\n",
    "import os\n",
    "os.makedirs(CHROMA_DIR, exist_ok=True)\n",
    "os.makedirs(CERT_DIR, exist_ok=True)\n",
    "\n",
    "print('Konfiguracja gotowa:')\n",
    "for k, v in [('WORKSHOP_EMAIL', WORKSHOP_EMAIL), ('WORKSHOP_PROJECT', WORKSHOP_PROJECT),\n",
    "             ('MODEL_LLM', MODEL_LLM), ('MODEL_EMB', MODEL_EMB),\n",
    "             ('CHROMA_DIR', CHROMA_DIR), ('CERT_DIR', CERT_DIR)]:\n",
    "    print(f'  {k:20s} = {v}')"
))

cells.append(md(
    "> 📌 **Email decyduje o kluczu szyfrowania certyfikatu** — jeśli zmienisz email po wygenerowaniu części checkpointów, kolejne checkpointy będą szyfrowane innym kluczem i certyfikat nie zostanie odszyfrowany jednym hasłem. Ustaw email **raz, na samym początku**."
))

# ------------------------------ SEKCJA 2 ------------------------------

cells.append(md(
    "## 2. Ollama + Bielik + EmbeddingGemma `~10 min`\n",
    "\n",
    "Odpowiednik kroku 3 warsztatu (Cloud Run + Ollama z modelami). Tu instalujemy Ollamę lokalnie w Colab i pobieramy oba modele bezpośrednio z Ollama Hub."
))

cells.append(code(
    "# [2.1] Instalacja Ollama\n",
    "!curl -fsSL https://ollama.com/install.sh | sh"
))

cells.append(code(
    "# [2.2] Uruchomienie Ollama serve w tle\n",
    "import subprocess, time, requests\n",
    "\n",
    "# Sprawdź czy nie działa już\n",
    "try:\n",
    "    requests.get(f'{OLLAMA_URL}/api/tags', timeout=2)\n",
    "    print('Ollama już działa.')\n",
    "except Exception:\n",
    "    ollama_proc = subprocess.Popen(\n",
    "        ['ollama', 'serve'],\n",
    "        stdout=subprocess.DEVNULL,\n",
    "        stderr=subprocess.DEVNULL,\n",
    "    )\n",
    "    # Czekamy aż złapie port 11434\n",
    "    for _ in range(30):\n",
    "        try:\n",
    "            requests.get(f'{OLLAMA_URL}/api/tags', timeout=1)\n",
    "            print('Ollama wystartowała.')\n",
    "            break\n",
    "        except Exception:\n",
    "            time.sleep(1)\n",
    "    else:\n",
    "        raise RuntimeError('Ollama nie wystartowała w 30 s — sprawdź logi')\n",
    "\n",
    "# Weryfikacja: czy widzi GPU?\n",
    "import json\n",
    "tags = requests.get(f'{OLLAMA_URL}/api/tags').json()\n",
    "print('Modele już dostępne:', [m['name'] for m in tags.get('models', [])] or '(jeszcze żadne)')"
))

cells.append(code(
    "# [2.3] Pobranie modelu Bielik 4.5B Q8_0 (~4.7 GB) — pierwsze pobranie 3–5 min\n",
    "import subprocess\n",
    "print(f'Pobieram {MODEL_LLM}...')\n",
    "result = subprocess.run(['ollama', 'pull', MODEL_LLM], check=True)\n",
    "print('Bielik gotowy.')"
))

cells.append(code(
    "# [2.4] Pobranie modelu EmbeddingGemma (~0.5 GB) — pierwsze pobranie poniżej minuty\n",
    "import subprocess\n",
    "print(f'Pobieram {MODEL_EMB}...')\n",
    "result = subprocess.run(['ollama', 'pull', MODEL_EMB], check=True)\n",
    "print('EmbeddingGemma gotowa.')\n",
    "\n",
    "# Lista zainstalowanych modeli\n",
    "!ollama list"
))

cells.append(code(
    "# [2.5] Test Bielika — pierwsze polskie zapytanie (bez RAG, bez kontekstu)\n",
    "import requests, time, json\n",
    "\n",
    "t0 = time.time()\n",
    "r = requests.post(f'{OLLAMA_URL}/api/chat', json={\n",
    "    'model': MODEL_LLM,\n",
    "    'messages': [{'role': 'user', 'content': 'Jak często powinien być mierzony poziom chloru w basenie?'}],\n",
    "    'stream': False,\n",
    "})\n",
    "r.raise_for_status()\n",
    "data = r.json()\n",
    "elapsed_ms = int((time.time() - t0) * 1000)\n",
    "print(json.dumps({\n",
    "    'odpowiedz': data['message']['content'],\n",
    "    'model': MODEL_LLM,\n",
    "    'czas_ms': elapsed_ms,\n",
    "}, ensure_ascii=False, indent=2))"
))

cells.append(code(
    "# [2.6] Test EmbeddingGemma — wektor 768-wymiarowy dla polskiego tekstu\n",
    "import requests, time, json\n",
    "\n",
    "t0 = time.time()\n",
    "r = requests.post(f'{OLLAMA_URL}/api/embed', json={\n",
    "    'model': MODEL_EMB,\n",
    "    'input': 'Suwerenne AI po polsku — Bielik i RAG w Google Cloud',\n",
    "})\n",
    "r.raise_for_status()\n",
    "vec = r.json()['embeddings'][0]\n",
    "elapsed_ms = int((time.time() - t0) * 1000)\n",
    "print(json.dumps({\n",
    "    'model': MODEL_EMB,\n",
    "    'wymiary': len(vec),\n",
    "    'czas_ms': elapsed_ms,\n",
    "    'pierwsze_5_wartosci': [round(x, 4) for x in vec[:5]],\n",
    "}, ensure_ascii=False, indent=2))"
))

cells.append(md(
    "> 💡 **Zwróć uwagę:** Bielik odpowiedział na podstawie ogólnej wiedzy o pływalniach. W kroku 5 zobaczysz jak ta sama odpowiedź wygląda z kontekstem RAG — bazując na konkretnej zasadzie hotelowej (reguła 12: pomiar **co równe trzy godziny**).\n",
    "\n",
    "> 💡 **Wymiar 768** jest stały dla `embeddinggemma` — niezależnie od długości tekstu wejściowego."
))

# ------------------------------ SEKCJA 3 ------------------------------

cells.append(md(
    "## 3. Inicjalizacja lokalnej bazy wektorowej (ChromaDB) `~1 min`\n",
    "\n",
    "Odpowiednik kroku 4 warsztatu (BigQuery + Vector Search). W wariancie Colab używamy ChromaDB — lokalnej bazy wektorowej z indeksem HNSW. Ten sam schemat: `id`, `content`, `embedding` (768d)."
))

cells.append(code(
    "# [3.1] Instalacja Chroma\n",
    "!pip install -q chromadb"
))

cells.append(md(
    "> ℹ️ **`ERROR: pip's dependency resolver...` — to NIE jest błąd, możesz przejść dalej.**\n",
    ">\n",
    "> ChromaDB instaluje nowszą wersję `opentelemetry-sdk` (1.42) niż chcą widzieć preinstalowane na Colab biblioteki Google (`google-adk`, `opentelemetry-exporter-gcp-logging`). "
    "Te biblioteki **nie są używane w warsztacie** — konflikt jest czysto kosmetyczny i nie wpływa na działanie Chromy ani RAG-a.\n",
    ">\n",
    "> Jeśli komórka pokazuje zielony tick (✓) po lewej — instalacja się udała. Idź do 3.2."
))

cells.append(code(
    "# [3.2] Utworzenie kolekcji\n",
    "import chromadb\n",
    "\n",
    "chroma_client = chromadb.PersistentClient(path=CHROMA_DIR)\n",
    "\n",
    "# embedding_function=None — wektory podajemy ręcznie z Ollamy (EmbeddingGemma).\n",
    "# Chroma nie generuje embeddingów automatycznie — pełna kontrola, jak w wariancie GCP.\n",
    "collection = chroma_client.get_or_create_collection(\n",
    "    name=COLLECTION_NAME,\n",
    "    embedding_function=None,\n",
    "    metadata={'hnsw:space': 'cosine'},\n",
    ")\n",
    "\n",
    "print(f'Kolekcja \"{COLLECTION_NAME}\" gotowa. Rekordów: {collection.count()}')"
))

# ------------------------------ SEKCJA 4 ------------------------------

cells.append(md(
    "## 4. Orchestrator FastAPI (lokalny) `~2 min`\n",
    "\n",
    "Odpowiednik kroku 5 (Cloud Run + Orchestration API). Definiujemy te same 5 endpointów (`/`, `/ingest`, `/ask`, `/ask_direct`, `/records`) — różnice:\n",
    "\n",
    "- **Bez JWT** — Ollama lokalnie\n",
    "- **Chroma** zamiast BigQuery — `collection.query(query_embeddings=..., n_results=3)` zamiast `VECTOR_SEARCH(...COSINE)`\n",
    "- **uvicorn w wątku** zamiast osobnego kontenera"
))

cells.append(code(
    "# [4.1] Zależności orchestratora\n",
    "!pip install -q fastapi uvicorn nest_asyncio python-multipart"
))

cells.append(code(
    "# [4.2] Definicja aplikacji FastAPI (inline, bez JWT, na Chroma)\n",
    "from fastapi import FastAPI, File, UploadFile, HTTPException\n",
    "from fastapi.staticfiles import StaticFiles\n",
    "from fastapi.responses import FileResponse\n",
    "from pydantic import BaseModel\n",
    "import requests, csv, io\n",
    "\n",
    "app = FastAPI(\n",
    "    title='RAG API (Bielik & EmbeddingGemma) — wariant Colab',\n",
    "    description='Lokalna wersja warsztatowa: Ollama + ChromaDB',\n",
    "    version='1.0.0-colab',\n",
    ")\n",
    "\n",
    "app.mount('/static', StaticFiles(directory=STATIC_DIR), name='static')\n",
    "\n",
    "@app.get('/', include_in_schema=False)\n",
    "def root():\n",
    "    return FileResponse(f'{STATIC_DIR}/index.html')\n",
    "\n",
    "def get_embedding(text: str) -> list:\n",
    "    r = requests.post(f'{OLLAMA_URL}/api/embed',\n",
    "                      json={'model': MODEL_EMB, 'input': text})\n",
    "    r.raise_for_status()\n",
    "    return r.json()['embeddings'][0]\n",
    "\n",
    "class AskRequest(BaseModel):\n",
    "    query: str\n",
    "\n",
    "@app.post('/ingest', tags=['Ingestion'])\n",
    "async def ingest_csv(file: UploadFile = File(...)):\n",
    "    content = await file.read()\n",
    "    reader = csv.DictReader(io.StringIO(content.decode('utf-8')))\n",
    "    ids, docs, embs = [], [], []\n",
    "    for row in reader:\n",
    "        doc_id = row.get('id'); text = row.get('text')\n",
    "        if not doc_id or not text:\n",
    "            continue\n",
    "        try:\n",
    "            embs.append(get_embedding(text))\n",
    "            ids.append(doc_id); docs.append(text)\n",
    "        except Exception as e:\n",
    "            print(f'Błąd embedding dla {doc_id}: {e}')\n",
    "    if ids:\n",
    "        # upsert: idempotentne — kolejne /ingest nie zduplikują\n",
    "        collection.upsert(ids=ids, documents=docs, embeddings=embs)\n",
    "    return {'status': 'success', 'inserted_count': len(ids)}\n",
    "\n",
    "@app.post('/ask', tags=['RAG'])\n",
    "async def ask(req: AskRequest):\n",
    "    qe = get_embedding(req.query)\n",
    "    res = collection.query(query_embeddings=[qe], n_results=3)\n",
    "    context_docs = res['documents'][0]\n",
    "    context_ids = res['ids'][0]\n",
    "    distances = res['distances'][0]\n",
    "    # Chroma zwraca cosine distance (0 = identyczny, 2 = przeciwny);\n",
    "    # przeliczamy na % podobieństwa: (1 - dist) * 100, dist ∈ [0,1] dla tekstów\n",
    "    scores = [round(max(0.0, 1 - d) * 100, 1) for d in distances]\n",
    "    context_text = '\\\\n\\\\n'.join(context_docs)\n",
    "    prompt = (\n",
    "        f'Jesteś pomocnym asystentem odpowiadającym na pytania dotyczące zasad hotelowych. '\n",
    "        f'Odpowiedz na poniższe pytanie bazując TYLKO na dostarczonym kontekście.\\\\n\\\\n'\n",
    "        f'KONTEKST:\\\\n{context_text}\\\\n\\\\n'\n",
    "        f'PYTANIE:\\\\n{req.query}'\n",
    "    )\n",
    "    r = requests.post(f'{OLLAMA_URL}/api/chat', json={\n",
    "        'model': MODEL_LLM,\n",
    "        'messages': [{'role': 'user', 'content': prompt}],\n",
    "        'stream': False,\n",
    "    })\n",
    "    r.raise_for_status()\n",
    "    answer = r.json().get('message', {}).get('content', '')\n",
    "    avg = round(sum(scores) / len(scores), 1) if scores else 0.0\n",
    "    return {\n",
    "        'answer': answer,\n",
    "        'context_used': context_docs,\n",
    "        'context_ids': context_ids,\n",
    "        'context_scores': scores,\n",
    "        'confidence': avg,\n",
    "    }\n",
    "\n",
    "@app.post('/ask_direct', tags=['RAG'])\n",
    "async def ask_direct(req: AskRequest):\n",
    "    prompt = f'Odpowiedz na poniższe pytanie w sposób jasny i zwięzły:\\\\n\\\\nPYTANIE:\\\\n{req.query}'\n",
    "    r = requests.post(f'{OLLAMA_URL}/api/chat', json={\n",
    "        'model': MODEL_LLM,\n",
    "        'messages': [{'role': 'user', 'content': prompt}],\n",
    "        'stream': False,\n",
    "    })\n",
    "    r.raise_for_status()\n",
    "    return {'answer': r.json().get('message', {}).get('content', '')}\n",
    "\n",
    "@app.get('/records', tags=['Ingestion'])\n",
    "async def records(limit: int = 100):\n",
    "    got = collection.get(limit=limit)\n",
    "    return {\n",
    "        'total': len(got['ids']),\n",
    "        'records': [{'id': i, 'content': c} for i, c in zip(got['ids'], got['documents'])],\n",
    "    }\n",
    "\n",
    "print('FastAPI app zdefiniowane:', [r.path for r in app.routes if hasattr(r, 'path')])"
))

cells.append(code(
    "# [4.3] Uruchomienie uvicorn w tle (osobny wątek)\n",
    "# Używamy uvicorn.Server (nie uvicorn.run) żeby przy ponownym uruchomieniu komórki\n",
    "# 4.2/4.3 zatrzymać stary serwer i wystartować nowy z aktualnym `app`.\n",
    "# Dodatkowo: jeśli port jest jeszcze w TIME_WAIT po starym serwerze, próbujemy 8081/8082/8083.\n",
    "import socket, threading, uvicorn, nest_asyncio, time, requests as _r\n",
    "\n",
    "nest_asyncio.apply()\n",
    "\n",
    "# Jeśli wisi serwer z poprzedniego runu — zatrzymaj go (agresywnie)\n",
    "if '_orch_server' in globals():\n",
    "    try:\n",
    "        globals()['_orch_server'].should_exit = True\n",
    "        globals()['_orch_server'].force_exit = True\n",
    "        time.sleep(3)\n",
    "        print('Poprzedni orchestrator zatrzymany.')\n",
    "    except Exception as e:\n",
    "        print(f'Ostrzeżenie przy zatrzymywaniu: {e}')\n",
    "\n",
    "def _port_free(p):\n",
    "    with socket.socket() as s:\n",
    "        try:\n",
    "            s.bind(('0.0.0.0', p)); return True\n",
    "        except OSError:\n",
    "            return False\n",
    "\n",
    "# Znajdź pierwszy wolny port w preferowanym zakresie\n",
    "for _p in [ORCH_PORT, 8081, 8082, 8083]:\n",
    "    if _port_free(_p):\n",
    "        ORCH_PORT = _p\n",
    "        break\n",
    "else:\n",
    "    raise RuntimeError('Brak wolnych portów w 8080-8083 — zrestartuj kernel (Runtime → Restart)')\n",
    "\n",
    "config = uvicorn.Config(app, host='0.0.0.0', port=ORCH_PORT, log_level='warning')\n",
    "_orch_server = uvicorn.Server(config)\n",
    "threading.Thread(target=_orch_server.run, daemon=True).start()\n",
    "\n",
    "for _ in range(20):\n",
    "    try:\n",
    "        _r.get(f'http://localhost:{ORCH_PORT}/docs', timeout=1)\n",
    "        # Sanity check: czy uvicorn faktycznie widzi nasze endpointy?\n",
    "        paths = _r.get(f'http://localhost:{ORCH_PORT}/openapi.json').json().get('paths', {})\n",
    "        assert '/ingest' in paths, f'uvicorn serwuje starszą appkę — routes: {sorted(paths.keys())}'\n",
    "        print(f'Orchestrator wystartował na :{ORCH_PORT}')\n",
    "        print(f'Routes: {sorted(paths.keys())}')\n",
    "        break\n",
    "    except AssertionError:\n",
    "        raise\n",
    "    except Exception:\n",
    "        time.sleep(0.5)\n",
    "else:\n",
    "    raise RuntimeError('Orchestrator nie odpowiedział w 10 s')"
))

# ------------------------------ SEKCJA 5 ------------------------------

cells.append(md(
    "## 5. Zasilanie bazy i pierwsze zapytania RAG `~5 min`\n",
    "\n",
    "Odpowiednik kroku 6 warsztatu. Wgrywamy `hotel_rules.csv` przez `/ingest`, potem 3 testowe pytania `/ask`."
))

cells.append(code(
    "# [5.1] Podgląd danych wejściowych\n",
    "!head -5 {CSV_PATH}\n",
    "print('...')\n",
    "!wc -l {CSV_PATH}"
))

cells.append(code(
    "# [5.2] Zasilenie bazy — wyśle CSV przez /ingest, każdy wiersz wygeneruje embedding\n",
    "import requests, json\n",
    "\n",
    "with open(CSV_PATH, 'rb') as f:\n",
    "    r = requests.post(f'http://localhost:{ORCH_PORT}/ingest',\n",
    "                      files={'file': ('hotel_rules.csv', f, 'text/csv')})\n",
    "r.raise_for_status()\n",
    "print(json.dumps(r.json(), ensure_ascii=False, indent=2))\n",
    "print(f'Stan kolekcji Chroma: {collection.count()} rekordów')"
))

cells.append(code(
    "# [5.3] Test RAG — chlor w basenie\n",
    "import requests, json\n",
    "r = requests.post(f'http://localhost:{ORCH_PORT}/ask',\n",
    "                  json={'query': 'Jak często powinien być mierzony poziom chloru w basenie?'})\n",
    "r.raise_for_status()\n",
    "print(json.dumps(r.json(), ensure_ascii=False, indent=2))"
))

cells.append(md(
    "> 💡 Porównaj z odpowiedzią Bielika bez RAG z kroku 2.5 — tam model odpowiedział ogólnikowo. "
    "Tutaj RAG znalazł w Chromie regułę nr 3: **co równe trzy godziny**."
))

cells.append(code(
    "# [5.4] Test RAG — śniadanie i parking\n",
    "import requests, json\n",
    "for q in ['O której godzinie jest podawane śniadanie?',\n",
    "          'Ile kosztuje parking hotelowy?']:\n",
    "    r = requests.post(f'http://localhost:{ORCH_PORT}/ask', json={'query': q})\n",
    "    r.raise_for_status()\n",
    "    print(f'\\n--- Pytanie: {q} ---')\n",
    "    print(json.dumps(r.json(), ensure_ascii=False, indent=2))"
))

# ------------------------------ SEKCJA 6 ------------------------------

cells.append(md(
    "## 6. Przegląd API — Swagger /docs `~3 min`\n",
    "\n",
    "Odpowiednik kroku 7. FastAPI automatycznie generuje interaktywną dokumentację — Colab daje nam publiczny URL przez `kernel.proxyPort`."
))

cells.append(code(
    "# [6.1] Publiczny URL do /docs\n",
    "from google.colab.output import eval_js\n",
    "proxy_base = eval_js(f'google.colab.kernel.proxyPort({ORCH_PORT})').rstrip('/')\n",
    "print('Otwórz Swagger UI w nowej karcie:')\n",
    "print(f'  {proxy_base}/docs')\n",
    "print()\n",
    "print('Lista wszystkich endpointów:')\n",
    "for r in app.routes:\n",
    "    if hasattr(r, 'path') and hasattr(r, 'methods'):\n",
    "        for m in (r.methods or []):\n",
    "            if m in ('GET', 'POST'):\n",
    "                print(f'  {m:5s} {r.path}')"
))

# ------------------------------ SEKCJA 7 ------------------------------

cells.append(md(
    "## 7. Web UI w komórce notebooka `~5 min`\n",
    "\n",
    "Odpowiednik kroku 8 — interfejs graficzny porównujący odpowiedź modelu z RAG i bez RAG. "
    "W Colab osadzamy go bezpośrednio w wyjściu komórki przez `serve_kernel_port_as_iframe`."
))

cells.append(code(
    "# [7.1] Web UI w iframe — RAG vs. bez RAG, obie kolumny obok siebie\n",
    "from google.colab.output import serve_kernel_port_as_iframe\n",
    "serve_kernel_port_as_iframe(ORCH_PORT, height='800')"
))

cells.append(md(
    "**Przykładowe pytania do wpisania:**\n",
    "- *Do której godziny jest otwarty basen?*\n",
    "- *Czy mogę zabrać psa do hotelu?*\n",
    "- *Jak połączyć się z WiFi?*\n",
    "\n",
    "Porównaj **lewą kolumnę** (model bez RAG) z **prawą** (model + kontekst z Chromy). "
    "Prawa kolumna pokazuje także użyte fragmenty z bazy i ich procent podobieństwa."
))

# ------------------------------ SEKCJA 8 ------------------------------

cells.append(md(
    "## 8. Checkpointy + certyfikat ukończenia `~5 min`\n",
    "\n",
    "Mechanizm punktów zachowany z warsztatu GCP — każdy checkpoint produkuje plik `cert_artifacts/checkpoint_N.enc` "
    "zaszyfrowany openssl AES-256-CBC z kluczem opartym o `WORKSHOP_EMAIL` i `WORKSHOP_PROJECT`.\n",
    "\n",
    "**Mapowanie punktów (75 pkt łącznie):**\n",
    "\n",
    "| Checkpoint | Walidacja Colab | Punkty |\n",
    "|---|---|---|\n",
    "| 1 — Projekt | repo sklonowane + GPU widoczny | 5 |\n",
    "| 2 — Konfiguracja | zmienne `WORKSHOP_*` ustawione, Ollama proces żyje | 10 |\n",
    "| 3 — Modele | Bielik + EmbeddingGemma w `ollama list` | 20 |\n",
    "| 4 — Vector store | kolekcja Chroma istnieje | 5 |\n",
    "| 5 — Orchestrator | `GET /docs` → 200 | 10 |\n",
    "| 6 — RAG | `collection.count() == 19`, `/ask` → 200 | 10 |\n",
    "| 7 — Przegląd API | `/`, `/docs`, `/records` → 200 | 5 |\n",
    "| 8 — Web UI | `/ask`, `/ask_direct` → 200 | 10 |"
))

cells.append(code(
    "# [8.1] Wspólny helper — szyfrowanie checkpointu (kompatybilne z _encrypt.sh)\n",
    "import hashlib, subprocess, datetime, os, pathlib\n",
    "\n",
    "HEADER_TEXT = 'Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud'\n",
    "CHECKPOINT_POINTS = {1: 5, 2: 10, 3: 20, 4: 5, 5: 10, 6: 10, 7: 5, 8: 10}\n",
    "CHECKPOINT_LABELS = {\n",
    "    1: 'Setup Colab + GPU',\n",
    "    2: 'Konfiguracja warsztatu i Ollama',\n",
    "    3: 'Modele Bielik + EmbeddingGemma',\n",
    "    4: 'Vector store (ChromaDB)',\n",
    "    5: 'Orchestrator FastAPI',\n",
    "    6: 'Zasilanie bazy i zapytania RAG',\n",
    "    7: 'Przegląd API',\n",
    "    8: 'Web UI w iframe',\n",
    "}\n",
    "CHECKPOINT_MSGS = {\n",
    "    1: 'Colab gotowy, GPU aktywny!',\n",
    "    2: 'Konfiguracja i Ollama dziala. Czas na modele!',\n",
    "    3: 'Oba modele zaladowane na GPU. Najtrudniejszy krok za Toba!',\n",
    "    4: 'Baza wektorowa Chroma gotowa.',\n",
    "    5: 'API Orchestration w tle. System RAG zlozony!',\n",
    "    6: 'Wyszukiwanie semantyczne dziala. Jeden krok do mety!',\n",
    "    7: 'Architektura przejrzana i zrozumiana. Ostatni krok!',\n",
    "    8: 'WARSZTAT UKONCZONY! Wygeneruj certyfikat i pochwal sie wynikiem.',\n",
    "}\n",
    "\n",
    "def _key():\n",
    "    \"\"\"SHA512(HEADER|project|account) — identycznie jak _encrypt.sh::_checkpoint_save.\"\"\"\n",
    "    raw = f'{HEADER_TEXT}|{WORKSHOP_PROJECT}|{WORKSHOP_EMAIL}'\n",
    "    return hashlib.sha512(raw.encode('utf-8')).hexdigest()\n",
    "\n",
    "def save_checkpoint(num, content):\n",
    "    \"\"\"Tworzy cert_artifacts/checkpoint_N.enc w formacie zgodnym z wariantem GCP.\"\"\"\n",
    "    key = _key()\n",
    "    ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')\n",
    "    proc = subprocess.run(\n",
    "        ['openssl', 'enc', '-aes-256-cbc', '-pbkdf2', '-iter', '100000',\n",
    "         '-pass', f'pass:{key}', '-base64'],\n",
    "        input=content.encode('utf-8'),\n",
    "        capture_output=True,\n",
    "        check=True,\n",
    "    )\n",
    "    encrypted = proc.stdout.decode('utf-8').strip()\n",
    "    path = pathlib.Path(CERT_DIR) / f'checkpoint_{num}.enc'\n",
    "    path.write_text(\n",
    "        f'PROJECT_ID: {WORKSHOP_PROJECT}\\n'\n",
    "        f'ACCOUNT: {WORKSHOP_EMAIL}\\n'\n",
    "        f'CHECKPOINT: {num}\\n'\n",
    "        f'TIMESTAMP: {ts}\\n'\n",
    "        f'---BEGIN ENCRYPTED---\\n{encrypted}\\n---END ENCRYPTED---\\n'\n",
    "    )\n",
    "    earned = sum(CHECKPOINT_POINTS[i] for i in range(1, 9)\n",
    "                 if (pathlib.Path(CERT_DIR) / f'checkpoint_{i}.enc').exists())\n",
    "    total = sum(CHECKPOINT_POINTS.values())\n",
    "    width = 30; filled = earned * width // total\n",
    "    bar = '[' + '#' * filled + '.' * (width - filled) + f'] {earned * 100 // total}%'\n",
    "    print('=' * 54)\n",
    "    print(f'  CHECKPOINT {num} ZALICZONY!')\n",
    "    print(f'  {CHECKPOINT_LABELS[num]}')\n",
    "    print('=' * 54)\n",
    "    print(f'  Punkty za ten krok : +{CHECKPOINT_POINTS[num]} pkt')\n",
    "    print(f'  Lacznie            : {earned} / {total} pkt')\n",
    "    print(f'  Postep             : {bar}')\n",
    "    print('=' * 54)\n",
    "    print(f'  {CHECKPOINT_MSGS[num]}')\n",
    "    print(f'  Artefakt           : cert_artifacts/checkpoint_{num}.enc')\n",
    "    print('=' * 54)\n",
    "\n",
    "print('Helper checkpointów gotowy.')"
))

cells.append(code(
    "# [8.2] Checkpoint 1 — Setup Colab + GPU\n",
    "import subprocess, json\n",
    "errors = []\n",
    "gpu_info = subprocess.run(['nvidia-smi', '-L'], capture_output=True, text=True)\n",
    "if gpu_info.returncode == 0 and 'GPU' in gpu_info.stdout:\n",
    "    print('[OK] GPU widoczny:', gpu_info.stdout.strip().split('\\n')[0])\n",
    "else:\n",
    "    print('[!!] GPU niedostępny — włącz GPU runtime'); errors.append('gpu')\n",
    "\n",
    "if pathlib.Path(REPO_DIR).exists():\n",
    "    print(f'[OK] Repo sklonowane: {REPO_DIR}')\n",
    "else:\n",
    "    print('[!!] Brak repo'); errors.append('repo')\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(1, f'CHECKPOINT_1_COLAB_SETUP\\nemail={WORKSHOP_EMAIL}\\nproject={WORKSHOP_PROJECT}\\ngpu={gpu_info.stdout.strip()}\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}. Popraw i uruchom ponownie.')"
))

cells.append(code(
    "# [8.3] Checkpoint 2 — Konfiguracja warsztatu i Ollama\n",
    "import requests\n",
    "errors = []\n",
    "if WORKSHOP_EMAIL and '@' in WORKSHOP_EMAIL and WORKSHOP_EMAIL != 'uczestnik@example.com':\n",
    "    print(f'[OK] WORKSHOP_EMAIL ustawione: {WORKSHOP_EMAIL}')\n",
    "else:\n",
    "    print('[!!] WORKSHOP_EMAIL — zmień placeholder na swój email'); errors.append('email')\n",
    "\n",
    "try:\n",
    "    requests.get(f'{OLLAMA_URL}/api/tags', timeout=2).raise_for_status()\n",
    "    print(f'[OK] Ollama nasłuchuje na {OLLAMA_URL}')\n",
    "except Exception as e:\n",
    "    print(f'[!!] Ollama nie działa: {e}'); errors.append('ollama')\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(2, f'CHECKPOINT_2_KONFIGURACJA\\nemail={WORKSHOP_EMAIL}\\nproject={WORKSHOP_PROJECT}\\nollama_url={OLLAMA_URL}\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.4] Checkpoint 3 — Modele Bielik + EmbeddingGemma\n",
    "import requests\n",
    "errors = []\n",
    "tags = requests.get(f'{OLLAMA_URL}/api/tags').json()\n",
    "names = [m['name'] for m in tags.get('models', [])]\n",
    "if any(MODEL_LLM in n or MODEL_LLM.split(':')[0] in n for n in names):\n",
    "    print(f'[OK] Model LLM dostępny: {MODEL_LLM}')\n",
    "else:\n",
    "    print(f'[!!] Brak {MODEL_LLM} — uruchom sekcję 2.3'); errors.append('llm')\n",
    "\n",
    "if any(MODEL_EMB in n for n in names):\n",
    "    print(f'[OK] Model EMB dostępny: {MODEL_EMB}')\n",
    "else:\n",
    "    print(f'[!!] Brak {MODEL_EMB} — uruchom sekcję 2.4'); errors.append('emb')\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(3, f'CHECKPOINT_3_MODELE\\nllm={MODEL_LLM}\\nemb={MODEL_EMB}\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.5] Checkpoint 4 — Vector store\n",
    "errors = []\n",
    "try:\n",
    "    c = chroma_client.get_collection(COLLECTION_NAME)\n",
    "    print(f'[OK] Kolekcja \"{COLLECTION_NAME}\" istnieje')\n",
    "    print(f'[OK] Konfiguracja przestrzeni: {c.metadata}')\n",
    "except Exception as e:\n",
    "    print(f'[!!] Brak kolekcji: {e}'); errors.append('coll')\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(4, f'CHECKPOINT_4_VECTOR_STORE\\ncollection={COLLECTION_NAME}\\nspace=cosine\\ndimensions=768\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.6] Checkpoint 5 — Orchestrator FastAPI\n",
    "import requests\n",
    "errors = []\n",
    "for ep in ['/docs', '/']:\n",
    "    try:\n",
    "        r = requests.get(f'http://localhost:{ORCH_PORT}{ep}', timeout=5)\n",
    "        if r.status_code == 200:\n",
    "            print(f'[OK] {ep} → HTTP 200')\n",
    "        else:\n",
    "            print(f'[!!] {ep} → HTTP {r.status_code}'); errors.append(ep)\n",
    "    except Exception as e:\n",
    "        print(f'[!!] {ep} — {e}'); errors.append(ep)\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(5, f'CHECKPOINT_5_ORCHESTRATOR\\nport={ORCH_PORT}\\nendpoints_ok=docs,root\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.7] Checkpoint 6 — Dane w bazie + zapytania RAG\n",
    "import requests\n",
    "errors = []\n",
    "count = collection.count()\n",
    "if count == 19:\n",
    "    print(f'[OK] Rekordy w Chroma: {count} (oczekiwano 19)')\n",
    "else:\n",
    "    print(f'[!!] Rekordy w Chroma: {count} (oczekiwano 19) — uruchom /ingest'); errors.append('count')\n",
    "\n",
    "try:\n",
    "    r = requests.post(f'http://localhost:{ORCH_PORT}/ask',\n",
    "                      json={'query': 'Jak często mierzyć chlor?'}, timeout=60)\n",
    "    if r.status_code == 200 and r.json().get('answer'):\n",
    "        print(f'[OK] /ask zwrócił odpowiedź ({len(r.json()[\"answer\"])} znaków)')\n",
    "    else:\n",
    "        print(f'[!!] /ask → {r.status_code}'); errors.append('ask')\n",
    "except Exception as e:\n",
    "    print(f'[!!] /ask błąd: {e}'); errors.append('ask')\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(6, f'CHECKPOINT_6_RAG\\nrecords={count}\\ndimensions=768\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.8] Checkpoint 7 — Przegląd API\n",
    "import requests\n",
    "errors = []\n",
    "for ep in ['/', '/docs', '/records']:\n",
    "    try:\n",
    "        r = requests.get(f'http://localhost:{ORCH_PORT}{ep}', timeout=5)\n",
    "        if r.status_code == 200:\n",
    "            print(f'[OK] GET {ep} → 200')\n",
    "        else:\n",
    "            print(f'[!!] GET {ep} → {r.status_code}'); errors.append(ep)\n",
    "    except Exception as e:\n",
    "        print(f'[!!] GET {ep} — {e}'); errors.append(ep)\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(7, f'CHECKPOINT_7_API\\nendpoints_ok=root,docs,records\\nverification=PASSED')\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.9] Checkpoint 8 — Web UI (RAG vs. bez RAG)\n",
    "import requests\n",
    "errors = []\n",
    "for ep in ['/ask', '/ask_direct']:\n",
    "    try:\n",
    "        r = requests.post(f'http://localhost:{ORCH_PORT}{ep}',\n",
    "                          json={'query': 'Ile kosztuje parking?'}, timeout=60)\n",
    "        if r.status_code == 200:\n",
    "            print(f'[OK] POST {ep} → 200')\n",
    "        else:\n",
    "            print(f'[!!] POST {ep} → {r.status_code}'); errors.append(ep)\n",
    "    except Exception as e:\n",
    "        print(f'[!!] POST {ep} — {e}'); errors.append(ep)\n",
    "\n",
    "if not errors:\n",
    "    save_checkpoint(8, f'CHECKPOINT_8_WEB_UI\\nendpoints_ok=ask,ask_direct\\nverification=PASSED')\n",
    "    print()\n",
    "    print('=' * 54)\n",
    "    print('  OSTATNI KROK — CERTYFIKAT UKONCZENIA')\n",
    "    print('=' * 54)\n",
    "    print('  Uruchom kolejną komórkę aby wygenerować certyfikat.')\n",
    "    print('=' * 54)\n",
    "else:\n",
    "    print(f'\\n[!!] Błędy: {errors}')"
))

cells.append(code(
    "# [8.10] Certyfikat ukończenia warsztatu\n",
    "import pathlib, hashlib\n",
    "\n",
    "missing = [i for i in range(1, 9)\n",
    "           if not (pathlib.Path(CERT_DIR) / f'checkpoint_{i}.enc').exists()]\n",
    "if missing:\n",
    "    print(f'[!!] Brakuje checkpointów: {missing}. Wróć do sekcji 8.x i wykonaj je.')\n",
    "else:\n",
    "    print('=' * 54)\n",
    "    print(' CERTYFIKAT UKOŃCZENIA — Eskadra Bielik Misja 2 (Colab)')\n",
    "    print('=' * 54)\n",
    "    print()\n",
    "    print('Weryfikacja checkpointów:')\n",
    "    for i in range(1, 9):\n",
    "        p = pathlib.Path(CERT_DIR) / f'checkpoint_{i}.enc'\n",
    "        size = p.stat().st_size\n",
    "        h = hashlib.sha256(p.read_bytes()).hexdigest()[:16]\n",
    "        print(f'  [OK] Checkpoint {i} — {size} bajtów — sha256={h}...')\n",
    "    print()\n",
    "    print(' ██████╗ ██████╗  █████╗ ████████╗██╗   ██╗██╗      █████╗  ██████╗     ██╗███████╗')\n",
    "    print('██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║   ██║██║     ██╔══██╗██╔════╝     ██║██╔════╝')\n",
    "    print('██║  ███╗██████╔╝███████║   ██║   ██║   ██║██║     ███████║██║          ██║█████╗')\n",
    "    print('██║   ██║██╔══██╗██╔══██║   ██║   ██║   ██║██║     ██╔══██║██║     ██   ██║██╔══╝')\n",
    "    print('╚██████╔╝██║  ██║██║  ██║   ██║   ╚██████╔╝███████╗██║  ██║╚██████╗╚█████╔╝███████╗')\n",
    "    print(' ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚════╝ ╚══════╝')\n",
    "    print()\n",
    "    print('         🚀  WARSZTAT UKOŃCZONY — 75 / 75 pkt  🚀')\n",
    "    print()\n",
    "    print('=' * 54)\n",
    "    print(f' Email uczestnika : {WORKSHOP_EMAIL}')\n",
    "    print(f' Projekt          : {WORKSHOP_PROJECT}')\n",
    "    print(f' Artefakty        : {CERT_DIR}')\n",
    "    print('=' * 54)"
))

# ------------------------------ SEKCJA 9 ------------------------------

cells.append(md(
    "## 9. Sprzątanie `~1 min`\n",
    "\n",
    "Odpowiednik kroku 10. Na Colab nie ma kosztów do zatrzymania, ale dobrze posprzątać procesy zanim zamkniesz sesję — szczególnie jeśli planujesz uruchomić inny notebook na tym samym kernelu."
))

cells.append(code(
    "# [9.1] Zatrzymanie procesów i zwolnienie GPU\n",
    "import subprocess, gc\n",
    "\n",
    "try:\n",
    "    subprocess.run(['pkill', '-f', 'ollama'], check=False)\n",
    "    print('[OK] Ollama zatrzymana')\n",
    "except Exception as e:\n",
    "    print(f'[--] {e}')\n",
    "\n",
    "# uvicorn działa w wątku — zamknie się gdy kernel zamknie się sam.\n",
    "# Chroma persistent — zostaje w /content/chroma_db.\n",
    "\n",
    "gc.collect()\n",
    "print('[OK] Sprzątanie zakończone.')\n",
    "print()\n",
    "print('Co warto zachować przed zamknięciem sesji:')\n",
    "print(f'  cert_artifacts/  — pobierz przez panel \"Files\" w Colab')\n",
    "print(f'  chroma_db/       — opcjonalnie, jeśli chcesz wrócić do bazy')"
))

cells.append(md(
    "## Zostańmy w kontakcie\n",
    "\n",
    "Materiał warsztatowy: [Legard777/eskadra-bielik-misja2](https://github.com/Legard777/eskadra-bielik-misja2). "
    "Wariant Colab to dodatek do oryginalnego warsztatu GCP — kod orchestratora, modele i dane są identyczne, "
    "różni się tylko warstwa runtime."
))

# ------------------------------ ZŁOŻENIE NOTEBOOKA ------------------------------

notebook = {
    "cells": cells,
    "metadata": {
        "accelerator": "GPU",
        "colab": {"provenance": [], "gpuType": "T4"},
        "kernelspec": {"display_name": "Python 3", "name": "python3"},
        "language_info": {"name": "python"},
    },
    "nbformat": 4,
    "nbformat_minor": 0,
}

OUT.write_text(json.dumps(notebook, ensure_ascii=False, indent=1))
print(f"Wygenerowano: {OUT}")
print(f"Komórek: {len(cells)} (md={sum(1 for c in cells if c['cell_type']=='markdown')}, code={sum(1 for c in cells if c['cell_type']=='code')})")
