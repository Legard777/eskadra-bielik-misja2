#!/bin/bash
# Tworzenie bucketów i kopiowanie modeli Ollama do projektu GCP.
#
# Skrypt wykonuje kolejno:
#   1. Tworzenie bucketu i kopiowanie modelu LLM (Bielik)
#   2. Tworzenie bucketu i kopiowanie modelu embeddingowego (EmbeddingGemma)
#
# Wymagania: uruchomiony wcześniej `source setup_env.sh` w katalogu głównym projektu.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Kopiowanie modeli Ollama ==="
echo ""

echo "--- Krok 1/2: Model LLM (Bielik) ---"
"$SCRIPT_DIR/copy_model.sh" llm
echo ""

echo "--- Krok 2/2: Model embeddingowy (EmbeddingGemma) ---"
"$SCRIPT_DIR/copy_model.sh" embedding
echo ""

echo "=== Wszystkie modele zostały skopiowane pomyślnie ==="
