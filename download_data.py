"""Download the weatherAUS dataset to data/weatherAUS.csv (only needed if the file is missing)."""
from pathlib import Path
from urllib.request import urlretrieve

DATA_URL = ("https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/"
            "_0eYOqji3unP1tDNKWZMjg/weatherAUS-2.csv")
DATA_PATH = Path("data/weatherAUS.csv")

if __name__ == "__main__":
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DATA_PATH.exists():
        print(f"{DATA_PATH} already exists, nothing to do.")
    else:
        print(f"Downloading dataset to {DATA_PATH} ...")
        urlretrieve(DATA_URL, DATA_PATH)
        print("Done.")
