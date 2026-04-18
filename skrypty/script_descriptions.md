# Opisy skryptów — materiał referencyjny

> Plik zawiera przykładowe wyjaśnienia skryptów i komend użytych w warsztacie.
> Traktuj go jako **jeden z możliwych** opisów — nie jedyny poprawny.
> Model językowy za każdym razem generuje odpowiedź od nowa i może sformułować te same treści zupełnie inaczej.

---

## Skrypt `setup_env.sh`

Skrypt `setup_env.sh` pełni dwie kluczowe funkcje:

- **Automatyzacja konfiguracji** — pobiera ID Twojego projektu Google Cloud i definiuje stałe nazwy dla usług (np. `bielik`, `rag_dataset`). Dzięki temu nie musisz wpisywać tych danych ręcznie w kolejnych krokach — skrypty wdrożeniowe same odczytają je z pamięci terminala.
- **Spójność środowiska** — gwarantuje że wszystkie komponenty (LLM, Embedding, BigQuery) zostaną uruchomione w tym samym regionie (`europe-west1`) i będą mogły się ze sobą komunikować.

**Ważne:** zmienne działają tylko w terminalu, w którym uruchomiono `source setup_env.sh`. Po otwarciu nowej karty Cloud Shell należy uruchomić skrypt ponownie.

---

## Dlaczego `source`, a nie `./setup_env.sh`?

- **Komenda `source`** sprawia że zmienne (`$PROJECT_ID`, `$REGION` itd.) pozostają dostępne w Twoim terminalu po zakończeniu skryptu. Zwykłe uruchomienie `./setup_env.sh` spowodowałoby że zniknęłyby zaraz po jego zakończeniu.
- **Przygotowanie pod kolejne kroki** — wszystkie następne skrypty (wdrażające Bielik, BigQuery itd.) nie pytają o nazwę projektu ani region — po prostu odczytują je z ustawionych tutaj zmiennych.
- **Wymóg powtarzalności** — zmienne żyją tylko w bieżącym oknie terminala. Po otwarciu nowej karty lub restarcie Cloud Shell należy wykonać ten punkt ponownie.

Bez wykonania tego kroku kolejne skrypty nie będą wiedziały gdzie wdrożyć kod i zakończą się błędem `Project ID not set`.

---

## Komendy `gcloud services enable`

Domyślnie wiele usług Google Cloud jest wyłączonych, aby uniknąć niepotrzebnych kosztów. Poniższe komendy aktywują interfejsy API niezbędne do działania warsztatu:

- **`run.googleapis.com`** — Cloud Run: platforma na której uruchamiane są kontenery z modelem Bielik, modelem embeddingowym oraz aplikacją orchestration.
- **`cloudbuild.googleapis.com`** — Cloud Build: automatycznie buduje obrazy Docker z kodu źródłowego przed wdrożeniem na Cloud Run.
- **`artifactregistry.googleapis.com`** — Artifact Registry: prywatne repozytorium przechowujące zbudowane obrazy kontenerów.
- **`bigquery.googleapis.com`** — BigQuery: pełni rolę wektorowej bazy danych (Vector Search) przechowującej zaindeksowane dokumenty i umożliwiającej ich semantyczne przeszukiwanie.

Bez wykonania tych komend próba wdrożenia aplikacji skryptami `cloud_run.sh` zakończyłaby się błędem `API not enabled`.

---

## Skrypt `llm/cloud_run.sh`

Skrypt wdraża model Bielik jako usługę na platformie Cloud Run. Oto co oznaczają poszczególne flagi:

- **`gcloud run deploy $LLM_SERVICE`** — wdraża usługę o nazwie zdefiniowanej w zmiennej `$LLM_SERVICE` (czyli `bielik`).
- **`--source .`** — buduje obraz Docker bezpośrednio z bieżącego katalogu za pomocą Cloud Build; nie trzeba ręcznie pisać `Dockerfile`.
- **`--region $REGION`** — region Google Cloud, w którym uruchamiana jest usługa (`europe-west1`).
- **`--concurrency 4`** — jedna instancja kontenera może obsługiwać do 4 równoczesnych żądań.
- **`--cpu 8`** — przydział 8 vCPU dla kontenera.
- **`--gpu 1` / `--gpu-type nvidia-l4`** — przydziela jeden akcelerator GPU NVIDIA L4, niezbędny do wydajnego wnioskowania modelu LLM.
- **`--no-allow-unauthenticated`** — usługa nie jest publiczna; wymagane uwierzytelnienie (token Google).
- **`--no-cpu-throttling`** — CPU działa pełną mocą przez cały czas, nie tylko podczas obsługi żądań (wymagane przy GPU).
- **`--no-gpu-zonal-redundancy`** — wyłącza redundancję strefową GPU, co obniża koszty na potrzeby warsztatu.
- **`--set-env-vars OLLAMA_NUM_PARALLEL=4`** — ustawia zmienną środowiskową silnika Ollama, pozwalając na 4 równoległe generowania.
- **`--max-instances 1`** — ogranicza liczbę instancji do jednej (kontrola kosztów GPU).
- **`--memory 16Gi`** — przydział 16 GB RAM dla kontenera z modelem.
- **`--timeout=600`** — maksymalny czas odpowiedzi na żądanie: 600 sekund (model może potrzebować chwili na generowanie).

