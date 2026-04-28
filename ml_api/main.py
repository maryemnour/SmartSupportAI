import os
import re
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Union, List
from classifier import IntentClassifier

# --- Embedding model (lazy-loaded singleton) ---
# Multilingual model that handles FR / AR / EN out of the box.
# 384-dim vectors -- light enough for Render free tier (~120 MB on disk).
EMBED_MODEL_NAME = os.getenv("EMBED_MODEL", "paraphrase-multilingual-MiniLM-L12-v2")
_embed_model = None  # populated on first call to _get_embed_model()


def _get_embed_model():
    """Lazy-load sentence-transformers so importing this file is cheap."""
    global _embed_model
    if _embed_model is None:
        from sentence_transformers import SentenceTransformer
        _embed_model = SentenceTransformer(EMBED_MODEL_NAME)
    return _embed_model


app = FastAPI(title="Smart Support AI -- ML Classifier + Embeddings")

_raw = os.getenv("ALLOWED_ORIGINS", "*")
_origins = [o.strip() for o in _raw.split(",")] if _raw != "*" else ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_methods=["POST", "GET", "DELETE"],
    allow_headers=["*"],
)

# --- Persistence layer -----------------------------------------------------
# Models survive process restarts by being dumped to MODELS_DIR.
# On Render's free tier the disk is ephemeral on redeploy but keeps state
# across the auto-spindown/spinup cycle (the main pain point).
# For full durability across redeploys, mount a Render Disk at this path
# and set MODELS_DIR to that mount.
MODELS_DIR = Path(os.getenv("MODELS_DIR", "/tmp/ssa_models"))
MODELS_DIR.mkdir(parents=True, exist_ok=True)

# Only allow safe characters in company_id when building file paths.
_SAFE_ID = re.compile(r"^[A-Za-z0-9_\-]+$")


def _model_path(company_id: str) -> Path:
    if not _SAFE_ID.match(company_id):
        raise HTTPException(status_code=400, detail="Invalid company_id")
    return MODELS_DIR / f"{company_id}.joblib"


# In-memory cache (fast path). Falls back to disk on miss.
classifiers: dict[str, IntentClassifier] = {}


def _get_classifier(company_id: str) -> Optional[IntentClassifier]:
    """Cache-first lookup: memory -> disk -> None."""
    clf = classifiers.get(company_id)
    if clf is not None:
        return clf
    path = _model_path(company_id)
    if path.exists():
        try:
            clf = IntentClassifier.load(str(path))
            classifiers[company_id] = clf
            return clf
        except Exception:
            return None
    return None


@app.on_event("startup")
def _warm_cache():
    """Re-hydrate every saved model at boot so /predict is hot from request #1."""
    for p in MODELS_DIR.glob("*.joblib"):
        try:
            classifiers[p.stem] = IntentClassifier.load(str(p))
        except Exception:
            pass


# --- Schemas ---------------------------------------------------------------
class TrainRequest(BaseModel):
    company_id: str
    intents: list[dict]


class PredictRequest(BaseModel):
    company_id: str
    message: str
    threshold: float = 0.3


class EmbedRequest(BaseModel):
    # Accept either a single string or a list of strings for batch embedding.
    text: Union[str, List[str]]


# --- Routes ----------------------------------------------------------------
@app.get("/health")
def health():
    return {
        "status": "ok",
        "models_loaded": len(classifiers),
        "models_on_disk": len(list(MODELS_DIR.glob("*.joblib"))),
        "embed_model": EMBED_MODEL_NAME,
        "embed_warm": _embed_model is not None,
    }


@app.post("/embed")
def embed(req: EmbedRequest):
    """Generate sentence embeddings for RAG. Returns 384-dim vectors."""
    texts = [req.text] if isinstance(req.text, str) else req.text
    if not texts or not all(isinstance(t, str) and t.strip() for t in texts):
        raise HTTPException(status_code=400, detail="Non-empty text(s) required")
    try:
        model = _get_embed_model()
        # normalize_embeddings=True so we can use cosine similarity directly.
        vectors = model.encode(texts, normalize_embeddings=True).tolist()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding failed: {e}")
    return {
        "model": EMBED_MODEL_NAME,
        "dim": len(vectors[0]) if vectors else 0,
        "embeddings": vectors,
    }


@app.post("/train")
def train(req: TrainRequest):
    if not req.intents:
        raise HTTPException(status_code=400, detail="No intents provided")
    phrases, labels = [], []
    for intent in req.intents:
        for phrase in intent.get("training_phrases", []):
            if phrase and phrase.strip():
                phrases.append(phrase.strip())
                labels.append(intent["id"])
    if len(phrases) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 training phrases")
    clf = IntentClassifier()
    result = clf.train(phrases, labels, req.intents)
    classifiers[req.company_id] = clf
    # Persist immediately so the model survives the next restart.
    try:
        clf.save(str(_model_path(req.company_id)))
        persisted = True
    except Exception:
        persisted = False
    return {
        "success": True,
        "company_id": req.company_id,
        "phrases_count": len(phrases),
        "intents_count": len(req.intents),
        "accuracy": result["accuracy"],
        "persisted": persisted,
    }


@app.post("/predict")
def predict(req: PredictRequest):
    clf = _get_classifier(req.company_id)
    if not clf:
        return {
            "matched": False,
            "intent_id": None,
            "intent_name": None,
            "response": None,
            "confidence": 0.0,
            "strategy": "ml_classifier",
        }
    result = clf.predict(req.message, threshold=req.threshold)
    result["strategy"] = "ml_classifier"
    return result


@app.get("/model/{company_id}")
def model_info(company_id: str):
    clf = _get_classifier(company_id)
    if not clf:
        raise HTTPException(status_code=404, detail="No model found")
    return clf.info()


@app.delete("/model/{company_id}")
def delete_model(company_id: str):
    """Remove a tenant's model from both memory and disk."""
    classifiers.pop(company_id, None)
    path = _model_path(company_id)
    if path.exists():
        path.unlink()
        return {"deleted": True, "company_id": company_id}
    return {"deleted": False, "company_id": company_id}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
