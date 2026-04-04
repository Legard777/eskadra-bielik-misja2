#!/bin/bash

echo ""
echo "======================================================"
echo " Wdrożenie aplikacji Orchestration API na Cloud Run"
echo "======================================================"
echo ""

# Nazwa usługi dla Cloud Run
export ORCHESTRATION_SERVICE="orchestration-api"

# Upewnij się, że zmienne środowiskowe są ustawione, żeby wstrzyknąć je do usługi
if [ -z "$REGION" ] || [ -z "$PROJECT_ID" ] || [ -z "$EMBEDDING_SERVICE" ] || [ -z "$LLM_SERVICE" ]; then
    echo " Błąd: Brak wymaganych zmiennych środowiskowych."
    echo " Uruchom 'source ../setup_env.sh' w głównym katalogu i spróbuj ponownie."
    exit 1
fi

echo " [1/3] Pobieranie adresów URL wdrożonych modeli..."
export EMBEDDING_URL=$(gcloud run services describe $EMBEDDING_SERVICE --region $REGION --format 'value(status.url)')
export LLM_URL=$(gcloud run services describe $LLM_SERVICE --region $REGION --format 'value(status.url)')

if [ -z "$EMBEDDING_URL" ] || [ -z "$LLM_URL" ]; then
    echo " Błąd: Nie udało się pobrać adresów URL usług."
    echo " Upewnij się, że modele Bielik i EmbeddingGemma są wdrożone i mają status Ready."
    exit 1
fi

echo "       Embedding URL : $EMBEDDING_URL"
echo "       LLM URL       : $LLM_URL"
echo ""

echo " [2/3] Uruchamianie wdrożenia aplikacji '$ORCHESTRATION_SERVICE'..."
echo "       Projekt : $PROJECT_ID"
echo "       Region  : $REGION"
echo ""

gcloud run deploy $ORCHESTRATION_SERVICE \
  --source . \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars PROJECT_ID=$PROJECT_ID,BIGQUERY_DATASET=$BIGQUERY_DATASET,BIGQUERY_TABLE=$BIGQUERY_TABLE,REGION=$REGION,EMBEDDING_URL=$EMBEDDING_URL,LLM_URL=$LLM_URL \
  --max-instances 2 \
  --labels dev-tutorial=dos-codelab-bielik-rag

echo ""
echo " [3/3] Wdrożenie zakończone."
echo ""
echo "======================================================"
echo " Aplikacja Orchestration API jest gotowa."
echo " Przejdź do następnego kroku aby pobrać jej adres URL."
echo "======================================================"
echo ""
