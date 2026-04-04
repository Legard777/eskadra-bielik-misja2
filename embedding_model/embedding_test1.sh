#!/bin/bash

echo ""
echo "======================================================"
echo " Test modelu EmbeddingGemma"
echo "======================================================"
echo ""

echo " [1/3] Pobieranie adresu URL usługi '$EMBEDDING_SERVICE'..."
export EMBEDDING_SERVICE_URL=$(gcloud run services describe $EMBEDDING_SERVICE --region $REGION --format="value(status.url)")
echo "       URL: $EMBEDDING_SERVICE_URL"
echo ""

echo " [2/3] Pobieranie tokenu autoryzacyjnego..."
export ID_TOKEN=$(gcloud auth print-identity-token)
echo "       Token pobrany pomyślnie."
echo ""

echo " [3/3] Wysyłanie tekstu testowego do modelu EmbeddingGemma..."
echo "       Tekst wejściowy: 'Suwerenne AI po polsku — Bielik i RAG w Google Cloud'"
echo "       Odpowiedź będzie tablicą liczb — wektorem reprezentującym znaczenie tekstu."
echo ""

curl -X POST "$EMBEDDING_SERVICE_URL/api/embed" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "embeddinggemma",
        "input": "Suwerenne AI po polsku — Bielik i RAG w Google Cloud"
    }'

echo ""
echo "======================================================"
echo " Wektor (embedding) wyświetlony powyżej."
echo " Tablica liczb reprezentuje znaczenie tekstu"
echo " 'Suwerenne AI po polsku — Bielik i RAG w Google Cloud'"
echo " w przestrzeni semantycznej modelu EmbeddingGemma."
echo "======================================================"
echo ""
