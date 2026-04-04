import os
import csv
import io
import requests
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import google.auth.transport.requests
import google.oauth2.id_token
from google.cloud import bigquery

app = FastAPI(
    title="RAG API (Bielik & EmbeddingGemma)",
    description=(
        "## API systemu RAG opartego na modelach Bielik i EmbeddingGemma\n\n"
        "Umożliwia:\n"
        "- **ingestion** dokumentów CSV do BigQuery z wektoryzacją\n"
        "- **wyszukiwanie wektorowe** w BigQuery i generowanie odpowiedzi przez LLM (RAG)\n"
        "- **bezpośrednie pytania** do modelu Bielik bez kontekstu\n\n"
        "Dokumentacja interaktywna: `/docs` · Alternatywna: `/redoc`"
    ),
    version="1.0.0",
)

# Zapewnij, że katalog static istnieje
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", include_in_schema=False)
def read_root():
    return FileResponse("static/index.html")

PROJECT_ID = os.environ.get("PROJECT_ID")
DATASET_ID = os.environ.get("BIGQUERY_DATASET", "rag_dataset")
TABLE_ID = os.environ.get("BIGQUERY_TABLE", "hotel_rules")
REGION = os.environ.get("REGION", "europe-west1")
EMBEDDING_URL = os.environ.get("EMBEDDING_URL")
LLM_URL = os.environ.get("LLM_URL")

bq_client = bigquery.Client(project=PROJECT_ID) if PROJECT_ID else None

def get_id_token(audience: str) -> str:
    """Fetch an identity token for the given external Cloud Run URL."""
    try:
        # Pobrane dla lokalnego testowania, jako fallback jeśli jesteśmy w Cloud Run
        request = google.auth.transport.requests.Request()
        token = google.oauth2.id_token.fetch_id_token(request, audience)
        return token
    except Exception as e:
        print(f"Błąd podczas pobierania tokenu za pomocą google.oauth2.id_token dla {audience}: {e}")
        # Próba bezpośredniego pobrania ze spersonalizowanego gcloud auth print-identity-token w środowisku dev
        token = os.popen("gcloud auth print-identity-token").read().strip()
        return token

def get_embedding(text: str) -> list[float]:
    if not EMBEDDING_URL:
        raise ValueError("EMBEDDING_URL variable is not set")
    
    url = f"{EMBEDDING_URL}/api/embed"
    token = get_id_token(EMBEDDING_URL)
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "embeddinggemma",
        "input": text
    }
    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()
    # Zakładamy odpowiedź z modelem `embed` z Ollama
    return response.json().get("embeddings", [[]])[0]

class AskRequest(BaseModel):
    query: str

@app.post(
    "/ingest",
    summary="Wgraj dokumenty CSV do BigQuery",
    description=(
        "Przyjmuje plik CSV z kolumnami `id` i `text`.\n\n"
        "Dla każdego wiersza generuje wektor osadzenia (EmbeddingGemma) "
        "i zapisuje rekord do tabeli BigQuery. "
        "Zwraca liczbę pomyślnie wstawionych wierszy."
    ),
    tags=["Ingestion"],
)
async def ingest_csv(file: UploadFile = File(...)):
    if not bq_client:
        raise HTTPException(status_code=500, detail="BigQuery client not initialized (missing PROJECT_ID)")
    
    content = await file.read()
    csv_reader = csv.DictReader(io.StringIO(content.decode("utf-8")))
    
    rows_to_insert = []
    
    for row in csv_reader:
        doc_id = row.get("id")
        text = row.get("text")
        
        if not doc_id or not text:
            continue
            
        try:
            embedding = get_embedding(text)
            rows_to_insert.append({
                "id": doc_id,
                "content": text,
                "embedding": embedding
            })
        except Exception as e:
            print(f"Błąd w generowaniu osadzenia dla '{text}': {e}")
            
    if rows_to_insert:
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
        errors = bq_client.insert_rows_json(table_ref, rows_to_insert)
        if errors:
            raise HTTPException(status_code=500, detail=f"Błąd wstawiania do BigQuery: {errors}")
            
    return {"status": "success", "inserted_count": len(rows_to_insert)}

