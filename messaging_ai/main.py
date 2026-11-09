"""Assistant IA de la messagerie Pet Sitter (FastAPI, port 8002).

Appelé uniquement par le backend Spring Boot (jamais directement par l'application) :
- POST /analyze         : le message est-il à risque (arnaque, insulte, lien douteux, coordonnées) ?
- POST /suggest-replies : 3 réponses courtes adaptées à la conversation.

Avec GROQ_API_KEY (fichier .env), l'analyse passe par le modèle llama-3.1-8b-instant de Groq,
toujours complétée par les règles locales. Sans clé, ou si Groq ne répond pas, les règles
locales seules répondent (champ "source" = "fallback").
"""
from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI
from pydantic import BaseModel, Field

from rules import REASONS, analyze_rules, analyze_rules_detailed, build_result, suggest_rules

try:
    from dotenv import load_dotenv

    load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")
except ImportError:  # python-dotenv facultatif
    pass

try:
    import httpx
except ImportError:  # sans httpx : règles locales uniquement
    httpx = None

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")
TIMEOUT_SECONDS = float(os.getenv("MESSAGING_AI_TIMEOUT", "6"))

app = FastAPI(title="Pet Sitter — assistant de messagerie")


def groq_key() -> str:
    return os.getenv("GROQ_API_KEY", "").strip()


# ———————————————————————————————— Modèles

class AnalyzeRequest(BaseModel):
    text: str = Field(..., max_length=2000)


class AnalyzeResponse(BaseModel):
    risk: str = Field(..., description="NONE, LOW ou HIGH")
    categories: List[str]
    reason: str
    source: str = Field(..., description="'llm' ou 'fallback'")


class ChatLine(BaseModel):
    fromMe: bool
    text: str = Field(..., max_length=2000)


class SuggestRequest(BaseModel):
    messages: List[ChatLine] = Field(default_factory=list, max_length=30)
    myRole: str = "OWNER"
    otherName: Optional[str] = ""
    subject: Optional[str] = ""


class SuggestResponse(BaseModel):
    replies: List[str]
    source: str


# ———————————————————————————————— Appel Groq

def extract_json(raw: str) -> dict:
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if not match:
        raise ValueError("réponse sans JSON")
    return json.loads(match.group(0))


async def ask_groq(system: str, user: str, max_tokens: int = 300) -> dict:
    key = groq_key()
    if not key or httpx is None:
        raise RuntimeError("Groq non configuré")
    payload = {
        "model": GROQ_MODEL,
        "temperature": 0.3,
        "max_tokens": max_tokens,
        "response_format": {"type": "json_object"},
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
    }
    async with httpx.AsyncClient(timeout=TIMEOUT_SECONDS) as client:
        resp = await client.post(GROQ_URL, json=payload, headers={"Authorization": f"Bearer {key}"})
        resp.raise_for_status()
        return extract_json(resp.json()["choices"][0]["message"]["content"])


ANALYZE_PROMPT = (
    "Tu modères la messagerie d'une application tunisienne de garde d'animaux (propriétaires et pet sitters). "
    "Classe le message reçu. Catégories possibles : "
    "ARNAQUE_PAIEMENT (demande d'argent d'avance par transfert, Western Union, recharge, code ou numéro de carte), "
    "PAIEMENT_EXTERNE (paiement hors application sans signe d'arnaque : D17, virement, RIB), "
    "INSULTE (insulte, obscénité, menace ou harcèlement, dans n'importe quelle langue : français, arabe, "
    "dialecte tunisien en lettres arabes ou latines/arabizi comme 9a7ba, zebi, ta77an, anglais, italien...), "
    "GROSSIERETE (gros mot non dirigé contre la personne : merde, putain, khra...), "
    "LIEN_SUSPECT (lien douteux, hameçonnage), "
    "COORDONNEES (numéro de téléphone ou e-mail partagé). Un message normal n'a aucune catégorie. "
    'Réponds uniquement en JSON : {"categories": ["..."]}.'
)

SUGGEST_PROMPT = (
    "Tu aides un membre d'une application tunisienne de garde d'animaux à répondre dans la messagerie. "
    "Propose exactement 3 réponses courtes (maximum 90 caractères chacune), en français, polies, naturelles, "
    "différentes entre elles, que l'utilisateur pourrait envoyer telles quelles. N'invente ni prix ni dates "
    "précis qui ne figurent pas dans la conversation. Ne propose jamais de payer hors de l'application. "
    'Réponds uniquement en JSON : {"replies": ["...", "...", "..."]}.'
)


# ———————————————————————————————— Routes

@app.get("/health")
def health():
    return {"status": "UP", "llm": bool(groq_key()), "model": GROQ_MODEL if groq_key() else None}


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(req: AnalyzeRequest) -> AnalyzeResponse:
    categories, details = analyze_rules_detailed(req.text)
    try:
        data = await ask_groq(ANALYZE_PROMPT, req.text, max_tokens=80)
        llm_categories = [c for c in data.get("categories", []) if c in REASONS]
        # Les règles restent appliquées : l'IA ajoute ce que les listes ne voient pas.
        return AnalyzeResponse(**build_result(categories + llm_categories, details), source="llm")
    except Exception:
        return AnalyzeResponse(**build_result(categories, details), source="fallback")


@app.post("/suggest-replies", response_model=SuggestResponse)
async def suggest_replies(req: SuggestRequest) -> SuggestResponse:
    lines = [m.model_dump() for m in req.messages[-12:]]
    fallback = suggest_rules(lines, req.myRole, req.otherName or "")
    if not lines:
        return SuggestResponse(replies=fallback, source="fallback")
    role = "pet sitter" if req.myRole == "PETSITTER" else "propriétaire d'animal"
    transcript = "\n".join(("Moi" if m["fromMe"] else (req.otherName or "L'autre")) + " : " + m["text"]
                           for m in lines)
    user = f"Je suis {role}. Sujet : {req.subject or 'aucun'}.\nConversation :\n{transcript}\n\nMa prochaine réponse ?"
    try:
        data = await ask_groq(SUGGEST_PROMPT, user, max_tokens=250)
        replies = [str(r).strip()[:120] for r in data.get("replies", []) if str(r).strip()]
        # On ne garde pas une suggestion que la modération jugerait elle-même risquée.
        replies = [r for r in replies if analyze_rules(r)["risk"] != "HIGH"][:3]
        if len(replies) < 3:
            replies += [r for r in fallback if r not in replies][: 3 - len(replies)]
        return SuggestResponse(replies=replies, source="llm")
    except Exception:
        return SuggestResponse(replies=fallback, source="fallback")
