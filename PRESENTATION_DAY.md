# Presentation Day — Single Runbook

**Goal:** finish everything you need to submit and present, in order, in one sitting.
Estimated time: **60 to 90 minutes** total. Skip nothing in section 0.

---

## 0. One-time pre-flight check (3 min)

Open a fresh PowerShell terminal and run:

```powershell
cd d:\dev\Masters\Travel-MLOps-Capstone
.\scripts\preflight.ps1
```

The script verifies every dependency, retrains models if needed, smoke-tests the
Flask API, checks Docker / Kubernetes / Docker Hub, and prints an `OK` / `FAIL`
summary at the end. **Do not move on until every line says OK.**

If anything is `FAIL`, the script prints the exact remedy. The most common ones:

| FAIL line | Fix |
|-----------|-----|
| `Docker daemon` | Start Docker Desktop, wait for the whale icon |
| `kubectl` | Settings → Kubernetes → Enable, Apply & Restart |
| `Python deps` | `pip install -r "Flight Prediction/requirements.txt"` |
| `Models` | `python "Flight Prediction/train_model.py"` |

---

## 1. Capture text evidence (2 min)

Most of the proof you need is plain text — `curl` responses, `pytest 6 passed`,
`kubectl get pods`. Run:

```powershell
.\scripts\capture-evidence.ps1
```

This populates `screenshots/evidence/*.txt` with everything you need to back up
the screenshots. Useful for the appendix of the Google Doc, and saves you from
typing the same `curl` four times during the recording.

---

## 2. Take screenshots (15 min)

You need around **15 screenshots** total. Run the demos in order; after each
demo, take the screenshots, save them in the matching folder under
`screenshots/`, then move on.

| # | Demo | Folder | Screens to take |
|---|------|--------|-----------------|
| 1 | Flask API | `screenshots/01-rest-api/` | form page, prediction success, `/health` JSON, `pytest 6 passed` |
| 2 | Streamlit Gender | `screenshots/02-streamlit-gender/` | full page with a sample prediction |
| 3 | Streamlit Hotel | `screenshots/03-streamlit-hotel/` | recommendation table, metric tiles |
| 4 | Docker | `screenshots/04-docker/` | `docker images`, `docker ps`, `:8001/health` in browser |
| 5 | Kubernetes | `screenshots/05-kubernetes/` | `kubectl get pods` (2/2 Running), `get svc` (NodePort 30007), `:30007/` form |
| 6 | Airflow + MLflow | `screenshots/06-airflow-mlflow/` | DAG graph green, MLflow runs page, MLflow run detail |
| 7 | GitHub Actions | `screenshots/07-cicd/` | Actions tab green check, `test` job log, `docker` job log, the auto-commit on main |

### How to run each demo

> All commands assume you are in `d:\dev\Masters\Travel-MLOps-Capstone`.

#### Demo 1 — Flask + tests

```powershell
# Terminal A: serve
cd "Flight Prediction"; python Flight_Price.py
# Terminal B: tests
cd "Flight Prediction"; python -m pytest tests/ -v
```

Browser: <http://localhost:8000/>, then submit a prediction, then
<http://localhost:8000/health>.

#### Demo 2 + 3 — Streamlit apps

```powershell
# Terminal A
cd Gender;  streamlit run gender_app.py --server.port 8501
# Terminal B
cd Hotel;   streamlit run hotel.py        --server.port 8502
```

#### Demo 4 + 5 — Docker + Kubernetes

```powershell
.\scripts\demo-docker-k8s.ps1
```

It builds the image, runs the container on `:8001`, deploys to Kubernetes,
waits for rollout, and prints the screenshot checklist for both demos.

#### Demo 6 — Airflow + MLflow

```powershell
.\scripts\demo-airflow-mlflow.ps1
```

Wait for the script to print `Airflow is healthy`, then:

1. Open <http://localhost:8080> (login: `airflow / airflow`).
2. Toggle `flight_price_prediction` ON, click ▶ Trigger DAG.
3. Click into the run, switch to the Graph view, wait for all three nodes green.
4. Open <http://localhost:5000>. Click the `flight_price_prediction` experiment, then any run.

#### Demo 7 — GitHub Actions

