#!/bin/bash
# Wspólna funkcja szyfrowania artefaktów checkpointów
# NIE uruchamiaj tego pliku bezpośrednio — jest sourcowany przez skrypty checkpoint_N.sh

_HEADER_TEXT="Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud"
_CERT_ARTIFACTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cert_artifacts"

# Punkty za każdy checkpoint (indeks = numer checkpointu)
_CHECKPOINT_POINTS=(0 5 10 20 5 10 10 5 10)
_TOTAL_POINTS=75

_CHECKPOINT_LABELS=(
    ""
    "Projekt Google Cloud"
    "Konfiguracja usług i uprawnień"
    "Modele Bielik + EmbeddingGemma na Cloud Run"
    "Wektorowa baza danych BigQuery"
    "API Orchestration na Cloud Run"
    "Zasilanie bazy i zapytania RAG"
    "Przegląd API i architektury"
    "Interfejs Web UI"
)

_CHECKPOINT_MESSAGES=(
    ""
    "Projekt skonfigurowany! Infrastruktura czeka na uruchomienie."
    "Uslugi aktywne, uprawnienia ustawione. Czas na modele!"
    "Oba modele dzialaja w chmurze. Najtrudniejszy krok za Toba!"
    "Baza wektorowa gotowa. Czas polaczyc wszystko w jedno API."
    "System RAG zlozony w calosci. Czas na prawdziwe testy!"
    "Wyszukiwanie semantyczne dziala. Jeden krok do mety!"
    "Architektura przejrzana i zrozumiana. Ostatni krok!"
    "WARSZTAT UKONCZONY! Wygeneruj certyfikat i pochwal sie wynikiem."
)

_get_earned_points() {
    local sum=0
    for i in 1 2 3 4 5 6 7 8; do
        if [ -f "${_CERT_ARTIFACTS_DIR}/checkpoint_${i}.enc" ]; then
            sum=$(( sum + _CHECKPOINT_POINTS[i] ))
        fi
    done
    echo "$sum"
}

_draw_progress_bar() {
    local earned="$1"
    local total="$2"
    local width=30
    local filled=$(( earned * width / total ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}#"; done
    for ((i=filled; i<width; i++)); do bar="${bar}."; done
    local pct=$(( earned * 100 / total ))
    printf "[%s] %d%%" "$bar" "$pct"
}

_print_separator() {
    echo "======================================================"
}

_print_ok()   { echo "  [OK]  $1"; }
_print_fail() { echo "  [!!]  $1"; }
_print_skip() { echo "  [--]  $1"; }

_CHECKPOINT_TRACKING_TOPIC="projects/bielik-greg-cloud-ai-ttt-pl/topics/checkpoint-events"

_checkpoint_publish() {
    local checkpoint_num="$1"
    local project_id="$2"
    local account="$3"
    local enc_file="$4"

    # Wyciągnij base64 blob spomiędzy znaczników (usuń znaki nowej linii)
    local blob
    blob=$(awk '/---BEGIN ENCRYPTED---/{f=1;next}/---END ENCRYPTED---/{f=0}f' \
           "$enc_file" | tr -d '\n')

    [ -z "$blob" ] && return 0  # brak blobu — nie blokuj uczestnika

    # Zbuduj JSON (base64 używa tylko [A-Za-z0-9+/=] — bezpieczne w JSON)
    local message
    message=$(printf \
        '{"checkpoint_num":%d,"account":"%s","project_id":"%s","encrypted_payload":"%s"}' \
        "$checkpoint_num" "$account" "$project_id" "$blob")

    # Publikuj — fail-silent: błąd nie blokuje uczestnika
    gcloud pubsub topics publish "$_CHECKPOINT_TRACKING_TOPIC" \
        --message="$message" \
        --quiet 2>/dev/null || true
}

_checkpoint_save() {
    local checkpoint_num="$1"
    local content="$2"

    local project_id
    local account
    project_id=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
    account=$(gcloud config get-value account 2>/dev/null | tr -d '[:space:]')

    if [ -z "$project_id" ] || [ "$project_id" = "(unset)" ]; then
        echo "BLAD: Brak skonfigurowanego projektu Google Cloud. Uruchom: gcloud config set project <ID>"
        return 1
    fi
    if [ -z "$account" ] || [ "$account" = "(unset)" ]; then
        echo "BLAD: Brak zalogowanego konta. Uruchom: gcloud auth login"
        return 1
    fi

    local key
    key=$(echo -n "${_HEADER_TEXT}|${project_id}|${account}" | sha512sum | awk '{print $1}')

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$_CERT_ARTIFACTS_DIR"
    local output_file="${_CERT_ARTIFACTS_DIR}/checkpoint_${checkpoint_num}.enc"

    local encrypted
    encrypted=$(echo "$content" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
        -pass "pass:${key}" -base64 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$encrypted" ]; then
        echo "BLAD: Szyfrowanie nie powiodlo sie. Sprawdz czy openssl jest zainstalowany."
        return 1
    fi

    cat > "$output_file" <<ARTIFACT
PROJECT_ID: ${project_id}
ACCOUNT: ${account}
CHECKPOINT: ${checkpoint_num}
TIMESTAMP: ${timestamp}
---BEGIN ENCRYPTED---
${encrypted}
---END ENCRYPTED---
ARTIFACT

    # Oblicz punkty po zapisaniu (uwzględnia właśnie zapisany checkpoint)
    local step_pts="${_CHECKPOINT_POINTS[$checkpoint_num]}"
    local earned
    earned=$(_get_earned_points)
    local bar
    bar=$(_draw_progress_bar "$earned" "$_TOTAL_POINTS")
    local label="${_CHECKPOINT_LABELS[$checkpoint_num]}"
    local msg="${_CHECKPOINT_MESSAGES[$checkpoint_num]}"

    echo ""
    _print_separator
    printf "  CHECKPOINT %s ZALICZONY!\n" "$checkpoint_num"
    printf "  %s\n" "$label"
    _print_separator
    printf "  Punkty za ten krok : +%d pkt\n" "$step_pts"
    printf "  Lacznie            : %d / %d pkt\n" "$earned" "$_TOTAL_POINTS"
    printf "  Postep             : %s\n" "$bar"
    _print_separator
    printf "  %s\n" "$msg"
    printf "  Artefakt           : cert_artifacts/checkpoint_%s.enc\n" "$checkpoint_num"
    _print_separator

    # Wysłanie do systemu śledzenia postępu (fail-silent — nie blokuje uczestnika)
    _checkpoint_publish "$checkpoint_num" "$project_id" "$account" "$output_file"

    return 0
}
