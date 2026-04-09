#!/bin/bash

# ======================================================
# MINIMALNE CZYSZCZENIE — usuwa tylko zasoby generujące
# stałe koszty po zakończeniu warsztatu.
#
# Usługi Cloud Run pozostają aktywne i skalują się do zera
# gdy nikt ich nie używa — możesz z nich dalej korzystać.
# ======================================================

if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
    echo ""
    echo "Brak zmiennych środowiskowych. Wczytuję setup_env.sh..."
    source "$(dirname "$0")/../setup_env.sh"
fi

echo ""
echo "======================================================"
echo " Minimalne czyszczenie zasobów po warsztacie"
echo "======================================================"
echo ""
echo " Projekt : $PROJECT_ID"
echo " Region  : $REGION"
echo ""
echo " Zasoby które zostaną usunięte:"
echo "   [Artifact Registry]  ollama-repo (obraz Docker z Ollama)"
echo "   [Artifact Registry]  cloud-run-source-deploy (kody źródłowe)"
echo ""
echo " Zasoby które POZOSTAJĄ (skalują do zera gdy idle):"
echo "   [Cloud Run]          $LLM_SERVICE"
echo "   [Cloud Run]          $EMBEDDING_SERVICE"
echo "   [Cloud Run]          orchestration-api"
echo "   [BigQuery]           dataset: $BIGQUERY_DATASET"
echo ""
echo "======================================================"
read -p " Czy chcesz usunąć repozytoria Artifact Registry? (wpisz 'tak'): " CONFIRM
echo ""

if [ "$CONFIRM" != "tak" ]; then
    echo " Anulowano. Żadne zasoby nie zostały usunięte."
    echo ""
    exit 0
fi

echo "------------------------------------------------------"
echo " Usuwanie repozytoriów Artifact Registry..."
echo "------------------------------------------------------"

gcloud artifacts repositories delete "${OLLAMA_REPO_NAME:-ollama-repo}" \
    --location "$REGION" \
    --quiet \
    && echo " [OK] Usunięto repozytorium: ${OLLAMA_REPO_NAME:-ollama-repo}" \
    || echo " [POMINIĘTO] Repozytorium nie istnieje lub wystąpił błąd"

gcloud artifacts repositories delete cloud-run-source-deploy \
    --location "$REGION" \
    --quiet \
    && echo " [OK] Usunięto repozytorium: cloud-run-source-deploy" \
    || echo " [POMINIĘTO] Repozytorium nie istnieje lub wystąpił błąd"

echo ""
echo "======================================================"
echo " Gotowe. Usługi Cloud Run pozostają aktywne."
echo ""
echo " Aby zabezpieczyć orchestration-api przed dostępem"
echo " publicznym (zalecane jeśli zostawiasz usługi):"
echo ""
echo "   gcloud run services update orchestration-api \\"
echo "     --region $REGION \\"
echo "     --no-allow-unauthenticated"
echo ""
echo " Sprawdź Artifact Registry:"
echo "   https://console.cloud.google.com/artifacts"
echo "======================================================"
echo ""