Open in browser: <https://github.com/zohaibsheikh007/Travel-MLOps-Capstone/actions>.
Click the most recent successful run with a green check, screenshot:

- The Actions tab (overview).
- The expanded `test` job (`Run API health check` step).
- The expanded `docker` job (`Build and push Docker image` step showing the
  `sheikh007/flight-price-api` push).
- The auto-commit on `main`: <https://github.com/zohaibsheikh007/Travel-MLOps-Capstone/commits/main>
  showing one of the `ci: update image tag to <sha>` commits.

---

## 3. Build the Google Doc (10 min)

1. Open <https://docs.google.com> → blank document.
2. Title: **TravelWise — MLOps Workflow Documentation**.
3. For each section in `DOCUMENTATION.md`:
   - Copy the section heading and paragraph text into the Google Doc.
   - Drag the screenshots from the matching `screenshots/0X-…/` folder into
     the doc, captioning each with one sentence.
4. Add a final **Appendix** section, paste the contents of
   `screenshots/evidence/all-evidence.txt` as monospace text.
5. Share → **Anyone with the link** → **Viewer**.
6. Copy the URL, paste it in your submission folder.

> The brief explicitly says: do not include installation steps. `DOCUMENTATION.md`
> is already written that way.

---

## 4. Upload notebooks to Drive + Colab (5 min)

1. Open <https://drive.google.com> → New → File upload. Upload all three:
   - `Flight Prediction\Flight_Price_Prediction.ipynb`
   - `Gender\Gender_Classification_Model.ipynb`
   - `Hotel\Hotel_Recommendation_Model.ipynb`
2. For each: right-click → **Open with → Google Colaboratory**. Once open,
   click **Share → Anyone with the link → Viewer**, copy the URL from the
   address bar — that is the Colab share link you submit.
3. Paste the three Colab links into a text file in your submission folder
   (or directly into the submission form).

---

## 5. Record the video (20–40 min)

1. Open OBS Studio (or Loom). Display capture, audio your microphone.
2. Pre-load these tabs / windows:
   - GitHub repo
   - Flight Colab notebook
   - <http://localhost:8000/> (Flask)
   - <http://localhost:8080/> (Airflow)
   - <http://localhost:5000/> (MLflow)
   - <http://localhost:8501/> (Gender)
   - <http://localhost:8502/> (Hotel)
   - GitHub Actions tab
3. Open `VIDEO_SCRIPT.md` in a separate window. Read sections 1 → 8.
4. **Aim for 18–22 minutes.** That comfortably exceeds the 15-minute minimum
   without padding. If you need 40 min, expand sections 4 and 5 with deeper
   notebook walk-throughs.
5. Save the recording (mp4). Upload to Google Drive *or* YouTube unlisted.
   Set sharing to **Anyone with the link → Viewer**.

> Tip: if you fluff a section, just stop, rewind a few seconds, restart the
> sentence. You can either re-record from there or trim in editing — both are
> fine. Examiners do not look for a single take.

---

## 6. Submit (2 min)

The classroom submission has two slots:

| Submission slot | What goes in |
|-----------------|--------------|
| **Project link** | A Google Drive folder containing: 3 Colab share links (in a `.txt`), the Google Doc share link, the GitHub repo URL |
| **Video link**   | The Drive / Loom / YouTube unlisted URL |

Set **every** link to "Anyone with the link → Viewer". The evaluator should not
have to request access to anything.

---

## Final cross-check before clicking submit

| Item | Check |
|------|-------|
| GitHub repo URL works in incognito | yes / no |
| All three Colab links open in incognito | yes / no |
| Google Doc opens in incognito | yes / no |
| Video plays in incognito | yes / no |
| Video duration ≥ 15 minutes | yes / no |
| Latest GitHub Actions run is green | yes / no |
| Google Doc has screenshots in all 7 sections | yes / no |
| You can answer "what does each MLOps layer do" without the script | yes / no |

If every box is "yes", submit.

---

## What NOT to mention in the video / doc

- Do not mention any AI assistants, IDE copilots, or generated content.
- Do not show your `.env` files, Docker Hub token, or any password.
- Do not show the chat history of any AI tool.

The repo, the script, the doc are yours; speak about them in first person.

Good luck.
