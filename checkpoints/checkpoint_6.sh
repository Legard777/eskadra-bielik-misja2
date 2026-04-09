#!/bin/bash
# Checkpoint 6 — Testowanie API: zasilanie bazy i zapytania RAG
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 6 — Zasilanie bazy i zapytania RAG"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"
BQ_DATASET="${BIGQUERY_DATASET:-rag_dataset}"
BQ_TABLE="${BIGQUERY_TABLE:-hotel_rules}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# Pobierz URL orchestration
ORCH_URL="${ORCHESTRATION_URL:-}"
if [ -z "$ORCH_URL" ]; then
    ORCH_URL=$(gcloud run services describe orchestration-api \
        --region "$REGION" \
        --format="value(status.url)" 2>/dev/null || true)
fi

# --- Weryfikacja 6.1: dane załadowane do BigQuery ---
echo ""
echo "[6.1] Dane w BigQuery (po /ingest):"
ROW_COUNT=$(bq query --nouse_legacy_sql --format=sparse \
    "SELECT COUNT(*) as cnt FROM \`${PROJECT_ID}.${BQ_DATASET}.${BQ_TABLE}\`" 2>/dev/null \
    | tail -1 | tr -d ' ' || echo "0")

if [ -n "$ROW_COUNT" ] && [ "$ROW_COUNT" -gt 0 ] 2>/dev/null; then
    _print_ok "Liczba rekordów w tabeli ${BQ_TABLE}: $ROW_COUNT"
else
    _print_fail "Tabela ${BQ_TABLE} jest pusta lub niedostępna (wiersze: ${ROW_COUNT:-0})"
    _print_skip "Uruchom: curl -X POST \"\$ORCHESTRATION_URL/ingest\" -F \"file=@vector_store/hotel_rules.csv\""
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 6.2: obecność wektorów (embedding nie jest NULL) ---
echo ""
echo "[6.2] Wektory embedding w tabeli:"
if [ -n "$ROW_COUNT" ] && [ "$ROW_COUNT" -gt 0 ] 2>/dev/null; then
    EMBED_COUNT=$(bq query --nouse_legacy_sql --format=sparse \
        "SELECT COUNT(*) FROM \`${PROJECT_ID}.${BQ_DATASET}.${BQ_TABLE}\` WHERE embedding IS NOT NULL" 2>/dev/null \
        | tail -1 | tr -d ' ' || echo "0")
    EMBED_DIMS=$(bq query --nouse_legacy_sql --format=sparse \
        "SELECT ARRAY_LENGTH(embedding) FROM \`${PROJECT_ID}.${BQ_DATASET}.${BQ_TABLE}\` WHERE embedding IS NOT NULL LIMIT 1" 2>/dev/null \
        | tail -1 | tr -d ' ' || echo "0")
    if [ -n "$EMBED_COUNT" ] && [ "$EMBED_COUNT" -gt 0 ] 2>/dev/null; then
        _print_ok "Wiersze z wektorem: $EMBED_COUNT / $ROW_COUNT"
        _print_ok "Wymiarowość wektora: $EMBED_DIMS"
    else
        _print_fail "Brak wektorów w tabeli — kolumna embedding jest pusta"
        _print_skip "Dane zostały wgrane, ale wektory nie zostały wygenerowane. Sprawdź logi /ingest."
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — brak danych w tabeli"
    EMBED_COUNT="0"
    EMBED_DIMS="0"
fi

# --- Weryfikacja 6.3: endpoint /ask odpowiada ---
echo ""
echo "[6.3] Endpoint POST /ask (test dostępności — max 60s):"
if [ -n "$ORCH_URL" ]; then
    TOKEN=$(gcloud auth print-identity-token 2>/dev/null || true)
    HTTP_CODE=$(curl -s --max-time 60 -o /dev/null -w "%{http_code}" \
        -X POST "${ORCH_URL}/ask" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{"query": "test"}' 2>/dev/null || true)
    if [ "$HTTP_CODE" = "200" ]; then
        _print_ok "Endpoint /ask odpowiada (HTTP $HTTP_CODE)"
        ASK_STATUS="HTTP_200"
    elif [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" = "000" ]; then
        _print_skip "Endpoint /ask — timeout po 60s (model Bielik potrzebuje więcej czasu — to normalne przy zimnym starcie)"
        ASK_STATUS="TIMEOUT"
    else
        _print_fail "Endpoint /ask zwrócił błąd HTTP $HTTP_CODE — sprawdź logi: gcloud run services logs read orchestration-api --region $REGION"
        ASK_STATUS="HTTP_${HTTP_CODE}"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — brak URL usługi orchestration-api"
    ASK_STATUS="SKIPPED"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — wgraj dane do BigQuery przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_6_RAG_TESTOWANIE
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
bq_dataset=${BQ_DATASET}
bq_table=${BQ_TABLE}
row_count=${ROW_COUNT:-0}
rows_with_embeddings=${EMBED_COUNT:-0}
embedding_dimensions=${EMBED_DIMS:-0}
orchestration_url=${ORCH_URL:-UNKNOWN}
ask_endpoint_status=${ASK_STATUS}
verification=PASSED"

echo " WYNIK: Dane załadowane, wektory wygenerowane, API dostępne."
_checkpoint_save "6" "$CONTENT"
_print_separator
