#!/bin/bash

echo ""
echo "======================================================"
echo " Test modelu LLM Bielik"
echo "======================================================"
echo ""

echo " [1/3] Pobieranie adresu URL usługi '$LLM_SERVICE'..."
export LLM_SERVICE_URL=$(gcloud run services describe $LLM_SERVICE --region $REGION --format="value(status.url)")
echo "       URL: $LLM_SERVICE_URL"
echo ""

echo " [2/3] Pobieranie tokenu autoryzacyjnego..."
export ID_TOKEN=$(gcloud auth print-identity-token)
echo "       Token pobrany pomyślnie."
echo ""

echo " [3/3] Wysyłanie zapytania testowego do modelu Bielik..."
echo "       Pytanie: 'Jak często powinien być mierzony poziom chloru w basenie?'"
echo ""

RESPONSE=$(curl -s -X POST "$LLM_SERVICE_URL/api/chat" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0",
        "messages": [{ "role": "user", "content": "Jak często powinien być mierzony poziom chloru w basenie?" }],
        "stream": false
    }')

echo " Odpowiedź:"
echo "$RESPONSE" | jq '{odpowiedz: .message.content, model: .model, czas_ms: (.total_duration / 1000000 | floor)}'

echo ""
echo "======================================================"
echo " Pełna odpowiedź JSON:"
echo "======================================================"
echo "$RESPONSE" | jq .
echo ""
