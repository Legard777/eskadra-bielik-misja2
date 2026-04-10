#!/bin/bash
# Wyświetlenie zawartości pliku z przykładowymi danymi hotel_rules.csv.
#
# Plik CSV zawiera dwie kolumny:
#   id   — unikalny identyfikator rekordu
#   text — treść dokumentu (zasada hotelowa w języku naturalnym)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tr -d '\r' < "$SCRIPT_DIR/hotel_rules.csv" | awk -F',' '{printf "%-4s  %s\n", $1, $2}'
