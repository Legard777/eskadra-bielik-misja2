# Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud

Suwerenne i wiarygodne AI - Od dokumentów firmowych do inteligentnej bazy wiedzy w oparciu o model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i Google Cloud.

> [!WARNING]
>**Materiał warsztatowy — wyłącznie do celów edukacyjnych.**
>Kod i konfiguracja zawarte w tym repozytorium nie są przystosowane do wdrożeń produkcyjnych. Celowo pominięto m.in. uwierzytelnianie API, zarządzanie sekretami, monitoring oraz limity kosztów, aby uprościć przebieg warsztatu i skupić się na zrozumieniu architektury RAG.

## Agenda warsztatu

| # | Temat | Czas | Punkty |
|---|---|---|:---:|
| 0 | Wstęp — czym jest RAG, Bielik i architektura rozwiązania | 10 min | — |
| 1 | Przygotowanie projektu Google Cloud | 20 min | **5** |
| 2 | Konfiguracja zmiennych środowiskowych i usług Google Cloud | 5 min | **10** |
| 3 | Uruchomienie modeli Bielik i EmbeddingGemma na Cloud Run | 15 min | **20** |
| 4 | Inicjalizacja wektorowej bazy danych w BigQuery | 5 min | **5** |
| 5 | Uruchomienie API (Orchestration) na Cloud Run | 10 min | **10** |
| — | **Przerwa — lunch / poczęstunek / kawa / herbata / sok** | **30 min** | — |
| 6 | Testowanie API — zasilanie bazy i pierwsze zapytania RAG | 10 min | **10** |
| 7 | Przegląd API i architektury kodu | 10 min | **5** |
| 8 | Interfejs Web UI — porównanie modelu z RAG i bez RAG + eksperymenty | 20 min | **10** |
| 9 | Certyfikat ukończenia warsztatu | 10 min | — |
| 10 | Czyszczenie zasobów Google Cloud | 5 min | — |
| 11 | Networking | 30 min | — |
| | **Łącznie** | **~180 min** | **75 pkt** |

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
- **Modelu językowym LLM:** Suwerenny polski model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) charakteryzujący się bardzo dobrym zrozumieniem języka polskiego oraz polskiego kontekstu kulturowego. Uruchomiony w usłudze [Cloud Run](https://cloud.google.com/run?hl=en), odpowiada za ostateczne generowanie naturalnej dla użytkownika odpowiedzi.
- **Modelu osadzania (Embedding):** Wydajny model [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) uruchomiony w usłudze [Cloud Run](https://cloud.google.com/run?hl=en), służący do szybkiej zamiany tekstu (zapytań użytkownika i dokumentów docelowych) na reprezentację wektorową.
- **Wektorowej Bazie Wiedzy:** Skalowalna hurtownia danych [BigQuery](https://cloud.google.com/bigquery?hl=en) z mechanizmem Vector Search zapewniająca wektorowe wyszukiwanie semantycznie dopasowanych fragmentów z pośród milionów dokumentów źródłowych.
- **Logice i serwerze aplikacyjnym:** Aplikacja napisana w języku Python (z frameworkiem FastAPI), udostępniająca nakładkę graficzną Web UI oraz publiczne API spinające platformy w całość.

Dodatkowo, dzięki prostemu interfejsowi graficznemu, aplikacja pozwala na wygodne porównanie i empiryczne przetestowanie "surowego" modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) polegającego tylko na sobie w konfrontacji z bogatszą odpowiedzią modelu wspartego kontekstem RAG.

> [!TIP]
>Jeśli chcesz lepiej zrozumieć ideę RAG przed przystąpieniem do warsztatu, zapoznaj się z wprowadzeniem Google Cloud: [Retrieval-Augmented Generation](https://cloud.google.com/use-cases/retrieval-augmented-generation?hl=pl)

## Diagramy architektury

Szczegółowe diagramy i dokumentacja architektoniczna dostępne są w katalogu [`architektura/`](architektura/):

| Plik | Zawartość |
|---|---|
| [`01_widok_systemowy.md`](architektura/01_widok_systemowy.md) | Pełna mapa komponentów GCP i przepływu danych |
| [`02_pipeline_rag.md`](architektura/02_pipeline_rag.md) | Diagram sekwencji endpointu `/ask` (RAG) |
| [`03_pipeline_ingestion.md`](architektura/03_pipeline_ingestion.md) | Diagram sekwencji endpointu `/ingest` |
| [`04_kroki_warsztatu.md`](architektura/04_kroki_warsztatu.md) | Kolejność budowania systemu krok po kroku |
| [`05_mapa_repozytorium.md`](architektura/05_mapa_repozytorium.md) | Struktura plików i ich rola w architekturze |
| [`prompty_nano_banana.md`](architektura/prompty_nano_banana.md) | Prompty dla agentów AI — spójność architektoniczna |

<details>
<summary>📸 Podgląd 01 — Diagram architektury RAG</summary>

![Screenshot 01 — Diagram architektury RAG](assets/screenshot-01-architektura-rag.png)
> *Do uzupełnienia: wizualny diagram przedstawiający przepływ danych — od zapytania użytkownika, przez embedding i Vector Search w BigQuery, aż po odpowiedź modelu Bielik.*

</details>

## Z czego składa się kod?

Przykładowy kod źródłowy zawarty w tym repozytorium pozwala w szczególności na:

* Skonfigurowanie własnej instancji modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) w oparciu o silnik [Ollama](https://ollama.com/)

* Skonfigurowanie własnej instancji modelu osadzającego (embedding model) [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) w oparciu o [Ollama](https://ollama.com/)

* Uruchomienie obu powyższych modeli na platformie typu bezserwerowego: [Cloud Run](https://cloud.google.com/run?hl=en)

* Skonfigurowanie bazy wektorów w [BigQuery](https://cloud.google.com/bigquery?hl=en) wraz ze specjalnym zaawansowanym przeszukiwaniem [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search)

* Uruchomienie serwera Orchestration, który udostępnia API oraz interfejs Web UI, umożliwiający bezpośrednie porównanie odpowiedzi surowego modelu z odpowiedzią wzbogaconą o kontekst z bazy wiedzy (RAG)

---


## 1. Przygotowanie projektu Google Cloud `~20 min`

> [!NOTE]
>Przed warsztatem otrzymałeś instrukcję zapoznania się z procesem aktywacji kredytów Google Cloud (link w TIP poniżej) — ten krok nie powinien być dla Ciebie nowością.
>
>Jeżeli nie zapoznałeś się z instrukcją lub nie masz linka do aktywacji kredytów — **poinformuj prowadzącego natychmiast**, ponieważ bez aktywnego konta rozliczeniowego nie będziesz mógł kontynuować warsztatu.

### Krok 1.1 — Aktywacja konta rozliczeniowego z kredytami OnRamp

> [!NOTE]
>Kredyty OnRamp pozwalają korzystać z Google Cloud **bez karty kredytowej**. Otrzymasz od prowadzącego indywidualny link do aktywacji kredytów.

1. Otwórz otrzymany od prowadzącego link do aktywacji kredytów i postępuj zgodnie z instrukcjami
> [!TIP]
>Szczegółową instrukcję aktywacji kredytów znajdziesz w tym przewodniku: [Google Cloud Credits Redemption](https://codelabs.developers.google.com/codelabs/cloud-codelab-credits#1)

2. Wypełnij formularz aktywacji — podaj imię i nazwisko, zaakceptuj regulamin

3. Potwierdź że konto rozliczeniowe zostało aktywowane — pojawi się komunikat o przyznaniu kredytów

<details>
<summary>📸 Podgląd 02 — Potwierdzenie aktywacji kredytów</summary>

![Screenshot 02 — Potwierdzenie aktywacji kredytów](assets/screenshot-02-aktywacja-kredytow.png)
> *Do uzupełnienia: ekran potwierdzający przyznanie kredytów OnRamp — komunikat sukcesu z kwotą kredytów i datą wygaśnięcia.*

</details>

### Krok 1.2 — Utworzenie nowego projektu Google Cloud

1. W górnym lewym rogu [Google Cloud Console](https://console.cloud.google.com) kliknij nazwę aktywnego projektu (lub napis **„Wybierz projekt"**) — otworzy się selektor projektów. Kliknij **Nowy projekt**
> [!TIP]
>Szczegółową instrukcję tworzenia projektu znajdziesz w tym przewodniku: [Google Cloud Credits Redemption — krok 2](https://codelabs.developers.google.com/codelabs/cloud-codelab-credits#2)

2. Nadaj projektowi nazwę (np. `bielik-warsztat`) i jako konto rozliczeniowe wybierz konto aktywowane w poprzednim kroku

3. Kliknij **Utwórz** i poczekaj aż projekt zostanie utworzony

4. Upewnij się że nowo utworzony projekt jest aktywny (widoczny w selektorze projektów w górnym pasku)

<details>
<summary>📸 Podgląd 03 — Selektor projektów i nowy projekt</summary>

![Screenshot 03 — Selektor projektów i przycisk Nowy projekt](assets/screenshot-03-selektor-projektow.png)
> *Do uzupełnienia: górny pasek Google Cloud Console z otwartym selektorem projektów i podświetlonym przyciskiem "Nowy projekt".*

</details>

> [!CAUTION]
>Nie pomyl nazwy projektu z ID projektu — nie zawsze są takie same. ID projektu widoczne jest pod nazwą podczas tworzenia i na stronie głównej konsoli.

> [!TIP]
>Możesz potwierdzić że kredyty są powiązane z projektem wchodząc w menu po lewej stronie: **Billing → Credits**

### Krok 1.3 — Otwarcie terminala Cloud Shell i sklonowanie repozytorium

1. Otwórz terminal Cloud Shell klikając ikonę **`>_`** w górnym pasku Google Cloud Console ([dokumentacja](https://cloud.google.com/shell/docs))

<details>
<summary>📸 Podgląd 04 — Ikona Cloud Shell w górnym pasku</summary>

![Screenshot 04 — Ikona Cloud Shell w górnym pasku konsoli](assets/screenshot-04-ikona-cloud-shell.png)
> *Do uzupełnienia: górny pasek Google Cloud Console z podświetloną ikoną terminala `>_` (Cloud Shell).*

</details>

2. Zweryfikuj że zalogowane jest właściwe konto
   ```bash
   gcloud auth list
   ```
> [!TIP]
>Jeżeli widoczne jest inne konto niż to z kredytami, zaloguj się komendą: `gcloud auth login`

3. Potwierdź że aktywny jest właściwy projekt
   ```bash
   gcloud config get project
   ```
> [!TIP]
>Jeżeli projekt jest inny niż oczekiwany, zmień go komendą: `gcloud config set project <ID_TWOJEGO_PROJEKTU>`

4. Sklonuj repozytorium z kodem warsztatu
   ```bash
   git clone https://github.com/Legard777/eskadra-bielik-misja2
   ```

5. Przejdź do katalogu z kodem
   ```bash
   cd eskadra-bielik-misja2
   ```

<details>
<summary>📸 Podgląd 05 — Terminal Cloud Shell po sklonowaniu repozytorium</summary>

![Screenshot 05 — Terminal Cloud Shell z wynikiem git clone](assets/screenshot-05-cloud-shell-git-clone.png)
> *Do uzupełnienia: terminal Cloud Shell pokazujący pomyślne wykonanie `git clone` i przejście do katalogu projektu — widoczny prompt z ścieżką `~/eskadra-bielik-misja2`.*

</details>

> [!TIP]
>Cloud Shell posiada wbudowany edytor graficzny — przydatny do przeglądania i edycji plików bez znajomości edytorów terminalowych. Na potrzeby tego warsztatu nie jest wymagany, jednak możesz go uruchomić w dowolnym momencie komendą `cloudshell workspace .` lub klikając przycisk **Open Editor** w górnym pasku Cloud Shell. Więcej informacji: [Cloud Shell Editor](https://docs.cloud.google.com/shell/docs/editor-overview)

6. Zalicz krok i zdobądź **+5 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_1.sh
   ```

## 2. Konfiguracja zmiennych środowiskowych i usług Google Cloud `~5 min`

1. Nadaj prawa wykonywania wszystkim skryptom `.sh` *(z wyjątkiem `setup_env.sh`, który uruchamiamy przez `source` — nie wymaga bitu wykonywalności)*
   ```bash
   bash skrypty/make_scripts_executable.sh
   ```

2. Uruchom skrypt ochrony plików źródłowych *(tylko raz — zabezpiecza pliki `.py`, `.html`, `.csv` przed przypadkową edycją)*
   ```bash
   ./skrypty/protect_files.sh
   ```

3. Przejrzyj zawartość skryptu `setup_env.sh`
   ```bash
   cat setup_env.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zamiast czytać opis, zapytaj AI! Uruchom w terminalu:
   > ```bash
   > gemini "Co robi ten skrypt @setup_env.sh? Wyjaśnij każdą zmienną środowiskową."
   > ```
   > W celu zamknięcia Gemini CLI wybierz komendę `/quit`.
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-setupenvsh) — Twoja może brzmieć zupełnie inaczej i to jest jak najbardziej w porządku. Modele językowe są niedeterministyczne: za każdym razem generują odpowiedź od nowa, dlatego dwie osoby zadające to samo pytanie mogą otrzymać różne, ale równie poprawne wyjaśnienia.

4. Uruchom skrypt `setup_env.sh`
   ```bash
   source setup_env.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o różnicę między `source` a `./`:
   > ```bash
   > gemini "Jaka jest różnica między source setup_env.sh a ./setup_env.sh w bashu? Kiedy używać każdej z form?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#dlaczego-source-a-nie-setupenvsh).

   > **Ważne**
   >Jeżeli z jakiegoś powodu musisz ponownie uruchomić terminal Cloud Shell, pamiętaj aby ponownie uruchomić skrypt `setup_env.sh` aby wczytać zmienne środowiskowe.

5. Włącz potrzebne usługi w projekcie Google Cloud
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   gcloud services enable bigquery.googleapis.com
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI dlaczego usługi są domyślnie wyłączone:
   > ```bash
   > gemini "Dlaczego usługi Google Cloud są domyślnie wyłączone? Wyjaśnij krótko każdą z włączanych usług: run, cloudbuild, artifactregistry, bigquery i co się stanie jeśli pominąć ten krok."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#komendy-gcloud-services-enable).

6. Uzyskaj uprawnienia do wywoływania usług [Cloud Run](https://cloud.google.com/run?hl=en)
   ```bash
   gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$(gcloud config get-value account) \
    --role='roles/run.invoker'
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o model bezpieczeństwa Google Cloud:
   > ```bash
   > gemini "Wyjaśnij czym jest IAM w Google Cloud i jak działa rola roles/run.invoker. Co się stanie gdy wywołam curl bez tej roli — jaki błąd HTTP i dlaczego?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#komenda-gcloud-projects-add-iam-policy-binding).

7. Zażądaj dostępu do bucketu z modelami Ollama

   Modele [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) są przechowywane w centralnym buckecie organizatora warsztatu. Aby je skopiować w kroku 3, musisz najpierw uzyskać dostęp — skrypt wysyła Twoje konto do systemu i czeka na potwierdzenie:
   ```bash
   ./skrypty/request_access.sh
   ```

   > **Ważne**
   > Jeśli po 30 sekundach skrypt zgłosi brak dostępu — poinformuj prowadzącego. Bez dostępu do bucketu nie będziesz mógł wykonać kroku 3.

   > **Wskazówka**
   > Możesz ręcznie sprawdzić dostęp w dowolnym momencie:
   > ```bash
   > gcloud storage ls gs://$BUCKET_NAME_SOURCE
   > ```

8. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_2.sh
   ```

## 3. Uruchomienie modeli LLM Bielik i EmbeddingGemma na [Cloud Run](https://cloud.google.com/run?hl=en) `~15 min`

Poniższe kroki przeprowadzą Cię przez wdrożenie obu modeli **jeden po drugim** w tym samym terminalu.

### 3.1 Tworzenie bucketów i kopiowanie modeli Ollama

Uruchom skrypt, który automatycznie tworzy buckety i kopiuje oba modele — **[Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct)** (LLM) oraz **[EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/)** (embeddingowy):

```bash
./ollama_models/setup_models.sh
```

Po zakończeniu skrypt wypisze podsumowanie wykonanych kroków.

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o Cloud Storage i rozmiary modeli:
   > ```bash
   > gemini "Co robi skrypt @ollama_models/setup_models.sh? Czym jest Cloud Storage bucket i dlaczego modele językowe LLM ważą kilka gigabajtów, a nie kilka megabajtów jak zwykłe programy?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-ollama_modelssetup_modelssh).

### 3.2 Tworzenie dedykowanego repozytorium na obraz zawierający Ollama

Uruchom skrypt, który automatycznie tworzy repozytorium w Artifact Registry i buduje dedykowany obraz Docker z Ollama:

```bash
./ollama_docker_image/setup_ollama_image.sh
```

Po zakończeniu skrypt wypisze podsumowanie wykonanych kroków.

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o konteneryzację modeli AI:
   > ```bash
   > gemini "Co robi skrypt @ollama_docker_image/setup_ollama_image.sh? Czym jest obraz Docker, dlaczego buduje się własny obraz zamiast użyć gotowego i do czego służy Artifact Registry?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-ollama_docker_imagesetup_ollama_imagesh).

### 3.3 Model LLM->[Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct)
1. Przejdź do katalogu `llm`
   ```bash
   cd llm
   ```

2. Przejrzyj zawartość skryptu `cloud_run.sh` w tym katalogu
   ```bash
   cat cloud_run.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o GPU w chmurze:
   > ```bash
   > gemini "Co robi skrypt @llm/cloud_run.sh? Dlaczego model Bielik wymaga GPU NVIDIA L4 — czym fundamentalnie różni się przetwarzanie na GPU od CPU w kontekście modeli językowych?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-llmcloud_runsh).

3. Uruchom skrypt utworzenie modelu LLM->[Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) na [Cloud Run](https://cloud.google.com/run?hl=en) uruchamianym przez Ollama. Model pobrany za Google Cloud Storage
   ```bash
   ./cloud_run.sh
   ```

   > **Brak kwoty GPU?** Jeśli pojawi się błąd:
   > ```
   > ERROR: You do not have quota for using GPUs without zonal redundancy.
   > ```
   > Użyj awaryjnego skryptu bez GPU. Odpowiedzi modelu będą bardzo wolne (1–5 minut na prompt), ale warsztat można kontynuować:
   > ```bash
   > ./cloud_run_no_gpu.sh
   > ```

4. Sprawdź czy usługa `bielik` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

<details>
<summary>📸 Podgląd 06 — Usługa bielik w Cloud Run ze statusem Ready</summary>

![Screenshot 06 — Cloud Run lista usług z bielik Ready](assets/screenshot-06-cloud-run-bielik-ready.png)
> *Do uzupełnienia: widok listy usług Cloud Run w Google Cloud Console — usługa `bielik` z zielonym statusem "Ready" i adresem URL.*

</details>

5. Przejrzyj zawartość pliku `llm_test1.sh` w tym katalogu
   ```bash
   cat llm_test1.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o autoryzację JWT w API:
   > ```bash
   > gemini "Co robi skrypt @llm/llm_test1.sh? Wyjaśnij jak działa token JWT w Google Cloud — skąd pochodzi, jak długo jest ważny i co się stanie gdy wyślę zapytanie bez nagłówka Authorization?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-llmllm_test1sh).

6. Zadaj pierwsze pytanie modelowi [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i sprawdź jego odpowiedź
   ```bash
   ./llm_test1.sh
   ```

<details>
<summary>📸 Podgląd 07 — Przykładowa odpowiedź modelu Bielik</summary>

![Screenshot 07 — Terminal z odpowiedzią modelu Bielik](assets/screenshot-07-bielik-odpowiedz.png)
> *Do uzupełnienia: terminal pokazujący odpowiedź modelu Bielik na pierwsze testowe zapytanie — widoczny JSON z polem `response` zawierającym tekst po polsku.*

</details>

7. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

### 3.4 Model [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/)

1. Przejdź do katalogu `embedding_model`
   ```bash
   cd embedding_model
   ```

2. Przejrzyj zawartość skryptu `cloud_run.sh` w tym katalogu
   ```bash
   cat cloud_run.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o różnicę między modelem generatywnym a embeddingowym:
   > ```bash
   > gemini "Co robi skrypt @embedding_model/cloud_run.sh? Dlaczego model embeddingowy działa bez GPU, a Bielik go potrzebuje — co fundamentalnie różni generowanie tekstu od generowania wektora?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-embedding_modelcloud_runsh).

3. Uruchom skrypt utworzenie modelu EMBEDDING->Gemma na [Cloud Run](https://cloud.google.com/run?hl=en) uruchamianym przez Ollama. Model pobrany za Google Cloud Storage
   ```bash
   ./cloud_run.sh
   ```

4. Sprawdź czy usługa `embedding-gemma` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

<details>
<summary>📸 Podgląd 08 — Usługa embedding-gemma w Cloud Run ze statusem Ready</summary>

![Screenshot 08 — Cloud Run lista usług z embedding-gemma Ready](assets/screenshot-08-cloud-run-embedding-ready.png)
> *Do uzupełnienia: widok listy usług Cloud Run — obie usługi `bielik` i `embedding-gemma` widoczne z zielonym statusem "Ready".*

</details>

5. Przejrzyj zawartość pliku `embedding_model/embedding_test1.sh`
   ```bash
   cat embedding_test1.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o przestrzeń semantyczną:
   > ```bash
   > gemini "Co robi skrypt @embedding_model/embedding_test1.sh? Wyjaśnij czym jest przestrzeń wektorowa — jak 2048 liczb może wyrażać 'znaczenie' tekstu i dlaczego zdania o podobnym sensie dają wektory bliskie sobie geometrycznie?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-embedding_modelembedding_test1sh).

6. Wygeneruj pierwsze testowe embeddingi (wektory) dla przykładowego tekstu "Suwerenne AI po polsku — [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i RAG w Google Cloud".
   ```bash
   ./embedding_test1.sh
   ```

<details>
<summary>📸 Podgląd 09 — Przykładowy wektor embedding z modelu EmbeddingGemma</summary>

![Screenshot 09 — Terminal z fragmentem zwróconego wektora liczbowego](assets/screenshot-09-embedding-wektor.png)
> *Do uzupełnienia: terminal pokazujący odpowiedź modelu EmbeddingGemma — fragment tablicy liczb zmiennoprzecinkowych (embeddings) reprezentujących znaczenie tekstu.*

</details>

7. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

8. Zalicz krok i zdobądź **+20 punktów** — oba modele wdrożone, to najtrudniejszy etap warsztatu:
   ```bash
   ./checkpoints/checkpoint_3.sh
   ```

## 4. Inicjalizacja wektorowej bazy danych w BigQuery `~5 min`

Projekt wykorzystuje [BigQuery](https://cloud.google.com/bigquery?hl=en) z funkcją Vector Search jako bazę z wiedzą kontekstową.

1. Przejdź do katalogu `vector_store`
   ```bash
   cd vector_store
   ```

2. Zainstaluj wymagane biblioteki i zweryfikuj ich działanie
   ```bash
   ./install_deps.sh
   ```

   Skrypt wykonuje trzy rzeczy: instaluje pakiet `google-cloud-bigquery` (z flagą `--quiet`, żeby wyciszyć zbędne logi pip), a następnie automatycznie sprawdza czy biblioteka daje się zaimportować — to szybka weryfikacja, że instalacja przebiegła bez błędów i środowisko jest gotowe do pracy.

   > **Uwaga**
   > Celowo pomijamy tworzenie wirtualnego środowiska Python (`venv`). W warsztacie korzystamy z Cloud Shell, który jest tymczasowym środowiskiem uruchamianym od nowa po każdej sesji — instalacja globalna jest tu w zupełności wystarczająca. Wirtualne środowisko byłoby przydatne przy długotrwałym projekcie, gdzie chcemy izolować zależności między aplikacjami na tej samej maszynie.

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o zarządzanie zależnościami w Pythonie:
   > ```bash
   > gemini "Do czego służy biblioteka google-cloud-bigquery w Pythonie? Czym jest pip, jak działa instalacja zależności i dlaczego w Cloud Shell pomijamy wirtualne środowisko venv?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#pip-install-google-cloud-bigquery).

3. Przejrzyj kod skryptu inicjalizacyjnego
   ```bash
   cat init_db.py
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o projektowanie schematu dla Vector Search:
   > ```bash
   > gemini "Co robi skrypt @vector_store/init_db.py? Dlaczego kolumna embedding ma typ FLOAT64 REPEATED a nie JSON ani STRING — jak BigQuery Vector Search korzysta z tego konkretnego typu do wyszukiwania podobnych wektorów?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-vector_storeinit_dbpy).

4. Uruchom skrypt inicjalizacyjny, który stworzy zbiór danych i tabelę w [BigQuery](https://cloud.google.com/bigquery?hl=en)
   ```bash
   python init_db.py
   ```

5. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

6. Zalicz krok i zdobądź **+5 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_4.sh
   ```

## 5. Uruchomienie API (Orchestration) na [Cloud Run](https://cloud.google.com/run?hl=en) `~10 min`

Aplikacja Orchestration to serce całego rozwiązania RAG — spina model embeddingowy, [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search) i model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) w jeden przepływ i udostępnia go przez API oraz interfejs Web UI.

1. Przejrzyj kod aplikacji FastAPI
   ```bash
   cat orchestration/main.py
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o architekturę systemu RAG:
   > ```bash
   > gemini "Co robi plik @orchestration/main.py? Policz ile linii liczy ten plik i wyjaśnij jak FastAPI pozwala zbudować pełny system RAG — embedding, Vector Search, LLM — w tak zwartym kodzie."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#plik-orchestrationmainpy).

2. Przejrzyj skrypt wdrożeniowy
   ```bash
   cat orchestration/cloud_run.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o dobre praktyki konfiguracji aplikacji:
   > ```bash
   > gemini "Co robi skrypt @orchestration/cloud_run.sh? Wyjaśnij dlaczego adresy URL modeli są przekazywane przez zmienne środowiskowe a nie wpisane na stałe w kodzie — czym jest zasada twelve-factor app?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#skrypt-orchestrationcloud_runsh).

3. Przejdź do katalogu `orchestration`
   ```bash
   cd orchestration
   ```

4. Uruchom skrypt wdrażający aplikację na [Cloud Run](https://cloud.google.com/run?hl=en)
   ```bash
   ./cloud_run.sh
   ```

   > **Uwaga**
   > W trakcie wdrożenia może pojawić się pytanie o utworzenie repozytorium Docker w Artifact Registry:
   > ```
   > Deploying from source requires an Artifact Registry Docker repository to store built containers.
   > A repository named [cloud-run-source-deploy] in region [europe-west1] will be created.
   >
   > Do you want to continue (Y/n)?
   > ```
   > Wpisz `Y` i zatwierdź Enterem — to jednorazowy krok przy pierwszym wdrożeniu z kodu źródłowego.

5. Po zakończeniu wdrożenia pobierz adres URL usługi i zapisz go do zmiennej środowiskowej
   ```bash
   export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
   ```

   > **Uwaga**
   > Zmienna `$ORCHESTRATION_URL` będzie potrzebna w kolejnych krokach do wysyłania zapytań przez `curl`. Jak wszystkie zmienne środowiskowe — działa tylko w bieżącym terminalu.

6. Wróć do głównego katalogu
   ```bash
   cd ..
   ```

7. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_5.sh
   ```

---

## ☕ Przerwa — lunch / poczęstunek / kawa / herbata / sok `~30 min`

> Wszystkie komponenty są wdrożone i gotowe. Po przerwie przetestujemy całe rozwiązanie RAG w akcji.

---

> [!IMPORTANT]
> **Powrót po przerwie — sprawdź terminal przed kontynuacją.**
> Cloud Shell automatycznie rozłącza się po okresie bezczynności, co usuwa wszystkie zmienne środowiskowe z pamięci. Jeśli robiłeś przerwę, uruchom poniższe komendy przed przejściem do kroku 6:
>
> 1. Przejdź do katalogu projektu
>    ```bash
>    cd ~/eskadra-bielik-misja2
>    ```
>
> 2. Załaduj zmienne środowiskowe
>    ```bash
>    source setup_env.sh
>    ```
>
> 3. Odtwórz adres URL usługi Orchestration API
>    ```bash
>    export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
>    ```
>
> Jeśli nie robiłeś przerwy i terminal był aktywny — możesz pominąć ten krok.

---

## 6. Testowanie API — Zasilanie i Wyszukiwanie (RAG) `~10 min`

1. Przejrzyj plik z przykładowymi danymi
   ```bash
   ./vector_store/show_data.sh
   ```

   Plik CSV zawiera dwie kolumny:

   | Kolumna | Opis |
   |---|---|
   | `id` | Unikalny identyfikator rekordu |
   | `text` | Treść dokumentu — zasada hotelowa w języku naturalnym |

   > **Uwaga**
   > Po wgraniu danych przez endpoint `/ingest` aplikacja automatycznie doda trzecią kolumnę: **`embedding`** — wygenerowany przez [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) wektor liczbowy reprezentujący znaczenie tekstu. To właśnie ta kolumna umożliwia semantyczne wyszukiwanie w [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search).

2. Wgraj przykładowe dane do [BigQuery](https://cloud.google.com/bigquery?hl=en) z pliku CSV
   ```bash
   curl -X POST "$ORCHESTRATION_URL/ingest" \
        -F "file=@vector_store/hotel_rules.csv"
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI jak działa wysyłanie pliku przez HTTP:
   > ```bash
   > gemini "Co robi ta komenda curl? Wyjaśnij czym jest multipart/form-data, czym różni się flaga -F od -d w curl i jak endpoint /ingest po stronie serwera odbiera i przetwarza przesłany plik CSV."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#komenda-curl-ingest).

3. Zweryfikuj czy rekordy pojawiły się w [BigQuery](https://cloud.google.com/bigquery?hl=en)

   Otwórz [BigQuery w Google Cloud Console](https://console.cloud.google.com/bigquery), przejdź do tabeli `rag_dataset` → `hotel_rules` i kliknij przycisk **Preview** aby podejrzeć dane.

   > **Preview jest bezpłatny** — nie wykonuje zapytania SQL i nie zużywa limitu darmowych zapytań BigQuery. To najszybszy sposób sprawdzenia czy dane zostały załadowane poprawnie.

   > **Uwaga**
   > Dane tekstowe w kolumnach `id`, `content` widoczne są natychmiast. Indeksowanie kolumny `embedding` na potrzeby Vector Search może chwilę potrwać — to normalne i nie blokuje kolejnych kroków.

<details>
<summary>📸 Podgląd 10 — BigQuery Preview tabeli hotel_rules z danymi</summary>

![Screenshot 10 — BigQuery Preview tabeli z kolumną embedding](assets/screenshot-10-bigquery-preview.png)
> *Do uzupełnienia: widok BigQuery Console z otwartą tabelą `hotel_rules` i klikniętym przyciskiem "Preview" — widoczne kolumny `id`, `content` i `embedding` z wypełnionymi danymi.*

</details>

   > **Dla chętnych — weryfikacja SQL:** jeśli chcesz zobaczyć dane zapytaniem, wklej w edytorze BigQuery:
   > ```sql
   > SELECT id, content, ARRAY_LENGTH(embedding) AS embedding_dimensions
   > FROM `rag_dataset.hotel_rules`
   > ORDER BY id
   > LIMIT 10
   > ```
   > Kolumna `embedding_dimensions` pokaże ile wymiarów ma wygenerowany wektor.

4. Wykonaj testowe zapytania RAG

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

<details>
<summary>📸 Podgląd 11 — Przykładowa odpowiedź RAG z endpointu /ask</summary>

![Screenshot 11 — Terminal z odpowiedzią RAG](assets/screenshot-11-odpowiedz-rag.png)
> *Do uzupełnienia: terminal pokazujący odpowiedź JSON z endpointu `/ask` — widoczne pola `answer` (odpowiedź Bielika) oraz `context` (fragmenty dokumentów pobrane z BigQuery Vector Search).*

</details>

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o mechanizm RAG od środka:
   > ```bash
   > gemini "Prześledź krok po kroku co dzieje się w systemie gdy wysyłam zapytanie do endpointu /ask: od wektora zapytania, przez VECTOR_SEARCH w BigQuery, aż do odpowiedzi Bielika. Ile żądań HTTP wykonuje orchestration-api w tle obsługując jedno pytanie użytkownika?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](script_descriptions.md#komenda-curl-ask).

   > **Dla chętnych — odpowiednik SQL:** każde z powyższych zapytań wewnętrznie wykonuje Vector Search w BigQuery. Możesz zobaczyć jak to wygląda „pod maską", wklejając w edytorze BigQuery (zastąp `[...]` wektorem zwróconym przez `/api/embed`):
   > ```sql
   > SELECT base.content, distance
   > FROM VECTOR_SEARCH(
   >   TABLE `rag_dataset.hotel_rules`,
   >   'embedding',
   >   (SELECT [...] AS embedding),
   >   top_k => 3,
   >   distance_type => 'COSINE'
   > )
   > ```
   > Wynik to 3 dokumenty semantycznie najbliższe zapytaniu — dokładnie to, co aplikacja wysyła jako kontekst do modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct).

5. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_6.sh
   ```

## 7. Interfejs Programistyczny (API) `~10 min`

Aplikacja udostępnia proste API stworzone przy pomocy frameworka *FastAPI*, pozwalające nie tylko na zasilanie bazy wiedzy, ale również na zadawanie pytań.

Aplikacja definiuje w pliku `orchestration/main.py` następujące ścieżki:

* `GET /` – serwuje statyczny plik interfejsu użytkownika (`index.html`).
* `POST /ingest` – przyjmuje plik CSV i indeksuje zawarte w nim informacje jako wektory w [BigQuery](https://cloud.google.com/bigquery?hl=en) (wykorzystując model embeddingowy `EmbeddingGemma`).
* `POST /ask` – główny endpoint RAG: 
  - zamienia zapytanie z tekstu na wektor,
  - wyszukuje semantycznie 3 najbardziej zbliżone dokumenty wektorowe w tabeli [BigQuery](https://cloud.google.com/bigquery?hl=en),
  - buduje prompt z odnalezionym kontekstem,
  - wysyła połączony prompt do modelu `Bielik` i zwraca ostateczną odpowiedź wraz z wybranym i wykorzystanym kontekstem.
* `POST /ask_direct` – służy jako zestawienie porównawcze (baseline). Przyjmuje zapytanie i wysyła je bezpośrednio do bazowego modelu `Bielik`, z całkowitym pominięciem RAG.
* `GET /records` – zwraca listę dokumentów zapisanych w tabeli [BigQuery](https://cloud.google.com/bigquery?hl=en) (pola `id` i `content`, bez wektorów). Parametr `limit` pozwala ograniczyć liczbę wyników (domyślnie 100).
* `GET /docs` – interaktywna dokumentacja API wygenerowana automatycznie przez FastAPI (Swagger UI). Pozwala przeglądać i testować wszystkie endpointy bezpośrednio w przeglądarce.
* `GET /redoc` – alternatywna dokumentacja API w formacie ReDoc.

Otwórz interaktywną dokumentację API w przeglądarce:
```bash
echo "$ORCHESTRATION_URL/docs"
```

<details>
<summary>📸 Podgląd 12 — Swagger UI z dokumentacją API</summary>

![Screenshot 12 — Przeglądarka z interfejsem Swagger UI /docs](assets/screenshot-12-swagger-ui.png)
> *Do uzupełnienia: przeglądarka otwarta na adresie `/docs` — widoczny interfejs Swagger UI z listą wszystkich endpointów: GET `/`, POST `/ingest`, POST `/ask`, POST `/ask_direct`, GET `/records`.*

</details>

Zalicz krok i zdobądź **+5 punktów** — uruchom skrypt weryfikacyjny, który potwierdzi że wszystkie usługi działają razem:

```bash
./checkpoints/checkpoint_7.sh
```

## 8. Interfejs Użytkownika (Web UI) `~20 min`

Oprócz interfejsu API, aplikacja udostępnia również prostą nakładkę WWW. Całość pozwala na wygodne sprawdzenie i porównanie działania bazowego modelu [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) z modelem [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) wspartym przez RAG.

Interfejs użytkownika zaimplementowano w jednym, statycznym pliku: `orchestration/static/index.html`. 

Skrypt osadzony w pliku HTML wysyła dwa jednoczesne żądania do endpointów `/ask` (wsparty RAG) oraz `/ask_direct` (bezpośrednio do modelu `Bielik`) i prezentuje obie odpowiedzi modelu obok siebie celem zilustrowania różnic. Wyświetla obok również jakich dokładnie fragmentów dokumentów [BigQuery](https://cloud.google.com/bigquery?hl=en) model użył w przypadku posiłkowania się dodatkowym kontekstem RAG.

> [!TIP]
> Zachęcamy Cię gorąco do eksperymentów! Przejrzyj kod źródłowy plików `orchestration/main.py` oraz `orchestration/static/index.html`, aby zobaczyć, w jak prosty sposób w Pythonie łączy się wyszukiwanie wektorowe [BigQuery](https://cloud.google.com/bigquery?hl=en) z modelem LLM i serwuje dla prostej graficznej nakładki JavaScript.
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

2. Po otwarciu opublikowanej strony w Twojej przeglądarce internetowej, wpisz w okno dialogowe dowolne zapytanie i kliknij "Zapytaj". Przykładowe pytania:
   - *"Do której godziny jest otwarty basen?"*
   - *"Czy mogę zabrać psa do hotelu?"*
   - *"Jak połączyć się z WiFi?"*

3. Porównaj strumień odpowiedzi wyświetlany dla samej bazy wiedzy modelu (bez dodatkowego kontekstu) z bogatszą odpowiedzią RAG wygenerowaną w oparciu o wiedzę z przeszukiwania [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search).

<details>
<summary>📸 Podgląd 13 — Web UI z porównaniem odpowiedzi RAG vs bez RAG</summary>

![Screenshot 13 — Interfejs Web UI z dwoma kolumnami odpowiedzi](assets/screenshot-13-webui-porownanie.png)
> *Do uzupełnienia: przeglądarka z otwartym interfejsem Web UI — widoczne dwie kolumny z odpowiedziami na to samo pytanie: lewa (model bez RAG) i prawa (model z kontekstem RAG z BigQuery), poniżej sekcja "Użyty kontekst" z fragmentami dokumentów.*

</details>

### Eksperymenty — zmień wygląd interfejsu

> [!TIP]
> **🤖 Zadanie dla Gemini CLI** — zmień motyw kolorystyczny interfejsu Web UI!
>
> 1. Odblokuj plik interfejsu do edycji:
>    ```bash
>    chmod +w orchestration/static/index.html
>    ```
> 2. Poproś Gemini CLI o zmianę motywu — możesz wybrać dowolny styl:
>    ```bash
>    gemini "Zmodyfikuj plik @orchestration/static/index.html zmieniając motyw kolorystyczny na ciemny (dark mode) z akcentami w kolorze niebieskim. Zachowaj całą funkcjonalność i strukturę HTML."
>    ```
>    Lub spróbuj innego stylu:
>    ```bash
>    gemini "Zmodyfikuj plik @orchestration/static/index.html nadając mu wygląd retro-terminala (zielony tekst na czarnym tle, czcionka monospace). Zachowaj całą funkcjonalność."
>    ```
> 3. Przejrzyj zmiany w edytorze Cloud Shell:
>    ```bash
>    cloudshell edit orchestration/static/index.html
>    ```
> 4. Aby zobaczyć zmiany na żywo — wdróż ponownie aplikację (tak samo jak w kroku 5):
>    ```bash
>    cd orchestration && ./cloud_run.sh && cd ..
>    ```
>    Po zakończeniu wdrożenia odśwież stronę w przeglądarce.

4. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_8.sh
   ```

## 9. Certyfikat ukończenia warsztatu `~10 min`

Gratulacje — warsztat dobiegł końca! Wygeneruj zaszyfrowany certyfikat zawierający wszystkie 8 checkpointów i prześlij go prowadzącemu.

> [!IMPORTANT]
> Przed wygenerowaniem certyfikatu upewnij się, że wszystkie 8 checkpointów zostało wykonanych (pliki `cert_artifacts/checkpoint_N.enc` muszą istnieć). Skrypt sam to weryfikuje i zgłosi brakujące kroki.

```bash
./checkpoints/certyfikat_generate.sh
```

Po pomyślnym wykonaniu pobierz plik certyfikatu na swój komputer za pomocą wbudowanej komendy Cloud Shell:

```bash
cloudshell dl cert_artifacts/checkpoint_certyfikat.enc
```

> [!TIP]
> Komenda `cloudshell dl` automatycznie pobiera plik do folderu Pobrane na Twoim lokalnym komputerze. Plik jest zaszyfrowany — możesz go przesłać prowadzącemu przez dowolny kanał (email, Slack, formularz).

Wyślij pobrany plik `checkpoint_certyfikat.enc` prowadzącemu.

> [!TIP]
> Plik jest zaszyfrowany — możesz go przesłać przez dowolny kanał (email, formularz, Slack). Zawiera potwierdzenie wykonania wszystkich etapów warsztatu powiązane z Twoim kontem Google Cloud i projektem.

---

## 10. Czyszczenie zasobów Google Cloud `~5 min`

Po zakończeniu warsztatu masz dwie opcje — wybierz w zależności od tego, czy chcesz zachować dostęp do wdrożonego systemu RAG.

### Przegląd kosztów zasobów

| Zasób | Nazwa | Koszt po warsztacie | Uwagi |
|---|---|---|---|
| Cloud Run | `bielik`, `embedding-gemma`, `orchestration-api` | ~$0 gdy idle | Skalują do zera gdy brak ruchu |
| BigQuery | dataset `rag_dataset` | bezpłatny | W ramach free tier |
| Artifact Registry | `ollama-repo`, `cloud-run-source-deploy` | **~$0.01/mies.** | Jedyny stały koszt — warto usunąć |
| Cloud Storage | buckety z modelami i źródłami | ~$0 | W ramach free tier |

### Opcja A — Zalecana: zostaw usługi, usuń tylko Artifact Registry

Usługi [Cloud Run](https://cloud.google.com/run?hl=en) skalują się automatycznie do zera gdy nikt ich nie odpytuje — nie generują kosztów w trybie idle. Jedynym stałym kosztem są repozytoria Artifact Registry (~$0.01/mies.).

1. Wróć do głównego katalogu i uruchom minimalny skrypt czyszczący:
   ```bash
   cd ~/eskadra-bielik-misja2
   ./skrypty/cleanup_minimal.sh
   ```

2. *(Opcjonalnie)* Zabezpiecz publiczny endpoint orchestration-api przed nieautoryzowanym dostępem:
   ```bash
   gcloud run services update orchestration-api \
     --region $REGION \
     --no-allow-unauthenticated
   ```
   > **Uwaga**
   > Po tej zmianie dostęp do Web UI i API będzie wymagał tokenu autoryzacyjnego Google. Aby wygenerować token: `gcloud auth print-identity-token`

3. Zweryfikuj usunięcie repozytoriów:
   - **Artifact Registry:** [console.cloud.google.com/artifacts](https://console.cloud.google.com/artifacts)

### Opcja B — Pełne czyszczenie: usuń wszystko

Jeśli chcesz mieć 100% pewności braku kosztów lub zamierzasz zakończyć pracę z projektem, usuń wszystkie zasoby. Możesz je odtworzyć od nowa powtarzając kroki warsztatu.

> [!CAUTION]
> Ta operacja jest nieodwracalna. Wszystkie dane w [BigQuery](https://cloud.google.com/bigquery?hl=en), wdrożone modele i usługi zostaną trwale usunięte.

1. Wróć do głównego katalogu projektu i uruchom pełny skrypt czyszczący:
   ```bash
   cd ~/eskadra-bielik-misja2
   ./skrypty/cleanup.sh
   ```

2. Skrypt wyświetli listę zasobów do usunięcia i poprosi o potwierdzenie. Wpisz `tak` aby kontynuować.

3. Po zakończeniu zweryfikuj w Google Cloud Console, że zasoby zostały usunięte:
   - **Cloud Run:** [console.cloud.google.com/run](https://console.cloud.google.com/run)
   - **BigQuery:** [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)
   - **Artifact Registry:** [console.cloud.google.com/artifacts](https://console.cloud.google.com/artifacts)
   - **Cloud Storage:** [console.cloud.google.com/storage](https://console.cloud.google.com/storage)

## 11. Networking `~30 min`

Właśnie zbudowałeś działający system RAG oparty na polskim modelu językowym i Google Cloud. Czas porozmawiać z innymi uczestnikami — może przy kawie.

### Tematy do rozmowy

Wszyscy przeszliście przez ten sam warsztat, ale każdy może mieć inne przemyślenia. Kilka pytań na start:

- **Co Cię zaskoczyło?** — Czy coś zadziałało lepiej lub gorzej niż się spodziewałeś?
- **Gdzie widzisz zastosowanie RAG w swoim projekcie/firmie?** — Jakie dokumenty chciałbyś przeszukiwać semantycznie?
- **Co byś zmienił w architekturze?** — Inne modele? Inna baza wektorowa? Inne chunking strategii?
- **Bielik vs. inne modele** — Jak oceniasz jakość odpowiedzi w porównaniu do modeli, których używasz na co dzień?

### Co dalej?

Zbudowany dziś system to punkt startowy. Kilka kierunków do eksploracji:

| Kierunek | Opis |
|---|---|
| Własne dokumenty | Zamień `hotel_rules.csv` na własne dane — regulaminy, dokumentację, FAQ |
| Chunking | Podziel długie dokumenty na fragmenty przed indeksowaniem dla lepszej precyzji RAG |
| Ewaluacja | Zmierz jakość odpowiedzi RAG — sprawdź projekt [RAGAS](https://docs.ragas.io/) |
| Streaming | Dodaj strumieniowanie odpowiedzi (`stream: true` w Ollama API) do Web UI |
| Większy Bielik | Wypróbuj większą wersję modelu — [SpeakLeash na Hugging Face](https://huggingface.co/speakleash) |
| Produkcja | Dodaj uwierzytelnianie, monitoring, limity kosztów zgodnie z [Cloud Run GPU Best Practices](https://docs.cloud.google.com/run/docs/configuring/services/gpu-best-practices) |

### Zostańmy w kontakcie

- Repozytorium warsztatu: [github.com/Legard777/eskadra-bielik-misja2](https://github.com/Legard777/eskadra-bielik-misja2)
- Model Bielik: [SpeakLeash](https://speakleash.org/) — projekt tworzenia polskich modeli językowych open source
- Społeczność: [Google Cloud Community Poland](https://www.meetup.com/google-cloud-community-poland/)

---

### Orientacyjny koszt warsztatu

Na podstawie rzeczywistego przebiegu warsztatu całkowity koszt wynosi **~$3–4**.

Dominującą pozycją jest GPU NVIDIA L4 używany przez model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) na [Cloud Run](https://cloud.google.com/run?hl=en). Usługi [Cloud Run](https://cloud.google.com/run?hl=en) z GPU działają w trybie **instance-based billing** (wymagane przez Google Cloud) — oznacza to, że płacisz za każdą sekundę gdy instancja jest aktywna, niezależnie od tego czy w danej chwili obsługuje zapytanie. Instancja może skalować do zera gdy przez dłuższy czas nikt jej nie odpytuje, jednak ze względu na długi czas zimnego startu (ładowanie modelu) pozostaje aktywna przez cały czas trwania warsztatu.

| Usługa | Składnik | Orientacyjny koszt |
|---|---|---|
| Cloud Run (Bielik) | GPU NVIDIA L4 | ~$1.30 |
| Cloud Run | CPU — billing instancyjny | ~$1.01 |
| Cloud Run | RAM — billing instancyjny | ~$0.25 |
| Cloud Run | CPU — billing requestowy | ~$0.03 |
| Networking | Network Intelligence Center | ~$0.02 |
| Artifact Registry | `ollama-repo` + `cloud-run-source-deploy` | ~$0.01/mies. |
| **Łącznie** | | **~$3.91** |

> [!IMPORTANT]
>Uruchom skrypt `cleanup.sh` niezwłocznie po zakończeniu warsztatu. Usługi [Cloud Run](https://cloud.google.com/run?hl=en) z GPU naliczają koszty przez cały czas działania instancji — nawet gdy nikt z nich aktywnie nie korzysta.

### Optymalizacje dla środowisk produkcyjnych [Cloud Run](https://cloud.google.com/run?hl=en)

Konfiguracja użyta w tym warsztacie jest celowo uproszczona. Dla zastosowań produkcyjnych Google [Cloud Run](https://cloud.google.com/run?hl=en) dokumentuje szereg optymalizacji - szczegóły: [Cloud Run GPU Best Practices](https://docs.cloud.google.com/run/docs/configuring/services/gpu-best-practices)
