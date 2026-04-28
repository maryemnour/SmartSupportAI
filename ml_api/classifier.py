import re
import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import cross_val_score


class IntentClassifier:
    def __init__(self):
        self.pipeline = None
        self.encoder = None
        self.intents = {}
        self.trained = False
        self.n_phrases = 0
        self.n_intents = 0
        self.accuracy = 0.0

    # --- Persistence -------------------------------------------------------
    def save(self, path: str) -> None:
        """Dump the trained classifier to disk so it survives process restarts."""
        if not self.trained:
            raise RuntimeError("Cannot save an untrained classifier")
        joblib.dump({
            'pipeline':  self.pipeline,
            'encoder':   self.encoder,
            'intents':   self.intents,
            'n_phrases': self.n_phrases,
            'n_intents': self.n_intents,
            'accuracy':  self.accuracy,
        }, path)

    @classmethod
    def load(cls, path: str) -> 'IntentClassifier':
        """Restore a previously saved classifier from disk."""
        data = joblib.load(path)
        clf = cls()
        clf.pipeline = data['pipeline']
        clf.encoder = data['encoder']
        clf.intents = data['intents']
        clf.n_phrases = data['n_phrases']
        clf.n_intents = data['n_intents']
        clf.accuracy = data['accuracy']
        clf.trained = True
        return clf

    # --- Train -------------------------------------------------------------
    def train(self, phrases, labels, intents_data):
        self.intents = {
            i['id']: {'name': i.get('name', ''), 'response': i.get('response', '')}
            for i in intents_data
        }
        normalized = [self._normalize(p) for p in phrases]
        self.encoder = LabelEncoder()
        y = self.encoder.fit_transform(labels)
        self.pipeline = Pipeline([
            ('tfidf', TfidfVectorizer(ngram_range=(1, 2), min_df=1, max_features=5000, sublinear_tf=True)),
            ('clf',   MultinomialNB(alpha=0.1)),
        ])
        # Use cross-validation only when there are enough samples;
        # fall back to train accuracy otherwise.
        if len(phrases) >= 5 and len(set(labels)) >= 2:
            cv_folds = min(3, len(phrases) // max(len(set(labels)), 1))
            if cv_folds >= 2:
                scores = cross_val_score(self.pipeline, normalized, y, cv=cv_folds, scoring='accuracy')
                self.accuracy = round(float(scores.mean()), 4)
            else:
                self.pipeline.fit(normalized, y)
                preds = self.pipeline.predict(normalized)
                self.accuracy = round(float(np.mean(preds == y)), 4)
        else:
            self.pipeline.fit(normalized, y)
            preds = self.pipeline.predict(normalized)
            self.accuracy = round(float(np.mean(preds == y)), 4)

        self.pipeline.fit(normalized, y)
        self.trained = True
        self.n_phrases = len(phrases)
        self.n_intents = len(self.intents)
        return {'classes': list(self.encoder.classes_), 'accuracy': self.accuracy}

    # --- Predict -----------------------------------------------------------
    def predict(self, message, threshold=0.3):
        if not self.trained:
            return self._no_match(0.0)
        norm = self._normalize(message)
        if not norm.strip():
            return self._no_match(0.0)
        proba = self.pipeline.predict_proba([norm])[0]
        best_idx = int(np.argmax(proba))
        confidence = float(proba[best_idx])
        if confidence < threshold:
            return self._no_match(confidence)
        intent_id = self.encoder.inverse_transform([best_idx])[0]
        intent = self.intents.get(intent_id, {})
        return {
            'matched': True,
            'intent_id': intent_id,
            'intent_name': intent.get('name', ''),
            'response': intent.get('response', ''),
            'confidence': round(confidence, 4),
        }

    def info(self):
        return {
            'trained': self.trained,
            'n_phrases': self.n_phrases,
            'n_intents': self.n_intents,
            'accuracy': self.accuracy,
        }

    def _normalize(self, text):
        return re.sub(r'\s+', ' ', re.sub(r'[^\w\s]', ' ', text.lower().strip())).strip()

    def _no_match(self, confidence):
        return {
            'matched': False,
            'intent_id': None,
            'intent_name': None,
            'response': None,
            'confidence': confidence,
        }