@app.post(
    "/ask",
    summary="Zapytaj model RAG (z kontekstem z BigQuery)",
    description=(
        "Przyjmuje pytanie w polu `query`.\n\n"
        "**Przepływ:**\n"
        "1. Generuje wektor zapytania (EmbeddingGemma)\n"
        "2. Wyszukuje 3 najbliższe dokumenty w BigQuery (VECTOR_SEARCH, COSINE)\n"
        "3. Buduje prompt z kontekstem i wysyła do modelu Bielik\n\n"
        "Zwraca odpowiedź modelu oraz listę użytych fragmentów kontekstu."
    ),
    tags=["RAG"],
)
async def ask_question(request_data: AskRequest):
    if not bq_client:
        raise HTTPException(status_code=500, detail="BigQuery client not initialized (missing PROJECT_ID)")
        
    query = request_data.query
    
    try:
        query_embedding = get_embedding(query)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd generowania wektora zapytania: {e}")
        
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    
    # Krok 1: Wyszukiwanie Wektorowe w BigQuery
    bq_query = f"""
    SELECT base.id, base.content, distance
    FROM VECTOR_SEARCH(
      TABLE `{table_ref}`,
      'embedding',
      (SELECT {query_embedding} as embedding),
      top_k => 3,
      distance_type => 'COSINE'
    )
    """
    try:
        query_job = bq_client.query(bq_query)
        results = query_job.result()
        rows = list(results)
        context_docs = [row.content for row in rows]
        # distance COSINE: 0 = identyczny, 1 = ortogonalny; zamieniamy na % podobieństwa
        context_scores = [round((1 - row.distance) * 100, 1) for row in rows]
        context_ids = [row.id for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd przeszukiwania wektorowego w BigQuery: {e}")
        
    # Krok 2: Przygotowanie Kontekstu i Wiadomości do LLM
    context_text = "\\n\\n".join(context_docs)
    
    prompt = (
        f"Jesteś pomocnym asystentem odpowiadającym na pytania dotyczące zasad hotelowych. "
        f"Odpowiedz na poniższe pytanie bazując TYLKO na dostarczonym kontekście.\\n\\n"
        f"KONTEKST:\\n{context_text}\\n\\n"
        f"PYTANIE:\\n{query}"
    )
    
    if not LLM_URL:
        raise HTTPException(status_code=500, detail="LLM_URL variable is not set")
        
    token = get_id_token(LLM_URL)
    url = f"{LLM_URL}/api/chat"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0",
        "messages": [{"role": "user", "content": prompt}],
        "stream": False
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        answer = response.json().get("message", {}).get("content", "")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas komunikacji z modelem LLM: {e}")
        
    avg_score = round(sum(context_scores) / len(context_scores), 1) if context_scores else 0.0

    return {
        "answer": answer,
        "context_used": context_docs,
        "context_ids": context_ids,
        "context_scores": context_scores,
        "confidence": avg_score,
    }

@app.post(
    "/ask_direct",
    summary="Zapytaj model Bielik bezpośrednio (bez RAG)",
    description=(
        "Przyjmuje pytanie w polu `query` i przesyła je wprost do modelu Bielik "
        "**bez** wyszukiwania kontekstu w BigQuery.\n\n"
        "Przydatne do weryfikacji działania modelu LLM niezależnie od pipeline'u RAG."
    ),
    tags=["RAG"],
)
async def ask_direct(request_data: AskRequest):
    query = request_data.query

    if not LLM_URL:
        raise HTTPException(status_code=500, detail="LLM_URL variable is not set")
        
    token = get_id_token(LLM_URL)
    url = f"{LLM_URL}/api/chat"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    prompt = f"Odpowiedz na poniższe pytanie w sposób jasny i zwięzły:\\n\\nPYTANIE:\\n{query}"
    
    payload = {
        "model": "SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0",
        "messages": [{"role": "user", "content": prompt}],
        "stream": False
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        answer = response.json().get("message", {}).get("content", "")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas komunikacji z modelem LLM: {e}")
        
    return {
        "answer": answer
    }


@app.get(
    "/records",
    summary="Pobierz wszystkie rekordy z BigQuery",
    description=(
        "Zwraca listę wszystkich dokumentów zapisanych w tabeli BigQuery "
        "(pola `id` i `content`, bez wektora osadzenia).\n\n"
        "Parametr `limit` pozwala ograniczyć liczbę zwracanych rekordów (domyślnie 100)."
    ),
    tags=["Ingestion"],
)
async def list_records(limit: int = 100):
    if not bq_client:
        raise HTTPException(status_code=500, detail="BigQuery client not initialized (missing PROJECT_ID)")

    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    bq_query = f"SELECT id, content FROM `{table_ref}` LIMIT {limit}"

    try:
        query_job = bq_client.query(bq_query)
        rows = list(query_job.result())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd pobierania rekordów z BigQuery: {e}")

    return {
        "total": len(rows),
        "records": [{"id": row.id, "content": row.content} for row in rows],
    }
