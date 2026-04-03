# Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud

Suwerenne i wiarygodne AI - Od dokumentów firmowych do inteligentnej bazy wiedzy w oparciu o model Bielik i Google Cloud.

>[!WARNING]
>**Materiał warsztatowy — wyłącznie do celów edukacyjnych.**
>Kod i konfiguracja zawarte w tym repozytorium nie są przystosowane do wdrożeń produkcyjnych. Celowo pominięto m.in. uwierzytelnianie API, zarządzanie sekretami, monitoring oraz limity kosztów, aby uprościć przebieg warsztatu i skupić się na zrozumieniu architektury RAG.

## Agenda warsztatu

| # | Temat | Czas |
|---|---|---|
| 0 | Wstęp — czym jest RAG, Bielik i architektura rozwiązania | 15 min |
| 1 | Przygotowanie projektu Google Cloud | 15 min |
| 2 | Konfiguracja zmiennych środowiskowych i usług Google Cloud | 10 min |
| 3 | Uruchomienie modeli Bielik i EmbeddingGemma na Cloud Run (równolegle) | 15 min |
| 4 | Inicjalizacja wektorowej bazy danych w BigQuery | 5 min |
| 5 | Uruchomienie API (Orchestration) na Cloud Run | 15 min |
| 6 | Testowanie API — zasilanie bazy i pierwsze zapytania RAG | 10 min |
| 7 | Przegląd API i architektury kodu | 5 min |
| 8 | Interfejs Web UI — porównanie modelu z RAG i bez RAG + eksperymenty | 20 min |
| 9 | Czyszczenie zasobów Google Cloud | 5 min |
| | **Łącznie** | **~115 min** |

---

## Jak czytać ten przewodnik

### Placeholdery — co wpisać zamiast `<...>`

Gdy w komendzie widzisz tekst ujęty w nawiasy ostre `<`, `>`, zastąp go swoją wartością **bez nawiasów**.

| Zapis w przewodniku | Co wpisujesz zamiast tego |
|---|---|
| `gcloud config set project <ID_TWOJEGO_PROJEKTU>` | `gcloud config set project my-project-123` |

> [!CAUTION]
> Nawiasy `<` i `>` są tylko znacznikiem miejsca — **nie wpisuj ich** do terminala. Wpisz wyłącznie swoją wartość.

### Zmienne środowiskowe — `$NAZWA`

Gdy w komendzie widzisz `$PROJECT_ID`, `$REGION` lub `$ORCHESTRATION_URL` — **nie zmieniaj nic i nie przepisuj ręcznie**. Są one ustawiane automatycznie przez skrypt `setup_env.sh` i terminal sam podstawia właściwą wartość podczas wykonania komendy.

| Zapis w przewodniku | Co terminal widzi w praktyce |
|---|---|
| `--region $REGION` | `--region europe-west1` |
| `--project $PROJECT_ID` | `--project my-project-123` |
| `"$ORCHESTRATION_URL/ask"` | `"https://twoja-usługa.run.app/ask"` |

### Podstawianie komendy — `$(komenda)`

Zapis `$(gcloud run services describe ...)` oznacza: uruchom komendę wewnątrz `$(...)` i użyj jej wyniku jako wartości. Możesz wkleić cały blok kodu bez żadnych modyfikacji.

---

## O projekcie

Niniejsze repozytorium prezentuje kompletne, bezserwerowe (serverless) rozwiązanie klasy RAG (Retrieval-Augmented Generation) wdrożone w chmurze Google Cloud. Głównym celem aplikacji jest dostarczenie wydajnego i suwerennego inteligentnego asystenta zdolnego do odpowiadania na pytania użytkownika w oparciu o dedykowaną bazę wiedzy (np. wewnętrzne dokumenty, regulaminy).

