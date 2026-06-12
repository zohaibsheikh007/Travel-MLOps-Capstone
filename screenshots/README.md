# Screenshots

Save your demo screenshots in the matching subfolder. The Google Doc renders
the sections in this order, so name the files with the prefix shown.

| Folder | What to save here | Demo command |
|--------|-------------------|--------------|
| `01-rest-api/` | Flask form, prediction success, `/health` JSON, `pytest 6 passed` | `cd "Flight Prediction"; python Flight_Price.py` |
| `02-streamlit-gender/` | Gender app full page with a sample prediction | `cd Gender; streamlit run gender_app.py --server.port 8501` |
| `03-streamlit-hotel/` | Hotel app — recommendation table + metric tiles | `cd Hotel; streamlit run hotel.py --server.port 8502` |
| `04-docker/` | `docker images`, `docker ps`, `:8001/health` in browser | `.\scripts\demo-docker-k8s.ps1` |
| `05-kubernetes/` | `kubectl get pods` (2/2 Running), `get svc`, `:30007/` in browser | same script as above |
| `06-airflow-mlflow/` | Airflow DAG green, MLflow runs page, MLflow run detail | `.\scripts\demo-airflow-mlflow.ps1` |
| `07-cicd/` | Actions tab green, `test` job log, `docker` job log, auto-commit on `main` | <https://github.com/zohaibsheikh007/Travel-MLOps-Capstone/actions> |

## evidence/

The `evidence/` folder is auto-populated by `scripts/capture-evidence.ps1`. It
contains plain-text snapshots (`pytest -v` output, JSON responses, `kubectl get
pods`, etc.) that you can paste straight into the Google Doc appendix.

You can re-run that script any time:

```powershell
.\scripts\capture-evidence.ps1
```

## File-naming hint

Use names like `01-form.png`, `02-prediction-success.png` so the order is
preserved when you drag them into the Google Doc.
