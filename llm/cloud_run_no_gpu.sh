#!/bin/bash

# =============================================================
#  AWARYJNY DEPLOYMENT BEZ GPU — tylko na wypadek braku kvoty
#  UWAGA: Odpowiedzi modelu będą bardzo wolne (1–5 minut).
#         Używaj tego skryptu wyłącznie gdy cloud_run.sh
#         zgłasza błąd braku kwoty GPU.
# =============================================================

# Weryfikacja zmiennych środowiskowych
REQUIRED_VARS=("LLM_SERVICE" "REGION" "BUCKET_NAME_LLM")
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

echo ""
echo "============================================================"
echo "  AWARYJNY DEPLOYMENT BIELIKA BEZ GPU"
echo "  Odpowiedzi modelu będą bardzo wolne (1–5 minut na prompt)."
echo "  Zwiększono limit czasu Cloud Run do 3600 sekund (1 godz.)."
echo "============================================================"
echo ""

gcloud run deploy $LLM_SERVICE \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/$OLLAMA_REPO_NAME/ollama:latest \
  --region $REGION \
  --concurrency 1 \
  --cpu 8 \
  --no-allow-unauthenticated \
  --no-cpu-throttling \
  --set-env-vars OLLAMA_NUM_PARALLEL=1 \
  --max-instances 1 \
  --memory 16Gi \
  --timeout=3600 \
  --labels dev-tutorial=dos-codelab-bielik-rag \
  --add-volume=name=models,type=cloud-storage,bucket=$BUCKET_NAME_LLM \
  --add-volume-mount=volume=models,mount-path=/models
