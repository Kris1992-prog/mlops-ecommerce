import os
import logging
import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM Gateway")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama.ml.svc.cluster.local:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "phi3:mini")
OLLAMA_TIMEOUT = float(os.getenv("OLLAMA_TIMEOUT", "60"))


class ChatRequest(BaseModel):
    product_id: int
    product_name: str
    product_description: str
    question: str


class ChatResponse(BaseModel):
    product_id: int
    answer: str
    model: str


def _build_prompt(req: ChatRequest) -> str:
    return (
        f"Sei un assistente e-commerce esperto.\n"
        f"Prodotto: {req.product_name} (ID: {req.product_id})\n"
        f"Descrizione: {req.product_description}\n\n"
        f"Domanda del cliente: {req.question}\n\n"
        f"Rispondi in modo conciso e utile."
    )


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{OLLAMA_URL}/api/tags")
            resp.raise_for_status()
        return {"status": "ready", "ollama": "up"}
    except Exception:
        raise HTTPException(status_code=503, detail="Ollama not reachable")


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    prompt = _build_prompt(req)
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
    }
    try:
        async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
            resp = await client.post(f"{OLLAMA_URL}/api/generate", json=payload)
            resp.raise_for_status()
    except httpx.TimeoutException:
        logger.error("Ollama timeout after %ss", OLLAMA_TIMEOUT)
        raise HTTPException(status_code=503, detail="Ollama timeout")
    except Exception as e:
        logger.error("Ollama unreachable: %s", e)
        raise HTTPException(status_code=503, detail="Ollama not reachable")

    answer = resp.json().get("response", "").strip()
    return ChatResponse(product_id=req.product_id, answer=answer, model=OLLAMA_MODEL)
