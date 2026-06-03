"""Streamlit app for gender classification."""

import pickle
from pathlib import Path

import pandas as pd
import streamlit as st

BASE_DIR = Path(__file__).resolve().parent

pipeline = pickle.load(open(BASE_DIR / "gender_model.pkl", "rb"))
company_encoder = pickle.load(open(BASE_DIR / "company_encoder.pkl", "rb"))

st.set_page_config(page_title="Gender Classification", page_icon="✈️", layout="centered")
st.title("Travel User Gender Classification")
st.write("Predict traveler gender from profile attributes using a trained classification model.")

name = st.text_input("User Name", "Charlotte Johnson")
usercode = st.number_input("User Code", min_value=0, max_value=1339, value=100, step=1)
age = st.number_input("Age", min_value=18, max_value=80, value=35, step=1)
company = st.selectbox(
    "Company",
    ["Acme Factory", "Wonka Company", "Monsters CYA", "Umbrella LTDA", "4You"],
)

if st.button("Predict Gender"):
    input_df = pd.DataFrame(
        [
            {
                "name": name,
                "company": company,
                "age": age,
                "code": usercode,
                "company_encoded": company_encoder.transform([company])[0],
            }
        ]
    )
    prediction = pipeline.predict(input_df)[0]
    gender = "Male" if prediction == 1 else "Female"
    st.success(f"Predicted Gender: **{gender}**")

st.markdown("---")
st.caption("Model: Logistic Regression with TF-IDF name features and company encoding.")
