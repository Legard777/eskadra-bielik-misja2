#!/bin/bash

# Nadanie praw wykonywania wszystkim skryptom .sh w projekcie.
# Plik setup_env.sh jest celowo pomijany — uruchamiany przez `source`,
# nie wymaga bitu wykonywalności.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "======================================================"
echo " Nadawanie praw wykonywania skryptom .sh"
echo "======================================================"
echo ""

COUNT=0
while IFS= read -r -d '' file; do
    REL_PATH="${file#"$ROOT_DIR/"}"
    chmod +x-w "$file"
    echo "  [+] $REL_PATH"
    COUNT=$((COUNT + 1))
done < <(find "$ROOT_DIR" -name "*.sh" ! -name "setup_env.sh" -print0 | sort -z)

echo ""
echo "  Gotowe — nadano wykonywalność i zdjęto bit zapisu dla $COUNT plików."
echo "  Plik setup_env.sh pozostaje bez zmian (używaj: source setup_env.sh)."
echo ""
