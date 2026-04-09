#!/bin/bash

# Weryfikacja zmiennych środowiskowych
REQUIRED_VARS=("BUCKET_NAME_EMBEDDING" "REGION" "BUCKET_NAME_SOURCE")
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

echo "Tworzenie bucketu $BUCKET_NAME_EMBEDDING w regionie $REGION..."
if gcloud storage buckets create --uniform-bucket-level-access gs://$BUCKET_NAME_EMBEDDING --location=$REGION; then
    echo "Bucket $BUCKET_NAME_EMBEDDING został utworzony pomyślnie."
else
    echo "Ostrzeżenie: Błąd podczas tworzenia bucketu $BUCKET_NAME_EMBEDDING. Sprawdzam czy już istnieje..."
    if ! gcloud storage buckets describe gs://$BUCKET_NAME_EMBEDDING > /dev/null 2>&1; then
        echo "Krytyczny błąd: Bucket nie istnieje i nie mógł zostać utworzony. Sprawdź uprawnienia i poprawność nazwy."
        exit 1
    fi
    echo "Bucket już istnieje, kontynuujemy operacje."
fi

echo "Kopiowanie modelu EMBEDDING z $BUCKET_NAME_SOURCE do $BUCKET_NAME_EMBEDDING..."
if gcloud storage cp -r gs://$BUCKET_NAME_SOURCE/embedding_model/models/** gs://$BUCKET_NAME_EMBEDDING/; then
    echo "Kopiowanie modelu EMBEDDING zakończone sukcesem."
else
    echo "Błąd podczas kopiowania modelu EMBEDDING."
    exit 1
fi

echo "Proces kopiowania modelu EMBEDDING zakończony pomyślnie."