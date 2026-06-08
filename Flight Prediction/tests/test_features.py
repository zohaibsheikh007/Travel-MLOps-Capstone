"""Unit tests for the feature engineering pipeline."""

import sys
from pathlib import Path

import pandas as pd

API_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(API_DIR))

from train_model import build_feature_matrix, load_and_engineer  # noqa: E402


def test_load_and_engineer_creates_date_features(tmp_path):
    csv = tmp_path / "flights.csv"
    csv.write_text(
        "travelCode,userCode,from,to,flightType,price,time,distance,agency,date\n"
        "0,0,Sao_Paulo (SP),Recife (PE),economic,500.0,1.5,500,CloudFy,03/15/2024\n"
    )
    df = load_and_engineer(csv)
    assert "week_no" in df.columns
    assert "week_day" in df.columns
    assert "day" in df.columns
    assert df["day"].iloc[0] == 15


def test_build_feature_matrix_drops_identifiers():
    df = pd.DataFrame(
        {
            "travelCode": [1],
            "userCode": [2],
            "from": ["Sao_Paulo (SP)"],
            "to": ["Recife (PE)"],
            "flightType": ["economic"],
            "agency": ["CloudFy"],
            "price": [500.0],
            "time": [1.5],
            "distance": [500],
            "date": pd.to_datetime(["2024-03-15"]),
            "week_no": [11],
            "week_day": [5],
            "day": [15],
            "month": [3],
        }
    )
    X, y = build_feature_matrix(df)
    assert "travelCode" not in X.columns
    assert "userCode" not in X.columns
    assert "price" not in X.columns
    assert y.iloc[0] == 500.0
    assert any(c.startswith("from_") for c in X.columns)
