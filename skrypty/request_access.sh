#!/bin/bash
# Żądanie dostępu do bucketu źródłowego z modelami Ollama.
#
# Skrypt wysyła konto Google uczestnika do tematu Pub/Sub organizatora,
# co automatycznie przyznaje dostęp do bucketu $BUCKET_NAME_SOURCE.
#
# Użycie:
#   ./request_access.sh

ACCOUNT="$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')"

# Weryfikacja zmiennych środowiskowych
REQUIRED_VARS=("PUBSUB_PUBLISH_TOPIC" "BUCKET_NAME_SOURCE")
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "BŁĄD: Brakuje zmiennych środowiskowych: ${MISSING_VARS[*]}"
    echo "Uruchom najpierw: source setup_env.sh"
    exit 1
fi

if [ -z "$ACCOUNT" ]; then
    echo "BŁĄD: Nie można pobrać zalogowanego konta Google."
    echo "Uruchom: gcloud auth login"
    exit 1
fi

echo ""
echo "======================================================"
echo " Żądanie dostępu do bucketu z modelami"
echo "======================================================"
echo ""
echo "  Konto     : $ACCOUNT"
echo "  Temat     : $PUBSUB_PUBLISH_TOPIC"
echo "  Bucket    : gs://$BUCKET_NAME_SOURCE"
echo ""

echo "Wysyłanie żądania dostępu..."
if gcloud pubsub topics publish "$PUBSUB_PUBLISH_TOPIC" \
    --message="$ACCOUNT" \
    --quiet 2>/dev/null; then
    echo "[OK] Żądanie wysłane pomyślnie."
else
    echo "[!!] Błąd podczas wysyłania żądania."
    echo "     Sprawdź czy zmienne PUBSUB_PUBLISH_TOPIC są poprawne"
    echo "     i czy masz uprawnienia do publikowania w tym temacie."
    exit 1
fi

echo ""
echo "Oczekiwanie na przyznanie dostępu (max 60 sekund)..."
ACCESS_GRANTED=false
for i in $(seq 1 12); do
    sleep 5
    printf "\r  Sprawdzanie po %d s..." "$((i * 5))"
    if gcloud storage ls "gs://$BUCKET_NAME_SOURCE/" 2>/dev/null; then
        printf "\r  Dostęp przyznany po %d s!              \n" "$((i * 5))"
        ACCESS_GRANTED=true
        break
    fi
done

echo ""
echo "======================================================"
echo " Weryfikacja dostępu do gs://$BUCKET_NAME_SOURCE"
echo "======================================================"
echo ""
if [ "$ACCESS_GRANTED" = true ]; then
    echo "[OK] Dostęp przyznany! Widzisz zawartość bucketu źródłowego."
    echo "     Możesz przejść do kroku 3."
else
    echo "[!!] Brak dostępu do gs://$BUCKET_NAME_SOURCE po 60 sekundach."
    echo ""
    echo "     Możliwe przyczyny:"
    echo "     - Żądanie jest jeszcze przetwarzane — poczekaj chwilę i uruchom ponownie:"
    echo "       gcloud storage ls gs://$BUCKET_NAME_SOURCE"
    echo "     - Żądanie nie dotarło — uruchom skrypt ponownie"
    echo "     - Skontaktuj się z prowadzącym warsztatu"
    exit 1
fi
echo ""