---

## Skrypt `orchestration/cloud_run.sh`

Skrypt wdraża aplikację Orchestration API na Cloud Run. W odróżnieniu od skryptów modeli, musi najpierw pobrać adresy URL działających już usług, aby przekazać je aplikacji:

- **Walidacja zmiennych środowiskowych** — skrypt sprawdza czy `$REGION`, `$PROJECT_ID`, `$EMBEDDING_SERVICE` i `$LLM_SERVICE` są ustawione. Jeśli nie — kończy działanie z czytelnym komunikatem błędu zanim wykona jakiekolwiek zapytanie do Google Cloud.
- **Pobranie URL-i modeli** — `gcloud run services describe` odpytuje Google Cloud o publiczny adres HTTPS każdej z usług. Są one potrzebne, bo aplikacja Orchestration musi wiedzieć gdzie wysyłać żądania do EmbeddingGemma i Bielika.
- **`--allow-unauthenticated`** — w odróżnieniu od modeli (które wymagają tokenu), aplikacja Orchestration jest publiczna, aby użytkownik mógł ją otworzyć w przeglądarce bez dodatkowego uwierzytelniania.
- **`--set-env-vars`** — przekazuje do kontenera wszystkie potrzebne zmienne: `PROJECT_ID`, nazwy dataset i tabeli BigQuery, region oraz URL-e obu modeli. Aplikacja FastAPI odczyta je przy starcie z `os.environ.get(...)`.
- **`--max-instances 2`** — pozwala uruchomić do 2 instancji (wyższy limit niż przy modelach, bo aplikacja obsługuje ruch użytkowników, a nie intensywne obliczenia).

---

## Plik `orchestration/main.py`

Plik zawiera aplikację FastAPI, która spina wszystkie komponenty systemu RAG w jeden przepływ. Oto co robi każdy element:

- **`GET /`** — serwuje statyczny plik `index.html` z interfejsem Web UI.
- **`POST /ingest`** — przyjmuje plik CSV, dla każdego wiersza generuje embedding przez EmbeddingGemma, a następnie zapisuje tekst i wektor do tabeli BigQuery. To zasilanie bazy wiedzy.
- **`POST /ask`** — główny endpoint RAG. Przepływ danych krok po kroku:
  1. Zamienia zapytanie użytkownika na wektor (EmbeddingGemma)
  2. Wykonuje zapytanie `VECTOR_SEARCH` w BigQuery — szuka 3 dokumentów semantycznie najbliższych zapytaniu (metryka kosinusowa)
  3. Buduje prompt z odnalezionymi dokumentami jako kontekstem
  4. Wysyła prompt do modelu Bielik i zwraca odpowiedź wraz z użytym kontekstem
- **`POST /ask_direct`** — wysyła zapytanie bezpośrednio do Bielika, z pominięciem RAG. Używany przez Web UI do porównania odpowiedzi "z" i "bez" kontekstu.
- **`get_id_token()`** — funkcja pomocnicza pobierająca token JWT do autoryzacji żądań do modeli (które są wdrożone z `--no-allow-unauthenticated`). W Cloud Run token pobierany jest automatycznie z metadanych instancji.

---

## Skrypt `vector_store/init_db.py`

Skrypt tworzy strukturę danych w BigQuery niezbędną do przechowywania dokumentów i ich wektorów. Oto co robi każdy element:

