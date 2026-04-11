#!/bin/bash

# Ochrona plików źródłowych przed przypadkową edycją
# Pliki .sh pozostają wykonywalne (rwxr-xr-x)
# Pozostałe pliki źródłowe ustawiane jako tylko do odczytu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "======================================================"
echo " Ochrona plików źródłowych (chmod 444)"
echo "======================================================"
echo ""

COUNT=0
while IFS= read -r -d '' file; do
    REL_PATH="${file#"$ROOT_DIR/"}"
    chmod 444 "$file"
    echo "  [+] $REL_PATH"
    COUNT=$((COUNT + 1))
done < <(find "$ROOT_DIR" -type f \( -name "*.py" -o -name "*.html" -o -name "*.csv" \) -print0 | sort -z)

echo ""
echo "  Gotowe — ustawiono tylko do odczytu dla $COUNT plików."
echo "  Aby edytować plik na potrzeby eksperymentów, użyj: chmod +w <nazwa_pliku>"
echo ""
