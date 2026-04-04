# Eskadra Bielika — Misja 2: RAG w Google Cloud

## Instrukcja certyfikacji

Poniższa instrukcja pozwala na szybkie pobranie informacji o usługach Cloud Run wymaganych do certyfikacji ukończenia warsztatu.

### Komenda

Skopiuj i wykonaj poniższą komendę w terminalu (Cloud Shell):

> [!IMPORTANT]
> Wynik komendy skopiuj do schowka i wklej do formularza certyfikacji.

```bash
echo -e "\n=== START KOPIOWANIA TEKSTU ===" && \
echo -e "\n=== INFORMACJE O PROJEKCIE ===" && \
echo "Projekt: $(gcloud config get-value project)" && \
echo "Konto:   $(gcloud config get-value account)" && \
echo -e "\n=== WDROŻONE USŁUGI CLOUD RUN ===" && \
gcloud run services list \
  --filter="metadata.name:bielik OR metadata.name:embedding-gemma OR metadata.name:orchestration-api" \
  --format="table(metadata.name,status.url,metadata.creationTimestamp,status.lastTransitionTime,metadata.labels)" && \
echo -e "\n=== STOP KOPIOWANIA TEKSTU ==="
```

### Opis działania i wyniku

Powyższa komenda wykonuje następujące czynności:

- **Wyświetlenie nazwy projektu i konta** — potwierdza tożsamość uczestnika i projekt Google Cloud użyty podczas warsztatu.
- **Filtrowanie usług Cloud Run** (`gcloud run services list`) — ogranicza wynik do trzech usług wdrożonych podczas warsztatu:
  - **`bielik`** — model językowy LLM uruchomiony na GPU NVIDIA L4
  - **`embedding-gemma`** — model osadzania (embedding) zamieniający tekst na wektory
  - **`orchestration-api`** — aplikacja FastAPI spinająca RAG w całość
- **Tabela wynikowa** zawiera:
  - **SERVICE** — nazwa usługi
  - **URL** — publiczny adres HTTPS usługi
  - **CREATION** — data i godzina wdrożenia
  - **LAST DEPLOYED** — data ostatniej modyfikacji
  - **LABELS** — etykiety przypisane podczas wdrożenia (w tym `dev-tutorial=dos-codelab-bielik-rag`)
