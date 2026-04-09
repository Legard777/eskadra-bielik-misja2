#!/bin/bash

# Weryfikacja zmiennych środowiskowych
REQUIRED_VARS=("BUCKET_NAME_LLM" "REGION" "BUCKET_NAME_SOURCE")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "BŁĄD: Brakuje następujących zmiennych środowiskowych: ${MISSING_VARS[*]}"
    echo "Proszę najpierw uruchomić: source setup_env.sh"
    exit 1
fi

echo "Tworzenie bucketu $BUCKET_NAME_LLM w regionie $REGION..."
if gcloud storage buckets create --uniform-bucket-level-access gs://$BUCKET_NAME_LLM --location=$REGION; then
    echo "Bucket $BUCKET_NAME_LLM został utworzony pomyślnie."
else
    echo "Ostrzeżenie: Błąd podczas tworzenia bucketu $BUCKET_NAME_LLM. Sprawdzam czy już istnieje..."
    if ! gcloud storage buckets describe gs://$BUCKET_NAME_LLM > /dev/null 2>&1; then
        echo "Krytyczny błąd: Bucket nie istnieje i nie mógł zostać utworzony. Sprawdź uprawnienia i poprawność nazwy."
        exit 1
    fi
    echo "Bucket już istnieje, kontynuujemy operacje."
fi

echo "Kopiowanie modelu LLM z $BUCKET_NAME_SOURCE do $BUCKET_NAME_LLM..."
if gcloud storage cp -r gs://$BUCKET_NAME_SOURCE/llm/models/** gs://$BUCKET_NAME_LLM/; then
    echo "Kopiowanie modelu LLM zakończone sukcesem."
else
    echo "Błąd podczas kopiowania modelu LLM."
    exit 1
fi

echo "Proces kopiowania modelu LLM zakończony pomyślnie."