import os
import logging
import joblib
import boto3
import httpx
from typing import List, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="E-commerce Recommendation Service")

S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY", "model.joblib")
AWS_REGION = os.getenv("AWS_REGION", "eu-south-1")
MODEL_PATH = "/tmp/model.joblib"

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama.ml.svc.cluster.local:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:0.5b")
OLLAMA_TIMEOUT = float(os.getenv("OLLAMA_TIMEOUT", "30.0"))

model = None
product_ids: List[int] = []


class RecommendRequest(BaseModel):
    product_id: int
    n: int = 5


class RecommendResponse(BaseModel):
    product_id: int
    recommendations: List[int]
    source: str
    marketing_copy: Optional[str] = None


def _load_from_s3() -> None:
    global model, product_ids
    logger.info("Downloading model from s3://%s/%s", S3_BUCKET, S3_KEY)
    s3 = boto3.client("s3", region_name=AWS_REGION)
    s3.download_file(S3_BUCKET, S3_KEY, MODEL_PATH)
    
    artifact = joblib.load(MODEL_PATH)
    
    # Gestione flessibile sia per dummy model che per dizionari strutturati
    if isinstance(artifact, dict):
        model = artifact.get("model", artifact)
        product_ids = artifact.get("product_ids", [1, 2, 3, 4, 5])
    else:
        model = artifact
        product_ids = [1, 2, 3, 4, 5]

    logger.info("Model loaded — %d products indexed", len(product_ids))


def _generate_marketing_copy(product_id: int, recs: List[int]) -> Optional[str]:
    prompt = (
        f"L'utente ha mostrato interesse per il prodotto ID {product_id}. "
        f"Il sistema di raccomandazione ha selezionato i seguenti prodotti correlati: {recs}. "
        f"Scrivi una breve, accattivante e concisa motivazione commerciale in italiano (massimo 2 frasi) "
        f"per spiegare perché questi prodotti fanno al caso suo."
    )
    try:
        response = httpx.post(
            f"{OLLAMA_URL}/api/generate",
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "keep_alive": "-1",  # Mantiene il modello residente in RAM
            },
            timeout=OLLAMA_TIMEOUT,
        )
        if response.status_code == 200:
            return response.json().get("response", "").strip()
        logger.error("Ollama returned status code %d", response.status_code)
    except Exception as e:
        logger.error("Failed to connect to Ollama service: %s", e)
    return None


@app.on_event("startup")
def load_model_on_startup() -> None:
    try:
        _load_from_s3()
    except Exception as e:
        logger.error("Model load failed at startup: %s", e)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    if model is None:
        raise HTTPException(status_code=503, detail="Model not ready")
    return {"status": "ready", "model_loaded": True}


@app.post("/recommend", response_model=RecommendResponse)
def recommend(req: RecommendRequest):
    if model is None:
        raise HTTPException(status_code=503, detail="Model not ready")
    try:
        idx = product_ids.index(req.product_id)
    except ValueError:
        raise HTTPException(status_code=404, detail=f"product_id {req.product_id} not found")

    if hasattr(model, "kneighbors"):
        distances, indices = model.kneighbors([[idx]], n_neighbors=req.n + 1)
        recs = [product_ids[i] for i in indices[0] if product_ids[i] != req.product_id][: req.n]
    else:
        recs = [pid for pid in product_ids if pid != req.product_id][: req.n]

    marketing_copy = _generate_marketing_copy(req.product_id, recs)

    return RecommendResponse(
        product_id=req.product_id,
        recommendations=recs,
        source="s3",
        marketing_copy=marketing_copy,
    )


@app.post("/reload")
def reload_model():
    try:
        _load_from_s3()
        return {"status": "reloaded", "products": len(product_ids)}
    except Exception as e:
        logger.error("Reload failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))
