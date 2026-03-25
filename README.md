# Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud

Suwerenne i wiarygodne AI - Od dokumentów firmowych do inteligentnej bazy wiedzy w oparciu o model Bielik i Google Cloud.

Przykładowy kod źródłowy pozwalający na:

* Skonfigurowanie własnej instancji modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) w oparciu o [Ollama](https://ollama.com/)

* Skonfigurowanie własnej instancji modelu embeddingowego [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) w oparciu o [Ollama](https://ollama.com/)

* Uruchomienie obu powyższych serwisów na [Cloud Run](https://cloud.google.com/run?hl=en)

* Konfiguracja bazy wektorowej [BigQuery](https://cloud.google.com/bigquery?hl=en) wraz z wyszukiwaniem semantycznym [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search)

## 1. Przygotowanie projektu Google Cloud

1. Uzyskaj kredyt Cloud **OnRamp**, lub skonfiguruj płatności w projekcie Google Cloud

2. Przejdź do **Google Cloud Console**: [console.cloud.google.com](https://console.cloud.google.com)

3. Stwórz nowy projekt Google Cloud i wybierz go aby był aktywny
>[!TIP]
>Możesz sprawdzić dostępność kredytów OnRamp wybierając z menu po lewej stronie: Billing / Credits

4. Otwórz Cloud Shell ([dokumentacja](https://cloud.google.com/shell/docs))

5. Zweryfikuj konto które jest zalogowane w Cloud Shell
   ```bash
   gcloud auth list
   ```
>[!TIP]
>Jeżeli konto nie jest zalogowane, lub jest to inne konto niż to z dostępem do Twojego projektu Google Cloud, zaloguj się za pomocą komendy: `gcloud auth login`

6. Potwierdź, że wybrany jest odpowiedni projekt Google Cloud
   ```bash
   gcloud config get project
   ```
>[!TIP]
>Jeżeli projekt jest nieodpowiedni, zmień go za pomocą komendy: `gcloud config set project <ID_TWOJEGO_PROJEKTU>`

>[!CAUTION]
>Nie pomyl nazwy projektu z ID projektu! Nie zawsze są one takie same.

7. Sklonuj repozytorium z przykładowym kodem i przejdź do nowoutworzonego katalogu
   ```bash
   git clone https://github.com/avedave/eskadra-bielik-misja2
   ```

8. Przejdź do katalogu z kodem źródłowym
   ```bash
   cd eskadra-bielik-misja2
   ```

9. Uruchom edytor w katalogu z kodem źródłowym
   ```bash
   cloudshell workspace .
   ```

## 2. Konfiguracja zmiennych środowiskowych i usług Google Cloud

1. Przeanalizuj skrypt `setup_env.sh`

2. Otwórz ponownie terminal Cloud Shell

3. Uruchom skrypt `setup_env.sh`
   ```bash
   source setup_env.sh
   ```
>[!IMPORTANT]
>Jeżeli z jakiegoś powodu musisz ponownie uruchomić terminal Cloud Shell, pamiętaj aby ponownie uruchomić skrypt `setup_env.sh` aby wczytać zmienne środowiskowe.

4. Włącz potrzebne usługi w projekcie Google Cloud
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   gcloud services enable bigquery.googleapis.com
   ```
5. Uzyskaj uprawnienia do wywoływania usług Cloud Run
   ```bash
   gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$(gcloud config get-value account) \
    --role='roles/run.invoker'
   ```  

## 3. Uruchomienie modelu LLM Bielik na Cloud Run

1. Przeanalizuj skrypt `llm/cloud_run.sh`

2. Uruchom skrypt `llm/cloud_run.sh`
   ```bash
   cd llm
   ./cloud_run.sh
   ```
3. Sprawdź status usługi `bielik` w Cloud Console - Cloud Run - Services

4. Przeanalizuj plik `llm/llm_test1.sh` i zadaj pierwsze pytanie modelowi Bielik uruchamiając ten skrypt
   ```bash
   ./llm_test1.sh
   ```
5. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

## 4. Uruchomienie modelu embeddingowego EmbeddingGemma na Cloud Run

1. Przeanalizuj skrypt `embedding_model/cloud_run.sh`

2. Uruchom skrypt `embedding_model/cloud_run.sh`
   ```bash
   cd embedding_model
   ./cloud_run.sh
   ```
3. Sprawdź status usługi `embedding-gemma` w Cloud Console - Cloud Run - Services

4. Przeanalizuj plik `embedding_model/embedding_test1.sh` i wygeneruj pierwsze testowe embeddingi (wektory) dla przykładowego tekstu uruchamiając ten skrypt
   ```bash
   ./embedding_test1.sh
   ```
5. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

## 5. Inicjalizacja wektorowej bazy danych w BigQuery

Projekt wykorzystuje BigQuery z funkcją Vector Search jako bazę z wiedzą kontekstową.

1. Przejdź do katalogu `vector_store`
   ```bash
   cd vector_store
   ```

2. Zainstaluj wymagane biblioteki (w środowisku deweloperskim)
   ```bash
   pip install google-cloud-bigquery
   ```

3. Uruchom skrypt inicjalizacyjny, który stworzy zbiór danych i tabelę w BigQuery
   ```bash
   python init_db.py
   ```

4. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

## 6. Uruchomienie API (Orchestration) na Cloud Run

1. Przeanalizuj kod aplikacji FastAPI w katalogu `orchestration`

2. Przejdź do katalogu `orchestration`
   ```bash
   cd orchestration
   ```

3. Uruchom skrypt publikujący aplikację na Cloud Run
   ```bash
   ./cloud_run.sh
   ```

4. Po wdrożeniu gcloud wypisze adres URL usługi `orchestration-api`. Zapisz go do zmiennej środowiskowej
   ```bash
   export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
   ```

5. Wróć do głównego katalogu
   ```bash
   cd ..
   ```

## 7. Testowanie API - Zasilanie i Wyszukiwanie (RAG)

1. Zasil bazę BigQuery przykładowymi danymi z pliku CSV
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ingest" \
        -F "file=@vector_store/hotel_rules.csv"
   ```

2. Sprawdź w Google Cloud Console -> BigQuery, czy rekordy pojawiły się w tabeli `rag_dataset.hotel_rules` 
   *(Proces indeksowania danych do Vector Search może chwilę potrwać, jednak dane tekstowe widoczne są natychmiast).*

3. Wykonaj testowe zapytanie wykorzystując RAG, dopytujące o informacje z wgranych reguł
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "O której godzinie jest podawane śniadanie?"}'
   ```
   
   oraz testowo o parking:
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "Ile kosztuje parking hotelowy?"}'
   ```