Podstawowa architektura wdrażanego rozwiązania opiera się na poniższych serwisach i komponentach:
- **Modelu językowym LLM:** Suwerenny polski model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) charakteryzujący się bardzo dobrym zrozumieniem języka polskiego oraz polskiego kontekstu kulturowego. Uruchomiony w usłudze Cloud Run, odpowiada za ostateczne generowanie naturalnej dla użytkownika odpowiedzi.
- **Modelu osadzania (Embedding):** Wydajny model [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) uruchomiony w usłudze Cloud Run, służący do szybkiej zamiany tekstu (zapytań użytkownika i dokumentów docelowych) na reprezentację wektorową.
- **Wektorowej Bazie Wiedzy:** Skalowalna hurtownia danych [BigQuery](https://cloud.google.com/bigquery?hl=en) z mechanizmem Vector Search zapewniająca wektorowe wyszukiwanie semantycznie dopasowanych fragmentów z pośród milionów dokumentów źródłowych.
- **Logice i serwerze aplikacyjnym:** Aplikacja napisana w języku Python (z frameworkiem FastAPI), udostępniająca nakładkę graficzną Web UI oraz publiczne API spinające platformy w całość.

Dodatkowo, dzięki prostemu interfejsowi graficznemu, aplikacja pozwala na wygodne porównanie i empiryczne przetestowanie "surowego" modelu Bielik polegającego tylko na sobie w konfrontacji z bogatszą odpowiedzią modelu wspartego kontekstem RAG.

>[!TIP]
>Jeśli chcesz lepiej zrozumieć ideę RAG przed przystąpieniem do warsztatu, zapoznaj się z wprowadzeniem Google Cloud: [Retrieval-Augmented Generation](https://cloud.google.com/use-cases/retrieval-augmented-generation?hl=pl)


## Z czego składa się kod?

Przykładowy kod źródłowy zawarty w tym repozytorium pozwala w szczególności na:

* Skonfigurowanie własnej instancji modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) w oparciu o silnik [Ollama](https://ollama.com/)

* Skonfigurowanie własnej instancji modelu osadzającego (embedding model) [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) w oparciu o [Ollama](https://ollama.com/)

* Uruchomienie obu powyższych modeli na platformie typu bezserwerowego: [Cloud Run](https://cloud.google.com/run?hl=en)

* Skonfigurowanie bazy wektorów w [BigQuery](https://cloud.google.com/bigquery?hl=en) wraz ze specjalnym zaawansowanym przeszukiwaniem [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search)

## 1. Przygotowanie projektu Google Cloud `~15 min`

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

## 2. Konfiguracja zmiennych środowiskowych i usług Google Cloud `~10 min`

1. Przejrzyj zawartość skryptu `setup_env.sh`
   ```bash
   cat setup_env.sh
   ```

2. Otwórz terminal Cloud Shell — po uruchomieniu edytora w poprzednim kroku terminal może być ukryty za zakładką edytora. Kliknij zakładkę **Terminal** w dolnym pasku aby go przywrócić

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

## 3. Uruchomienie modeli LLM Bielik i EmbeddingGemma na Cloud Run `~15 min`

Aby zaoszczędzić czas, uruchom oba modele **równolegle** w dwóch osobnych terminalach Cloud Shell.

>[!IMPORTANT]
>Każdy nowy terminal Cloud Shell wymaga ponownego wczytania zmiennych środowiskowych. Zanim wykonasz jakąkolwiek komendę w nowym terminalu, uruchom:
>```bash
>source ~/eskadra-bielik-misja2/setup_env.sh
>```

### Terminal 1 — Model LLM Bielik

1. Przejrzyj zawartość skryptu `llm/cloud_run.sh`
   ```bash
   cat llm/cloud_run.sh
   ```

2. Uruchom skrypt `llm/cloud_run.sh`
   ```bash
   cd llm
   ./cloud_run.sh
   ```
3. Sprawdź czy usługa `bielik` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

4. Przejrzyj zawartość pliku `llm/llm_test1.sh`
   ```bash
   cat llm_test1.sh
   ```

5. Zadaj pierwsze pytanie modelowi Bielik uruchamiając ten skrypt
   ```bash
   ./llm_test1.sh
   ```
6. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

### Terminal 2 — Model EmbeddingGemma

>[!NOTE]
>Nowy terminal startuje zawsze w katalogu domowym (`~`), dlatego poniższe komendy używają pełnych ścieżek do plików projektu.

1. Otwórz **nowy terminal** Cloud Shell klikając ikonę **+** w górnym pasku terminala

2. Wczytaj zmienne środowiskowe
   ```bash
   source ~/eskadra-bielik-misja2/setup_env.sh
   ```

3. Przejrzyj zawartość skryptu `embedding_model/cloud_run.sh`
   ```bash
   cat ~/eskadra-bielik-misja2/embedding_model/cloud_run.sh
   ```

4. Przejdź do katalogu i uruchom skrypt `embedding_model/cloud_run.sh`
   ```bash
   cd ~/eskadra-bielik-misja2/embedding_model
   ./cloud_run.sh
   ```
5. Sprawdź czy usługa `embedding-gemma` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

6. Przejrzyj zawartość pliku `embedding_model/embedding_test1.sh`
   ```bash
   cat embedding_test1.sh
   ```

7. Wygeneruj pierwsze testowe embeddingi (wektory) dla przykładowego tekstu
   ```bash
   ./embedding_test1.sh
   ```
8. Wróć do głównego katalogu projektu
   ```bash
   cd ~/eskadra-bielik-misja2
   ```

>[!TIP]
>Możesz przełączać się między terminalami klikając ich zakładki w dolnym pasku Cloud Shell. Poczekaj aż oba wdrożenia zakończą się sukcesem zanim przejdziesz do następnego kroku.

## 4. Inicjalizacja wektorowej bazy danych w BigQuery `~5 min`

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

## 5. Uruchomienie API (Orchestration) na Cloud Run `~15 min`

1. Przejrzyj kod aplikacji FastAPI
   ```bash
   cat orchestration/main.py
   ```

2. Przejdź do katalogu `orchestration`
   ```bash
   cd orchestration
   ```

3. Uruchom skrypt wdrażający aplikację na Cloud Run
   ```bash
   ./cloud_run.sh
   ```

4. Po zakończeniu wdrożenia pobierz adres URL usługi i zapisz go do zmiennej środowiskowej
   ```bash
   export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
   ```

5. Wróć do głównego katalogu
   ```bash
   cd ..
   ```

## 6. Testowanie API — Zasilanie i Wyszukiwanie (RAG) `~10 min`

1. Wgraj przykładowe dane do BigQuery z pliku CSV
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ingest" \
        -F "file=@vector_store/hotel_rules.csv"
   ```

2. Sprawdź w Google Cloud Console -> BigQuery, czy rekordy pojawiły się w tabeli `rag_dataset.hotel_rules` 
   *(Proces indeksowania danych do Vector Search może chwilę potrwać, jednak dane tekstowe widoczne są natychmiast).*

3. Wykonaj testowe zapytanie wykorzystując RAG, dopytujące o informacje z wgranych reguł
   
   Pytanie o częstotliwość pomiaru chloru w basenie:
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "Jak często powinien być mierzony poziom chloru w basenie?"}'
   ```

   Pytanie o godzinę podawania śniadania:
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "O której godzinie jest podawane śniadanie?"}'
   ```
   
   Pytanie o parking:
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "Ile kosztuje parking hotelowy?"}'
   ```

## 7. Interfejs Programistyczny (API) `~5 min`

Aplikacja udostępnia proste API stworzone przy pomocy frameworka *FastAPI*, pozwalające nie tylko na zasilanie bazy wiedzy, ale również na zadawanie pytań.

Aplikacja definiuje w pliku `orchestration/main.py` następujące ścieżki:

* `GET /` – serwuje statyczny plik interfejsu użytkownika (`index.html`).
* `POST /ingest` – przyjmuje plik CSV i indeksuje zawarte w nim informacje jako wektory w BigQuery (wykorzystując model embeddingowy `EmbeddingGemma`).
* `POST /ask` – główny endpoint RAG: 
  - zamienia zapytanie z tekstu na wektor,
  - wyszukuje semantycznie 3 najbardziej zbliżone dokumenty wektorowe w tabeli BigQuery,
  - buduje prompt z odnalezionym kontekstem,
  - wysyła połączony prompt do modelu `Bielik` i zwraca ostateczną odpowiedź wraz z wybranym i wykorzystanym kontekstem.
* `POST /ask_direct` – służy jako zestawienie porównawcze (baseline). Przyjmuje zapytanie i wysyła je bezpośrednio do bazowego modelu `Bielik`, z całkowitym pominięciem RAG.

## 8. Interfejs Użytkownika (Web UI) `~20 min`

Oprócz interfejsu API, aplikacja udostępnia również prostą nakładkę WWW. Całość pozwala na wygodne sprawdzenie i porównanie działania bazowego modelu Bielik z modelem Bielik wspartym przez RAG.

Interfejs użytkownika zaimplementowano w jednym, statycznym pliku: `orchestration/static/index.html`. 

Skrypt osadzony w pliku HTML wysyła dwa jednoczesne żądania do endpointów `/ask` (wsparty RAG) oraz `/ask_direct` (bezpośrednio do modelu `Bielik`) i prezentuje obie odpowiedzi modelu obok siebie celem zilustrowania różnic. Wyświetla obok również jakich dokładnie fragmentów dokumentów BigQuery model użył w przypadku posiłkowania się dodatkowym kontekstem RAG.

> [!TIP]
> Zachęcamy Cię gorąco do eksperymentów! Przejrzyj kod źródłowy plików `orchestration/main.py` oraz `orchestration/static/index.html`, aby zobaczyć, w jak prosty sposób w Pythonie łączy się wyszukiwanie wektorowe BigQuery z modelem LLM i serwuje dla prostej graficznej nakładki JavaScript.
> ```bash
> cat orchestration/main.py
> cat orchestration/static/index.html
> ```
> Spróbuj zmodyfikować instrukcję systemową w pliku `main.py`, aby polecić Bielikowi zachowywanie się jak pirat lub ekspert od IT! Najpierw odblokuj plik do edycji, a następnie otwórz go w edytorze Cloud Shell:
> ```bash
> chmod +w orchestration/main.py
> cloudshell edit orchestration/main.py
> ```

### Uruchomienie interfejsu

Aby otworzyć interfejs graficzny testowej aplikacji z poziomu Twojego projektu:

1. Wyświetl i kliknij w adres URL usługi `orchestration-api` uruchamiając w terminalu poniższą komendę:
   ```bash
   echo $ORCHESTRATION_URL
   ```
2. Po otwarciu opublikowanej strony w Twojej przeglądarce internetowej, wpisz w okno dialogowe dowolne zapytanie (np. "Do której godziny jest otwarty basen?") i kliknij "Zapytaj".
3. Porównaj strumień odpowiedzi wyświetlany dla samej bazy wiedzy modelu (bez dodatkowego kontekstu) z bogatszą odpowiedzią RAG wygenerowaną w oparciu o wiedzę z przeszukiwania BigQuery Vector Search.

## 9. Czyszczenie zasobów Google Cloud `~5 min`

Po zakończeniu warsztatu usuń utworzone zasoby aby uniknąć niepotrzebnych kosztów.

Skrypt `cleanup.sh` usuwa wszystkie zasoby utworzone podczas warsztatu:

| Zasób | Nazwa | Koszty | Uwagi |
|---|---|---|---|
| Cloud Run | `bielik` | naliczane przez czas działania instancji | |
| Cloud Run | `embedding-gemma` | naliczane przez czas działania instancji | |
| Cloud Run | `orchestration-api` | naliczane przez czas działania instancji | |
| BigQuery | dataset `rag_dataset` | w ramach free tier | |
| Artifact Registry | `cloud-run-source-deploy` | **~$0.01/miesiąc** za przechowywanie obrazów Docker | pojawia się w billingu nawet po zakończeniu warsztatu — należy usunąć |
| Cloud Storage | `run-sources-{PROJECT_ID}-{REGION}` | nie pojawia się w billingu | archiwa zip tworzone automatycznie przez `gcloud run deploy --source` |

1. Wróć do głównego katalogu projektu i uruchom skrypt czyszczący
   ```bash
   cd ~/eskadra-bielik-misja2
   ./cleanup.sh
   ```

2. Skrypt wyświetli listę zasobów do usunięcia i poprosi o potwierdzenie. Wpisz `tak` aby kontynuować.

3. Po zakończeniu zweryfikuj w Google Cloud Console, że zasoby zostały usunięte:
   - **Cloud Run:** [console.cloud.google.com/run](https://console.cloud.google.com/run)
   - **BigQuery:** [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)
   - **Artifact Registry:** [console.cloud.google.com/artifacts](https://console.cloud.google.com/artifacts)

### Orientacyjny koszt warsztatu

Na podstawie rzeczywistego przebiegu warsztatu całkowity koszt wynosi **~$3–4**.

Dominującą pozycją jest GPU NVIDIA L4 używany przez model Bielik na Cloud Run. Usługi Cloud Run z GPU działają w trybie **instance-based billing** (wymagane przez Google Cloud) — oznacza to, że płacisz za każdą sekundę gdy instancja jest aktywna, niezależnie od tego czy w danej chwili obsługuje zapytanie. Instancja może skalować do zera gdy przez dłuższy czas nikt jej nie odpytuje, jednak ze względu na długi czas zimnego startu (ładowanie modelu) pozostaje aktywna przez cały czas trwania warsztatu.

| Usługa | Składnik | Orientacyjny koszt |
|---|---|---|
| Cloud Run (Bielik) | GPU NVIDIA L4 | ~$1.30 |
| Cloud Run | CPU — billing instancyjny | ~$1.01 |
| Cloud Run | RAM — billing instancyjny | ~$0.25 |
| Cloud Run | CPU — billing requestowy | ~$0.03 |
| Networking | Network Intelligence Center | ~$0.02 |
| Artifact Registry | Przechowywanie obrazów Docker | ~$0.01/mies. |
| **Łącznie** | | **~$3.91** |

>[!IMPORTANT]
>Uruchom skrypt `cleanup.sh` niezwłocznie po zakończeniu warsztatu. Usługi Cloud Run z GPU naliczają koszty przez cały czas działania instancji — nawet gdy nikt z nich aktywnie nie korzysta.

### Optymalizacje dla środowisk produkcyjnych

Konfiguracja użyta w tym warsztacie jest celowo uproszczona. Dla zastosowań produkcyjnych Google Cloud dokumentuje szereg optymalizacji:

- **Szybszy cold start** — pobieranie modelu z Cloud Storage zamiast osadzania go w obrazie Docker, użycie formatu GGUF
- **Niższe koszty GPU** — konfiguracja `min-instances: 0` + odpowiednie proby startowe, aby instancja skalowała do zera gdy nikt nie korzysta
- **Wyższa przepustowość** — tuning współbieżności (`concurrency`) i rozmiaru okna kontekstu modelu
- **Sieć** — Direct VPC z `egress: all-traffic` dla niższych opóźnień

Szczegóły: [Cloud Run GPU Best Practices](https://docs.cloud.google.com/run/docs/configuring/services/gpu-best-practices)
