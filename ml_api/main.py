from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from classifier import IntentClassifier

app = FastAPI(title="Smart Support AI — ML Classifier")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

classifiers: dict[str, IntentClassifier] = {}

class TrainRequest(BaseModel):
    company_id: str
    intents: list[dict]

class PredictRequest(BaseModel):
    company_id: str
    message: str
    threshold: float = 0.3

@app.get("/health")
def health():
    return {"status": "ok", "models_loaded": len(classifiers)}

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
    return {"success": True, "company_id": req.company_id, "phrases_count": len(phrases), "intents_count": len(req.intents), "accuracy": result["accuracy"]}

@app.post("/predict")
def predict(req: PredictRequest):
    clf = classifiers.get(req.company_id)
    if not clf:
        return {"matched": False, "intent_id": None, "intent_name": None, "response": None, "confidence": 0.0, "strategy": "ml_classifier"}
    result = clf.predict(req.message, threshold=req.threshold)
    result["strategy"] = "ml_classifier"
    return result

@app.get("/model/{company_id}")
def model_info(company_id: str):
    clf = classifiers.get(company_id)
    if not clf:
        raise HTTPException(status_code=404, detail="No model found")
    return clf.info()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
