import pandas as pd
from sklearn.preprocessing import StandardScaler


class DataTransformer:
    def __init__(self, data: pd.DataFrame):
        self.original_data = data.copy()
        self.scaler = StandardScaler()
        self.fitted_columns = None

    def fit_transform(self):
        data = self.original_data.copy()
        data["date"] = pd.to_datetime(data["date"], format="%m/%d/%Y")
        data["week_no"] = data["date"].dt.isocalendar().week.astype(int)
        data["week_day"] = data["date"].dt.dayofweek + 1
        data["day"] = data["date"].dt.day

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

        self.fitted_columns = X_encoded.columns
        X_scaled = self.scaler.fit_transform(X_encoded)
        X_df = pd.DataFrame(X_scaled, columns=self.fitted_columns)
        return X_df, y
