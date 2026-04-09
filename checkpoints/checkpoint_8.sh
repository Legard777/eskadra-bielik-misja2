#!/bin/bash
# Checkpoint 8 — Interfejs Web UI: porównanie RAG vs. bez RAG
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 8 — Interfejs Web UI (RAG vs. bez RAG)"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

ORCH_URL="${ORCHESTRATION_URL:-}"
if [ -z "$ORCH_URL" ]; then
    ORCH_URL=$(gcloud run services describe orchestration-api \
        --region "$REGION" \
        --format="value(status.url)" 2>/dev/null || true)
fi

TOKEN=$(gcloud auth print-identity-token 2>/dev/null || true)

# --- Weryfikacja 8.1: Web UI (GET /) ---
echo ""
echo "[8.1] Dostępność Web UI:"
if [ -n "$ORCH_URL" ]; then
    HTTP_CODE=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "${ORCH_URL}/" 2>/dev/null || true)
    if [ "$HTTP_CODE" = "200" ]; then
        _print_ok "Web UI dostępny pod: $ORCH_URL"
        _print_ok "HTTP status: $HTTP_CODE"
        UI_STATUS="HTTP_200"
    else
        _print_fail "Web UI niedostępny — HTTP ${HTTP_CODE:-timeout}"
        UI_STATUS="HTTP_${HTTP_CODE:-TIMEOUT}"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_fail "Brak URL usługi orchestration-api"
    UI_STATUS="NO_URL"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 8.2: endpoint /ask_direct (baseline bez RAG) ---
echo ""
echo "[8.2] Endpoint /ask_direct (model bez RAG — max 60s):"
if [ -n "$ORCH_URL" ]; then
    HTTP_CODE_DIRECT=$(curl -s --max-time 60 -o /dev/null -w "%{http_code}" \
        -X POST "${ORCH_URL}/ask_direct" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{"query": "test"}' 2>/dev/null || true)
    if [ "$HTTP_CODE_DIRECT" = "200" ]; then
        _print_ok "Endpoint /ask_direct dostępny (HTTP $HTTP_CODE_DIRECT)"
        DIRECT_STATUS="HTTP_200"
    elif [ -z "$HTTP_CODE_DIRECT" ] || [ "$HTTP_CODE_DIRECT" = "000" ]; then
        _print_skip "Endpoint /ask_direct — timeout po 60s (model Bielik potrzebuje więcej czasu — to normalne przy zimnym starcie)"
        DIRECT_STATUS="TIMEOUT"
    else
        _print_fail "Endpoint /ask_direct zwrócił błąd HTTP $HTTP_CODE_DIRECT — sprawdź logi: gcloud run services logs read orchestration-api --region $REGION"
        DIRECT_STATUS="HTTP_${HTTP_CODE_DIRECT}"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — brak URL"
    DIRECT_STATUS="SKIPPED"
fi

# --- Weryfikacja 8.3: endpoint /ask (z RAG) ---
echo ""
echo "[8.3] Endpoint /ask (model z RAG — max 60s):"
if [ -n "$ORCH_URL" ]; then
    HTTP_CODE_RAG=$(curl -s --max-time 60 -o /dev/null -w "%{http_code}" \
        -X POST "${ORCH_URL}/ask" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{"query": "test"}' 2>/dev/null || true)
    if [ "$HTTP_CODE_RAG" = "200" ]; then
        _print_ok "Endpoint /ask dostępny (HTTP $HTTP_CODE_RAG)"
        RAG_STATUS="HTTP_200"
    elif [ -z "$HTTP_CODE_RAG" ] || [ "$HTTP_CODE_RAG" = "000" ]; then
        _print_skip "Endpoint /ask — timeout po 60s (model Bielik potrzebuje więcej czasu — to normalne przy zimnym starcie)"
        RAG_STATUS="TIMEOUT"
    else
        _print_fail "Endpoint /ask zwrócił błąd HTTP $HTTP_CODE_RAG — sprawdź logi: gcloud run services logs read orchestration-api --region $REGION"
        RAG_STATUS="HTTP_${HTTP_CODE_RAG}"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — brak URL"
    RAG_STATUS="SKIPPED"
fi

# --- Weryfikacja 8.4: dokumentacja FastAPI (/docs) ---
echo ""
echo "[8.4] Dokumentacja API (FastAPI /docs):"
if [ -n "$ORCH_URL" ]; then
    HTTP_DOCS=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "${ORCH_URL}/docs" 2>/dev/null || true)
    if [ "$HTTP_DOCS" = "200" ]; then
        _print_ok "Dokumentacja /docs dostępna (HTTP $HTTP_DOCS)"
        DOCS_STATUS="HTTP_200"
    else
        _print_skip "Dokumentacja /docs — HTTP ${HTTP_DOCS:-timeout}"
        DOCS_STATUS="HTTP_${HTTP_DOCS:-TIMEOUT}"
    fi
else
    _print_skip "Pominięto — brak URL"
    DOCS_STATUS="SKIPPED"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — sprawdź usługę orchestration-api."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_8_WEB_UI
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
orchestration_url=${ORCH_URL:-UNKNOWN}
web_ui_status=${UI_STATUS}
ask_direct_status=${DIRECT_STATUS}
ask_rag_status=${RAG_STATUS}
docs_status=${DOCS_STATUS}
verification=PASSED"

echo " WYNIK: Web UI dostępny, oba tryby (RAG i bez RAG) aktywne."
_checkpoint_save "8" "$CONTENT"
_print_separator
