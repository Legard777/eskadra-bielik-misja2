#!/bin/bash

# ======================================================
# SKRYPT CZYSZCZĄCY ZASOBY GOOGLE CLOUD PO WARSZTACIE
# Materiał warsztatowy - tylko do celów edukacyjnych
# ======================================================

# Sprawdź czy zmienne środowiskowe są wczytane
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
    echo ""
    echo "Brak zmiennych środowiskowych. Wczytuję setup_env.sh..."
    source "$(dirname "$0")/setup_env.sh"
fi

echo ""
echo "======================================================"
echo " Czyszczenie zasobów Google Cloud po warsztacie"
echo "======================================================"
echo ""
echo " Projekt : $PROJECT_ID"
echo " Region  : $REGION"
echo ""
echo " Zasoby które zostaną usunięte:"
echo "   [Cloud Run]        $LLM_SERVICE"
echo "   [Cloud Run]        $EMBEDDING_SERVICE"
echo "   [Cloud Run]        orchestration-api"
echo "   [BigQuery]         dataset: $BIGQUERY_DATASET (w tym tabela: $BIGQUERY_TABLE)"
echo "   [Artifact Registry] repozytorium: cloud-run-source-deploy (obrazy Docker)"
echo "   [Cloud Storage]     bucket: run-sources-$PROJECT_ID-$REGION (kody źródłowe zip)"
echo ""
echo "======================================================"
read -p " Czy na pewno chcesz usunąć wszystkie powyższe zasoby? (wpisz 'tak' aby potwierdzić): " CONFIRM
echo ""

if [ "$CONFIRM" != "tak" ]; then
    echo " Anulowano. Żadne zasoby nie zostały usunięte."
    echo ""
    exit 0
fi

echo "------------------------------------------------------"
echo " Usuwanie usług Cloud Run..."
echo "------------------------------------------------------"

gcloud run services delete $LLM_SERVICE \
    --region $REGION \
    --quiet \
    && echo " [OK] Usunięto: $LLM_SERVICE" \
    || echo " [POMINIĘTO] $LLM_SERVICE nie istnieje lub wystąpił błąd"

gcloud run services delete $EMBEDDING_SERVICE \
    --region $REGION \
    --quiet \
    && echo " [OK] Usunięto: $EMBEDDING_SERVICE" \
    || echo " [POMINIĘTO] $EMBEDDING_SERVICE nie istnieje lub wystąpił błąd"

gcloud run services delete orchestration-api \
    --region $REGION \
    --quiet \
    && echo " [OK] Usunięto: orchestration-api" \
    || echo " [POMINIĘTO] orchestration-api nie istnieje lub wystąpił błąd"

echo ""
echo "------------------------------------------------------"
echo " Usuwanie datasetu BigQuery..."
echo "------------------------------------------------------"

bq rm -r -f --dataset "$PROJECT_ID:$BIGQUERY_DATASET" \
    && echo " [OK] Usunięto dataset: $BIGQUERY_DATASET" \
    || echo " [POMINIĘTO] Dataset $BIGQUERY_DATASET nie istnieje lub wystąpił błąd"

echo ""
echo "------------------------------------------------------"
echo " Usuwanie obrazów Docker z Artifact Registry..."
echo "------------------------------------------------------"

gcloud artifacts repositories delete cloud-run-source-deploy \
    --location $REGION \
    --quiet \
    && echo " [OK] Usunięto repozytorium: cloud-run-source-deploy" \
    || echo " [POMINIĘTO] Repozytorium nie istnieje lub wystąpił błąd"

echo ""
echo "------------------------------------------------------"
echo " Usuwanie bucketa Cloud Storage z kodami źródłowymi..."
echo "------------------------------------------------------"

BUCKET_NAME="run-sources-$PROJECT_ID-$REGION"
gcloud storage rm -r gs://$BUCKET_NAME \
    && echo " [OK] Usunięto bucket: $BUCKET_NAME" \
    || echo " [POMINIĘTO] Bucket $BUCKET_NAME nie istnieje lub wystąpił błąd"

echo ""
echo "======================================================"
echo " Czyszczenie zakończone."
echo " Sprawdź Google Cloud Console aby potwierdzić usunięcie zasobów:"
echo "   - Cloud Run:         https://console.cloud.google.com/run"
echo "   - BigQuery:          https://console.cloud.google.com/bigquery"
echo "   - Artifact Registry: https://console.cloud.google.com/artifacts"
echo "   - Cloud Storage:     https://console.cloud.google.com/storage"
echo "======================================================"
echo ""
