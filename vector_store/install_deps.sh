#!/bin/bash

# Instalacja zależności Python dla vector_store i weryfikacja działania biblioteki

echo ""
echo "======================================================"
echo " Instalacja google-cloud-bigquery"
echo "======================================================"
echo ""

pip install --quiet google-cloud-bigquery

echo "  Instalacja zakończona."
echo ""
echo "  Weryfikacja importu biblioteki..."
echo ""

python3 - <<'EOF'
try:
    from google.cloud import bigquery
    client_class = bigquery.Client.__name__
    print(f"  [OK] google-cloud-bigquery zaimportowana poprawnie (klasa: {client_class})")
except ImportError as e:
    print(f"  [!!] Błąd importu: {e}")
    exit(1)
EOF

echo ""
echo "======================================================"
echo " Biblioteka gotowa do użycia."
echo "======================================================"
echo ""
