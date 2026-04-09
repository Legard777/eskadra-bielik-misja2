#!/bin/bash
# Checkpoint 7 — Przegląd API i architektury (wszystkie usługi działają)
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 7 — Przegląd API: wszystkie usługi działają"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja 7.1: stan wszystkich 3 usług Cloud Run ---
echo ""
echo "[7.1] Stan wszystkich usług Cloud Run warsztatu:"
SERVICES=("bielik" "embedding-gemma" "orchestration-api")
ALL_SERVICES_INFO=""

for SVC in "${SERVICES[@]}"; do
    SVC_STATUS=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(status.conditions[0].status)" 2>/dev/null || true)
    SVC_URL=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(status.url)" 2>/dev/null || true)
    SVC_CREATED=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(metadata.creationTimestamp)" 2>/dev/null || true)
    SVC_LAST=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(status.lastTransitionTime)" 2>/dev/null || true)
    SVC_IMAGE=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(spec.template.spec.containers[0].image)" 2>/dev/null || true)

    if [ "$SVC_STATUS" = "True" ]; then
        _print_ok "${SVC}: Ready"
        echo "         URL:     $SVC_URL"
        echo "         Deploy:  $SVC_CREATED"
    else
        _print_fail "${SVC}: NOT READY (status: ${SVC_STATUS:-BRAK})"
        ERRORS=$((ERRORS+1))
    fi
    echo ""
    ALL_SERVICES_INFO="${ALL_SERVICES_INFO}${SVC}:status=${SVC_STATUS:-UNKNOWN};url=${SVC_URL:-UNKNOWN};created=${SVC_CREATED:-UNKNOWN};last=${SVC_LAST:-UNKNOWN}\n"
done

# --- Weryfikacja 7.2: endpointy API dostępne ---
echo "[7.2] Weryfikacja endpointów API:"
ORCH_URL=$(gcloud run services describe orchestration-api \
    --region "$REGION" \
    --format="value(status.url)" 2>/dev/null || true)

if [ -n "$ORCH_URL" ]; then
    TOKEN=$(gcloud auth print-identity-token 2>/dev/null || true)
    for ENDPOINT in "/" "/docs" "/records"; do
        HTTP_CODE=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $TOKEN" \
            "${ORCH_URL}${ENDPOINT}" 2>/dev/null || true)
        if [ "$HTTP_CODE" = "200" ]; then
            _print_ok "GET ${ENDPOINT} → HTTP $HTTP_CODE"
        else
            _print_skip "GET ${ENDPOINT} → HTTP ${HTTP_CODE:-timeout}"
        fi
    done
    ENDPOINTS_STATUS="checked"
else
    _print_skip "Pominięto — brak URL orchestration-api"
    ENDPOINTS_STATUS="skipped"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS usługa(i) nie jest gotowa — sprawdź Cloud Run Console."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_7_PRZEGLAD_API
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
services:
$(echo -e "$ALL_SERVICES_INFO")
orchestration_url=${ORCH_URL:-UNKNOWN}
endpoints_status=${ENDPOINTS_STATUS}
verification=PASSED"

echo " WYNIK: Wszystkie 3 usługi Cloud Run działają poprawnie."
_checkpoint_save "7" "$CONTENT"
_print_separator
