#!/bin/bash
# Wyświetlenie zawartości pliku z przykładowymi danymi hotel_rules.csv.
#
# Plik CSV zawiera dwie kolumny:
#   id   — unikalny identyfikator rekordu
#   text — treść dokumentu (zasada hotelowa w języku naturalnym)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Plik: vector_store/hotel_rules.csv"
echo "Zawiera zasady hotelowe, które zostaną wgrane do BigQuery jako baza wiedzy RAG."
echo "Każdy wiersz to jeden dokument — model Bielik będzie na ich podstawie odpowiadał na pytania."
echo ""
echo "Kolumny:"
echo "  id   — unikalny identyfikator rekordu"
echo "  text — treść zasady hotelowej w języku naturalnym"
echo ""
echo "--- Zawartość pliku ---"
tr -d '\r' < "$SCRIPT_DIR/hotel_rules.csv" | awk -F',' '{printf "%-4s  %s\n", $1, $2}'
echo "--- Koniec pliku ---"
