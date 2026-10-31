# Adoption matching (offline)

Local FastAPI service. It embeds the listing profile and the candidate profile
with `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` and returns a
cosine-similarity score. No cloud AI, no API key, no Ollama.

The model is **downloaded into the Hugging Face cache on first startup**. Do not
commit model weights.

## Setup (Windows)

```powershell
cd adoption_ai
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

First start can take several minutes while the model downloads. Later starts
reuse the cache.

- Health: `http://localhost:8000/health`
- Match: `POST http://localhost:8000/match`

Spring Boot (`:8081`) calls this service. Flutter never talks to port 8000.

## Tests (no model download)

```powershell
cd adoption_ai
.\.venv\Scripts\activate
pytest -q
```
