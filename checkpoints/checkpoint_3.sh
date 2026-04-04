#!/bin/bash
# Checkpoint 3 — Uruchomienie modeli Bielik i EmbeddingGemma na Cloud Run
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 3 — Modele Bielik i EmbeddingGemma na Cloud Run"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja 3.1: usługa bielik ---
echo ""
echo "[3.1] Usługa Cloud Run: bielik (model LLM)"
BIELIK_STATUS=$(gcloud run services describe bielik \
    --region "$REGION" \
    --format="value(status.conditions[0].status)" 2>/dev/null || true)
BIELIK_URL=$(gcloud run services describe bielik \
    --region "$REGION" \
    --format="value(status.url)" 2>/dev/null || true)
BIELIK_CREATED=$(gcloud run services describe bielik \
    --region "$REGION" \
    --format="value(metadata.creationTimestamp)" 2>/dev/null || true)
BIELIK_GPU=$(gcloud run services describe bielik \
    --region "$REGION" \
    --format="value(spec.template.spec.containers[0].resources.limits.nvidia.com/gpu)" 2>/dev/null || true)

if [ "$BIELIK_STATUS" = "True" ]; then
    _print_ok "Status: Ready"
    _print_ok "URL: $BIELIK_URL"
    _print_ok "Utworzono: $BIELIK_CREATED"
    [ -n "$BIELIK_GPU" ] && _print_ok "GPU: $BIELIK_GPU × NVIDIA L4"
else
    _print_fail "Usługa bielik nie jest gotowa (status: ${BIELIK_STATUS:-BRAK})"
    _print_skip "Sprawdź: cd llm && ./cloud_run.sh"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 3.2: usługa embedding-gemma ---
echo ""
echo "[3.2] Usługa Cloud Run: embedding-gemma (model embeddingowy)"
EMBED_STATUS=$(gcloud run services describe embedding-gemma \
    --region "$REGION" \
    --format="value(status.conditions[0].status)" 2>/dev/null || true)
EMBED_URL=$(gcloud run services describe embedding-gemma \
    --region "$REGION" \
    --format="value(status.url)" 2>/dev/null || true)
EMBED_CREATED=$(gcloud run services describe embedding-gemma \
    --region "$REGION" \
    --format="value(metadata.creationTimestamp)" 2>/dev/null || true)

if [ "$EMBED_STATUS" = "True" ]; then
    _print_ok "Status: Ready"
    _print_ok "URL: $EMBED_URL"
    _print_ok "Utworzono: $EMBED_CREATED"
else
    _print_fail "Usługa embedding-gemma nie jest gotowa (status: ${EMBED_STATUS:-BRAK})"
    _print_skip "Sprawdź: cd embedding_model && ./cloud_run.sh"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 3.3: test odpowiedzi modelu bielik ---
echo ""
echo "[3.3] Test odpowiedzi modelu Bielik (ping):"
if [ -n "$BIELIK_URL" ] && [ "$BIELIK_STATUS" = "True" ]; then
    TOKEN=$(gcloud auth print-identity-token 2>/dev/null || true)
    BIELIK_PING=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "${BIELIK_URL}/api/tags" 2>/dev/null || true)
    if [ "$BIELIK_PING" = "200" ]; then
        _print_ok "Endpoint /api/tags odpowiada (HTTP $BIELIK_PING)"
        BIELIK_PING_STATUS="HTTP_200"
    else
        _print_skip "Endpoint /api/tags — HTTP ${BIELIK_PING:-timeout} (model może być w trakcie ładowania)"
        BIELIK_PING_STATUS="HTTP_${BIELIK_PING:-TIMEOUT}"
    fi
else
    _print_skip "Pominięto — usługa nie jest gotowa"
    BIELIK_PING_STATUS="SKIPPED"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — wdróż oba modele przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_3_MODELE_CLOUD_RUN
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
bielik_status=${BIELIK_STATUS:-UNKNOWN}
bielik_url=${BIELIK_URL:-UNKNOWN}
bielik_created=${BIELIK_CREATED:-UNKNOWN}
bielik_gpu=${BIELIK_GPU:-UNKNOWN}
bielik_ping=${BIELIK_PING_STATUS}
embedding_status=${EMBED_STATUS:-UNKNOWN}
embedding_url=${EMBED_URL:-UNKNOWN}
embedding_created=${EMBED_CREATED:-UNKNOWN}
verification=PASSED"

echo " WYNIK: Oba modele wdrożone i gotowe."
_checkpoint_save "3" "$CONTENT"
_print_separator
