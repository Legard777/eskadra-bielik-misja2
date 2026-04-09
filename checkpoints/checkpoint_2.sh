#!/bin/bash
# Checkpoint 2 — Konfiguracja zmiennych środowiskowych i usług Google Cloud
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 2 — Konfiguracja zmiennych i usług Google Cloud"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom najpierw: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja 2.1: usługi Google Cloud ---
echo ""
echo "[2.1] Wymagane usługi Google Cloud:"
REQUIRED_SERVICES=("run.googleapis.com" "cloudbuild.googleapis.com" "artifactregistry.googleapis.com" "bigquery.googleapis.com")
SERVICE_STATUS=""
for SVC in "${REQUIRED_SERVICES[@]}"; do
    ENABLED=$(gcloud services list --enabled \
        --filter="name:${SVC}" \
        --format="value(name)" 2>/dev/null || true)
    if [ -n "$ENABLED" ]; then
        _print_ok "$SVC — włączona"
        SERVICE_STATUS="${SERVICE_STATUS}${SVC}=ENABLED\n"
    else
        _print_fail "$SVC — WYŁĄCZONA. Uruchom: gcloud services enable $SVC"
        SERVICE_STATUS="${SERVICE_STATUS}${SVC}=DISABLED\n"
        ERRORS=$((ERRORS+1))
    fi
done

# --- Weryfikacja 2.2: rola IAM run.invoker ---
echo ""
echo "[2.2] Uprawnienie roles/run.invoker:"
IAM_CHECK=$(gcloud projects get-iam-policy "$PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members=user:${ACCOUNT} AND bindings.role=roles/run.invoker" \
    --format="value(bindings.role)" 2>/dev/null || true)
if [ -n "$IAM_CHECK" ]; then
    _print_ok "Rola roles/run.invoker przypisana do $ACCOUNT"
    IAM_STATUS="roles/run.invoker=ASSIGNED"
else
    _print_fail "Brak roli roles/run.invoker dla $ACCOUNT"
    _print_skip "Uruchom: gcloud projects add-iam-policy-binding \$PROJECT_ID --member=user:\$(gcloud config get-value account) --role='roles/run.invoker'"
    IAM_STATUS="roles/run.invoker=MISSING"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 2.3: zmienne środowiskowe ---
echo ""
echo "[2.3] Zmienne środowiskowe (setup_env.sh):"
ENV_STATUS=""
for VAR in PROJECT_ID REGION EMBEDDING_SERVICE LLM_SERVICE BIGQUERY_DATASET BIGQUERY_TABLE; do
    VAL="${!VAR:-}"
    if [ -n "$VAL" ]; then
        _print_ok "${VAR}=${VAL}"
        ENV_STATUS="${ENV_STATUS}${VAR}=${VAL}\n"
    else
        _print_fail "${VAR} — nie ustawiona. Uruchom: source setup_env.sh"
        ENV_STATUS="${ENV_STATUS}${VAR}=UNSET\n"
        ERRORS=$((ERRORS+1))
    fi
done

# --- Weryfikacja 2.4: ochrona plików źródłowych ---
echo ""
echo "[2.4] Ochrona plików źródłowych (protect_files.sh):"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROTECTED_FILES=("orchestration/main.py" "orchestration/static/index.html" "vector_store/hotel_rules.csv")
ALL_PROTECTED=true
for REL_PATH in "${PROTECTED_FILES[@]}"; do
    FILE="$REPO_ROOT/$REL_PATH"
    if [ -f "$FILE" ] && [ ! -w "$FILE" ]; then
        _print_ok "$REL_PATH — tylko do odczytu (chmod 444)"
    elif [ -f "$FILE" ]; then
        _print_fail "$REL_PATH — plik jest zapisywalny. Uruchom: ./skrypty/protect_files.sh"
        ALL_PROTECTED=false
        ERRORS=$((ERRORS+1))
    fi
done
if [ "$ALL_PROTECTED" = true ]; then
    PROTECT_STATUS="PROTECTED"
else
    PROTECT_STATUS="NOT_PROTECTED"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — wykonaj brakujące kroki przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_2_KONFIGURACJA_USLUG
project_id=${PROJECT_ID}
account=${ACCOUNT}
services:
$(echo -e "$SERVICE_STATUS")
iam:
${IAM_STATUS}
env_vars:
$(echo -e "$ENV_STATUS")
protect_files=${PROTECT_STATUS}
verification=PASSED"

echo " WYNIK: Wszystkie weryfikacje przeszły pomyślnie."
_checkpoint_save "2" "$CONTENT"
_print_separator
