"""Smoke tests for the Flask flight-price API."""

import json
import sys
from pathlib import Path

import pytest

API_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(API_DIR))

from Flight_Price import app  # noqa: E402


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health_endpoint_returns_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["status"] == "healthy"
    assert body["service"] == "flight-price-api"


def test_home_renders_form(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"Flight Price Prediction" in resp.data


def test_predict_endpoint_returns_price(client):
    payload = {
        "from_location": "Sao_Paulo (SP)",
        "destination": "Rio_de_Janeiro (RJ)",
        "flight_type": "economic",
        "agency": "CloudFy",
        "week_no": 10,
        "week_day": 3,
        "day": 15,
    }
    resp = client.post(
        "/api/predict", data=json.dumps(payload), content_type="application/json"
    )
    assert resp.status_code == 200
    body = resp.get_json()
    assert "predicted_price" in body
    assert body["predicted_price"] > 0
    assert body["currency"] == "USD"


def test_predict_missing_fields_returns_400(client):
    resp = client.post("/api/predict", json={"from_location": "Sao_Paulo (SP)"})
    assert resp.status_code == 400
    body = resp.get_json()
    assert "error" in body
