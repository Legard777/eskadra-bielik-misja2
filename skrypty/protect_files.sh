#!/bin/bash

# Ochrona plików źródłowych przed przypadkową edycją
# Pliki .sh pozostają wykonywalne (rwxr-xr-x)
# Pozostałe pliki źródłowe ustawiane jako tylko do odczytu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find "$SCRIPT_DIR" -type f \( -name "*.py" -o -name "*.html" -o -name "*.csv" \) -exec chmod 444 {} \;
echo " Pliki źródłowe (.py, .html, .csv) ustawione jako tylko do odczytu."
echo " Aby edytować plik na potrzeby eksperymentów, użyj: chmod +w <nazwa_pliku>"
echo ""
