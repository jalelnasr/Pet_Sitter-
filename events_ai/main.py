import os
import json
import re
from pathlib import Path
from typing import List, Optional

try:
    from dotenv import load_dotenv
    env_file = Path(__file__).resolve().parent / ".env"
    load_dotenv(dotenv_path=env_file)
    load_dotenv()
except ImportError:
    pass

try:
    import httpx
except ImportError:
    httpx = None

from fastapi import FastAPI
from pydantic import BaseModel, Field

def get_groq_api_key() -> str:
    return os.getenv("GROQ_API_KEY", "").strip()

app = FastAPI(title="Events AI Assistant")

class SuggestRequest(BaseModel):
    title: str
    keywords: Optional[List[str]] = None
    category: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None

class SuggestResponse(BaseModel):
    titles: List[str] = Field(..., description="3 catchy titles")
    description: str = Field(..., description="3-5 sentences, warm tone")
    summary: str = Field(..., description="1 line, max 120 chars")
    tags: List[str] = Field(..., description="3-6 tags")
    checklist: List[str] = Field(..., description="4-6 items matériel à prévoir")
    suggestedCategory: str = Field(..., description="One of: Adoption, Éducation, Rencontre, Bien-être, Promenade")
    tip: str = Field(..., description="Capacity or organization advice")
    source: str = Field(..., description="'llm' or 'fallback'")

VALID_CATEGORIES = ["Adoption", "Éducation", "Rencontre", "Bien-être", "Promenade"]

CATEGORY_CHECKLISTS = {
    "Adoption": [
        "Gamelles d'eau fraîche",
        "Dossiers d'adoption et formulaires",
        "Laisses et harnais de sécurité",
        "Friandises et jouets d'accueil",
        "Kit de premiers secours vétérinaire"
    ],
    "Éducation": [
        "Friandises appétentes de récompense",
        "Saccoche à friandises et clicker",
        "Longes d'éducation (5-10m)",
        "Tapis de repos pour chaque chien",
        "Gamelles d'eau individuelles"
    ],
    "Rencontre": [
        "Gamelles d'eau partagées et bouteilles",
        "Sacs à déjections canines",
        "Jouets d'interaction adaptés",
        "Trousse de premiers secours",
        "Badges nominatifs pour les propriétaires"
    ],
    "Bien-être": [
        "Brosses et serviettes douces",
        "Tapis confortables et coussins",
        "Espace calme et ombragé",
        "Diffuseurs ou sprays apaisants naturels",
        "Eau fraîche à volonté"
    ],
    "Promenade": [
        "Laisses solides et colliers ajustés",
        "Gourdes de voyage et gamelles pliables",
        "Sacs à déjections en quantité",
        "Gilets fluorescents ou foulards repères",
        "Trousse de secours pour pattes et coussinets"
    ]
}

CATEGORY_TIPS = {
    "Adoption": "Limitez à 15 participants simultanés pour ne pas stresser les animaux candidats.",
    "Éducation": "Prévoyez un espace de 3 à 5 mètres entre chaque binôme maître-chien pour favoriser la concentration.",
    "Rencontre": "Favorisez un terrain clos et prévoyez une zone de décompression pour les chiens timides.",
    "Bien-être": "Maintenez un volume sonore bas et une température ambiante agréable tout au long de la session.",
    "Promenade": "Vérifiez la météo avant le départ et prévoyez une pause boisson toutes les 20 minutes."
}

def clean_json_response(raw_text: str) -> str:
    cleaned = raw_text.strip()
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", cleaned, re.DOTALL)
    if match:
        return match.group(1).strip()
    match_braces = re.search(r"(\{.*\})", cleaned, re.DOTALL)
    if match_braces:
        return match_braces.group(1).strip()
    return cleaned

