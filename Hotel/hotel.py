"""Streamlit hotel recommendation app using collaborative filtering."""

import warnings

import numpy as np
import pandas as pd
import streamlit as st
from scipy.sparse.linalg import svds
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

warnings.filterwarnings("ignore")

st.set_page_config(page_title="Hotel Recommendations", page_icon="🏨", layout="wide")
st.title("Travel Hotel Recommendation System")
st.write("Personalized hotel suggestions based on user booking history.")

file_path = "hotels.csv"


@st.cache_data
def load_data(path: str):
    return pd.read_csv(path)


def preprocess_data(df: pd.DataFrame):
    interactions_count = df.groupby("userCode")["name"].count()
    active_users = interactions_count[interactions_count >= 2].index
    filtered_df = df[df["userCode"].isin(active_users)].copy()

    label_encoder = LabelEncoder()
    filtered_df["name_encoded"] = label_encoder.fit_transform(filtered_df["name"])
    return filtered_df, label_encoder


class CFRecommender:
    def __init__(self, data: pd.DataFrame, factors: int = 8):
        self.data = data
        self.factors = factors
        self.cf_preds_df = None
        self.label_encoder = None

    def train_model(self, label_encoder: LabelEncoder):
        self.label_encoder = label_encoder
        interactions = (
            self.data.groupby(["userCode", "name_encoded"])["price"].sum().reset_index()
        )

        train_df, _ = train_test_split(interactions, test_size=0.25, random_state=42)
        pivot = train_df.pivot(index="userCode", columns="name_encoded", values="price").fillna(0)
        pivot_matrix = pivot.values
        user_ids = list(pivot.index)

        k_factors = min(self.factors, min(pivot_matrix.shape) - 1)
        if k_factors < 1:
            return False

        U, sigma, Vt = svds(pivot_matrix, k=k_factors)
        sigma = np.diag(sigma)
        all_user_ratings = np.dot(np.dot(U, sigma), Vt)
        self.cf_preds_df = pd.DataFrame(all_user_ratings, columns=pivot.columns, index=user_ids)
        return True

    def recommend_hotels(self, user_id: int, topn: int = 5):
        if self.cf_preds_df is None or user_id not in self.cf_preds_df.index:
            return pd.DataFrame(), f"User ID {user_id} not found in recommendations."

        predictions = (
            self.cf_preds_df.loc[user_id].sort_values(ascending=False).reset_index()
        )
        predictions.columns = ["name_encoded", "recStrength"]
        predictions["name"] = self.label_encoder.inverse_transform(
            predictions["name_encoded"].astype(int)
        )
        return predictions[["name", "recStrength"]].head(topn), None


hotel_df = load_data(file_path)
if hotel_df is None:
    st.stop()

filtered_df, label_encoder = preprocess_data(hotel_df)
recommender = CFRecommender(filtered_df)
trained = recommender.train_model(label_encoder)

if not trained:
    st.error("Not enough data to train the recommendation model.")
    st.stop()

col1, col2 = st.columns([1, 2])
with col1:
    user_list = sorted(filtered_df["userCode"].unique())
    selected_user = st.selectbox("Select User ID", user_list)
    top_n = st.slider("Number of recommendations", 3, 10, 5)

    if st.button("Get Recommendations"):
        recommendations, error = recommender.recommend_hotels(selected_user, top_n)
        if error:
            st.warning(error)
        elif recommendations.empty:
            st.warning("No recommendations found.")
        else:
            st.success("Recommended Hotels")
            recommendations["recStrength"] = recommendations["recStrength"].round(2)
            st.dataframe(recommendations, use_container_width=True)

with col2:
    st.subheader("Dataset Overview")
    st.dataframe(hotel_df.head(20), use_container_width=True)
    st.metric("Total Bookings", len(hotel_df))
    st.metric("Active Users", filtered_df["userCode"].nunique())
    st.metric("Unique Hotels", hotel_df["name"].nunique())
