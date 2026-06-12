# TravelWise — MLOps in Travel Analytics

End-to-end ML system for the travel and tourism domain. Three models (flight price regression, gender classification, hotel recommendation) wrapped in the full MLOps stack: Flask REST API, Docker, Kubernetes, Apache Airflow, MLflow, Jenkins, GitHub Actions, and Streamlit.

**Author:** Zohaib Sheikh — Masters Capstone (TravelWise / Voyage Analytics).

---

## What this repository contains

| Layer | Tech | Where |
|-------|------|-------|
| Regression model | scikit-learn (Random Forest) | `Flight Prediction/train_model.py` |
| Classification model | scikit-learn (Logistic Regression + TF-IDF) | `Gender/train_model.py` |
| Recommender | Truncated SVD on user-hotel matrix | `Hotel/Hotel_Recommendation_Model.ipynb` + `Hotel/hotel.py` |
| REST API | Flask + Gunicorn | `Flight Prediction/Flight_Price.py` |
| Container | Docker | `Flight Prediction/Dockerfile` |
| Orchestration | Kubernetes | `Flight Prediction/deployment.yaml`, `service.yaml` |
| Workflow | Apache Airflow | `Flight Prediction/airflow-docker/dags/flight_prediction_dag.py` |
| Experiment tracking | MLflow | logged inside `train_model.py` |
| CI/CD | GitHub Actions, Jenkins | `.github/workflows/deploy.yml`, `Jenkinsfile` |
| Apps | Streamlit | `Gender/gender_app.py`, `Hotel/hotel.py` |
| Tests | pytest | `Flight Prediction/tests/` |

---

## Repository structure

```
Travel-MLOps-Capstone/
├── Flight Prediction/
│   ├── flights.csv
│   ├── train_model.py
│   ├── Flight_Price.py            # Flask app
│   ├── Flight_Price_Prediction.ipynb
│   ├── Dockerfile
│   ├── deployment.yaml            # Kubernetes
│   ├── service.yaml
│   ├── tests/
│   │   ├── test_api.py
│   │   └── test_features.py
│   ├── random_forest.pkl          # trained artifact
│   ├── scaling.pkl
│   ├── feature_columns.json
│   ├── model_leaderboard.csv      # 4-model comparison
│   └── airflow-docker/            # Airflow + MLflow stack
│       ├── docker-compose.yaml
│       ├── Dockerfile
│       ├── Dockerfile.mlflow
│       ├── dags/
│       │   ├── flight_prediction_dag.py
│       │   ├── data/flights.csv
│       │   └── utils/
│       │       ├── data_ingestion.py
│       │       ├── data_transformation.py
│       │       └── model_training.py
│       └── postgres-init/init.sql
├── Gender/
│   ├── users.csv
│   ├── train_model.py
│   ├── gender_app.py              # Streamlit
│   ├── Gender_Classification_Model.ipynb
│   ├── gender_model.pkl
│   └── company_encoder.pkl
├── Hotel/
│   ├── hotels.csv
│   ├── hotel.py                   # Streamlit
│   └── Hotel_Recommendation_Model.ipynb
├── .github/workflows/deploy.yml
├── Jenkinsfile
├── scripts/push-to-github.ps1
└── README.md                      # this file
```

---

## Quickstart

### 1. Train all three models

```bash
pip install -r "Flight Prediction/requirements.txt"
pip install -r "Gender/requirements.txt"
pip install -r "Hotel/requirements.txt"

python "Flight Prediction/train_model.py"
python "Gender/train_model.py"
```

The flight script trains four models (Linear Regression, Decision Tree, Gradient Boosting, Random Forest), logs every run to MLflow under the `flight_price_prediction` experiment, registers the best one, and writes a `model_leaderboard.csv` next to the pickle.

### 2. Serve the regression model

```bash
cd "Flight Prediction"
python Flight_Price.py
```

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | HTML form |
| `/health` | GET | Liveness probe |
| `/api/predict` | POST | JSON prediction |

JSON example:

```bash
curl -X POST http://localhost:8000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"from_location":"Sao_Paulo (SP)","destination":"Rio_de_Janeiro (RJ)","flight_type":"economic","agency":"CloudFy","week_no":10,"week_day":3,"day":15}'
```

### 3. Run the Streamlit apps

```bash
cd Gender && streamlit run gender_app.py
# in another terminal
cd Hotel  && streamlit run hotel.py
```

### 4. Run the unit tests

```bash
cd "Flight Prediction"
python -m pytest tests/ -v
```

### 5. Docker

```bash
cd "Flight Prediction"
docker build -t travelwise/flight-price-api .
docker run -p 8000:8000 travelwise/flight-price-api
```

### 6. Kubernetes

```bash
kubectl apply -f "Flight Prediction/deployment.yaml"
kubectl apply -f "Flight Prediction/service.yaml"
kubectl get pods,svc
```

Service is on NodePort `30007`.

### 7. Airflow + MLflow

```bash
cd "Flight Prediction/airflow-docker"
cp .env.example .env
docker compose up -d
```

- Airflow: <http://localhost:8080> (`airflow / airflow`)
- MLflow: <http://localhost:5000>

The DAG `flight_price_prediction` chains:

```
extract_data >> transform_data >> train_model
```

Each `train_model` execution registers a new version of `flight_price_model` in the MLflow registry.

### 8. CI/CD

- **GitHub Actions** (`.github/workflows/deploy.yml`) — runs on every push to `main`. Trains the model, runs tests, builds and pushes the Docker image, updates the K8s manifest with the new image tag and commits it back.
- **Jenkins** (`Jenkinsfile`) — equivalent pipeline for on-prem CI.

For the GitHub Actions Docker push to work, set the repo secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`.

---

## Model performance

Logged in MLflow on the latest run; mirror saved to `Flight Prediction/model_leaderboard.csv`.

| Model | RMSE | MAE | R² |
|-------|------|-----|-----|
| Linear Regression | 216.85 | 165.36 | 0.6431 |
| Decision Tree (depth=12) | 112.95 | 48.41 | 0.9032 |
| Gradient Boosting (100 est.) | 88.02 | 59.69 | 0.9412 |
| **Random Forest (100 est., depth=20)** | **1.13** | **0.10** | **1.0000** |

The Random Forest reaches near-perfect R² because the dataset's pricing rule is deterministic per `(from, to, flightType, agency)` group — a finding documented in the EDA section of `Flight_Price_Prediction.ipynb`. The four-way comparison is included so the modelling story remains meaningful.

Gender classifier: 70.1% accuracy / 0.7356 AUC (logistic regression on character-level TF-IDF + standardised numerics, tuned via 3-fold grid search).

---

## How the pieces fit together

```
                                     +-----------------+
                                     |   MLflow DB     |
                                     +--------+--------+
                                              ^
                                              | log_metrics
   +-----------+    +----------+    +---------+--------+
   | flights   +--> | Airflow  +--> | train_model task |
   | CSV       |    | DAG      |    +---------+--------+
   +-----------+    +----------+              |
                                              v
                                     +--------+--------+
                                     |  random_forest  |
                                     |     .pkl        |
                                     +--------+--------+
                                              |
                                              v
   +-----------------+    +-----------------+
   | Flask /api      | <-+ Docker image     |
   | /predict        |    | (Gunicorn 8000) |
   +--------+--------+    +--------+--------+
            |                      |
            v                      v
   +-----------------+    +-----------------+
   | Kubernetes      |    | Jenkins / GHA   |
   | 2 replicas      |    | CI/CD updates   |
   +-----------------+    +-----------------+
```

---

## License

MIT — for academic use.
