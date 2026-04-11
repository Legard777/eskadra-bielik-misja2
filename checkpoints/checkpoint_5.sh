#!/bin/bash
# Checkpoint 5 — Uruchomienie API Orchestration na Cloud Run
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 5 — API Orchestration na Cloud Run"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja 5.1: usługa orchestration-api ---
echo ""
echo "[5.1] Usługa Cloud Run: orchestration-api"
ORCH_STATUS=$(gcloud run services describe orchestration-api \
    --region "$REGION" \
    --format="value(status.conditions[0].status)" 2>/dev/null || true)
ORCH_URL=$(gcloud run services describe orchestration-api \
    --region "$REGION" \
    --format="value(status.url)" 2>/dev/null || true)
ORCH_CREATED=$(gcloud run services describe orchestration-api \
    --region "$REGION" \
    --format="value(metadata.creationTimestamp)" 2>/dev/null || true)
ORCH_LAST=$(gcloud run services describe orchestration-api \
    --region "$REGION" \
    --format="value(status.conditions.type[RoutesReady].lastTransitionTime)" 2>/dev/null || true)

if [ "$ORCH_STATUS" = "True" ]; then
    _print_ok "Status: Ready"
    _print_ok "URL: $ORCH_URL"
    _print_ok "Utworzono: $ORCH_CREATED"
    _print_ok "Ostatni deploy: $ORCH_LAST"
else
    _print_fail "Usługa orchestration-api nie jest gotowa (status: ${ORCH_STATUS:-BRAK})"
    _print_skip "Sprawdź: cd orchestration && ./cloud_run.sh"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 5.2: zmienne środowiskowe usługi (LLM_URL, EMBEDDING_URL, BQ config) ---
echo ""
echo "[5.2] Zmienne środowiskowe wdrożonej usługi:"
if [ "$ORCH_STATUS" = "True" ]; then
    ENV_VARS=$(gcloud run services describe orchestration-api \
        --region "$REGION" \
        --format="value(spec.template.spec.containers[0].env)" 2>/dev/null || true)
    LLM_ENV=$(gcloud run services describe orchestration-api \
        --region "$REGION" \
        --format="value(spec.template.spec.containers[0].env[name][LLM_URL].value)" 2>/dev/null || true)
    EMBED_ENV=$(gcloud run services describe orchestration-api \
        --region "$REGION" \
        --format="value(spec.template.spec.containers[0].env[name][EMBEDDING_URL].value)" 2>/dev/null || true)

    if [ -n "$LLM_ENV" ]; then
        _print_ok "LLM_URL skonfigurowany: $LLM_ENV"
    else
        _print_fail "LLM_URL — nie skonfigurowany w usłudze. Sprawdź czy modele są wdrożone i uruchom ponownie ./cloud_run.sh"
        ERRORS=$((ERRORS+1))
    fi
    if [ -n "$EMBED_ENV" ]; then
        _print_ok "EMBEDDING_URL skonfigurowany: $EMBED_ENV"
    else
        _print_fail "EMBEDDING_URL — nie skonfigurowany w usłudze. Sprawdź czy modele są wdrożone i uruchom ponownie ./cloud_run.sh"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — usługa nie jest gotowa"
    LLM_ENV="SKIPPED"
    EMBED_ENV="SKIPPED"
fi

# --- Weryfikacja 5.3: dostępność endpointu głównego ---
echo ""
echo "[5.3] Dostępność Web UI (GET /):"
if [ -n "$ORCH_URL" ] && [ "$ORCH_STATUS" = "True" ]; then
    TOKEN=$(gcloud auth print-identity-token 2>/dev/null || true)
    HTTP_CODE=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        "${ORCH_URL}/" 2>/dev/null || true)
    if [ "$HTTP_CODE" = "200" ]; then
        _print_ok "Endpoint GET / odpowiada (HTTP $HTTP_CODE)"
        UI_STATUS="HTTP_200"
    else
        _print_fail "Endpoint GET / — HTTP ${HTTP_CODE:-timeout}"
        _print_skip "Sprawdź logi: gcloud run services logs read orchestration-api --region $REGION"
        UI_STATUS="HTTP_${HTTP_CODE:-TIMEOUT}"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — usługa nie jest gotowa"
    UI_STATUS="SKIPPED"
fi

# --- Weryfikacja 5.4: zmienna ORCHESTRATION_URL w bieżącym terminalu ---
echo ""
echo "[5.4] Zmienna ORCHESTRATION_URL w bieżącym terminalu:"
if [ -n "${ORCHESTRATION_URL:-}" ]; then
    _print_ok "ORCHESTRATION_URL=${ORCHESTRATION_URL}"
else
    _print_fail "ORCHESTRATION_URL nie jest ustawiona. Uruchom:"
    _print_skip "export ORCHESTRATION_URL=\$(gcloud run services describe orchestration-api --region \$REGION --format=\"value(status.url)\")"
    ERRORS=$((ERRORS+1))
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — wdróż usługę orchestration-api przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_5_ORCHESTRATION_API
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
orchestration_status=${ORCH_STATUS:-UNKNOWN}
orchestration_url=${ORCH_URL:-UNKNOWN}
orchestration_created=${ORCH_CREATED:-UNKNOWN}
orchestration_last_deploy=${ORCH_LAST:-UNKNOWN}
llm_url_configured=${LLM_ENV:-NOT_FOUND}
embedding_url_configured=${EMBED_ENV:-NOT_FOUND}
orchestration_url_local=${ORCHESTRATION_URL:-NOT_SET}
ui_http_status=${UI_STATUS}
verification=PASSED"

echo " WYNIK: API Orchestration wdrożone i dostępne."
_checkpoint_save "5" "$CONTENT"
_print_separator
