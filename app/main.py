import os
import joblib
import boto3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="E-commerce Recommendation Service")

MODEL_PATH = "/tmp/model.joblib"
S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY", "recommendation/model.joblib")

def download_model():
    s3 = boto3.client(
        "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_REGION", "eu-west-1")
    )
    s3.download_file(S3_BUCKET, S3_KEY, MODEL_PATH)

model = None

@app.on_event("startup")
def load_model_on_startup():
    global model
    try:
        download_model()
        model = joblib.load(MODEL_PATH)
    except Exception as e:
        print(f"Errore caricamento modello da S3: {e}")

class RecommendRequest(BaseModel):
    user_features: list[float]

@app.get("/healthz")
def health():
    return {"status": "ok", "model_loaded": model is not None}

@app.post("/recommend")
def predict(req: RecommendRequest):
    global model
    if not model:
        try:
            download_model()
            model = joblib.load(MODEL_PATH)
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Modello non disponibile: {str(e)}")
    
    preds = model.predict([req.user_features])
    return {"recommended_product_ids": preds.tolist()}