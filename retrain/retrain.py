import os
import joblib
import boto3
import numpy as np
from sklearn.neighbors import NearestNeighbors

S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY", "recommendation/model.joblib")
LOCAL_MODEL_PATH = "/tmp/model.joblib"

def train_and_upload():
    # Simulazione dati e-commerce
    X = np.random.rand(100, 5)
    
    # Addestramento modello ML
    model = NearestNeighbors(n_neighbors=3, algorithm='ball_tree')
    model.fit(X)

    # Salvataggio e caricamento su S3
    joblib.dump(model, LOCAL_MODEL_PATH)

    s3 = boto3.client(
        "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_REGION", "eu-west-1")
    )
    s3.upload_file(LOCAL_MODEL_PATH, S3_BUCKET, S3_KEY)
    print("Retraining completato. Nuovo modello caricato con successo su S3.")

if __name__ == "__main__":
    train_and_upload()