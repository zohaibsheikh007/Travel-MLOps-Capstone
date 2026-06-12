# Submission Checklist

Print this. Tick each box. Hand in.

## A. The three Colab notebooks

| File | Where to find it | Status |
|------|------------------|--------|
| `Flight_Price_Prediction.ipynb` | `Flight Prediction/` | Done — has project summary + repo link at top |
| `Gender_Classification_Model.ipynb` | `Gender/` | Done — has project summary + repo link at top |
| `Hotel_Recommendation_Model.ipynb` | `Hotel/` | Done — has project summary + repo link at top |

What to do:
1. Upload each notebook to your **Google Drive**.
2. Right-click -> Share -> "Anyone with the link" -> **Viewer**.
3. Open each one with **Google Colab** so the share link is the Colab URL.
4. Paste the three Colab links in the submission form.

---

## B. The single GitHub repository

Has to contain:

- [x] All three notebooks (already in the repo)
- [x] Pickle / joblib artefacts (`Flight Prediction/random_forest.pkl`, `Gender/gender_model.pkl`, `Gender/company_encoder.pkl`)
- [x] Flask app (`Flight Prediction/Flight_Price.py`)
- [x] Streamlit apps (`Gender/gender_app.py`, `Hotel/hotel.py`)
- [x] `Dockerfile`s (Flight Prediction + Airflow stack)
- [x] `requirements.txt` per component
- [x] Kubernetes `deployment.yaml` and `service.yaml`
- [x] Airflow DAG file (`flight_prediction_dag.py`) and utils
- [x] MLflow code (logged inside `train_model.py` and `model_training.py`)
- [x] CI/CD config (`Jenkinsfile`, `.github/workflows/deploy.yml`)
- [x] Unit tests (`Flight Prediction/tests/`)
- [x] Comprehensive `README.md`

What to do:
1. Run `scripts/push-to-github.ps1` (instructions below).
2. Once the repo is on GitHub, paste the URL in the submission Drive folder.

---

## C. The Google Doc workflow documentation

Source: `DOCUMENTATION.md` in this repo.

What to do:
1. Open Google Docs -> blank document.
2. Title it `TravelWise — MLOps Workflow Documentation`.
3. Copy each section from `DOCUMENTATION.md` into the doc, in order:
   - REST API
   - Streamlit Apps
   - Docker
   - Kubernetes
   - Airflow
   - CI/CD
   - MLflow
4. For each section, drag in the screenshots listed at the bottom of that section in `DOCUMENTATION.md`. Run the matching demo command (Flask, Streamlit, Docker, Kubernetes, Airflow, MLflow, GitHub Actions) and capture the screens.
5. Share -> "Anyone with the link" -> **Viewer**.
6. Drop the link in your Drive submission folder.

> The brief explicitly says **do not** include installation steps. `DOCUMENTATION.md` is already written that way.

---

## D. Video presentation (>= 15 min, ideally 40 min)

Source: `VIDEO_SCRIPT.md`.

What to do:
1. Open OBS Studio (or Loom, or Google Meet record-yourself).
2. Pre-load the tabs listed at the top of `VIDEO_SCRIPT.md`.
3. Read sections 1 -> 8 with the matching screen shared.
4. Upload the recording to Google Drive (or YouTube unlisted).
5. Make it public-viewable.
6. Paste the link under "Video link" in the submission dashboard.

---

## E. Final share

| Submission slot | What goes there |
|-----------------|-----------------|
| Project link    | Drive folder containing 3 Colab notebooks + the workflow Google Doc + repo URL |
| Video link      | Drive / YouTube unlisted URL of the presentation |

Make sure the **Drive folder is shared** (Anyone with the link, Viewer). The classroom evaluator must be able to open everything without requesting access.

---

## Push to GitHub — one command

Open PowerShell and run:

```powershell
cd d:\dev\Masters\Travel-MLOps-Capstone
.\scripts\push-to-github.ps1
```

The script will:
1. Run `gh auth login` if you aren't logged in.
2. Create the GitHub repo `zohaibsheikh007/Travel-MLOps-Capstone` (public).
3. Push every commit.

If `gh` is not installed, use the manual fallback in `scripts/push-to-github.ps1` — it tells you exactly what to do.

---

## Cross-check against the brief

### Project description coverage

- [x] Regression model for flight price (`Flight Prediction/train_model.py`)
- [x] Flask REST API (`Flight Prediction/Flight_Price.py`)
- [x] Docker (`Flight Prediction/Dockerfile`)
- [x] Kubernetes (`Flight Prediction/deployment.yaml`, `service.yaml`)
- [x] Airflow DAG (`Flight Prediction/airflow-docker/dags/flight_prediction_dag.py`)
- [x] CI/CD (Jenkinsfile + GitHub Actions)
- [x] MLflow (logged in `train_model.py` + Airflow task)
- [x] Gender classification (`Gender/`)
- [x] Hotel recommendation + Streamlit (`Hotel/`)

### Evaluation criteria mapping (1-6)

| Criterion | Weight | Where it lives |
|-----------|-------:|----------------|
| 1. Technical accuracy | 40% | All training scripts + tests + leaderboard.csv + working API/DAG/CI |
| 2. Code quality + docs | 15% | Type hints, docstrings, READMEs in every folder, unit tests |
| 3. GitHub structure + commits | 10% | Folder layout mirrors the brief; commit history is incremental |
| 4. Model performance | 5% | 4-model leaderboard with RMSE/MAE/R²; CV; feature importance |
| 5. MLOps integration | 10% | DAG triggers training, MLflow logs every run, CI updates K8s |
| 6. Presentation | 20% | `VIDEO_SCRIPT.md` + `DOCUMENTATION.md` cover this |
