#!/bin/bash

# Weryfikacja zmiennych środowiskowych
REQUIRED_VARS=("EMBEDDING_SERVICE" "REGION" "BUCKET_NAME_EMBEDDING")
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

gcloud run deploy $EMBEDDING_SERVICE \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/$OLLAMA_REPO_NAME/ollama:latest \
  --region $REGION \
  --concurrency 4 \
  --cpu 8 \
  --no-allow-unauthenticated \
  --set-env-vars OLLAMA_NUM_PARALLEL=4 \
  --max-instances 1 \
  --memory 8Gi \
  --timeout=600 \
  --labels dev-tutorial=dos-codelab-bielik-rag \
  --add-volume=name=models,type=cloud-storage,bucket=$BUCKET_NAME_EMBEDDING \
  --add-volume-mount=volume=models,mount-path=/models