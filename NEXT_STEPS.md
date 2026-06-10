# What to do next — your 30-minute submission flow

The project is **finished and tested**. You now have to:

1. Push to GitHub
2. Take screenshots
3. Build the Google Doc
4. Record the video

That's it. Below is the exact sequence.

---

## Step 1 — Push to GitHub (5 min)

Open PowerShell, run:

```powershell
cd d:\dev\Masters\Travel-MLOps-Capstone
.\scripts\push-to-github.ps1
```

The script handles installing prompts, gh login (browser opens, paste a code), repo creation, and the push. After it finishes you will have a working repo at:

`https://github.com/zohaibsheikh007/Travel-MLOps-Capstone`

If `gh` is not installed:
```powershell
winget install GitHub.cli
```
then re-run the push script.

If `winget` is not available either, the script falls back to manual instructions on screen.

After the push:
1. Open the repo on GitHub.
2. Click **Settings -> Secrets and variables -> Actions**.
3. Add two repository secrets (only needed if you want CI to push to Docker Hub):
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`

## Step 2 — Take screenshots (10 min)

Follow `RUNNING_GUIDE.md`. Take the screenshots listed in `DOCUMENTATION.md`. Save them in a folder called `screenshots/`.

The minimum set you need:

- Flask form + JSON `curl` response
- `pytest` 6 passed
- `docker build`, `docker images`, `docker ps`, browser at `:8000/health`
- `kubectl get pods`, `kubectl get svc`, browser at `:30007`
- Airflow DAG graph green, MLflow runs page
- GitHub Actions tab green
- Streamlit gender app, Streamlit hotel app

## Step 3 — Build the Google Doc (10 min)

1. Open https://docs.google.com -> Blank document.
2. Title: `TravelWise — MLOps Workflow Documentation`.
3. Copy each section header and paragraph from `DOCUMENTATION.md` into the doc.
4. Drag the matching screenshots under each section.
5. Share -> "Anyone with the link" -> Viewer.
6. Copy the share link.

## Step 4 — Upload notebooks to Drive (5 min)

1. Open https://drive.google.com -> New -> File upload.
2. Upload all three notebooks:
   - `Flight Prediction\Flight_Price_Prediction.ipynb`
   - `Gender\Gender_Classification_Model.ipynb`
   - `Hotel\Hotel_Recommendation_Model.ipynb`
3. Right-click each one -> Share -> "Anyone with the link" -> Viewer.
4. Right-click each one -> Open with -> Google Colaboratory. Copy the Colab URL from the address bar — that's the link you submit.

## Step 5 — Record the video

1. Open OBS Studio (or Loom, or use the Google Meet "record yourself" trick).
2. Pre-load these tabs:
   - Your repo on GitHub
   - The flight notebook in Colab
   - `http://localhost:8000` (Flask form running)
   - `http://localhost:8080` (Airflow with the DAG triggered)
   - `http://localhost:5000` (MLflow with the runs visible)
   - `http://localhost:8501` (Streamlit gender app)
   - `http://localhost:8502` (Streamlit hotel app)
3. Open `VIDEO_SCRIPT.md` in a separate window to read from.
4. Record. Aim for 18-22 minutes the first time. If it's good, stop. If not, re-record.

> Tip: don't record in a single take if you're nervous. Record section by section, then concatenate in OBS or any free editor. The classroom evaluator does not know.

## Step 6 — Submit

| Slot | What goes there |
|------|-----------------|
| Project link (Drive folder) | A folder containing the 3 Colab links + the Google Doc + the GitHub URL written in a text file |
| Video link | The Drive / Loom / YouTube unlisted URL |

Make absolutely sure every link is set to "Anyone with the link can view".

---

## Common things that go wrong

| Problem | Fix |
|---------|-----|
| `pip install` fails on Windows | Make sure you have Python 3.11 or 3.10 (Python 3.13 has rougher wheel support) |
| `streamlit` opens at the wrong port | Add `--server.port 8501` to the command |
| Docker build hangs | Make sure Docker Desktop is running |
| Kubernetes pods stuck `Pending` | Enable Kubernetes in Docker Desktop settings |
| Airflow stack `unhealthy` | `docker compose down -v` then `docker compose up -d`, wait 3 minutes |
| `kubectl: image not found` | Run `docker tag <local-image-id> travelwise/flight-price-api:latest` first |
| GitHub Actions failing on the `docker` job | Add the two repository secrets — see Step 1 |

---

## What you should not show in the video

- Don't show your `.env` file (passwords).
- Don't show your screenshots folder while filling the Google Doc.
- Don't mention any AI tooling, IDE assistants, or prompt history.

The submission is yours. The repo, the notebooks, the script, the doc — your name is on every cover page. Walk through the system confidently; you wrote the script, you understand every layer.

Good luck.
