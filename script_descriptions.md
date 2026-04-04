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

## Komenda `gcloud projects add-iam-policy-binding`

Komenda nadaje Twojemu kontu uprawnienia do wywoływania usług Cloud Run. Oto co robią poszczególne elementy:

- **`add-iam-policy-binding $PROJECT_ID`** — dopisuje nową regułę do polityki dostępu (IAM) Twojego projektu.
- **`--member=user:$(gcloud config get-value account)`** — automatycznie pobiera adres e-mail aktualnie zalogowanego użytkownika, dzięki czemu nie musisz wpisywać go ręcznie.
- **`--role='roles/run.invoker'`** — nadaje rolę Cloud Run Invoker, niezbędną do wysyłania zapytań (np. przez `curl` lub przeglądarkę) do modeli i API wdrożonych na Cloud Run.

W Google Cloud obowiązuje zasada najmniejszych uprawnień — nawet właściciel projektu musi jawnie przypisać tę rolę, aby komunikacja między komponentami przebiegała poprawnie.