async def call_llm(req: SuggestRequest) -> SuggestResponse:
    if httpx is None:
        raise RuntimeError("httpx not installed")
    api_key = get_groq_api_key()
    if not api_key:
        raise RuntimeError("GROQ_API_KEY not configured")

    location_str = f" à {req.location}" if req.location else " en Tunisie"
    keywords_str = f", mots-clés: {', '.join(req.keywords)}" if req.keywords else ""
    cat_str = f", catégorie actuelle: {req.category}" if req.category else ""
    desc_str = f", description préliminaire: {req.description}" if req.description else ""

    prompt = (
        "Tu es un assistant expert pour l'organisation d'événements animaliers sur l'application mobile Pet Sitter en Tunisie.\n"
        f"Génère une proposition complète pour l'événement suivant:\n"
        f"Titre de travail: {req.title}{location_str}{keywords_str}{cat_str}{desc_str}\n\n"
        "Réponds STRICTEMENT avec un objet JSON valide sans aucun texte avant ni après, respectant ce schéma exact:\n"
        "{\n"
        '  "titles": ["Titre accrocheur 1", "Titre accrocheur 2", "Titre accrocheur 3"],\n'
        '  "description": "Texte chaleureux et engageant de 3 à 5 phrases décrivant l\'événement.",\n'
        '  "summary": "Résumé en une ligne percutante de 120 caractères maximum.",\n'
        '  "tags": ["tag1", "tag2", "tag3", "tag4"],\n'
        '  "checklist": ["Élément 1", "Élément 2", "Élément 3", "Élément 4", "Élément 5"],\n'
        '  "suggestedCategory": "Une seule parmi: Adoption, Éducation, Rencontre, Bien-être, Promenade",\n'
        '  "tip": "Un conseil pertinent d\'organisation ou de capacité d\'accueil."\n'
        "}"
    )

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {
                "role": "system",
                "content": "Tu es un assistant bienveillant et professionnel pour Pet Sitter Tunisie. Tu réponds exclusivement en JSON valide."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0.6
    }

    async with httpx.AsyncClient(timeout=15.0) as client:
        resp = await client.post("https://api.groq.com/openai/v1/chat/completions", json=payload, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        raw_content = data["choices"][0]["message"]["content"]
        json_str = clean_json_response(raw_content)
        parsed = json.loads(json_str)

        # Validate category
        suggested_cat = parsed.get("suggestedCategory", "Rencontre")
        if suggested_cat not in VALID_CATEGORIES:
            suggested_cat = req.category if req.category in VALID_CATEGORIES else "Rencontre"
            parsed["suggestedCategory"] = suggested_cat

        # Truncate summary if too long
        if "summary" in parsed and len(parsed["summary"]) > 120:
            parsed["summary"] = parsed["summary"][:117] + "..."

        parsed["source"] = "llm"
        return SuggestResponse(**parsed)

def fallback_response(req: SuggestRequest) -> SuggestResponse:
    title = req.title.strip() if req.title else "Événement Pet Sitter"
    loc = f" à {req.location}" if req.location else ""
    
    # Determine best category
    cat = req.category if req.category in VALID_CATEGORIES else "Rencontre"
    title_lower = title.lower()
    if "adopt" in title_lower:
        cat = "Adoption"
    elif "éduc" in title_lower or "dress" in title_lower or "train" in title_lower:
        cat = "Éducation"
    elif "balad" in title_lower or "promenad" in title_lower or "marche" in title_lower:
        cat = "Promenade"
    elif "soin" in title_lower or "sant" in title_lower or "bien" in title_lower:
        cat = "Bien-être"

    titles = [
        f"Grand rassemblement : {title}{loc}",
        f"{title} – Moments complices avec nos compagnons",
        f"Atelier convivial : {title}"
    ]

    description = (
        f"Rejoignez-nous pour {title.lower()}{loc} ! "
        f"Un rendez-vous pensé spécialement pour nos fidèles boules de poils et leurs propriétaires passionnés. "
        f"Profitez d'un moment chaleureux de partage, d'échanges de conseils et de jeux en toute sécurité. "
        f"Nous avons hâte de vous retrouver nombreux avec vos animaux !"
    )

    summary = f"Rejoignez notre événement {title.lower()}{loc} pour un moment de partage inoubliable."
    if len(summary) > 120:
        summary = summary[:117] + "..."

    raw_tags = ["petsitter", "animaux", cat.lower()]
    if req.keywords:
        raw_tags.extend([k.strip().lower() for k in req.keywords if k.strip()])
    if req.location:
        raw_tags.append(req.location.strip().lower().replace(" ", ""))
    
    unique_tags = []
    for t in raw_tags:
        if t and t not in unique_tags:
            unique_tags.append(t)
    tags = unique_tags[:5]
    if len(tags) < 3:
        tags.extend(["tunisie", "partage", "bienetre"])
        tags = tags[:4]

    checklist = CATEGORY_CHECKLISTS.get(cat, CATEGORY_CHECKLISTS["Rencontre"])
    tip = CATEGORY_TIPS.get(cat, "Pensez à prévoir un espace d'accueil calme et un point d'eau accessible.")

    return SuggestResponse(
        titles=titles,
        description=description,
        summary=summary,
        tags=tags,
        checklist=checklist,
        suggestedCategory=cat,
        tip=tip,
        source="fallback"
    )

@app.post("/suggest", response_model=SuggestResponse)
async def suggest(req: SuggestRequest):
    try:
        return await call_llm(req)
    except Exception:
        return fallback_response(req)

@app.get("/")
def root():
    return {
        "service": "Events AI Assistant",
        "status": "UP",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
def health():
    return {"status": "UP"}
