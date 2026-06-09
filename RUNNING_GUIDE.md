# Running the Project Locally — Step by Step

This is the practical "how do I get every part of this project on screen" guide.  
Every command is copy-pasteable. Run them from `d:\dev\Masters\Travel-MLOps-Capstone\` unless stated otherwise.

> If anything fails, stop, read the error, and search it. Most of the time it's a missing dependency or a port already in use.

---

## 0. One-time setup

```powershell
cd d:\dev\Masters\Travel-MLOps-Capstone

# Train all three models (writes the .pkl artifacts the apps need)
pip install -r "Flight Prediction/requirements.txt"
pip install -r "Gender/requirements.txt"
pip install -r "Hotel/requirements.txt"

python "Flight Prediction/train_model.py"
python "Gender/train_model.py"
```

The hotel recommender trains in-memory inside the Streamlit app, so you don't need a separate train step.

---

## 1. Demo the Flask REST API

```powershell
cd "Flight Prediction"
python Flight_Price.py
```

Then in a browser open `http://localhost:8000`.  
Take screenshots of:
1. The form page.
2. A successful prediction (form filled, banner showing the price).
3. A second terminal hitting `http://localhost:8000/health`.

To stop: `Ctrl+C` in the terminal.

---

## 2. Demo the Streamlit apps

In two separate terminals:

```powershell
cd Gender
streamlit run gender_app.py
```

```powershell
cd Hotel
streamlit run hotel.py
```

Streamlit auto-opens the browser. The first app lands on `http://localhost:8501`, the second usually picks `8502`.  
Take screenshots of each app with a sample prediction or recommendation.

---

## 3. Demo Docker

Make sure Docker Desktop is running.

```powershell
cd "Flight Prediction"
docker build -t travelwise/flight-price-api .
docker run -d -p 8001:8000 --name flight-api travelwise/flight-price-api
docker ps
docker logs flight-api
```

Then hit `http://localhost:8001/health`. Screenshots:
1. The `docker build` final lines.
2. `docker images` listing the image.
3. `docker ps` listing the running container.
4. The browser hitting `:8001/health` with the JSON response.

To stop: `docker rm -f flight-api`.

---

## 4. Demo Kubernetes

This needs Docker Desktop with Kubernetes enabled (Settings -> Kubernetes -> Enable -> Apply).

```powershell
cd "Flight Prediction"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods -w     # wait until both replicas show 1/1 Running, then Ctrl+C
kubectl get svc
```

The service is on NodePort 30007. Open `http://localhost:30007/` in the browser.

Screenshots:
1. `kubectl get pods` showing 2/2 Running.
2. `kubectl get svc` showing port 30007.
3. `kubectl describe pod <pod-name>` with the probes section visible.
4. The browser at port 30007.

To clean up: `kubectl delete -f deployment.yaml -f service.yaml`.

> The deployment uses image `travelwise/flight-price-api:latest`. If your local Docker image isn't tagged that way, run `docker tag <image-id> travelwise/flight-price-api:latest` first.

---

## 5. Demo Airflow + MLflow

```powershell
cd "Flight Prediction\airflow-docker"
copy .env.example .env
docker compose up -d
docker compose ps
```

Wait two to three minutes for everything to become healthy. Then:

- Airflow UI: `http://localhost:8080` (login `airflow / airflow`).
- MLflow UI: `http://localhost:5000`.

In Airflow:
1. Toggle the `flight_price_prediction` DAG ON.
2. Click "Trigger DAG" to run it manually.
3. Click into the run and switch to the **Graph** view — three nodes should turn green sequentially.

Screenshots:
1. Airflow DAGs list with the DAG enabled.
2. Graph view of a successful run.
3. Logs of the `train_model` task showing `Model training completed and saved`.
4. MLflow experiments page showing the run.
5. MLflow run detail page with logged metrics.

To clean up: `docker compose down -v`.

---

## 6. Demo CI/CD (GitHub Actions)

Once the repo is pushed (see `scripts/push-to-github.ps1`):

1. Go to your repo on GitHub.
2. Click the **Actions** tab.
3. The first run kicks off automatically on push.
4. Click into the run, expand each step.

Screenshots:
1. Actions tab with a green checkmark on the latest run.
2. The `test` job logs (health check passing).
3. The `docker` job logs (image pushed).

> The `docker` job needs two repository secrets to actually push to Docker Hub: `DOCKER_USERNAME` and `DOCKER_PASSWORD`. If you don't have a Docker Hub account, that's fine — the test job alone is enough proof for the screenshot. The build step will simply skip on PRs.

---

## 7. Demo CI/CD (Jenkins) — optional

If you have Jenkins installed:

1. New Item -> Pipeline.
2. Name `flight-price-pipeline`.
3. In the pipeline section, choose "Pipeline from SCM" and point it at the GitHub repo.
4. Path: `Jenkinsfile`.
5. Save -> Build Now.

Screenshots: the Blue Ocean view with all stages green.

---

## 8. Run the unit tests

```powershell
cd "Flight Prediction"
python -m pytest tests/ -v
```

Should print `6 passed`. Take a screenshot — that goes into the report under "Code Quality".

---

## 9. Quick "everything works" sanity script

```powershell
# 1. Health
curl http://localhost:8000/health

# 2. Predict
curl -X POST http://localhost:8000/api/predict `
     -H "Content-Type: application/json" `
     -d '{\"from_location\":\"Sao_Paulo (SP)\",\"destination\":\"Rio_de_Janeiro (RJ)\",\"flight_type\":\"economic\",\"agency\":\"CloudFy\",\"week_no\":10,\"week_day\":3,\"day\":15}'

# 3. Tests
python -m pytest "Flight Prediction/tests/" -v
```

If all three return successfully, the modelling + serving layer is good to demo.
