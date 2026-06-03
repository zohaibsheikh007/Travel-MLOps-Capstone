"""Train the gender classification model and persist artifacts."""

import pickle
from pathlib import Path

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder, StandardScaler

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "users.csv"


def main() -> None:
    df = pd.read_csv(DATA_PATH)
    df["gender_label"] = (df["gender"].str.lower() == "male").astype(int)

    X = df[["name", "company", "age", "code"]].copy()
    y = df["gender_label"]

    company_encoder = LabelEncoder()
    X["company_encoded"] = company_encoder.fit_transform(X["company"])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    preprocess = ColumnTransformer(
        transformers=[
            (
                "name_tfidf",
                TfidfVectorizer(max_features=200, ngram_range=(1, 3), analyzer="char_wb"),
                "name",
            ),
            ("numeric", StandardScaler(), ["age", "code", "company_encoded"]),
        ]
    )

    pipe = Pipeline(
        [
            ("features", preprocess),
            ("clf", LogisticRegression(max_iter=1000, random_state=42)),
        ]
    )
    grid = {"clf__C": [0.1, 1.0, 5.0]}
    search = GridSearchCV(pipe, grid, cv=3, scoring="roc_auc", n_jobs=-1)
    search.fit(X_train, y_train)

    best = search.best_estimator_
    pred = best.predict(X_test)
    proba = best.predict_proba(X_test)[:, 1]
    print(f"Best params : {search.best_params_}")
    print(f"Test accuracy: {accuracy_score(y_test, pred):.4f}")
    print(f"Test AUC     : {roc_auc_score(y_test, proba):.4f}")
    print(classification_report(y_test, pred, target_names=["Female", "Male"]))

    with open(BASE_DIR / "gender_model.pkl", "wb") as f:
        pickle.dump(best, f)
    with open(BASE_DIR / "company_encoder.pkl", "wb") as f:
        pickle.dump(company_encoder, f)
    print("Artifacts saved.")


if __name__ == "__main__":
    main()
