#!/bin/bash
# Konfiguruje ID projektu prowadzącego w systemie śledzenia checkpointów.
# Użycie: ./checkpoints/cf_project_change.sh {ID_PROJEKTU}  lub  ./checkpoints/cf_project_change.sh ID_PROJEKTU

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENCRYPT_FILE="${SCRIPT_DIR}/_encrypt.sh"
PLACEHOLDER="CF_PROJECT_CHANGE"

PROJECT_ID="$1"

# Usuń nawiasy klamrowe jeśli uczestnik wpisał {bielik-test} zamiast bielik-test
PROJECT_ID="${PROJECT_ID#\{}"
PROJECT_ID="${PROJECT_ID%\}}"

if [ -z "$PROJECT_ID" ]; then
    echo "Blad: brak argumentu."
    echo "Uzycie: $0 <ID_PROJEKTU_PROWADZACEGO>"
    echo "Przyklad: $0 bielik-test"
    exit 1
fi

if ! grep -q "$PLACEHOLDER" "$ENCRYPT_FILE"; then
    echo "INFO: Konfiguracja zostala juz wczesniej wykonana."
    echo "      Aktualny temat: $(grep '_CHECKPOINT_TRACKING_TOPIC=' "$ENCRYPT_FILE")"
    exit 0
fi

sed -i "s|${PLACEHOLDER}|${PROJECT_ID}|g" "$ENCRYPT_FILE"

echo "OK: ID projektu prowadzacego ustawione na: ${PROJECT_ID}"
