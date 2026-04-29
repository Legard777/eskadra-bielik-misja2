#!/usr/bin/env bash
# Lokalny serwer HTTP dla diagramu interaktywnego
# Użycie: ./serve.sh
# W Cloud Shell kliknij "Web Preview" (ikona oka) > "Preview on port 8080"

set -e

PORT=8080
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Serwer uruchomiony na porcie ${PORT}"
echo ""
echo "Dostępne diagramy:"
echo "  http://localhost:${PORT}/architektura_interaktywna.html"
echo "  http://localhost:${PORT}/architektura_interaktywna_ingestion.html"
echo "  http://localhost:${PORT}/architektura_interaktywna_rag.html"
echo ""
echo "Cloud Shell   : kliknij 'Web Preview' > 'Preview on port ${PORT}'"
echo "Zatrzymaj     : Ctrl+C"
echo ""

cd "${SCRIPT_DIR}"
python3 -m http.server "${PORT}"
