import logging
import os
from datetime import datetime, timedelta

import pandas as pd
from airflow import DAG
from airflow.operators.python import PythonOperator

from utils.data_ingestion import DataLoader
from utils.data_transformation import DataTransformer
from utils.model_training import RandomForestModel

DATA_DIR = "/opt/airflow/dags/data"
DATA_FILE_PATH = os.path.join(DATA_DIR, "flights.csv")

default_args = {
    "owner": "travelwise",
    "start_date": datetime(2024, 1, 1),
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


def extract_data():
    if not os.path.exists(DATA_FILE_PATH):
        raise FileNotFoundError(f"{DATA_FILE_PATH} not found.")

    loader = DataLoader(DATA_FILE_PATH)
    data = loader.load_data()
    cleaned_path = os.path.join(DATA_DIR, "cleaned.csv")
    data.to_csv(cleaned_path, index=False)
    logging.info("Data extracted and saved to cleaned.csv")


def transform_data():
    cleaned_path = os.path.join(DATA_DIR, "cleaned.csv")
    data = pd.read_csv(cleaned_path)
    transformer = DataTransformer(data)
    X, y = transformer.fit_transform()

    pd.DataFrame(X).to_csv(os.path.join(DATA_DIR, "X.csv"), index=False)
    y.to_csv(os.path.join(DATA_DIR, "y.csv"), index=False)
    logging.info("Data transformed and saved as X.csv and y.csv")


def train_model():
    X = pd.read_csv(os.path.join(DATA_DIR, "X.csv"))
    y = pd.read_csv(os.path.join(DATA_DIR, "y.csv"))

    model = RandomForestModel(X, y.values.ravel())
    model.random_forest()
    logging.info("Model training completed and saved")


with DAG(
    dag_id="flight_price_prediction",
    default_args=default_args,
    description="Daily flight price prediction pipeline",
    schedule_interval="@daily",
    catchup=False,
    tags=["mlops", "travel", "regression"],
) as dag:
    extract = PythonOperator(task_id="extract_data", python_callable=extract_data)
    transform = PythonOperator(task_id="transform_data", python_callable=transform_data)
    train = PythonOperator(task_id="train_model", python_callable=train_model)

    extract >> transform >> train