- **Odczyt zmiennych środowiskowych** — skrypt pobiera `PROJECT_ID`, `BIGQUERY_DATASET`, `BIGQUERY_TABLE` i `REGION` z ustawionych wcześniej zmiennych powłoki. Jeśli `PROJECT_ID` nie jest ustawiony, wyświetla czytelny błąd i kończy działanie.
- **Tworzenie datasetu** — `client.create_dataset()` tworzy kontener (dataset) o nazwie `rag_dataset` w regionie `europe-west1`. Obsługa wyjątku `Conflict` sprawia, że skrypt nie zwróci błędu jeśli dataset już istnieje — można go bezpiecznie uruchomić ponownie.
- **Tworzenie tabeli ze schematem** — tabela `hotel_rules` ma trzy kolumny:
  - **`id`** (`STRING REQUIRED`) — unikalny identyfikator dokumentu.
  - **`content`** (`STRING REQUIRED`) — oryginalny tekst dokumentu, który będzie zwracany jako kontekst do modelu Bielik.
  - **`embedding`** (`FLOAT64 REPEATED`) — wektor liczbowy reprezentujący znaczenie tekstu. Typ `REPEATED` oznacza tablicę dowolnej długości — w tym przypadku tyle wartości, ile wymiarów ma model EmbeddingGemma. Na tej kolumnie BigQuery Vector Search wykonuje wyszukiwanie semantyczne.

---

## Skrypt `embedding_model/cloud_run.sh`

Skrypt wdraża model EmbeddingGemma jako usługę na platformie Cloud Run. Konfiguracja jest celowo uproszczona w porównaniu do modelu Bielik — model embeddingowy nie wymaga GPU:

- **`gcloud run deploy $EMBEDDING_SERVICE`** — wdraża usługę o nazwie zdefiniowanej w zmiennej `$EMBEDDING_SERVICE` (czyli `embedding-gemma`).
- **`--source .`** — buduje obraz Docker bezpośrednio z bieżącego katalogu za pomocą Cloud Build.
- **`--region $REGION`** — region Google Cloud, w którym uruchamiana jest usługa (`europe-west1`).
- **`--concurrency 4`** — jedna instancja kontenera może obsługiwać do 4 równoczesnych żądań.
- **`--cpu 8`** — przydział 8 vCPU dla kontenera.
- **Brak flag GPU** — w odróżnieniu od modelu Bielik, EmbeddingGemma działa wyłącznie na CPU. Generowanie wektorów jest znacznie mniej obliczeniowo intensywne niż generowanie tekstu, dlatego GPU nie jest potrzebny.
- **`--no-allow-unauthenticated`** — usługa nie jest publiczna; wymagane uwierzytelnienie tokenem Google.
- **`--set-env-vars OLLAMA_NUM_PARALLEL=4`** — umożliwia 4 równoległe przetwarzania w silniku Ollama.
- **`--max-instances 1`** — ogranicza liczbę instancji do jednej (kontrola kosztów).
- **`--memory 8Gi`** — przydział 8 GB RAM (połowa w porównaniu do modelu Bielik — model embeddingowy jest lżejszy).
- **`--timeout=600`** — maksymalny czas odpowiedzi na żądanie: 600 sekund.

---

## Skrypt `embedding_model/embedding_test1.sh`

Skrypt wysyła pierwsze testowe zapytanie do modelu EmbeddingGemma wdrożonego na Cloud Run w celu wygenerowania wektora dla przykładowego tekstu:

- **Pobranie URL usługi** — analogicznie jak w teście LLM, `gcloud run services describe` pobiera adres HTTPS usługi `embedding-gemma`.
- **Pobranie tokenu autoryzacyjnego** — `gcloud auth print-identity-token` generuje token JWT wymagany do uwierzytelnienia.
- **Zapytanie curl do endpointu `/api/embed`** — w odróżnieniu od `/api/chat` (generowanie tekstu), endpoint `/api/embed` zamienia tekst wejściowy na reprezentację wektorową (embedding). Ciało żądania zawiera:
  - **`model`** — nazwa modelu embeddingowego załadowanego w Ollama (`embeddinggemma`).
  - **`input`** — tekst wejściowy, który zostanie zamieniony na wektor liczbowy.
- **Co zwraca odpowiedź?** — zamiast tekstu naturalnego, model zwraca tablicę liczb zmiennoprzecinkowych (np. 2048 wartości). Każda liczba reprezentuje jeden wymiar przestrzeni semantycznej. Dwa teksty o podobnym znaczeniu będą miały wektory bliskie sobie geometrycznie — na tym opiera się wyszukiwanie semantyczne w BigQuery Vector Search.

---

## Skrypt `llm/llm_test1.sh`

