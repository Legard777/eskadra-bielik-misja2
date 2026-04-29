# Eskadra Bielik - Misja 2 - RAG w oparciu o model Bielik i Google Cloud

Suwerenne i wiarygodne AI - Od dokumentów firmowych do inteligentnej bazy wiedzy w oparciu o model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i Google Cloud.

> [!NOTE]
> To repozytorium jest forkiem projektu [eskadra-bielik-misja2](https://github.com/avedave/eskadra-bielik-misja2) autorstwa [Dawida Ostrowskiego](https://github.com/avedave). Oficjalna wersja oryginalna dostępna jest pod adresem: https://github.com/avedave/eskadra-bielik-misja2. Niniejsza wersja zawiera dodatkowe modyfikacje i rozszerzenia względem oryginału.

> [!WARNING]
>**Materiał warsztatowy — wyłącznie do celów edukacyjnych.**
>Kod i konfiguracja zawarte w tym repozytorium nie są przystosowane do wdrożeń produkcyjnych. Celowo pominięto m.in. uwierzytelnianie API, zarządzanie sekretami, monitoring oraz limity kosztów, aby uprościć przebieg warsztatu i skupić się na zrozumieniu architektury RAG.

<video src="https://github.com/user-attachments/assets/5e0f5dca-dca6-4b87-be20-0ef5834bd746" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

## Agenda warsztatu

| # | Temat | Czas | Punkty |
|---|---|---|:---:|
| 0 | Wstęp — czym jest RAG, Bielik i architektura rozwiązania | 10 min | — |
| 1 | Przygotowanie projektu Google Cloud | 20 min | **5** |
| 2 | Konfiguracja zmiennych środowiskowych i usług Google Cloud | 5 min | **10** |
| 3 | Uruchomienie modeli Bielik i EmbeddingGemma na Cloud Run | 15 min | **20** |
| 4 | Inicjalizacja wektorowej bazy danych w BigQuery | 5 min | **5** |
| 5 | Uruchomienie API (Orchestration) na Cloud Run | 10 min | **10** |
| 6 | Testowanie API — zasilanie bazy i pierwsze zapytania RAG | 10 min | **10** |
| 7 | Przegląd API i architektury kodu | 10 min | **5** |
| 8 | Interfejs Web UI — porównanie modelu z RAG i bez RAG + eksperymenty | 20 min | **10** |
| 9 | Certyfikat ukończenia warsztatu | 10 min | — |
| 10 | Czyszczenie zasobów Google Cloud | 5 min | — |
| 11 | **Lunch i networking** | **60 min** | — |
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

<video src="https://github.com/user-attachments/assets/d2feb2b3-cab1-4a05-9b9c-62beaccd0670" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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
<summary>▶️ Nagranie — Pipeline ingestion: ładowanie danych do BigQuery</summary>

<a href="https://youtu.be/D0qCltR8UJQ" target="_blank">
  <img src="https://img.youtube.com/vi/D0qCltR8UJQ/0.jpg" alt="RAG Ingestion Steps" width="480">
</a>

</details>

<details>
<summary>▶️ Nagranie — Pipeline RAG: zapytanie → embedding → BQ → LLM → odpowiedź</summary>

<a href="https://youtu.be/D7s8duHl7sQ" target="_blank">
  <img src="https://img.youtube.com/vi/D7s8duHl7sQ/0.jpg" alt="RAG Query Steps" width="480">
</a>

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

<video src="https://github.com/user-attachments/assets/8d0bf96a-1460-4bd4-8c52-cf389c8533dd" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

> [!NOTE]
>Przed warsztatem została przesłana instrukcja zapoznania się z procesem aktywacji kredytów Google Cloud (link w TIP poniżej) — ten krok nie powinien być nowością.
>
>Jeżeli instrukcja nie dotarła lub nie ma dostępu do linka aktywacji kredytów — **poinformuj prowadzącego natychmiast**, ponieważ bez aktywnego konta rozliczeniowego kontynuowanie warsztatu nie będzie możliwe.

### Krok 1.1 — Aktywacja konta rozliczeniowego z kredytami OnRamp

> [!NOTE]
>Kredyty OnRamp pozwalają korzystać z Google Cloud **bez karty kredytowej**. Otrzymasz od prowadzącego indywidualny link do aktywacji kredytów.

1. Otwórz otrzymany od prowadzącego link do aktywacji kredytów i postępuj zgodnie z instrukcjami
> [!TIP]
>Szczegółową instrukcję aktywacji kredytów znajdziesz w tym przewodniku: [Google Cloud Credits Redemption](https://codelabs.developers.google.com/codelabs/cloud-codelab-credits#1)

2. Wypełnij formularz aktywacji — podaj imię i nazwisko, zaakceptuj regulamin

3. Potwierdź że konto rozliczeniowe zostało aktywowane — pojawi się komunikat o przyznaniu kredytów

<!-- 
<details>
<summary>📸 Podgląd 02 — Potwierdzenie aktywacji kredytów</summary>

![Screenshot 02 — Potwierdzenie aktywacji kredytów](assets/screenshot-02-aktywacja-kredytow.png)
> *Do uzupełnienia: ekran potwierdzający przyznanie kredytów OnRamp — komunikat sukcesu z kwotą kredytów i datą wygaśnięcia.*

</details>
-->

### Krok 1.2 — Utworzenie nowego projektu Google Cloud

1. W górnym lewym rogu [Google Cloud Console](https://console.cloud.google.com) kliknij nazwę aktywnego projektu (lub napis **„Wybierz projekt"**) — otworzy się selektor projektów. Kliknij **Nowy projekt**
> [!TIP]
>Szczegółową instrukcję tworzenia projektu znajdziesz w tym przewodniku: [Google Cloud Credits Redemption — krok 2](https://codelabs.developers.google.com/codelabs/cloud-codelab-credits#2)

2. Nadaj projektowi nazwę (np. `bielik-warsztat-20260429-gw` — dodaj datę bez kresek i swoje inicjały, np. `bielik-warsztat-RRRRMMDD-XX`, ponieważ nazwy projektów w GCP muszą być **unikalne globalnie**) i jako konto rozliczeniowe wybierz konto aktywowane w poprzednim kroku

3. Kliknij **Utwórz** i poczekaj aż projekt zostanie utworzony

4. Upewnij się że nowo utworzony projekt jest aktywny (widoczny w selektorze projektów w górnym pasku)

<!-- 
<details>
<summary>📸 Podgląd 03 — Selektor projektów i nowy projekt</summary>

![Screenshot 03 — Selektor projektów i przycisk Nowy projekt](assets/screenshot-03-selektor-projektow.png)
> *Do uzupełnienia: górny pasek Google Cloud Console z otwartym selektorem projektów i podświetlonym przyciskiem "Nowy projekt".*

</details>
-->

> [!CAUTION]
>Nie pomyl nazwy projektu z ID projektu — nie zawsze są takie same. ID projektu widoczne jest pod nazwą podczas tworzenia i na stronie głównej konsoli.

> [!TIP]
>Możesz potwierdzić że kredyty są powiązane z projektem wchodząc w menu po lewej stronie: **Billing → Credits**

### Krok 1.3 — Otwarcie terminala Cloud Shell i sklonowanie repozytorium

1. Otwórz terminal Cloud Shell klikając ikonę **`>_`** w górnym pasku Google Cloud Console ([dokumentacja](https://cloud.google.com/shell/docs))

<!-- 
<details>
<summary>📸 Podgląd 04 — Ikona Cloud Shell w górnym pasku</summary>

![Screenshot 04 — Ikona Cloud Shell w górnym pasku konsoli](assets/screenshot-04-ikona-cloud-shell.png)
> *Do uzupełnienia: górny pasek Google Cloud Console z podświetloną ikoną terminala `>_` (Cloud Shell).*

</details>
-->

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

<!-- 
<details>
<summary>📸 Podgląd 05 — Terminal Cloud Shell po sklonowaniu repozytorium</summary>

![Screenshot 05 — Terminal Cloud Shell z wynikiem git clone](assets/screenshot-05-cloud-shell-git-clone.png)
> *Do uzupełnienia: terminal Cloud Shell pokazujący pomyślne wykonanie `git clone` i przejście do katalogu projektu — widoczny prompt z ścieżką `~/eskadra-bielik-misja2`.*

</details>
-->

> [!TIP]
>Cloud Shell posiada wbudowany edytor graficzny — przydatny do przeglądania i edycji plików bez znajomości edytorów terminalowych. Na potrzeby tego warsztatu nie jest wymagany, jednak możesz go uruchomić w dowolnym momencie komendą `cloudshell workspace .` lub klikając przycisk **Open Editor** w górnym pasku Cloud Shell. Więcej informacji: [Cloud Shell Editor](https://docs.cloud.google.com/shell/docs/editor-overview)

6. 🛑 **STOP — wstaw tutaj nazwę otrzymaną od prowadzącego.** Jest to oddzielna wartość (`CF_NAZWA_PROJEKTU`) — **nie** jest to nazwa ani ID Twojego własnego projektu Google Cloud:
   ```bash
   ./checkpoints/cf_project_change.sh {CF_NAZWA_PROJEKTU}
   ```

> ⚠️ Bez tego kroku certyfikat z wynikami nie trafi do prowadzącego. Zastąp `{CF_NAZWA_PROJEKTU}` dokładnie tą wartością, którą podał prowadzący — **nie wpisuj tu nazwy ani ID swojego projektu Google Cloud**. Skrypt obsługuje oba formaty: `{bielik-test}` i `bielik-test`.

7. Zalicz krok i zdobądź **+5 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_1.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 1 — Przygotowanie projektu Google Cloud
======================================================

[1.1] Konto Google Cloud:
  [OK]  Zalogowane konto: [dane dynamiczne, np. jan.kowalski@gmail.com]

[1.2] Projekt Google Cloud:
  [OK]  Aktywny projekt: [dane dynamiczne, np. bielik-warsztat-20260429-jk]

[1.3] Dostęp do projektu:
  [OK]  Projekt istnieje i jest dostępny (stan: ACTIVE)
  [OK]  Utworzony: [dane dynamiczne, np. 2026-04-29T10:15:00Z]

[1.4] Konto rozliczeniowe:
  [OK]  Billing aktywny: [dane dynamiczne, np. billingAccounts/0A1B2C-3D4E5F-6G7H8I]

[1.5] Repozytorium warsztatu:
  [OK]  Repozytorium sklonowane: [dane dynamiczne, np. /home/user/eskadra-bielik-misja2]
  [OK]  Remote: https://github.com/Legard777/eskadra-bielik-misja2.git

======================================================
 WYNIK: Wszystkie weryfikacje przeszły pomyślnie.

======================================================
  CHECKPOINT 1 ZALICZONY!
  Projekt Google Cloud
======================================================
  Punkty za ten krok : +5 pkt
  Lacznie            : 5 / 75 pkt
  Postep             : [##............................] 6%
======================================================
  Projekt skonfigurowany! Infrastruktura czeka na uruchomienie.
  Artefakt           : cert_artifacts/checkpoint_1.enc
======================================================
======================================================
```

</details>

## 2. Konfiguracja zmiennych środowiskowych i usług Google Cloud `~5 min`

<video src="https://github.com/user-attachments/assets/cbdfc7ed-948d-4812-bafc-4c9e5294ed12" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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

   > ℹ️ **Gemini CLI jest pre-zainstalowany w Cloud Shell** i uwierzytelnia się automatycznie Twoimi danymi Google. Przy pierwszym uruchomieniu może pojawić się prośba o akceptację warunków użytkowania — zatwierdź ją i kontynuuj. Komendę zamykającą Gemini CLI to `/quit`.

   > ```bash
   > gemini "Co robi ten skrypt @setup_env.sh? Wyjaśnij każdą zmienną środowiskową."
   > ```
   > W celu zamknięcia Gemini CLI wybierz komendę `/quit`.
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-setupenvsh) — Twoja może brzmieć zupełnie inaczej i to jest jak najbardziej w porządku. Modele językowe są niedeterministyczne: za każdym razem generują odpowiedź od nowa, dlatego dwie osoby zadające to samo pytanie mogą otrzymać różne, ale równie poprawne wyjaśnienia.

4. Uruchom skrypt `setup_env.sh`
   ```bash
   source setup_env.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o różnicę między `source` a `./`:
   > ```bash
   > gemini "Jaka jest różnica między source setup_env.sh a ./setup_env.sh w bashu? Kiedy używać każdej z form?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#dlaczego-source-a-nie-setupenvsh).

   > **Ważne**
   >Jeżeli z jakiegoś powodu musisz ponownie uruchomić terminal Cloud Shell, pamiętaj aby ponownie uruchomić skrypt `setup_env.sh` aby wczytać zmienne środowiskowe.

5. Włącz potrzebne usługi w projekcie Google Cloud
   ```bash
   gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com bigquery.googleapis.com
   ```

   > 💡 Podanie wielu usług w jednej komendzie to najlepsza praktyka — jedno wywołanie API zamiast czterech, wyraźnie szybsze. Możesz też włączać je osobno (`gcloud services enable run.googleapis.com`, itd.) — efekt jest identyczny, tylko wolniej.

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI dlaczego usługi są domyślnie wyłączone:
   > ```bash
   > gemini "Dlaczego usługi Google Cloud są domyślnie wyłączone? Wyjaśnij krótko każdą z włączanych usług: run, cloudbuild, artifactregistry, bigquery i co się stanie jeśli pominąć ten krok."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#komendy-gcloud-services-enable).

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
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#komenda-gcloud-projects-add-iam-policy-binding).

7. Zażądaj dostępu do bucketu z modelami Ollama

   Modele [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) są przechowywane w centralnym buckecie organizatora warsztatu. Aby je skopiować w kroku 3, musisz najpierw uzyskać dostęp — skrypt wysyła Twoje konto do systemu i czeka na potwierdzenie:
   ```bash
   ./skrypty/request_access.sh
   ```

   > ⚠️ 
   > Jeśli po 30 sekundach skrypt zgłosi brak dostępu — poinformuj prowadzącego. Bez dostępu do bucketu wykonanie kroku 3 nie będzie możliwe.

   > 💡 
   > Możesz ręcznie sprawdzić dostęp w dowolnym momencie:
   > ```bash
   > gcloud storage ls gs://$BUCKET_NAME_SOURCE
   > ```

8. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_2.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 2 — Konfiguracja zmiennych i usług Google Cloud
======================================================

[2.1] Wymagane usługi Google Cloud:
  [OK]  run.googleapis.com — włączona
  [OK]  cloudbuild.googleapis.com — włączona
  [OK]  artifactregistry.googleapis.com — włączona
  [OK]  bigquery.googleapis.com — włączona

[2.2] Uprawnienie roles/run.invoker:
  [OK]  Rola roles/run.invoker przypisana do [dane dynamiczne, np. jan.kowalski@gmail.com]

[2.3] Zmienne środowiskowe (setup_env.sh):
  [OK]  PROJECT_ID=[dane dynamiczne, np. bielik-warsztat-20260429-jk]
  [OK]  REGION=europe-west1
  [OK]  EMBEDDING_SERVICE=embedding-gemma
  [OK]  LLM_SERVICE=bielik
  [OK]  BIGQUERY_DATASET=rag_dataset
  [OK]  BIGQUERY_TABLE=hotel_rules

[2.4] Ochrona plików źródłowych (protect_files.sh):
  [OK]  orchestration/main.py — tylko do odczytu (chmod 444)
  [OK]  orchestration/static/index.html — tylko do odczytu (chmod 444)
  [OK]  vector_store/hotel_rules.csv — tylko do odczytu (chmod 444)

[2.5] Dostęp do bucketu źródłowego z modelami:
  [OK]  Dostęp do gs://warsztat-eskadra-bielika-modele potwierdzony (obiektów: [dane dynamiczne, np. 12])

======================================================
 WYNIK: Wszystkie weryfikacje przeszły pomyślnie.

======================================================
  CHECKPOINT 2 ZALICZONY!
  Konfiguracja usług i uprawnień
======================================================
  Punkty za ten krok : +10 pkt
  Lacznie            : 15 / 75 pkt
  Postep             : [######........................] 20%
======================================================
  Uslugi aktywne, uprawnienia ustawione. Czas na modele!
  Artefakt           : cert_artifacts/checkpoint_2.enc
======================================================
======================================================
```

</details>

## 3. Uruchomienie modeli LLM Bielik i EmbeddingGemma na [Cloud Run](https://cloud.google.com/run?hl=en) `~15 min`

<video src="https://github.com/user-attachments/assets/f99a57cd-ce05-433d-adf6-20b02587d3a2" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-ollama_modelssetup_modelssh).

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
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-ollama_docker_imagesetup_ollama_imagesh).

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
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-llmcloud_runsh).

3. Uruchom skrypt wdrażający model LLM->[Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) na [Cloud Run](https://cloud.google.com/run?hl=en) z silnikiem Ollama. Model zostanie pobrany z Google Cloud Storage
   ```bash
   ./cloud_run.sh
   ```

   > **🚫 Brak dostępnego GPU w wybranym regionie? Może tak być! GPU to cenny towar 🎰💎** Jeśli pojawi się błąd:
   > ```
   > ERROR: You do not have quota for using GPUs without zonal redundancy.
   > ```
   > Użyj awaryjnego skryptu bez GPU. Odpowiedzi modelu będą bardzo wolne (1–5 minut na prompt), ale warsztat można kontynuować:
   > ```bash
   > ./cloud_run_no_gpu.sh
   > ```

4. Sprawdź czy usługa `bielik` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

<!-- 
<details>
<summary>📸 Podgląd 06 — Usługa bielik w Cloud Run ze statusem Ready</summary>

![Screenshot 06 — Cloud Run lista usług z bielik Ready](assets/screenshot-06-cloud-run-bielik-ready.png)
> *Do uzupełnienia: widok listy usług Cloud Run w Google Cloud Console — usługa `bielik` z zielonym statusem "Ready" i adresem URL.*

</details>
-->

5. Przejrzyj zawartość pliku `llm_test1.sh` w tym katalogu
   ```bash
   cat llm_test1.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o autoryzację JWT w API:
   > ```bash
   > gemini "Co robi skrypt @llm/llm_test1.sh? Wyjaśnij jak działa token JWT w Google Cloud — skąd pochodzi, jak długo jest ważny i co się stanie gdy wyślę zapytanie bez nagłówka Authorization?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-llmllm_test1sh).

6. Zadaj pierwsze pytanie modelowi [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i sprawdź jego odpowiedź
   ```bash
   ./llm_test1.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — odpowiedź modelu Bielik (bez kontekstu RAG)</summary>

```text
======================================================
 Test modelu LLM Bielik
======================================================

 [1/3] Pobieranie adresu URL usługi 'bielik'...
       URL: [dane dynamiczne, np. https://bielik-abc123-ew.a.run.app]

 [2/3] Pobieranie tokenu autoryzacyjnego...
       Token pobrany pomyślnie.

 [3/3] Wysyłanie zapytania testowego do modelu Bielik...
       Pytanie: 'Jak często powinien być mierzony poziom chloru w basenie?'

 Odpowiedź:
{
  "odpowiedz": "Poziom chloru w basenie powinien być regularnie monitorowany. Standardowe zalecenia mówią o pomiarach co najmniej dwa razy dziennie — rano przed otwarciem i po południu. W przypadku intensywnego użytkowania lub wysokiej temperatury wody kontrole należy przeprowadzać częściej, nawet co kilka godzin. Prawidłowy poziom chloru wolnego wynosi zazwyczaj 0,5–1,5 mg/l.",
  "model": "SpeakLeash/bielik-4.5b-v3.0-instruct:Q8_0",
  "czas_ms": [dane dynamiczne, np. 9241]
}
```

> 💡 **Zwróć uwagę:** Bielik odpowiedział na podstawie ogólnej wiedzy o pływalniach. W kroku 6 zobaczysz jak ta sama odpowiedź wygląda z kontekstem RAG — bazując na konkretnej zasadzie hotelowej z BigQuery (reguła 12: pomiar **co równe trzy godziny**).

</details>

<!-- 
<details>
<summary>📸 Podgląd 07 — Przykładowa odpowiedź modelu Bielik</summary>

![Screenshot 07 — Terminal z odpowiedzią modelu Bielik](assets/screenshot-07-bielik-odpowiedz.png)
> *Do uzupełnienia: terminal pokazujący odpowiedź modelu Bielik na pierwsze testowe zapytanie — widoczny JSON z polem `response` zawierającym tekst po polsku.*

</details>
-->

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
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-embedding_modelcloud_runsh).

3. Uruchom skrypt wdrażający model EMBEDDING->Gemma na [Cloud Run](https://cloud.google.com/run?hl=en) z silnikiem Ollama. Model zostanie pobrany z Google Cloud Storage
   ```bash
   ./cloud_run.sh
   ```

4. Sprawdź czy usługa `embedding-gemma` pojawiła się w [Cloud Console → Cloud Run → Services](https://console.cloud.google.com/run) i ma status **Ready**

<!-- 
<details>
<summary>📸 Podgląd 08 — Usługa embedding-gemma w Cloud Run ze statusem Ready</summary>

![Screenshot 08 — Cloud Run lista usług z embedding-gemma Ready](assets/screenshot-08-cloud-run-embedding-ready.png)
> *Do uzupełnienia: widok listy usług Cloud Run — obie usługi `bielik` i `embedding-gemma` widoczne z zielonym statusem "Ready".*

</details>
-->

5. Przejrzyj zawartość pliku `embedding_model/embedding_test1.sh`
   ```bash
   cat embedding_test1.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o przestrzeń semantyczną:
   > ```bash
   > gemini "Co robi skrypt @embedding_model/embedding_test1.sh? Wyjaśnij czym jest przestrzeń wektorowa — jak 2048 liczb może wyrażać 'znaczenie' tekstu i dlaczego zdania o podobnym sensie dają wektory bliskie sobie geometrycznie?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-embedding_modelembedding_test1sh).

6. Wygeneruj pierwsze testowe embeddingi (wektory) dla przykładowego tekstu "Suwerenne AI po polsku — [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) i RAG w Google Cloud".
   ```bash
   ./embedding_test1.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — wektor z modelu EmbeddingGemma</summary>

```text
======================================================
 Test modelu EmbeddingGemma
======================================================

 [1/3] Pobieranie adresu URL usługi 'embedding-gemma'...
       URL: [dane dynamiczne, np. https://embedding-gemma-abc123-ew.a.run.app]

 [2/3] Pobieranie tokenu autoryzacyjnego...
       Token pobrany pomyślnie.

 [3/3] Wysyłanie tekstu testowego do modelu EmbeddingGemma...
       Tekst wejściowy: 'Suwerenne AI po polsku — Bielik i RAG w Google Cloud'
       Odpowiedź będzie tablicą liczb — wektorem reprezentującym znaczenie tekstu.

 Podsumowanie:
{
  "model": "embeddinggemma",
  "wymiary": 738,
  "czas_ms": [dane dynamiczne, np. 412],
  "pierwsze_5_wartosci": [
    [dane dynamiczne — np. 0.0234],
    [dane dynamiczne — np. -0.0891],
    [dane dynamiczne — np.  0.1142],
    [dane dynamiczne — np. -0.0567],
    [dane dynamiczne — np.  0.0823]
  ]
}

======================================================
 Pełny wektor (pierwsze 20 wartości):
======================================================
[
  [dane dynamiczne — 738 liczb zmiennoprzecinkowych reprezentujących
   znaczenie tekstu w przestrzeni semantycznej modelu EmbeddingGemma]
]

======================================================
 Wektor reprezentuje znaczenie tekstu
 'Suwerenne AI po polsku — Bielik i RAG w Google Cloud'
 w przestrzeni semantycznej modelu EmbeddingGemma.
======================================================
```

> 💡 **Kluczowy fakt:** wymiar wektora **738** jest stały dla modelu `embeddinggemma` — niezależnie od długości tekstu wejściowego odpowiedź zawsze ma dokładnie 738 liczb. Wartości liczbowe będą różne u każdego uczestnika tylko jeśli model zostanie wznowiony po zimnym starcie; dla identycznego tekstu i modelu są deterministyczne.

</details>

<!-- 
<details>
<summary>📸 Podgląd 09 — Przykładowy wektor embedding z modelu EmbeddingGemma</summary>

![Screenshot 09 — Terminal z fragmentem zwróconego wektora liczbowego](assets/screenshot-09-embedding-wektor.png)
> *Do uzupełnienia: terminal pokazujący odpowiedź modelu EmbeddingGemma — fragment tablicy liczb zmiennoprzecinkowych (embeddings) reprezentujących znaczenie tekstu.*

</details>
-->

7. Wróć do głównego katalogu projektu
   ```bash
   cd ..
   ```

8. Zalicz krok i zdobądź **+20 punktów** — oba modele wdrożone, to najtrudniejszy etap warsztatu:
   ```bash
   ./checkpoints/checkpoint_3.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 3 — Modele Bielik i EmbeddingGemma na Cloud Run
======================================================

[3.1] Usługa Cloud Run: bielik (model LLM)
  [OK]  Status: Ready
  [OK]  URL: [dane dynamiczne, np. https://bielik-abc123-ew.a.run.app]
  [OK]  Utworzono: [dane dynamiczne, np. 2026-04-29T10:45:00Z]
  [OK]  GPU: 1 × NVIDIA L4

[3.2] Usługa Cloud Run: embedding-gemma (model embeddingowy)
  [OK]  Status: Ready
  [OK]  URL: [dane dynamiczne, np. https://embedding-gemma-abc123-ew.a.run.app]
  [OK]  Utworzono: [dane dynamiczne, np. 2026-04-29T11:00:00Z]

[3.3] Test odpowiedzi modelu Bielik (ping):
  [OK]  Endpoint /api/tags odpowiada (HTTP 200)

[3.4] Test odpowiedzi modelu EmbeddingGemma (ping):
  [OK]  Endpoint /api/tags odpowiada (HTTP 200)

======================================================
 WYNIK: Oba modele wdrożone i gotowe.

======================================================
  CHECKPOINT 3 ZALICZONY!
  Modele Bielik + EmbeddingGemma na Cloud Run
======================================================
  Punkty za ten krok : +20 pkt
  Lacznie            : 35 / 75 pkt
  Postep             : [##############................] 46%
======================================================
  Oba modele dzialaja w chmurze. Najtrudniejszy krok za Toba!
  Artefakt           : cert_artifacts/checkpoint_3.enc
======================================================
======================================================
```

> ℹ️ Jeśli wdrożenie nastąpiło bez GPU (tryb awaryjny), linia `[OK]  GPU: 1 × NVIDIA L4` nie pojawi się — to normalne. Checkpoint przejdzie mimo braku tej linii.

</details>

## 4. Inicjalizacja wektorowej bazy danych w BigQuery `~5 min`

<video src="https://github.com/user-attachments/assets/41f2dc1a-ad88-4853-93b1-5b5de27a209a" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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

   > 📝 Celowo pomijamy tworzenie wirtualnego środowiska Python (`venv`). W warsztacie korzystamy z Cloud Shell, który jest tymczasowym środowiskiem uruchamianym od nowa po każdej sesji — instalacja globalna jest tu w zupełności wystarczająca. Wirtualne środowisko byłoby przydatne przy długotrwałym projekcie, gdzie chcemy izolować zależności między aplikacjami na tej samej maszynie.

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o zarządzanie zależnościami w Pythonie:
   > ```bash
   > gemini "Do czego służy biblioteka google-cloud-bigquery w Pythonie? Czym jest pip, jak działa instalacja zależności i dlaczego w Cloud Shell pomijamy wirtualne środowisko venv?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#pip-install-google-cloud-bigquery).

3. Przejrzyj kod skryptu inicjalizacyjnego
   ```bash
   cat init_db.py
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o projektowanie schematu dla Vector Search:
   > ```bash
   > gemini "Co robi skrypt @vector_store/init_db.py? Dlaczego kolumna embedding ma typ FLOAT64 REPEATED a nie JSON ani STRING — jak BigQuery Vector Search korzysta z tego konkretnego typu do wyszukiwania podobnych wektorów?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-vector_storeinit_dbpy).

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

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 4 — Wektorowa baza danych BigQuery
======================================================

[4.1] Dataset BigQuery: [dane dynamiczne, np. bielik-warsztat-20260429-jk]:rag_dataset
  [OK]  Dataset istnieje: rag_dataset
  [OK]  Lokalizacja: EU
  [OK]  Utworzono (ms epoch): [dane dynamiczne, np. 1746000000000]

[4.2] Tabela BigQuery: rag_dataset.hotel_rules
  [OK]  Tabela istnieje: hotel_rules
  [OK]  Schemat kolumn: id,content,embedding
  [OK]  Liczba wierszy: 0 (0 jest prawidłowe — dane załadujesz w kroku 6)
  [OK]  Utworzono (ms epoch): [dane dynamiczne, np. 1746000060000]

[4.3] Kolumna embedding (typ FLOAT64 REPEATED):
  [OK]  Kolumna embedding obecna: FLOAT64_REPEATED

======================================================
 WYNIK: Baza wektorowa zainicjalizowana poprawnie.

======================================================
  CHECKPOINT 4 ZALICZONY!
  Wektorowa baza danych BigQuery
======================================================
  Punkty za ten krok : +5 pkt
  Lacznie            : 40 / 75 pkt
  Postep             : [################..............] 53%
======================================================
  Baza wektorowa gotowa. Czas polaczyc wszystko w jedno API.
  Artefakt           : cert_artifacts/checkpoint_4.enc
======================================================
======================================================
```

</details>

## 5. Uruchomienie API (Orchestration) na [Cloud Run](https://cloud.google.com/run?hl=en) `~10 min`

<video src="https://github.com/user-attachments/assets/7d0b06cb-cf73-43a5-be40-9e8b9b4c340e" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

Aplikacja Orchestration to serce całego rozwiązania RAG — spina model embeddingowy, [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search) i model [Bielik](https://ollama.com/SpeakLeash/bielik-4.5b-v3.0-instruct) w jeden przepływ i udostępnia go przez API oraz interfejs Web UI.

1. Przejrzyj kod aplikacji FastAPI
   ```bash
   cat orchestration/main.py
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o architekturę systemu RAG:
   > ```bash
   > gemini "Co robi plik @orchestration/main.py? Policz ile linii liczy ten plik i wyjaśnij jak FastAPI pozwala zbudować pełny system RAG — embedding, Vector Search, LLM — w tak zwartym kodzie."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#plik-orchestrationmainpy).

2. Przejrzyj skrypt wdrożeniowy
   ```bash
   cat orchestration/cloud_run.sh
   ```

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o dobre praktyki konfiguracji aplikacji:
   > ```bash
   > gemini "Co robi skrypt @orchestration/cloud_run.sh? Wyjaśnij dlaczego adresy URL modeli są przekazywane przez zmienne środowiskowe a nie wpisane na stałe w kodzie — czym jest zasada twelve-factor app?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#skrypt-orchestrationcloud_runsh).

3. Przejdź do katalogu `orchestration`
   ```bash
   cd orchestration
   ```

4. Uruchom skrypt wdrażający aplikację na [Cloud Run](https://cloud.google.com/run?hl=en)
   ```bash
   ./cloud_run.sh
   ```

   > 🐳 W trakcie wdrożenia może pojawić się pytanie o utworzenie repozytorium Docker w Artifact Registry:
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

   > ⚠️ 
   > Zmienna `$ORCHESTRATION_URL` będzie potrzebna w kolejnych krokach do wysyłania zapytań przez `curl`. Jak wszystkie zmienne środowiskowe — działa tylko w bieżącym terminalu.

6. Wróć do głównego katalogu
   ```bash
   cd ..
   ```

7. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_5.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 5 — API Orchestration na Cloud Run
======================================================

[5.1] Usługa Cloud Run: orchestration-api
  [OK]  Status: Ready
  [OK]  URL: [dane dynamiczne, np. https://orchestration-api-abc123-ew.a.run.app]
  [OK]  Utworzono: [dane dynamiczne, np. 2026-04-29T11:30:00Z]
  [OK]  Ostatni deploy: [dane dynamiczne, np. 2026-04-29T11:32:00Z]

[5.2] Zmienne środowiskowe wdrożonej usługi:
  [OK]  LLM_URL skonfigurowany: [dane dynamiczne, np. https://bielik-abc123-ew.a.run.app]
  [OK]  EMBEDDING_URL skonfigurowany: [dane dynamiczne, np. https://embedding-gemma-abc123-ew.a.run.app]

[5.3] Dostępność Web UI (GET /):
  [OK]  Endpoint GET / odpowiada (HTTP 200)

[5.4] Zmienna ORCHESTRATION_URL w bieżącym terminalu:
  [OK]  ORCHESTRATION_URL=[dane dynamiczne, np. https://orchestration-api-abc123-ew.a.run.app]

======================================================
 WYNIK: API Orchestration wdrożone i dostępne.

======================================================
  CHECKPOINT 5 ZALICZONY!
  API Orchestration na Cloud Run
======================================================
  Punkty za ten krok : +10 pkt
  Lacznie            : 50 / 75 pkt
  Postep             : [####################..........] 66%
======================================================
  System RAG zlozony w calosci. Czas na prawdziwe testy!
  Artefakt           : cert_artifacts/checkpoint_5.enc
======================================================
======================================================
```

</details>

---

## 6. Testowanie API — Zasilanie i Wyszukiwanie (RAG) `~10 min`

<video src="https://github.com/user-attachments/assets/507b8e79-e72e-45b6-805f-50d63fb20bad" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

1. Przejrzyj plik z przykładowymi danymi
   ```bash
   ./vector_store/show_data.sh
   ```

   Plik CSV zawiera dwie kolumny:

   | Kolumna | Opis |
   |---|---|
   | `id` | Unikalny identyfikator rekordu |
   | `text` | Treść dokumentu — zasada hotelowa w języku naturalnym |

   > ⚠️ 
   > Po wgraniu danych przez endpoint `/ingest` aplikacja automatycznie doda trzecią kolumnę: **`embedding`** — wygenerowany przez [EmbeddingGemma](https://deepmind.google/models/gemma/embeddinggemma/) wektor liczbowy reprezentujący znaczenie tekstu. To właśnie ta kolumna umożliwia semantyczne wyszukiwanie w [BigQuery Vector Search](https://docs.cloud.google.com/bigquery/docs/vector-search).
   >
   > 📌 **Uwaga na nazwy kolumn:** kolumna CSV o nazwie `text` jest zapisywana w BigQuery pod nazwą **`content`** — tak zdefiniowany jest schemat tabeli. W podglądzie BigQuery zobaczysz kolumny `id`, `content` i `embedding` (nie `text`).

2. Wgraj przykładowe dane do [BigQuery](https://cloud.google.com/bigquery?hl=en) z pliku CSV
   ```bash
   curl -s -X POST "$ORCHESTRATION_URL/ingest" \
        -F "file=@vector_store/hotel_rules.csv" | jq .
   ```

<details>
<summary>▶️ Przykładowa odpowiedź — dane załadowane pomyślnie</summary>

```json
{
  "status": "success",
  "inserted_count": 19
}
```

> Liczba `19` odpowiada liczbie wierszy w pliku `hotel_rules.csv`. Jeśli uruchomisz `/ingest` ponownie na tym samym pliku, rekordy zostaną dodane ponownie — tabela BigQuery nie sprawdza duplikatów.

</details>

   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI jak działa wysyłanie pliku przez HTTP:
   > ```bash
   > gemini "Co robi ta komenda curl? Wyjaśnij czym jest multipart/form-data, czym różni się flaga -F od -d w curl i jak endpoint /ingest po stronie serwera odbiera i przetwarza przesłany plik CSV."
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#komenda-curl-ingest).

3. Zweryfikuj czy rekordy pojawiły się w [BigQuery](https://cloud.google.com/bigquery?hl=en)

   Otwórz [BigQuery w Google Cloud Console](https://console.cloud.google.com/bigquery), przejdź do tabeli `rag_dataset` → `hotel_rules` i kliknij przycisk **Preview** aby podejrzeć dane.

   > **🆓✨ Preview jest bezpłatny** — nie wykonuje zapytania SQL i nie zużywa limitu darmowych zapytań BigQuery. To najszybszy sposób sprawdzenia czy dane zostały załadowane poprawnie.

   > ⏳ 
   > Dane tekstowe w kolumnach `id`, `content` widoczne są natychmiast. Indeksowanie kolumny `embedding` na potrzeby Vector Search może chwilę potrwać — to normalne i nie blokuje kolejnych kroków.


   > **🔍 Dla chętnych — weryfikacja SQL:** jeśli chcesz zobaczyć dane zapytaniem, wklej w edytorze BigQuery:
   > ```sql
   > SELECT id, content, ARRAY_LENGTH(embedding) AS embedding_dimensions
   > FROM `rag_dataset.hotel_rules`
   > ORDER BY id
   > LIMIT 10
   > ```
   > Kolumna `embedding_dimensions` pokaże ile wymiarów ma wygenerowany wektor.

   > [!NOTE]
   > Wynik to **738** — stała właściwość modelu `embeddinggemma`, zakodowana w jego wagach. Aplikacja tej liczby nie konfiguruje ani nie skraca — po prostu przekazuje tablicę zwróconą przez model do BigQuery. Każdy model embeddingowy ma inny wymiar (np. modele BERT-base: 768, modele large: 1024, niektóre nowe: 2048+). Wyższy wymiar nie zawsze oznacza lepszą jakość — liczy się architektura i dane treningowe modelu.

   > **🧌 Dla Smerfa Marudy — czy da się zmienić wymiar wektora?**
   >
   > Tak, ale wymaga zamiany modelu embeddingowego na inny (np. `nomic-embed-text` → 768 wymiarów). BigQuery **nie wymaga** zmiany schematu tabeli — `FLOAT64 REPEATED` przyjmuje tablicę dowolnej długości — ale wszystkie rekordy w tabeli muszą mieć wektory tego samego wymiaru, bo inaczej `VECTOR_SEARCH` porównuje jabłka z pomarańczami. Zmiana modelu wymaga więc: zamiany modelu w `embedding_model/`, wyczyszczenia tabeli BigQuery i ponownego przejścia przez kroki 4–6.

4. Wykonaj testowe zapytania RAG

   Pytanie o częstotliwość pomiaru chloru w basenie:
   ```bash
   curl -s -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "Jak często powinien być mierzony poziom chloru w basenie?"}' | jq .
   ```

<details>
<summary>▶️ Przykładowa odpowiedź RAG — chlor w basenie</summary>

```json
{
  "answer": "Zgodnie z regulaminem hotelowym, poziom chloru w basenie powinien być mierzony co równe trzy godziny. Pomiarów dokonuje ratownik, który jednocześnie kontroluje temperaturę wody.",
  "context_used": [
    "Ratownik musi dokonywać pomiaru chloru i temperatury wody w basenie co równe trzy godziny.",
    "Basen oraz strefa saun są dostępne dla gości bez dodatkowych opłat w godzinach od 8:00 do 22:00.",
    "W strefie saun obowiązuje bezwzględny zakaz używania telefonów komórkowych przez personel i gości."
  ],
  "context_ids": [
    "3",
    "6",
    "8"
  ],
  "context_scores": [
    89.2,
    63.4,
    58.1
  ],
  "confidence": 70.2
}
```

> 💡 Porównaj z odpowiedzią Bielika bez RAG z kroku 3 — tam model odpowiedział ogólnikowo (co kilka godzin). Tutaj RAG znalazł w BigQuery konkretną zasadę hotelową i podał dokładną wartość: **co równe trzy godziny**.

</details>

   Pytanie o godzinę podawania śniadania:
   ```bash
   curl -s -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "O której godzinie jest podawane śniadanie?"}' | jq .
   ```

<details>
<summary>▶️ Przykładowa odpowiedź RAG — godziny śniadania</summary>

```json
{
  "answer": "Śniadanie w hotelu podawane jest codziennie w restauracji znajdującej się na parterze. Można z niego skorzystać w godzinach od 7:00 do 10:00.",
  "context_used": [
    "Śniadanie podawane jest codziennie w restauracji na parterze w godzinach od 7:00 do 10:00.",
    "Codzienne sprzątanie pokoi odbywa się w godzinach od 9:00 do 14:00 na życzenie gościa potwierdzone wywieszką na klamce.",
    "Całodobowa recepcja jest do dyspozycji gości w celu zgłaszania wszelkich usterek oraz potrzeb."
  ],
  "context_ids": [
    "2",
    "9",
    "4"
  ],
  "context_scores": [
    92.1,
    61.5,
    54.3
  ],
  "confidence": 69.3
}
```

</details>

   Pytanie o parking:
   ```bash
   curl -s -X POST "$ORCHESTRATION_URL/ask" \
        -H "Content-Type: application/json" \
        -d '{"query": "Ile kosztuje parking hotelowy?"}' | jq .
   ```

<details>
<summary>▶️ Przykładowa odpowiedź RAG — koszt parkingu</summary>

```json
{
  "answer": "Parking hotelowy kosztuje 40 PLN za dzień.",
  "context_used": [
    "Własny parking przed hotelem jest płatny 40 PLN za dzień i nie wymaga wcześniejszej rezerwacji.",
    "Własny parking przed hotelem jest płatny 40 PLN za dzień i nie wymaga wcześniejszej rezerwacji.",
    "Szybkie WiFi jest darmowe i dostępne w całym hotelu pod nazwą sieci Hotel_Guest."
  ],
  "context_ids": [
    "5",
    "5",
    "7"
  ],
  "context_scores": [
    81.0,
    81.0,
    55.7
  ],
  "confidence": 72.6
}
```

</details>

   > **🔍 Dla chętnych — VECTOR_SEARCH bezpośrednio w BigQuery:** chcesz zobaczyć jak wygląda wyszukiwanie wektorowe od środka? Wykonaj je samodzielnie w dwóch krokach.
   >
   > **Krok 1** — pobierz wektor zapytania przez curl:
   >
   > Najpierw pobierz i zapisz adres URL usługi embedding:
   > ```bash
   > export EMBEDDING_URL=$(gcloud run services describe embedding-gemma --region $REGION --format="value(status.url)")
   > ```
   > Następnie wyślij zapytanie:
   > ```bash
   > curl -s -X POST "$EMBEDDING_URL/api/embed" \
   >   -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
   >   -H "Content-Type: application/json" \
   >   -d '{"model": "embeddinggemma", "input": "Jak często mierzyć chlor?"}' | jq '{model: .model, wymiary: (.embeddings[0] | length), wektor: .embeddings[0]}'
   > ```
   > Skopiuj tablicę liczb z pola `wektor` w odpowiedzi powyżej.
   >
   > **Krok 2** — wklej wektor do edytora [BigQuery](https://console.cloud.google.com/bigquery) i uruchom zapytanie:
   > ```sql
   > SELECT base.id, base.content, distance
   > FROM VECTOR_SEARCH(
   >   TABLE `rag_dataset.hotel_rules`,
   >   'embedding',
   >   (SELECT [0.123, -0.456, 0.789, /* ... wklej tutaj swój wektor ... */] AS embedding),
   >   top_k => 3,
   >   distance_type => 'COSINE'
   > )
   > ORDER BY distance ASC
   > ```
   > Kolumna `distance` to odległość kosinusowa (0 = identyczny, 1 = ortogonalny) — im mniejsza, tym lepiej dopasowany dokument. Dokładnie to samo robi `orchestration-api` za kulisami przy każdym zapytaniu `/ask`.


   > **🤖 Zadanie dla Gemini CLI** — zapytaj AI o mechanizm RAG od środka:
   > ```bash
   > gemini "Prześledź krok po kroku co dzieje się w systemie gdy wysyłam zapytanie do endpointu /ask: od wektora zapytania, przez VECTOR_SEARCH w BigQuery, aż do odpowiedzi Bielika. Ile żądań HTTP wykonuje orchestration-api w tle obsługując jedno pytanie użytkownika?"
   > ```
   > Porównaj swoją odpowiedź z [opisem referencyjnym](skrypty/script_descriptions.md#komenda-curl-ask).


5. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_6.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 6 — Zasilanie bazy i zapytania RAG
======================================================

[6.1] Dane w BigQuery (po /ingest):
  [OK]  Liczba rekordów w tabeli hotel_rules: 19

[6.2] Wektory embedding w tabeli:
  [OK]  Wiersze z wektorem: 19 / 19
  [OK]  Wymiarowość wektora: 738

[6.3] Endpoint POST /ask (test dostępności — max 60s):
  [OK]  Endpoint /ask odpowiada (HTTP 200)

======================================================
 WYNIK: Dane załadowane, wektory wygenerowane, API dostępne.

======================================================
  CHECKPOINT 6 ZALICZONY!
  Zasilanie bazy i zapytania RAG
======================================================
  Punkty za ten krok : +10 pkt
  Lacznie            : 60 / 75 pkt
  Postep             : [########################......] 80%
======================================================
  Wyszukiwanie semantyczne dziala. Jeden krok do mety!
  Artefakt           : cert_artifacts/checkpoint_6.enc
======================================================
======================================================
```

> ℹ️ Jeśli model Bielik jest na zimnym starcie, weryfikacja [6.3] może pokazać `[--] Endpoint /ask — timeout po 60s` zamiast `[OK]`. To akceptowalne — checkpoint i tak zostanie zaliczony.

</details>

## 7. Przegląd API i architektury kodu `~10 min`

<video src="https://github.com/user-attachments/assets/5fb575ad-a61a-437d-8ab0-dcc0989e9ac3" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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
<summary>📸 Podgląd - Swagger UI z dokumentacją API</summary>

![Przeglądarka z interfejsem Swagger UI /docs](assets/Krok_7-swagger_ui_docs_view.jpg)

</details>

Zalicz krok i zdobądź **+5 punktów** — uruchom skrypt weryfikacyjny, który potwierdzi że wszystkie usługi działają razem:

```bash
./checkpoints/checkpoint_7.sh
```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 7 — Przegląd API: wszystkie usługi działają
======================================================

[7.1] Stan wszystkich usług Cloud Run warsztatu:
  [OK]  bielik: Ready
         URL:     [dane dynamiczne, np. https://bielik-abc123-ew.a.run.app]
         Deploy:  [dane dynamiczne, np. 2026-04-29T10:45:00Z]

  [OK]  embedding-gemma: Ready
         URL:     [dane dynamiczne, np. https://embedding-gemma-abc123-ew.a.run.app]
         Deploy:  [dane dynamiczne, np. 2026-04-29T11:00:00Z]

  [OK]  orchestration-api: Ready
         URL:     [dane dynamiczne, np. https://orchestration-api-abc123-ew.a.run.app]
         Deploy:  [dane dynamiczne, np. 2026-04-29T11:32:00Z]

[7.2] Weryfikacja endpointów API:
  [OK]  GET / → HTTP 200
  [OK]  GET /docs → HTTP 200
  [OK]  GET /records → HTTP 200

======================================================
 WYNIK: Wszystkie 3 usługi Cloud Run działają poprawnie.

======================================================
  CHECKPOINT 7 ZALICZONY!
  Przegląd API i architektury
======================================================
  Punkty za ten krok : +5 pkt
  Lacznie            : 65 / 75 pkt
  Postep             : [##########################....] 86%
======================================================
  Architektura przejrzana i zrozumiana. Ostatni krok!
  Artefakt           : cert_artifacts/checkpoint_7.enc
======================================================
======================================================
```

</details>

## 8. Interfejs Użytkownika (Web UI) `~20 min`

<video src="https://github.com/user-attachments/assets/5b7f87a2-5a9b-491d-acc8-b7f02e44bffa" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

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
<summary>📸 Podgląd - Web UI z porównaniem odpowiedzi RAG vs bez RAG</summary>

![Interfejs Web UI z dwoma kolumnami odpowiedzi](assets/Krok_8-web_ui_original_code.jpg)

</details>

4. Zalicz krok i zdobądź **+10 punktów** — uruchom skrypt weryfikacyjny:
   ```bash
   ./checkpoints/checkpoint_8.sh
   ```

<details>
<summary>▶️ Przykładowe wyjście — checkpoint zaliczony</summary>

```text
======================================================
 CHECKPOINT 8 — Interfejs Web UI (RAG vs. bez RAG)
======================================================

[8.1] Dostępność Web UI:
  [OK]  Web UI dostępny pod: [dane dynamiczne, np. https://orchestration-api-abc123-ew.a.run.app]
  [OK]  HTTP status: 200

[8.2] Endpoint /ask_direct (model bez RAG — max 60s):
  [OK]  Endpoint /ask_direct dostępny (HTTP 200)

[8.3] Endpoint /ask (model z RAG — max 60s):
  [OK]  Endpoint /ask dostępny (HTTP 200)

[8.4] Dokumentacja API (FastAPI /docs):
  [OK]  Dokumentacja /docs dostępna (HTTP 200)

======================================================
 WYNIK: Web UI dostępny, oba tryby (RAG i bez RAG) aktywne.

======================================================
  CHECKPOINT 8 ZALICZONY!
  Interfejs Web UI
======================================================
  Punkty za ten krok : +10 pkt
  Lacznie            : 75 / 75 pkt
  Postep             : [##############################] 100%
======================================================
  WARSZTAT UKONCZONY! Wygeneruj certyfikat i pochwal sie wynikiem.
  Artefakt           : cert_artifacts/checkpoint_8.enc
======================================================
======================================================
```

> ℹ️ Wejścia [8.2] i [8.3] mogą pokazać `[--] timeout po 60s` jeśli Bielik jest na zimnym starcie — checkpoint przejdzie mimo to. Błąd pojawi się tylko przy HTTP 4xx/5xx.

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

<details>
<summary>📸 Podgląd — Web UI w trybie dark mode</summary>

![Web UI w trybie dark mode](assets/Krok_8-web_ui_dark_mode.jpg)

</details>

>    Lub spróbuj innego stylu:
>    ```bash
>    gemini "Zmodyfikuj plik @orchestration/static/index.html nadając mu wygląd retro-terminala (zielony tekst na czarnym tle, czcionka monospace). Zachowaj całą funkcjonalność."
>    ```

<details>
<summary>📸 Podgląd — Web UI w stylu retro-terminala</summary>

![Web UI w stylu retro-terminala](assets/Krok_8-web_ui_terminal_mode.jpg)

</details>

> 3. Przejrzyj zmiany w edytorze Cloud Shell:
>    ```bash
>    cloudshell edit orchestration/static/index.html
>    ```
> 4. Aby zobaczyć zmiany na żywo — wdróż ponownie aplikację (tak samo jak w kroku 5):
>    ```bash
>    cd orchestration && ./cloud_run.sh && cd ..
>    ```
>    Po zakończeniu wdrożenia odśwież stronę w przeglądarce.

## 9. Certyfikat ukończenia warsztatu `~10 min`

<video src="https://github.com/user-attachments/assets/ebc7ba37-28a9-458e-9d9f-5de22e621b9c" controls width="720" muted preload="auto" poster="assets/videos/eskadra-bielika-misja2-video.jpg"></video>

Gratulacje — warsztat dobiegł końca! Wygeneruj zaszyfrowany certyfikat zawierający wszystkie 8 checkpointów i prześlij go prowadzącemu.

> [!IMPORTANT]
> Przed wygenerowaniem certyfikatu upewnij się, że wszystkie 8 checkpointów zostało wykonanych (pliki `cert_artifacts/checkpoint_N.enc` muszą istnieć). Skrypt sam to weryfikuje i zgłosi brakujące kroki.

```bash
./checkpoints/certyfikat_generate.sh
```

<details>
<summary>▶️ Przykładowe wyjście — certyfikat wygenerowany pomyślnie</summary>

```text
======================================================
 CERTYFIKAT UKOŃCZENIA — Eskadra Bielik Misja 2
 RAG w oparciu o model Bielik i Google Cloud
======================================================

Weryfikacja checkpointów:
  [OK]  Checkpoint 1 — obecny ([dane dynamiczne, np. 512] bajtów, zapisany: [dane dynamiczne, np. 2026-04-29T10:20:00Z])
  [OK]  Checkpoint 2 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 3 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 4 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 5 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 6 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 7 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])
  [OK]  Checkpoint 8 — obecny ([dane dynamiczne] bajtów, zapisany: [dane dynamiczne])

Końcowy stan usług Cloud Run:
  [OK]  bielik: Ready — [dane dynamiczne, np. https://bielik-abc123-ew.a.run.app]
  [OK]  embedding-gemma: Ready — [dane dynamiczne, np. https://embedding-gemma-abc123-ew.a.run.app]
  [OK]  orchestration-api: Ready — [dane dynamiczne, np. https://orchestration-api-abc123-ew.a.run.app]

Sumy kontrolne artefaktów:
  checkpoint_1: [dane dynamiczne — pierwsze 16 znaków SHA256]...
  checkpoint_2: [dane dynamiczne]...
  checkpoint_3: [dane dynamiczne]...
  checkpoint_4: [dane dynamiczne]...
  checkpoint_5: [dane dynamiczne]...
  checkpoint_6: [dane dynamiczne]...
  checkpoint_7: [dane dynamiczne]...
  checkpoint_8: [dane dynamiczne]...

======================================================
 Generowanie zaszyfrowanego certyfikatu...

======================================================
  *** WARSZTAT ESKADRA BIELIK - MISJA 2 ***
  *** UKONCZONY POMYSLNIE! ***
======================================================

  Uczestnik : [dane dynamiczne, np. jan.kowalski@gmail.com]
  Projekt   : [dane dynamiczne, np. bielik-warsztat-20260429-jk]
  Czas      : [dane dynamiczne, np. 2026-04-29T13:45:00Z]

  Wynik: 75 / 75 pkt
  [##############################] 100%

  Checkpointy zaliczone: 8 / 8
  [OK]  Krok 1  + 5 pkt  Projekt Google Cloud
  [OK]  Krok 2  +10 pkt  Konfiguracja usług i uprawnień
  [OK]  Krok 3  +20 pkt  Modele Bielik + EmbeddingGemma na Cloud Run
  [OK]  Krok 4  + 5 pkt  Wektorowa baza danych BigQuery
  [OK]  Krok 5  +10 pkt  API Orchestration na Cloud Run
  [OK]  Krok 6  +10 pkt  Zasilanie bazy i zapytania RAG
  [OK]  Krok 7  + 5 pkt  Przegląd API i architektury
  [OK]  Krok 8  +10 pkt  Interfejs Web UI

======================================================
  Pobierz certyfikat na swoj komputer:
  cloudshell dl cert_artifacts/checkpoint_certyfikat.enc

  Nastepnie wyslij plik prowadzacemu.
======================================================
```

</details>

Po pomyślnym wykonaniu pobierz plik certyfikatu na swój komputer za pomocą wbudowanej komendy Cloud Shell:

```bash
cloudshell dl cert_artifacts/checkpoint_certyfikat.enc
```

> [!TIP]
> Komenda `cloudshell dl` automatycznie pobiera plik do folderu Pobrane na Twoim lokalnym komputerze. Plik jest zaszyfrowany i zawiera potwierdzenie wykonania wszystkich etapów warsztatu powiązane z Twoim kontem Google Cloud i projektem — możesz go przesłać prowadzącemu przez dowolny kanał (email, Slack, formularz).

Wyślij pobrany plik `checkpoint_certyfikat.enc` prowadzącemu.

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
   ./skrypty/cleanup_minimal.sh
   ```

2. *(Opcjonalnie)* Zabezpiecz publiczny endpoint orchestration-api przed nieautoryzowanym dostępem:
   ```bash
   gcloud run services update orchestration-api \
     --region $REGION \
     --no-allow-unauthenticated
   ```
   > 🔐 
   > Po tej zmianie dostęp do Web UI i API będzie wymagał tokenu autoryzacyjnego Google. Aby wygenerować token: `gcloud auth print-identity-token`

3. Zweryfikuj usunięcie repozytoriów:
   - **Artifact Registry:** [console.cloud.google.com/artifacts](https://console.cloud.google.com/artifacts)

### Opcja B — Pełne czyszczenie: usuń wszystko

Jeśli chcesz mieć 100% pewności braku kosztów lub zamierzasz zakończyć pracę z projektem, usuń wszystkie zasoby. Możesz je odtworzyć od nowa powtarzając kroki warsztatu.

> [!CAUTION]
> Ta operacja jest nieodwracalna. Wszystkie dane w [BigQuery](https://cloud.google.com/bigquery?hl=en), wdrożone modele i usługi zostaną trwale usunięte.

1. Wróć do głównego katalogu projektu i uruchom pełny skrypt czyszczący:
   ```bash
   ./skrypty/cleanup.sh
   ```

2. Skrypt wyświetli listę zasobów do usunięcia i poprosi o potwierdzenie. Wpisz `tak` aby kontynuować.

3. Po zakończeniu zweryfikuj w Google Cloud Console, że zasoby zostały usunięte:
   - **Cloud Run:** [console.cloud.google.com/run](https://console.cloud.google.com/run)
   - **BigQuery:** [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)
   - **Artifact Registry:** [console.cloud.google.com/artifacts](https://console.cloud.google.com/artifacts)
   - **Cloud Storage:** [console.cloud.google.com/storage](https://console.cloud.google.com/storage)

## 11. Lunch i networking `~60 min`

Właśnie zbudowałeś działający system RAG oparty na polskim modelu językowym i Google Cloud. Czas na jedzenie i rozmowę z innymi uczestnikami.

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
>Usługi [Cloud Run](https://cloud.google.com/run?hl=en) automatycznie skalują do zera gdy nikt ich nie odpytuje — po zakończeniu warsztatu nie naliczają kosztów. Jedynym stałym kosztem są repozytoria Artifact Registry (~$0.01/mies.). Uruchom skrypt `cleanup_minimal.sh` jeśli chcesz je usunąć, lub `cleanup.sh` aby usunąć wszystkie zasoby.

### Optymalizacje dla środowisk produkcyjnych [Cloud Run](https://cloud.google.com/run?hl=en)

Konfiguracja użyta w tym warsztacie jest celowo uproszczona. Dla zastosowań produkcyjnych Google [Cloud Run](https://cloud.google.com/run?hl=en) dokumentuje szereg optymalizacji - szczegóły: [Cloud Run GPU Best Practices](https://docs.cloud.google.com/run/docs/configuring/services/gpu-best-practices)

---

## FAQ

<details>
<summary>▶️ Nagranie — Zmiana języka z Polskiego na Angielski w Google Cloud Platform</summary>

<a href="https://youtu.be/SfFSuInW_RE" target="_blank">
  <img src="https://img.youtube.com/vi/SfFSuInW_RE/0.jpg" alt="Zmiana języka z Polskiego na Angielski w Google Cloud Platform" width="480">
</a>

</details>

<details>
<summary>▶️ Nagranie — Zmiana wyglądu z "light" na "dark" w Google Cloud Platform</summary>

<a href="https://youtu.be/iOqdKGNks7Y" target="_blank">
  <img src="https://img.youtube.com/vi/iOqdKGNks7Y/0.jpg" alt="Zmiana wyglądu z light na dark w Google Cloud Platform" width="480">
</a>

</details>

### Co zrobić jeśli Cloud Shell się rozłączy?

Cloud Shell automatycznie rozłącza się po kilku minutach bezczynności. Może się to zdarzyć podczas warsztatu — szczególnie przy słabszym połączeniu Wi-Fi. Rozłączenie usuwa wszystkie zmienne środowiskowe z pamięci sesji, ale **nie usuwa plików ani wdrożonych usług Google Cloud**.

Aby wznowić pracę, wykonaj poniższe trzy komendy:

1. Przejdź do katalogu projektu
   ```bash
   cd eskadra-bielik-misja2
   ```

2. Załaduj zmienne środowiskowe
   ```bash
   source setup_env.sh
   ```

3. Odtwórz adres URL usługi Orchestration API
   ```bash
   export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
   ```

Po wykonaniu tych kroków możesz kontynuować od miejsca, w którym nastąpiło rozłączenie.

### Co zrobić jeśli pojawia się błąd braku GPU quota?

Jeśli podczas uruchamiania modelu Bielik pojawia się komunikat:
```
ERROR: You do not have quota for using GPUs without zonal redundancy.
```

Użyj awaryjnego skryptu bez GPU — jest w tym samym katalogu `llm/`:
```bash
./cloud_run_no_gpu.sh
```

Odpowiedzi modelu będą wolniejsze (1–5 minut na prompt), ale warsztat można w pełni kontynuować. Poinformuj prowadzącego — może odblokować quota na Twoim projekcie.

### Co zrobić jeśli skrypt checkpoint nie przechodzi?

Sprawdź kolejno:

1. Czy jesteś w głównym katalogu projektu (`eskadra-bielik-misja2`)?
   ```bash
   pwd
   ```
2. Czy zmienne środowiskowe są załadowane?
   ```bash
   echo $PROJECT_ID
   ```
   Jeśli puste — uruchom `source setup_env.sh`.
3. Czy wszystkie wymagane usługi Cloud Run mają status **Ready** w [Cloud Console → Cloud Run](https://console.cloud.google.com/run)?
4. Jeśli checkpoint nadal nie przechodzi — poinformuj prowadzącego i podaj treść komunikatu błędu.

### Co zrobić jeśli `curl` zwraca błąd lub pustą odpowiedź?

Najpierw sprawdź czy zmienna `$ORCHESTRATION_URL` jest ustawiona:
```bash
echo $ORCHESTRATION_URL
```
Jeśli jest pusta — ustaw ją ponownie:
```bash
export ORCHESTRATION_URL=$(gcloud run services describe orchestration-api --region $REGION --format="value(status.url)")
```

---

## Licencja

Projekt jest udostępniony na licencji **Apache License 2.0** — szczegółowy tekst znajdziesz w pliku [LICENSE](LICENSE).

### Czym Apache 2.0 różni się od innych popularnych licencji?

| Licencja | Użycie komercyjne | Modyfikacje | Patent | Copyleft |
|---|---|---|---|---|
| **Apache 2.0** | tak | tak (z informacją o zmianach) | jawna ochrona patentowa | brak |
| MIT | tak | tak | brak ochrony | brak |
| GPL v3 | tak | tak, ale kod pochodny musi być GPL | jawna ochrona | silny |
| BSD 2-Clause | tak | tak | brak ochrony | brak |

**Co to oznacza w praktyce?**

- **Możesz** używać, kopiować, modyfikować i dystrybuować kod — również komercyjnie.
- **Musisz** zachować informację o oryginalnej licencji i autorach oraz oznaczyć pliki, które zmodyfikowałeś.
- **Dostajesz** jawną ochronę patentową od każdego współtwórcy — jeśli ktoś wniósł kod, nie może Cię później pozwać za naruszenie swojego patentu związanego z tym kodem.
- **Nie musisz** udostępniać kodu pochodnego na tej samej licencji (w odróżnieniu od GPL).
Jeśli zmienna jest ustawiona, a curl nadal zwraca błąd `403` — sprawdź czy masz nadane uprawnienie `roles/run.invoker` (krok 2.6).
