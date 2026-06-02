# Flight Price Prediction (Regression + MLOps)

## Components

| Component | File / Folder |
|-----------|---------------|
| Model training | `train_model.py` |
| Flask REST API | `Flight_Price.py` |
| Docker image | `Dockerfile` |
| Kubernetes | `deployment.yaml`, `service.yaml` |
| Airflow + MLflow | `airflow-docker/` |

## Quick Start

### 1. Train model

```bash
pip install -r requirements.txt
python train_model.py
```

### 2. Run Flask API

```bash
python Flight_Price.py
```

- Web UI: http://localhost:8000
- Health: http://localhost:8000/health
- REST API: `POST http://localhost:8000/api/predict`

Example JSON body:

```json
{
  "from_location": "Sao_Paulo (SP)",
  "destination": "Rio_de_Janeiro (RJ)",
  "flight_type": "economic",
  "agency": "CloudFy",
  "week_no": 10,
  "week_day": 3,
  "day": 15
}
```

### 3. Docker

```bash
docker build -t travelwise/flight-price-api .
docker run -p 8000:8000 travelwise/flight-price-api
```

### 4. Kubernetes

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 5. Airflow + MLflow

```bash
cd airflow-docker
docker compose up -d
```

- Airflow UI: http://localhost:8080 (airflow / airflow)
- MLflow UI: http://localhost:5000
