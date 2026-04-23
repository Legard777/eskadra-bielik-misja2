#!/bin/bash
# Konfiguruje nazwę projektu prowadzącego w systemie śledzenia checkpointów.
# UWAGA: To NIE jest nazwa ani ID Twojego własnego projektu Google Cloud.
# Użycie: ./checkpoints/cf_project_change.sh {CF_NAZWA_PROJEKTU}  lub  ./checkpoints/cf_project_change.sh CF_NAZWA_PROJEKTU

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENCRYPT_FILE="${SCRIPT_DIR}/_encrypt.sh"
PLACEHOLDER="CF_PROJECT_CHANGE"

CF_NAZWA_PROJEKTU="$1"

# Usuń nawiasy klamrowe jeśli uczestnik wpisał {bielik-test} zamiast bielik-test
CF_NAZWA_PROJEKTU="${CF_NAZWA_PROJEKTU#\{}"
CF_NAZWA_PROJEKTU="${CF_NAZWA_PROJEKTU%\}}"

if [ -z "$CF_NAZWA_PROJEKTU" ]; then
    echo "Blad: brak argumentu."
    echo "Uzycie: $0 <CF_NAZWA_PROJEKTU>"
    echo "Przyklad: $0 bielik-warsztat-prowadzacy"
    echo "UWAGA: To NIE jest nazwa Twojego projektu Google Cloud — uzyj nazwy podanej przez prowadzacego."
    exit 1
fi

if ! grep -q "$PLACEHOLDER" "$ENCRYPT_FILE"; then
    echo "INFO: Konfiguracja zostala juz wczesniej wykonana."
    echo "      Aktualny temat: $(grep '_CHECKPOINT_TRACKING_TOPIC=' "$ENCRYPT_FILE")"
    exit 0
fi

sed -i "s|${PLACEHOLDER}|${CF_NAZWA_PROJEKTU}|g" "$ENCRYPT_FILE"

echo "OK: Nazwa projektu prowadzacego (CF_NAZWA_PROJEKTU) ustawiona na: ${CF_NAZWA_PROJEKTU}"
