import os
import sys
import logging
import joblib
import boto3
import numpy as np
from sklearn.neighbors import NearestNeighbors

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY", "recommendation/model.joblib")
LOCAL_MODEL_PATH = "/tmp/model.joblib"
AWS_REGION = os.getenv("AWS_REGION", "eu-west-1")


def generate_interactions(n_users=500, n_products=100, n_interactions=5000):
    """Genera dati fittizi: ogni prodotto ha un vettore di rating per utente."""
    logger.info(f"Genero {n_interactions} interazioni per {n_products} prodotti...")
    interactions = {}
    for _ in range(n_interactions):
        user_id = np.random.randint(1, n_users + 1)
        product_id = np.random.randint(1, n_products + 1)
        rating = np.random.randint(1, 6)
        interactions.setdefault(product_id, {})[user_id] = rating
    return interactions


def build_vectors(interactions, n_users=500):
    """Costruisce vettori prodotto (righe = prodotti, colonne = utenti)."""
    product_ids = sorted(interactions.keys())
    vectors = []
    for pid in product_ids:
        vec = np.zeros(n_users)
        for uid, rating in interactions[pid].items():
            if 1 <= uid <= n_users:
                vec[uid - 1] = rating
        vectors.append(vec)
    return np.array(vectors), product_ids


def train_and_upload():
    if not S3_BUCKET:
        logger.error("S3_BUCKET non configurato")
        return False

    # 1. Dati
    interactions = generate_interactions()
    vectors, product_ids = build_vectors(interactions)

    # 2. Modello
    logger.info(f"Alleno NearestNeighbors su {len(product_ids)} prodotti...")
    model = NearestNeighbors(n_neighbors=6, metric="cosine")
    model.fit(vectors)

    # 3. Salva artifact completo (coerente con l'API)
    artifact = {
        "model": model,
        "product_ids": product_ids,
        "vectors": vectors,
    }
    joblib.dump(artifact, LOCAL_MODEL_PATH)
    logger.info(f"Modello salvato: {LOCAL_MODEL_PATH}")

    # 4. Upload S3
    try:
        s3 = boto3.client("s3", region_name=AWS_REGION)
        logger.info(f"Upload su s3://{S3_BUCKET}/{S3_KEY}")
        s3.upload_file(LOCAL_MODEL_PATH, S3_BUCKET, S3_KEY)
        logger.info("Retraining completato.")
        return True
    except Exception as e:
        logger.error(f"Errore upload S3: {e}")
        return False


if __name__ == "__main__":
    success = train_and_upload()
    sys.exit(0 if success else 1)