# Diagramy interaktywne

Interaktywne wizualizacje architektury systemu RAG. Można je otworzyć już po **Kroku 1** (Cloud Shell gotowy).

## Dostępne diagramy

| Plik | Zawartość |
|---|---|
| `architektura_interaktywna.html` | Pełny widok systemu — komponenty i przepływ danych |
| `architektura_interaktywna_ingestion.html` | Pipeline ingestion — ładowanie danych do BigQuery |
| `architektura_interaktywna_rag.html` | Pipeline RAG — zapytanie → embedding → BQ → LLM → odpowiedź |

## Dostępne nagrania wideo

### Pipeline ingestion — ładowanie danych do BigQuery

<a href="https://youtu.be/D0qCltR8UJQ" target="_blank">
  <img src="https://img.youtube.com/vi/D0qCltR8UJQ/0.jpg" alt="RAG Ingestion Steps" width="480">
</a>

### Pipeline RAG — zapytanie → embedding → BQ → LLM → odpowiedź

<a href="https://youtu.be/D7s8duHl7sQ" target="_blank">
  <img src="https://img.youtube.com/vi/D7s8duHl7sQ/0.jpg" alt="RAG Query Steps" width="480">
</a>

## Uruchomienie w Cloud Shell (po Kroku 1)

1. Sklonuj repozytorium i przejdź do katalogu diagramów:

```bash
cd eskadra-bielik-misja2/assets/diagrams
```

2. Uruchom lokalny serwer HTTP:

```bash
bash serve.sh
```

3. Kliknij **Web Preview** (ikona oka w prawym górnym rogu Cloud Shell) > **Preview on port 8080**.

4. W przeglądarce wpisz adres wybranego diagramu, np.:

```
https://<twoj-cloud-shell-host>/architektura_interaktywna.html
```

Skrypt wypisze pełne adresy wszystkich trzech diagramów po uruchomieniu.

> [!NOTE]
> Serwer działa tylko podczas aktywnej sesji Cloud Shell. Zatrzymaj go przez **Ctrl+C**.

## Uruchomienie lokalnie (poza Cloud Shell)

```bash
bash serve.sh
# Otwórz: http://localhost:8080/architektura_interaktywna.html
```