Skrypt wysyła pierwsze testowe zapytanie bezpośrednio do modelu Bielik wdrożonego na Cloud Run. Oto co robi każdy krok:

- **Pobranie URL usługi** — komenda `gcloud run services describe` odpytuje Google Cloud i zwraca publiczny adres HTTPS usługi `bielik`. Wynik zapisywany jest do zmiennej `$LLM_SERVICE_URL`, dzięki czemu nie trzeba wpisywać adresu ręcznie.
- **Pobranie tokenu autoryzacyjnego** — `gcloud auth print-identity-token` generuje krótkotrwały token JWT potwierdzający tożsamość zalogowanego użytkownika. Jest wymagany, ponieważ usługa została wdrożona z flagą `--no-allow-unauthenticated` — bez tokenu Cloud Run odrzuci żądanie z błędem 403.
- **Zapytanie curl** — skrypt wysyła żądanie HTTP POST do endpointu `/api/chat`, który jest standardowym interfejsem API silnika Ollama. Ciało żądania w formacie JSON zawiera:
  - **`model`** — pełna nazwa modelu załadowanego w Ollama (`SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0`); Q8_0 oznacza kwantyzację 8-bitową, kompromis między jakością a zużyciem pamięci GPU.
  - **`messages`** — lista wiadomości w formacie konwersacji; tutaj jedno pytanie użytkownika (`role: user`).
  - **`stream: false`** — wyłącza strumieniowanie odpowiedzi; model poczeka z odesłaniem wyniku aż wygeneruje całą odpowiedź.

---

## Komenda `gcloud projects add-iam-policy-binding`

Komenda nadaje Twojemu kontu uprawnienia do wywoływania usług Cloud Run. Oto co robią poszczególne elementy:

- **`add-iam-policy-binding $PROJECT_ID`** — dopisuje nową regułę do polityki dostępu (IAM) Twojego projektu.
- **`--member=user:$(gcloud config get-value account)`** — automatycznie pobiera adres e-mail aktualnie zalogowanego użytkownika, dzięki czemu nie musisz wpisywać go ręcznie.
- **`--role='roles/run.invoker'`** — nadaje rolę Cloud Run Invoker, niezbędną do wysyłania zapytań (np. przez `curl` lub przeglądarkę) do modeli i API wdrożonych na Cloud Run.

W Google Cloud obowiązuje zasada najmniejszych uprawnień — nawet właściciel projektu musi jawnie przypisać tę rolę, aby komunikacja między komponentami przebiegała poprawnie. Brak tej roli skutkuje błędem HTTP **403 Forbidden** — serwer wie kim jesteś (autentykacja), ale nie masz pozwolenia na tę operację (autoryzacja).

---

## Skrypt `ollama_models/setup_models.sh`

Skrypt automatyzuje tworzenie bucketów Cloud Storage i kopiowanie modeli z centralnego bucketu organizatora warsztatu do Twojego projektu. Oto co robi każdy etap:

- **Tworzenie bucketów** — `gcloud storage buckets create` zakłada prywatne buckety w Twoim projekcie w regionie `europe-west1`. Bucket to odpowiednik katalogu w chmurze — płaski kontener na pliki o dowolnym rozmiarze.
- **Kopiowanie modeli** — `gcloud storage cp` kopiuje pliki modeli (`.gguf` lub paczki Ollama) z bucketu organizatora do Twojego bucketu. Kopiowanie odbywa się w sieci Google (nie przez Twój komputer), więc jest szybkie.
- **Dlaczego modele ważą gigabajty?** — model językowy to ogromna macierz liczb (wagi sieci neuronowej). Bielik 4.5B ma 4,5 miliarda takich parametrów. Nawet przy kwantyzacji 8-bitowej (1 bajt na parametr) daje to ~4,5 GB. Zwykły program przechowuje instrukcje dla procesora — model przechowuje „wiedzę" zakodowaną w miliardach liczb.

---

## Skrypt `ollama_docker_image/setup_ollama_image.sh`

Skrypt tworzy dedykowane repozytorium w Artifact Registry i buduje obraz Docker z silnikiem Ollama. Oto kluczowe elementy:

