# Events AI Service

## Description
FastAPI micro‑service that generates AI‑powered suggestions for event creation in the Pet Sitter app.

## Running locally
```powershell
# go to the folder
cd events_ai

# (optional) create a virtual env
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# install dependencies
pip install -r requirements.txt

# set the Groq API key (do NOT commit this file)
# copy .env.example → .env and edit the key
copy .env.example .env
# edit .env and replace `your_groq_api_key_here` with your real key

# start the service
uvicorn main:app --host 0.0.0.0 --port 8001
```

The service will be available at `http://localhost:8001`.

* `GET /health` – health check, returns `{"status":"UP"}`.
* `POST /suggest` – body `{title:string, keywords?:string[], category?:string, location?:string, description?:string}`.
  Returns JSON with titles, description, summary, tags, checklist, suggestedCategory, tip, and a `source` field (`"llm"` or `"fallback"`).
