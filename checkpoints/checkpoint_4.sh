#!/bin/bash
# Checkpoint 4 — Inicjalizacja wektorowej bazy danych w BigQuery
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CHECKPOINT 4 — Wektorowa baza danych BigQuery"
_print_separator

ERRORS=0
PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
BQ_DATASET="${BIGQUERY_DATASET:-rag_dataset}"
BQ_TABLE="${BIGQUERY_TABLE:-hotel_rules}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja 4.1: dataset BigQuery ---
echo ""
echo "[4.1] Dataset BigQuery: ${PROJECT_ID}:${BQ_DATASET}"
DATASET_INFO=$(bq show --format=json "${PROJECT_ID}:${BQ_DATASET}" 2>/dev/null || true)
if [ -n "$DATASET_INFO" ]; then
    DATASET_CREATED=$(echo "$DATASET_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('creationTime','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    DATASET_LOCATION=$(echo "$DATASET_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('location','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    _print_ok "Dataset istnieje: ${BQ_DATASET}"
    _print_ok "Lokalizacja: $DATASET_LOCATION"
    _print_ok "Utworzono (ms epoch): $DATASET_CREATED"
else
    _print_fail "Dataset '${BQ_DATASET}' nie istnieje w projekcie ${PROJECT_ID}"
    _print_skip "Uruchom: cd vector_store && python init_db.py"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 4.2: tabela hotel_rules ---
echo ""
echo "[4.2] Tabela BigQuery: ${BQ_DATASET}.${BQ_TABLE}"
TABLE_INFO=$(bq show --format=json "${PROJECT_ID}:${BQ_DATASET}.${BQ_TABLE}" 2>/dev/null || true)
if [ -n "$TABLE_INFO" ]; then
    TABLE_CREATED=$(echo "$TABLE_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('creationTime','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    TABLE_ROWS=$(echo "$TABLE_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('numRows','0'))" 2>/dev/null || echo "0")
    TABLE_SCHEMA=$(echo "$TABLE_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); cols=[f['name'] for f in d.get('schema',{}).get('fields',[])]; print(','.join(cols))" 2>/dev/null || echo "UNKNOWN")
    _print_ok "Tabela istnieje: ${BQ_TABLE}"
    _print_ok "Schemat kolumn: $TABLE_SCHEMA"
    _print_ok "Liczba wierszy: $TABLE_ROWS (0 jest prawidłowe — dane załadujesz w kroku 6)"
    _print_ok "Utworzono (ms epoch): $TABLE_CREATED"
else
    _print_fail "Tabela '${BQ_TABLE}' nie istnieje w datasecie ${BQ_DATASET}"
    _print_skip "Uruchom: cd vector_store && python init_db.py"
    ERRORS=$((ERRORS+1))
fi

# --- Weryfikacja 4.3: obecność kolumny embedding ---
echo ""
echo "[4.3] Kolumna embedding (typ FLOAT64 REPEATED):"
if [ -n "$TABLE_INFO" ]; then
    EMBED_FIELD=$(echo "$TABLE_INFO" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); fields=d.get('schema',{}).get('fields',[]); f=next((x for x in fields if x['name']=='embedding'),None); print(f'{f[\"type\"]}_{f[\"mode\"]}' if f else 'MISSING')" 2>/dev/null || echo "MISSING")
    if [ "$EMBED_FIELD" != "MISSING" ]; then
        _print_ok "Kolumna embedding obecna: $EMBED_FIELD"
    else
        _print_fail "Kolumna embedding nie istnieje w tabeli"
        ERRORS=$((ERRORS+1))
    fi
else
    _print_skip "Pominięto — tabela nie istnieje"
    EMBED_FIELD="SKIPPED"
fi

# --- Podsumowanie i zapis ---
echo ""
_print_separator
if [ "$ERRORS" -gt 0 ]; then
    echo " WYNIK: $ERRORS błąd(ów) — uruchom init_db.py przed zapisem checkpointu."
    _print_separator
    exit 1
fi

CONTENT="CHECKPOINT_4_BIGQUERY_INIT
project_id=${PROJECT_ID}
account=${ACCOUNT}
dataset=${BQ_DATASET}
table=${BQ_TABLE}
dataset_location=${DATASET_LOCATION:-UNKNOWN}
dataset_created=${DATASET_CREATED:-UNKNOWN}
table_created=${TABLE_CREATED:-UNKNOWN}
table_rows=${TABLE_ROWS:-0}
table_schema=${TABLE_SCHEMA:-UNKNOWN}
embedding_field=${EMBED_FIELD:-UNKNOWN}
verification=PASSED"

echo " WYNIK: Baza wektorowa zainicjalizowana poprawnie."
_checkpoint_save "4" "$CONTENT"
_print_separator
