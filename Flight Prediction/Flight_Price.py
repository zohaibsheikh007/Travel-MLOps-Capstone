"""Flask REST API for real-time flight price prediction."""

import json
import pickle
from pathlib import Path

import numpy as np
import pandas as pd
from flask import Flask, jsonify, render_template_string, request
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent

model = pickle.load(open(BASE_DIR / "random_forest.pkl", "rb"))
scaler = pickle.load(open(BASE_DIR / "scaling.pkl", "rb"))
with open(BASE_DIR / "feature_columns.json", "r", encoding="utf-8") as f:
    FEATURE_COLUMNS = json.load(f)

LOCATIONS = [
    "Florianopolis (SC)",
    "Sao_Paulo (SP)",
    "Salvador (BH)",
    "Brasilia (DF)",
    "Rio_de_Janeiro (RJ)",
    "Campo_Grande (MS)",
    "Aracaju (SE)",
    "Natal (RN)",
    "Recife (PE)",
]

app = Flask(__name__)
CORS(app)

HTML_FORM = """
<!DOCTYPE html>
<html>
<head>
    <title>TravelWise Flight Price Prediction</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 40px auto; }
        label { display: block; margin-top: 12px; font-weight: bold; }
        select, input, button { width: 100%; padding: 8px; margin-top: 4px; }
        button { background: #2563eb; color: white; border: none; cursor: pointer; margin-top: 16px; }
        .result { margin-top: 20px; padding: 12px; background: #ecfdf5; border-radius: 6px; }
    </style>
</head>
<body>
    <h2>Flight Price Prediction API</h2>
    <p>Enter flight details to get a predicted price.</p>
    <form action="/predict" method="post">
        <label>Origin</label>
        <select name="from_location">
            {% for loc in locations %}
            <option value="{{ loc }}">{{ loc.replace('_', ' ') }}</option>
            {% endfor %}
        </select>

        <label>Destination</label>
        <select name="destination">
            {% for loc in locations %}
            <option value="{{ loc }}">{{ loc.replace('_', ' ') }}</option>
            {% endfor %}
        </select>

        <label>Flight Type</label>
        <select name="flight_type">
            <option value="economic">Economic</option>
            <option value="firstClass">First Class</option>
            <option value="premium">Premium</option>
        </select>

        <label>Agency</label>
        <select name="agency">
            <option value="Rainbow">Rainbow</option>
            <option value="CloudFy">CloudFy</option>
            <option value="FlyingDrops">FlyingDrops</option>
        </select>

        <label>Week Number (1-52)</label>
        <input type="number" name="week_no" min="1" max="52" value="10" required>

        <label>Week Day (1-7)</label>
        <input type="number" name="week_day" min="1" max="7" value="3" required>

        <label>Day of Month (1-31)</label>
        <input type="number" name="day" min="1" max="31" value="15" required>

        <button type="submit">Predict Price</button>
    </form>
    {% if price %}
    <div class="result"><h3>Predicted Flight Price: ${{ price }}</h3></div>
    {% endif %}
</body>
</html>
"""


def build_feature_vector(payload: dict) -> np.ndarray:
    """Convert user input into model-ready feature vector."""
    row = {col: 0 for col in FEATURE_COLUMNS}

    from_key = f"from_{payload['from_location']}"
    to_key = f"destination_{payload['destination']}"
    flight_key = f"flightType_{payload['flight_type']}"
    agency_key = f"agency_{payload['agency']}"

    for key in [from_key, to_key, flight_key, agency_key]:
        if key in row:
            row[key] = 1

    row["week_no"] = float(payload["week_no"])
    row["week_day"] = float(payload["week_day"])
    row["day"] = float(payload["day"])

    df = pd.DataFrame([row], columns=FEATURE_COLUMNS)
    return scaler.transform(df)


@app.route("/")
def home():
    return render_template_string(HTML_FORM, locations=LOCATIONS)


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "flight-price-api"})


@app.route("/predict", methods=["POST"])
def predict_form():
    try:
        form_data = request.form.to_dict()
        features = build_feature_vector(form_data)
        prediction = float(model.predict(features)[0])
        return render_template_string(
            HTML_FORM,
            locations=LOCATIONS,
            price=round(prediction, 2),
        )
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.route("/api/predict", methods=["POST"])
def predict_api():
    """REST endpoint for JSON-based predictions."""
    try:
        payload = request.get_json(force=True)
        required = ["from_location", "destination", "flight_type", "agency", "week_no", "week_day", "day"]
        missing = [field for field in required if field not in payload]
        if missing:
            return jsonify({"error": f"Missing fields: {missing}"}), 400

        features = build_feature_vector(payload)
        prediction = float(model.predict(features)[0])
        return jsonify({"predicted_price": round(prediction, 2), "currency": "USD"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=8000)
