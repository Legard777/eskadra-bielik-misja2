#!/bin/bash
# Kopiowanie modeli Ollama z publicznego bucketu do bucketu projektu.
#
# Użycie:
#   ./copy_model.sh llm       — kopiuje model Bielik (LLM)
#   ./copy_model.sh embedding — kopiuje model EmbeddingGemma

MODEL_TYPE="${1:-}"

if [ -z "$MODEL_TYPE" ]; then
    echo "Użycie: $0 llm|embedding"
    echo "  llm       — kopiuje model Bielik do bucketu \$BUCKET_NAME_LLM"
    echo "  embedding — kopiuje model EmbeddingGemma do bucketu \$BUCKET_NAME_EMBEDDING"
    exit 1
fi

case "$MODEL_TYPE" in
    llm)
        REQUIRED_VARS=("BUCKET_NAME_LLM" "REGION" "BUCKET_NAME_SOURCE")
        BUCKET_VAR="BUCKET_NAME_LLM"
        SOURCE_PATH="llm/models"
        MODEL_LABEL="LLM (Bielik)"
        ;;
    embedding)
        REQUIRED_VARS=("BUCKET_NAME_EMBEDDING" "REGION" "BUCKET_NAME_SOURCE")
        BUCKET_VAR="BUCKET_NAME_EMBEDDING"
        SOURCE_PATH="embedding_model/models"
        MODEL_LABEL="EMBEDDING (EmbeddingGemma)"
        ;;
    *)
        echo "BŁĄD: Nieznany typ modelu: '$MODEL_TYPE'. Użyj: llm lub embedding"
        exit 1
        ;;
esac

BUCKET_NAME="${!BUCKET_VAR}"

# Weryfikacja zmiennych środowiskowych
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

echo "Tworzenie bucketu $BUCKET_NAME w regionie $REGION..."
if gcloud storage buckets create --uniform-bucket-level-access gs://$BUCKET_NAME --location=$REGION; then
    echo "Bucket $BUCKET_NAME został utworzony pomyślnie."
else
    echo "Ostrzeżenie: Błąd podczas tworzenia bucketu $BUCKET_NAME. Sprawdzam czy już istnieje..."
    if ! gcloud storage buckets describe gs://$BUCKET_NAME > /dev/null 2>&1; then
        echo "Krytyczny błąd: Bucket nie istnieje i nie mógł zostać utworzony. Sprawdź uprawnienia i poprawność nazwy."
        exit 1
    fi
    echo "Bucket już istnieje, kontynuujemy operacje."
fi

echo "Kopiowanie modelu $MODEL_LABEL z $BUCKET_NAME_SOURCE do $BUCKET_NAME..."
if gcloud storage cp -r gs://$BUCKET_NAME_SOURCE/$SOURCE_PATH/** gs://$BUCKET_NAME/; then
    echo "Kopiowanie modelu $MODEL_LABEL zakończone sukcesem."
else
    echo "Błąd podczas kopiowania modelu $MODEL_LABEL."
    exit 1
fi

echo "Proces kopiowania modelu $MODEL_LABEL zakończony pomyślnie."
