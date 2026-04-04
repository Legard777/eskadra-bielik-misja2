# Architektura — Pipeline Ingestion (`/ingest`)

Przepływ danych dla endpointu zasilania bazy — od pliku CSV do wektorów w BigQuery.

```mermaid
sequenceDiagram
    actor U as Użytkownik
    participant O as Orchestration API
    participant E as EmbeddingGemma
    participant B as BigQuery

    U->>O: POST /ingest multipart/form-data [hotel_rules.csv]

    O->>O: Parsowanie CSV (id, text)

    loop Dla każdego wiersza CSV
        O->>E: POST /api/embed {"model": "embeddinggemma", "input": text}
        E-->>O: {"embeddings": [[float64 x N]]}
        O->>O: Dodaj {id, content, embedding} do bufora
    end

    O->>B: insert_rows_json([{id, content, embedding}, ...])
    B-->>O: [] (brak błędów)

    O-->>U: {"status": "success", "inserted_count": N}
```

## Schemat tabeli BigQuery

```sql
CREATE TABLE rag_dataset.hotel_rules (
  id        STRING   NOT NULL,
  content   STRING   NOT NULL,
  embedding FLOAT64  REPEATED    -- wektor osadzenia (lista liczb)
);
```

## Format wejściowy CSV

Plik CSV musi zawierać dwie kolumny:

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | string | Unikalny identyfikator dokumentu |
| `text` | string | Treść dokumentu w języku naturalnym |

Po załadowaniu Orchestration API automatycznie dodaje kolumnę `embedding` — wygenerowany wektor liczbowy reprezentujący semantyczne znaczenie tekstu.

## Weryfikacja załadowanych danych — SQL

```sql
-- Liczba rekordów i wymiarowość wektorów
SELECT
  COUNT(*) AS total_records,
  ARRAY_LENGTH(embedding) AS embedding_dimensions
FROM `rag_dataset.hotel_rules`
GROUP BY embedding_dimensions;
```
