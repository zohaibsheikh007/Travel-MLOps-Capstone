"""Train flight price regression model.

Trains a Random Forest regressor on the flights dataset and saves the artifacts
needed by the Flask API and Airflow pipeline. We also compare a few baseline
models so the evaluation in MLflow has something meaningful to look at.
"""

import json
import pickle
from math import sqrt
from pathlib import Path

import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeRegressor

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "flights.csv"
MLFLOW_URI = "file:./mlruns"


def load_and_engineer(path: Path) -> pd.DataFrame:
    """Read the raw CSV and add date-derived features."""
    df = pd.read_csv(path)
    df["date"] = pd.to_datetime(df["date"], format="%m/%d/%Y")
    df["week_no"] = df["date"].dt.isocalendar().week.astype(int)
    df["week_day"] = df["date"].dt.dayofweek + 1
    df["day"] = df["date"].dt.day
    df["month"] = df["date"].dt.month
    return df


def build_feature_matrix(df: pd.DataFrame):
    """Drop identifier columns and one-hot encode the categoricals."""
    data = df.copy()
    drop_cols = ["travelCode", "userCode", "date", "time", "distance"]
    data.drop(columns=drop_cols, inplace=True, errors="ignore")

    X = data.drop(columns=["price"])
    y = data["price"]

    X_encoded = pd.get_dummies(
        X,
        columns=["from", "to", "flightType", "agency"],
        prefix=["from", "destination", "flightType", "agency"],
        drop_first=False,
    )
    return X_encoded, y


def evaluate(y_true, y_pred) -> dict:
    return {
        "rmse": float(sqrt(mean_squared_error(y_true, y_pred))),
        "mae": float(mean_absolute_error(y_true, y_pred)),
        "r2": float(r2_score(y_true, y_pred)),
    }


def main() -> None:
    print("Loading dataset...")
    df = load_and_engineer(DATA_PATH)
    print(f"  rows={len(df):,}, columns={df.shape[1]}")

    X_encoded, y = build_feature_matrix(df)
    print(f"  feature matrix shape: {X_encoded.shape}")

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_encoded)

    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42
    )

    candidates = {
        "LinearRegression": LinearRegression(),
        "DecisionTreeRegressor": DecisionTreeRegressor(max_depth=12, random_state=42),
        "GradientBoostingRegressor": GradientBoostingRegressor(
            n_estimators=100, max_depth=4, random_state=42
        ),
        "RandomForestRegressor": RandomForestRegressor(
            n_estimators=100, max_depth=20, random_state=42, n_jobs=-1
        ),
    }

    mlflow.set_tracking_uri(MLFLOW_URI)
    mlflow.set_experiment("flight_price_prediction")

    leaderboard = []
    best_model = None
    best_score = -np.inf
    best_name = ""

    for name, estimator in candidates.items():
        print(f"\nTraining {name}...")
        with mlflow.start_run(run_name=name):
            estimator.fit(X_train, y_train)
            preds = estimator.predict(X_test)
            metrics = evaluate(y_test, preds)
            mlflow.log_params({"model": name})
            mlflow.log_metrics(metrics)
            print(
                f"  RMSE={metrics['rmse']:.2f}  MAE={metrics['mae']:.2f}  R2={metrics['r2']:.4f}"
            )
            leaderboard.append({"model": name, **metrics})

            if metrics["r2"] > best_score:
                best_score = metrics["r2"]
                best_model = estimator
                best_name = name

    print(f"\nBest model: {best_name} (R2={best_score:.4f})")

    with mlflow.start_run(run_name=f"{best_name}_registered"):
        mlflow.log_param("model", best_name)
        mlflow.log_metric("r2", best_score)
        mlflow.sklearn.log_model(
            best_model, "model", registered_model_name="flight_price_model"
        )

    feature_columns = X_encoded.columns.tolist()
    with open(BASE_DIR / "random_forest.pkl", "wb") as f:
        pickle.dump(best_model, f)
    with open(BASE_DIR / "scaling.pkl", "wb") as f:
        pickle.dump(scaler, f)
    with open(BASE_DIR / "feature_columns.json", "w", encoding="utf-8") as f:
        json.dump(feature_columns, f, indent=2)
    pd.DataFrame(leaderboard).to_csv(BASE_DIR / "model_leaderboard.csv", index=False)

    print("\nArtifacts written:")
    print("  random_forest.pkl, scaling.pkl, feature_columns.json, model_leaderboard.csv")


if __name__ == "__main__":
    main()
