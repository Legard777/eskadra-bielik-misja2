#!/bin/bash
# Certyfikat ukończenia warsztatu — Eskadra Bielik Misja 2
# Weryfikuje obecność wszystkich checkpointów i generuje finalny artefakt certyfikatu
set -euo pipefail
source "$(dirname "$0")/_encrypt.sh"

_print_separator
echo " CERTYFIKAT UKOŃCZENIA — Eskadra Bielik Misja 2"
echo " RAG w oparciu o model Bielik i Google Cloud"
_print_separator

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
ACCOUNT=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')
REGION="${REGION:-europe-west1}"
CERT_DIR="$(cd "$(dirname "$0")/.." && pwd)/cert_artifacts"
ERRORS=0
MISSING_CHECKPOINTS=""

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "BŁĄD: Brak skonfigurowanego projektu. Uruchom: source setup_env.sh"
    exit 1
fi

# --- Weryfikacja obecności wszystkich checkpointów ---
echo ""
echo "Weryfikacja checkpointów:"
for i in 1 2 3 4 5 6 7 8; do
    CHECKPOINT_FILE="${CERT_DIR}/checkpoint_${i}.enc"
    if [ -f "$CHECKPOINT_FILE" ]; then
        FILE_SIZE=$(wc -c < "$CHECKPOINT_FILE" | tr -d ' ')
        FILE_MTIME=$(date -r "$CHECKPOINT_FILE" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                     stat -c "%y" "$CHECKPOINT_FILE" 2>/dev/null | cut -d'.' -f1 | tr ' ' 'T' || echo "UNKNOWN")
        _print_ok "Checkpoint $i — obecny (${FILE_SIZE} bajtów, zapisany: $FILE_MTIME)"
    else
        _print_fail "Checkpoint $i — BRAK pliku checkpoint_${i}.enc"
        MISSING_CHECKPOINTS="${MISSING_CHECKPOINTS} $i"
        ERRORS=$((ERRORS+1))
    fi
done

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "  Brakujące checkpointy:${MISSING_CHECKPOINTS}"
    echo "  Uruchom odpowiednie skrypty:"
    for i in $MISSING_CHECKPOINTS; do
        echo "    ./checkpoints/checkpoint_${i}.sh"
    done
    echo ""
    _print_separator
    echo " Certyfikat nie może być wygenerowany — wykonaj brakujące kroki."
    _print_separator
    exit 1
fi

# --- Weryfikacja końcowego stanu usług Cloud Run ---
echo ""
echo "Końcowy stan usług Cloud Run:"
FINAL_SERVICES_INFO=""
for SVC in bielik embedding-gemma orchestration-api; do
    SVC_STATUS=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(status.conditions[0].status)" 2>/dev/null || true)
    SVC_URL=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(status.url)" 2>/dev/null || true)
    SVC_CREATED=$(gcloud run services describe "$SVC" \
        --region "$REGION" \
        --format="value(metadata.creationTimestamp)" 2>/dev/null || true)
    if [ "$SVC_STATUS" = "True" ]; then
        _print_ok "${SVC}: Ready — $SVC_URL"
    else
        _print_skip "${SVC}: ${SVC_STATUS:-BRAK}"
    fi
    FINAL_SERVICES_INFO="${FINAL_SERVICES_INFO}${SVC}:status=${SVC_STATUS:-UNKNOWN};url=${SVC_URL:-UNKNOWN};created=${SVC_CREATED:-UNKNOWN}\n"
done

# --- Zbieranie sum kontrolnych checkpointów ---
echo ""
echo "Sumy kontrolne artefaktów:"
CHECKPOINT_HASHES=""
for i in 1 2 3 4 5 6 7 8; do
    CHECKPOINT_FILE="${CERT_DIR}/checkpoint_${i}.enc"
    FILE_HASH=$(sha256sum "$CHECKPOINT_FILE" | awk '{print $1}')
    echo "  checkpoint_${i}: ${FILE_HASH:0:16}..."
    CHECKPOINT_HASHES="${CHECKPOINT_HASHES}checkpoint_${i}=${FILE_HASH}\n"
done

# --- Generowanie certyfikatu ---
CERT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

CONTENT="CERTYFIKAT_UKONCZENIA_WARSZTATU
project_id=${PROJECT_ID}
account=${ACCOUNT}
region=${REGION}
completion_timestamp=${CERT_TIMESTAMP}
all_checkpoints_present=TRUE
final_cloud_run_services:
$(echo -e "$FINAL_SERVICES_INFO")
checkpoint_hashes:
$(echo -e "$CHECKPOINT_HASHES")
verification=PASSED_ALL_8_CHECKPOINTS"

echo ""
_print_separator
echo " Generowanie zaszyfrowanego certyfikatu..."

# Zapisz certyfikat (bez wywolania _checkpoint_save bo to nie jest checkpoint 1-8)
KEY=$(echo -n "${_HEADER_TEXT}|${PROJECT_ID}|${ACCOUNT}" | sha512sum | awk '{print $1}')
CERT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ENCRYPTED=$(echo "$CONTENT" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
    -pass "pass:${KEY}" -base64 2>/dev/null)
cat > "${CERT_DIR}/checkpoint_certyfikat.enc" <<ARTIFACT
PROJECT_ID: ${PROJECT_ID}
ACCOUNT: ${ACCOUNT}
CHECKPOINT: certyfikat
TIMESTAMP: ${CERT_TIMESTAMP}
---BEGIN ENCRYPTED---
${ENCRYPTED}
---END ENCRYPTED---
ARTIFACT

EARNED=$(_get_earned_points)
BAR=$(_draw_progress_bar "$EARNED" "$_TOTAL_POINTS")

echo ""
echo "======================================================"
echo "  *** WARSZTAT ESKADRA BIELIK - MISJA 2 ***"
echo "  *** UKONCZONY POMYSLNIE! ***"
echo "======================================================"
echo ""
echo "  Uczestnik : $ACCOUNT"
echo "  Projekt   : $PROJECT_ID"
echo "  Czas      : $CERT_TIMESTAMP"
echo ""
printf "  Wynik: %d / %d pkt\n" "$EARNED" "$_TOTAL_POINTS"
printf "  [%s] 100%%\n" "$BAR"
echo ""
echo "  Checkpointy zaliczone: 8 / 8"
for i in 1 2 3 4 5 6 7 8; do
    pts="${_CHECKPOINT_POINTS[$i]}"
    lbl="${_CHECKPOINT_LABELS[$i]}"
    printf "  [OK]  Krok %d  +%2d pkt  %s\n" "$i" "$pts" "$lbl"
done
echo ""
echo "======================================================"
echo "  Pobierz certyfikat na swoj komputer:"
echo "  cloudshell dl cert_artifacts/checkpoint_certyfikat.enc"
echo ""
echo "  Nastepnie wyslij plik prowadzacemu."
echo "======================================================"
