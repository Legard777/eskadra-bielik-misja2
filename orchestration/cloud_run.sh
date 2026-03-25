#!/bin/bash

# Nazwa usługi dla Cloud Run
export ORCHESTRATION_SERVICE="orchestration-api"

# Upewnij się, że zmienne środowiskowe są ustawione, żeby wstrzyknąć je do usługi
if [ -z "$REGION" ] || [ -z "$PROJECT_ID" ] || [ -z "$EMBEDDING_SERVICE" ] || [ -z "$LLM_SERVICE" ]; then
    echo "Brak wymaganych zmiennych środowiskowych. Uruchom 'source ../setup_env.sh' w głównym katalogu."
    exit 1
fi

# Pobierz adresy URL usług modeli (lub można polegać na wbudowanym mechanizmie Cloud Run / Cloud DNS jeśli jest w tej samej sieci)
export EMBEDDING_URL=$(gcloud run services describe $EMBEDDING_SERVICE --region $REGION --format 'value(status.url)')
export LLM_URL=$(gcloud run services describe $LLM_SERVICE --region $REGION --format 'value(status.url)')

if [ -z "$EMBEDDING_URL" ] || [ -z "$LLM_URL" ]; then
    echo "Nie udało się pobrać adresów URL usług. Upewnij się, że modele są wdrożone."
    exit 1
fi

gcloud run deploy $ORCHESTRATION_SERVICE \
  --source . \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars PROJECT_ID=$PROJECT_ID,BIGQUERY_DATASET=$BIGQUERY_DATASET,BIGQUERY_TABLE=$BIGQUERY_TABLE,REGION=$REGION,EMBEDDING_URL=$EMBEDDING_URL,LLM_URL=$LLM_URL \
  --max-instances 2 \
  --labels dev-tutorial=dos-codelab-bielik-rag
