"""Quick MLflow connectivity test for local development."""

import mlflow
import mlflow.sklearn
from math import sqrt
from sklearn.datasets import load_diabetes
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

mlflow.set_tracking_uri("http://localhost:5000")

data = load_diabetes()
X_train, X_test, y_train, y_test = train_test_split(data.data, data.target, random_state=42)

model = RandomForestRegressor(n_estimators=50, random_state=42)
model.fit(X_train, y_train)

preds = model.predict(X_test)
rmse = sqrt(mean_squared_error(y_test, preds))

with mlflow.start_run(run_name="mlflow_connectivity_test"):
    mlflow.log_param("model_type", "RandomForest")
    mlflow.log_metric("rmse", rmse)
    mlflow.sklearn.log_model(model, "model")

print(f"Logged test run to MLflow. RMSE={rmse:.4f}")
