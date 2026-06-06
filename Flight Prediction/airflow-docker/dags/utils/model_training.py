import os
import pickle
from math import sqrt

import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split


class RandomForestModel:
    def __init__(self, X, y):
        self.X = X
        self.y = y

    def random_forest(self):
        X_train, X_test, y_train, y_test = train_test_split(
            self.X, self.y, test_size=0.2, random_state=42
        )

        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)

        preds = model.predict(X_test)
        rmse = sqrt(mean_squared_error(y_test, preds))
        r2 = r2_score(y_test, preds)

        tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow:5000")
        mlflow.set_tracking_uri(tracking_uri)

        with mlflow.start_run(run_name="airflow_flight_training"):
            mlflow.log_param("model", "RandomForestRegressor")
            mlflow.log_param("n_estimators", 100)
            mlflow.log_metric("rmse", rmse)
            mlflow.log_metric("r2_score", r2)
            mlflow.sklearn.log_model(model, "model", registered_model_name="flight_price_model")

        model_dir = "/opt/airflow/dags/models"
        os.makedirs(model_dir, exist_ok=True)
        with open(os.path.join(model_dir, "random_forest.pkl"), "wb") as f:
            pickle.dump(model, f)
