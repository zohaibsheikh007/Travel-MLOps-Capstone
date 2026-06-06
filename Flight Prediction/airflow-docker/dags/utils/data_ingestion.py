import pandas as pd


class DataLoader:
    def __init__(self, filepath: str):
        self.filepath = filepath

    def load_data(self) -> pd.DataFrame:
        data = pd.read_csv(self.filepath)
        return data
