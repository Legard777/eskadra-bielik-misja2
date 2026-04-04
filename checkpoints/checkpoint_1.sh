#!/bin/bash
# Checkpoint 1 — Przygotowanie projektu Google Cloud
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 1 — Przygotowanie projektu Google Cloud"
_print_separator

ERRORS=0

# --- Weryfikacja 1.1: zalogowane konto ---
echo ""
echo "[1.1] Konto Google Cloud:"
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
if [ -n "$ACCOUNT" ] && [ "$ACCOUNT" != "(unset)" ]; then
    _print_ok "Zalogowane konto: $ACCOUNT"
else
    _print_fail "Brak zalogowanego konta. Uruchom: gcloud auth login"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 1.2: skonfigurowany projekt ---
echo ""
echo "[1.2] Projekt Google Cloud:"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -n "$PROJECT_ID" ] && [ "$PROJECT_ID" != "(unset)" ]; then
    _print_ok "Aktywny projekt: $PROJECT_ID"
else
    _print_fail "Brak skonfigurowanego projektu. Uruchom: gcloud config set project <ID>"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 1.3: dostęp do projektu ---
echo ""
echo "[1.3] Dostęp do projektu:"
PROJECT_INFO=$(gcloud projects describe "$PROJECT_ID" \
    --format="value(projectId,lifecycleState,createTime)" 2>/dev/null || true)
if [ -n "$PROJECT_INFO" ]; then
    PROJECT_STATE=$(gcloud projects describe "$PROJECT_ID" --format="value(lifecycleState)" 2>/dev/null || true)
    PROJECT_CREATE=$(gcloud projects describe "$PROJECT_ID" --format="value(createTime)" 2>/dev/null || true)
    _print_ok "Projekt istnieje i jest dostępny (stan: $PROJECT_STATE)"
    _print_ok "Utworzony: $PROJECT_CREATE"
else
    _print_fail "Brak dostępu do projektu $PROJECT_ID"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 1.4: billing ---
echo ""
echo "[1.4] Konto rozliczeniowe:"
BILLING_ENABLED=$(gcloud billing projects describe "$PROJECT_ID" \
    --format="value(billingEnabled)" 2>/dev/null || true)
BILLING_ACCOUNT=$(gcloud billing projects describe "$PROJECT_ID" \
    --format="value(billingAccountName)" 2>/dev/null || true)
if [ "$BILLING_ENABLED" = "True" ]; then
    _print_ok "Billing aktywny: $BILLING_ACCOUNT"
else
    _print_fail "Billing nieaktywny lub brak uprawnień do sprawdzenia. Konto: $BILLING_ACCOUNT"
    # Nie zwiększamy ERRORS — billing check może wymagać dodatkowych uprawnień
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — wykonaj brakujące kroki przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_1_PROJEKT_GOOGLE_CLOUD
project_id=${PROJECT_ID}
account=${ACCOUNT}
project_state=${PROJECT_STATE:-UNKNOWN}
project_create=${PROJECT_CREATE:-UNKNOWN}
billing_enabled=${BILLING_ENABLED:-UNKNOWN}
billing_account=${BILLING_ACCOUNT:-UNKNOWN}
verification=PASSED"

echo " WYNIK: Wszystkie weryfikacje przeszły pomyślnie."
_checkpoint_save "1" "$CONTENT"
_print_separator