- **Tworzenie repozytorium w Artifact Registry** — `gcloud artifacts repositories create` zakłada prywatny rejestr kontenerów. To odpowiednik Docker Hub, tyle że w Twoim projekcie Google Cloud — Cloud Run może pobierać obrazy bez dodatkowej autoryzacji.
- **Budowanie obrazu Docker** — `gcloud builds submit` wysyła kod do Cloud Build, który buduje obraz na serwerach Google. Obraz zawiera silnik Ollama gotowy do uruchomienia na Cloud Run.
- **Dlaczego własny obraz zamiast gotowego?** — gotowy obraz Ollama z Docker Hub nie wie skąd pobrać model przy starcie. Własny obraz zawiera skrypt startowy, który automatycznie pobiera model z bucketu Cloud Storage i ładuje go do pamięci przed przyjęciem pierwszego żądania.
- **Jeden obraz, dwa modele** — ten sam obraz Ollama jest używany zarówno dla modelu Bielik (LLM), jak i EmbeddingGemma. Różnica jest tylko w zmiennej środowiskowej wskazującej który model pobrać z bucketu.

---

## `pip install google-cloud-bigquery`

Komenda instaluje oficjalną bibliotekę Pythona do komunikacji z BigQuery. Oto co warto wiedzieć:

- **`pip`** — package manager Pythona, odpowiednik `apt` w Linuksie czy `npm` w Node.js. Pobiera bibliotekę z repozytorium PyPI i instaluje ją wraz z zależnościami.
- **`google-cloud-bigquery`** — biblioteka kliencka udostępniająca Pythonowe API do tworzenia tabel, wykonywania zapytań SQL i operacji na danych w BigQuery. Bez niej skrypt `init_db.py` nie mógłby się połączyć z usługą.
- **Dlaczego bez `venv`?** — wirtualne środowisko (`python -m venv`) izoluje zależności między różnymi projektami na tej samej maszynie, aby nie kolidowały ze sobą. Cloud Shell to tymczasowa maszyna wirtualna uruchamiana od nowa po każdej sesji — nie ma tu długotrwałych projektów ani konfliktów zależności, więc instalacja globalna jest wystarczająca i szybsza.

---

## Komenda `curl` — endpoint `/ingest`

```bash
curl -X POST "$ORCHESTRATION_URL/ingest" -F "file=@vector_store/hotel_rules.csv"
```

Komenda wysyła plik CSV do endpointu `/ingest` aplikacji Orchestration, który zaindeksuje jego zawartość w BigQuery. Oto co oznaczają poszczególne elementy:

- **`-X POST`** — typ żądania HTTP. `POST` służy do wysyłania danych na serwer (w odróżnieniu od `GET`, który tylko pobiera).
- **`-F "file=@..."`** — flaga `-F` wysyła dane w formacie **multipart/form-data** — tym samym, którego używa przeglądarka przy uploadzie pliku przez formularz HTML. Prefiks `@` oznacza „weź zawartość tego pliku". Gdybyś użył `-d`, curl wysłałby tekst jako zwykłe ciało żądania — serwer nie rozpoznałby go jako pliku.
- **Co robi endpoint `/ingest` po stronie serwera?** — dla każdego wiersza CSV wywołuje EmbeddingGemma (POST do `/api/embed`), odbiera wektor liczbowy i zapisuje parę `(tekst, wektor)` do tabeli BigQuery. Jedno wywołanie `/ingest` może więc wykonać dziesiątki żądań HTTP w tle.

---

## Komenda `curl` — endpoint `/ask`

```bash
curl -X POST "$ORCHESTRATION_URL/ask" \
     -H "Content-Type: application/json" \
     -d '{"query": "..."}'
```

Komenda wysyła zapytanie użytkownika do głównego endpointu RAG. Oto pełny przepływ tego, co dzieje się w tle:

1. **Wektoryzacja zapytania** — orchestration-api wysyła tekst zapytania do EmbeddingGemma (`POST /api/embed`). W odpowiedzi dostaje wektor liczbowy (~2048 liczb).
2. **Wyszukiwanie semantyczne** — orchestration-api wykonuje zapytanie SQL z funkcją `VECTOR_SEARCH` w BigQuery, które zwraca 3 dokumenty o wektorach najbliższych wektorowi zapytania (metryka kosinusowa).
3. **Budowanie promptu** — odnalezione fragmenty dokumentów są doklejane do zapytania jako kontekst.
4. **Generowanie odpowiedzi** — gotowy prompt trafia do modelu Bielik (`POST /api/chat`). Model generuje odpowiedź i odsyła ją przez orchestration-api z powrotem do `curl`.

Jedno zapytanie użytkownika powoduje więc wykonanie **3 żądań HTTP** w tle: do EmbeddingGemma, do BigQuery i do Bielika.
