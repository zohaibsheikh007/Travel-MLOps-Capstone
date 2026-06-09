# TravelWise — MLOps Workflow Documentation

This document is the source for the Google Doc that accompanies the submission. It walks through every MLOps stage with the exact commands, the URL each service runs at, and the screenshot the report should contain at that step. Installation steps are intentionally **not** included, per the project brief.

> Tip for the screenshots: drag each PNG into the Google Doc under the matching heading.

---

## 1. REST API (Flask)

The flight-price regressor is exposed as a REST service with two endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | HTML form for manual testing |
| `/health` | GET | Liveness probe (used by Kubernetes) |
| `/api/predict` | POST | JSON prediction endpoint |

Run locally:

```bash
cd "Flight Prediction"
python Flight_Price.py
```

The service binds to `http://localhost:8000`.

Sample request:

```bash
curl -X POST http://localhost:8000/api/predict \
     -H "Content-Type: application/json" \
     -d '{"from_location":"Sao_Paulo (SP)","destination":"Rio_de_Janeiro (RJ)","flight_type":"economic","agency":"CloudFy","week_no":10,"week_day":3,"day":15}'
```

Response:

```json
{"predicted_price": 459.97, "currency": "USD"}
```

**Screenshots to capture**
1. The browser at `http://localhost:8000` showing the HTML form.
2. A successful prediction (form submitted with values, predicted price banner visible).
3. A `curl` window with the JSON response.
4. A second terminal showing `python -m pytest tests/` with `6 passed`.

---

## 2. Streamlit Apps

Two Streamlit apps live in the repo:

| App | Folder | Command |
|-----|--------|---------|
| Gender classifier | `Gender/` | `streamlit run gender_app.py` |
| Hotel recommender | `Hotel/` | `streamlit run hotel.py` |

Both default to `http://localhost:8501`.

**Screenshots to capture**
1. Gender app — full page with a sample prediction.
2. Hotel app — left panel with user selected and right panel with recommendation table.
3. Hotel app — the metric tiles (Total Bookings / Active Users / Unique Hotels).

---

## 3. Docker Deployment

Build:

```bash
cd "Flight Prediction"
docker build -t travelwise/flight-price-api .
```

Run:

```bash
docker run -d -p 8000:8000 --name flight-api travelwise/flight-price-api
docker logs flight-api
```

**Screenshots to capture**
1. `docker build` output ending with `Successfully tagged travelwise/flight-price-api:latest`.
2. `docker images` showing the image with its size.
3. `docker ps` listing the running container.
4. The browser hitting `http://localhost:8000/health` returning the JSON `{"status":"healthy"}`.

---

## 4. Kubernetes Deployment

Apply the manifests:

```bash
cd "Flight Prediction"
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
kubectl get svc
```

The service is exposed on NodePort `30007`. With Docker Desktop's Kubernetes the URL is `http://localhost:30007`.

**Screenshots to capture**
1. `kubectl get pods` showing 2/2 running replicas.
2. `kubectl get svc flight-price-service` with the NodePort `30007/TCP`.
3. `kubectl describe pod` of one replica with the `livenessProbe` and `readinessProbe` sections visible.
4. The browser at `http://localhost:30007/` showing the form served from inside the cluster.

---

## 5. Apache Airflow Scheduling

```bash
cd "Flight Prediction/airflow-docker"
copy .env.example .env       # Windows
docker compose up -d
```

Once the stack is healthy, open `http://localhost:8080`. Default login is `airflow / airflow`.

The DAG is `flight_price_prediction` and chains:

```
extract_data >> transform_data >> train_model
```

`train_model` writes the new model into `dags/models/random_forest.pkl` and logs the run to MLflow.

**Screenshots to capture**
1. The Airflow UI DAGs list with `flight_price_prediction` toggled on.
2. The DAG graph view showing the three task nodes (all green).
3. The Gantt or Tree view after a successful run.
4. Inside one task, the Logs tab showing `Model training completed and saved`.

---

## 6. CI/CD Pipeline

Two equivalent pipelines ship in the repo. Pick one for the demo (we recommend GitHub Actions because it runs in the cloud and shows up in the PR).

### Option A — GitHub Actions

File: `.github/workflows/deploy.yml`. On every push to `main`:

1. Set up Python 3.11.
2. `pip install` and `python "Flight Prediction/train_model.py"`.
3. Run the API health-check test.
4. Build the Docker image and push it to Docker Hub tagged with the commit SHA.
5. Update `Flight Prediction/deployment.yaml` with the new image tag and commit it back to `main`.

**Screenshots to capture**
1. The Actions tab on GitHub with a green checkmark on the latest run.
2. The `test` job log showing `Health check passed`.
3. The `docker` job log showing `Successfully pushed travelwise/flight-price-api:<sha>`.
4. The auto-commit on the `main` branch with the message `ci: update image tag to ...`.

### Option B — Jenkins

File: `Jenkinsfile`. Stages: Checkout -> Install -> Train -> Test -> Build Image -> Push -> Deploy to K8s.

**Screenshots to capture**
1. The Jenkins blue-ocean pipeline view with all stages green.
2. The `Train Model` stage logs showing the leaderboard.
3. The `Build Docker Image` stage with the `docker tag` and `docker push` lines.
4. The `Deploy to Kubernetes` stage showing `deployment.apps/flight-price-deployment configured`.

---

## 7. MLflow Tracking

Local (no docker-compose):

```bash
cd "Flight Prediction"
mlflow ui --backend-store-uri file:./mlruns
```

Then open `http://localhost:5000`.

Inside the docker-compose stack, MLflow is wired to the same Postgres instance as Airflow and reachable at `http://localhost:5000` from the host.

**Screenshots to capture**
1. The MLflow Experiments page showing `flight_price_prediction` with multiple runs.
2. The runs comparison table with RMSE / MAE / R² for the four candidate models.
3. The Models page with `flight_price_model` and at least one registered version.
4. A run detail page showing the logged parameters, metrics, and the model artifact in the right-hand panel.

---

## 8. Reading order for the report

For the Google Doc, present the screenshots in this order so the reader experiences the same lifecycle the system was built in:

1. REST API
2. Docker
3. Kubernetes
4. Airflow
5. MLflow
6. CI/CD
7. Streamlit apps (gender, hotel)

Each section in the doc should have a one-paragraph caption that explains what the screenshot proves. The captions are already drafted above the screenshot list for each section.
