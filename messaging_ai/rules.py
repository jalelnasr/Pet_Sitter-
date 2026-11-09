"""Règles locales de l'assistant de messagerie (utilisées sans clé Groq ou si l'IA ne répond pas).

- analyze_rules : repère les messages à risque (arnaque au paiement, insultes, liens douteux,
  coordonnées partagées trop tôt).
- suggest_rules : propose 3 réponses courtes selon le dernier message reçu.
"""
from __future__ import annotations

import re
import unicodedata
from typing import Dict, List, Optional

from profanity import Hit, detector


def normalize(text: str) -> str:
    """Minuscules, sans accents ni apostrophes typographiques : « Envoyez l’argent » -> « envoyez l'argent »."""
    text = text.replace("’", "'").lower()
    return "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")


# ———————————————————————————————— Analyse des risques

# Arnaque au paiement / paiement hors de l'application : risque élevé.
PAYMENT_HIGH = [
    r"western\s*union", r"money\s*gram", r"\bria\b", r"mandat cash",
    r"code (de (la|ta|votre) )?carte", r"\bcvv\b", r"\bcvc\b", r"code secret", r"code pin",
    r"numero de (la |ta |votre )?carte", r"payer? (d'avance|en avance|avant)", r"paiement (d'avance|hors)",
    r"envoie[sz]?(-moi| moi)? (l'|de l')?argent", r"envoyer (l'|de l')?argent", r"recharge (orange|ooredoo|telecom)",
    r"carte (cadeau|google play|itunes)", r"bitcoin", r"crypto",
]
# Paiement à surveiller (moins sûr) : risque faible.
PAYMENT_LOW = [r"\bd17\b", r"flouci", r"\brib\b", r"\biban\b", r"virement", r"paypal"]

URL = re.compile(r"(https?://|www\.)\S+", re.IGNORECASE)
SHORTENERS = re.compile(r"(bit\.ly|tinyurl|goo\.gl|t\.co/|cutt\.ly|shorturl)", re.IGNORECASE)
PHONE = re.compile(r"(\+?216[\s.-]?)?\b[2-9]\d(?:[\s.-]?\d){6}\b")
EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+")

REASONS = {
    "ARNAQUE_PAIEMENT": "Demande de paiement hors de l'application ou de coordonnées bancaires : "
                        "ne payez jamais à l'avance par transfert d'argent et ne partagez jamais le code de votre carte.",
    "PAIEMENT_EXTERNE": "Paiement hors de l'application : réglez de préférence via Pet Sitter, "
                        "où la garde est protégée.",
    "INSULTE": "Ce message contient des propos insultants. Restez courtois : "
               "les messages irrespectueux peuvent être signalés.",
    "GROSSIERETE": "Langage grossier : restez courtois avec les autres membres.",
    "LIEN_SUSPECT": "Lien raccourci ou inconnu : n'ouvrez pas de lien et ne saisissez pas vos identifiants "
                    "si vous n'êtes pas sûr de l'expéditeur.",
    "COORDONNEES": "Coordonnées personnelles partagées : gardez les échanges dans la messagerie "
                   "jusqu'à la confirmation de la garde.",
}
HIGH = {"ARNAQUE_PAIEMENT", "INSULTE"}


def analyze_rules(text: str) -> Dict:
    categories, details = analyze_rules_detailed(text)
    return build_result(categories, details)


def analyze_rules_detailed(text: str):
    """Catégories détectées et explications précises (mot masqué, langue) par catégorie."""
    t = normalize(text)
    categories: List[str] = []
    if any(re.search(p, t) for p in PAYMENT_HIGH):
        categories.append("ARNAQUE_PAIEMENT")
    elif any(re.search(p, t) for p in PAYMENT_LOW):
        categories.append("PAIEMENT_EXTERNE")
    details: Dict[str, str] = {}
    hits = detector().find(text)
    high = [h for h in hits if h.term.level == "high"]
    low = [h for h in hits if h.term.level == "low"]
    if high:
        categories.append("INSULTE")
        details["INSULTE"] = ("Gros mot ou insulte détecté (" + describe(high) + "). Restez courtois : "
                              "les messages irrespectueux peuvent être signalés.")
    elif low:
        categories.append("GROSSIERETE")
        details["GROSSIERETE"] = "Langage grossier (" + describe(low) + ") : restez courtois avec les autres membres."
    if URL.search(text) and (SHORTENERS.search(text) or "login" in t or "connexion" in t):
        categories.append("LIEN_SUSPECT")
    if PHONE.search(text) or EMAIL.search(text):
        categories.append("COORDONNEES")
    return categories, details


def describe(hits: List[Hit]) -> str:
    """« « m****n » et « t***n », tunisien » ; deux mots au plus, regroupés par langue, jamais en clair."""
    d = detector()
    by_lang: Dict[str, List[str]] = {}
    for h in hits[:2]:
        by_lang.setdefault(d.language_name(h.term.lang), []).append(f"« {h.masked} »")
    return " ; ".join(f"{' et '.join(words)}, {lang}" for lang, words in by_lang.items())


def build_result(categories: List[str], details: Optional[Dict[str, str]] = None) -> Dict:
    categories = [c for c in dict.fromkeys(categories) if c in REASONS]
    if not categories:
        return {"risk": "NONE", "categories": [], "reason": ""}
    risk = "HIGH" if any(c in HIGH for c in categories) else "LOW"
    # Raison principale : la plus grave d'abord.
    main = sorted(categories, key=lambda c: 0 if c in HIGH else 1)[0]
    return {"risk": risk, "categories": categories, "reason": (details or {}).get(main, REASONS[main])}


# ———————————————————————————————— Réponses suggérées

def suggest_rules(messages: List[Dict], my_role: str = "OWNER", other_name: str = "") -> List[str]:
    """messages : [{"fromMe": bool, "text": str}], du plus ancien au plus récent."""
    last_other = next((m["text"] for m in reversed(messages) if not m.get("fromMe")), "")
    t = normalize(last_other)
    sitter = my_role == "PETSITTER"
    name = f" {other_name}" if other_name else ""

    if not messages:
        return [
            f"Bonjour{name} ! Êtes-vous disponible pour garder mon animal ?" if not sitter
            else f"Bonjour{name} ! Merci pour votre intérêt, comment puis-je vous aider ?",
            "Bonjour ! Pouvez-vous m'en dire plus sur vos besoins ?",
            "Bonjour, quelles sont vos disponibilités ?",
        ]
    if re.search(r"merci|super|parfait|genial|top", t):
        return ["Avec plaisir !", "Je vous en prie, à bientôt !", "N'hésitez pas si vous avez une question."]
    if re.search(r"dispo|disponible|libre|ces dates|du \d|week-?end", t):
        if sitter:
            return ["Oui, je suis disponible à ces dates.", "Pouvez-vous me préciser les dates exactes ?",
                    "Désolé, je ne suis pas disponible à ces dates."]
        return ["Les dates me conviennent, merci !", "Pouvons-nous décaler d'un jour ?",
                "Je vous confirme les dates dès que possible."]
    if re.search(r"prix|tarif|combien|cout|dt\b|dinars?", t):
        if sitter:
            return ["Mon tarif est indiqué sur mon profil, par nuit ou par visite.",
                    "Combien d'animaux et combien de jours ?", "Je peux vous faire un devis précis."]
        return ["D'accord, ça me convient.", "Le tarif comprend-il les promenades ?",
                "Pouvez-vous me faire un devis pour 3 nuits ?"]
    if re.search(r"photo|nouvelles|comment (va|vont)|ca va", t):
        if sitter:
            return ["Tout va très bien, je vous envoie une photo !", "Il a bien mangé et il est en forme.",
                    "Il dort paisiblement en ce moment."]
        return ["Merci pour les nouvelles !", "Super, ça me rassure !", "Pouvez-vous m'envoyer une photo ?"]
    if re.search(r"chat|chien|oiseau|lapin|poisson|animal|age|vaccin|seul", t):
        return ["Il est très calme et sociable.", "Il est vacciné et en bonne santé.",
                "Je vous donne toutes les consignes avant la garde."]
    if re.search(r"\?$", last_other.strip()):
        return ["Oui, bien sûr.", "Je vérifie et je vous réponds.", "Pouvez-vous préciser ?"]
    if re.search(r"bonjour|salut|bonsoir|salam|ahla|aslema", t):
        return [f"Bonjour{name} !", "Bonjour, comment puis-je vous aider ?", "Bonjour, merci pour votre message."]
    return ["D'accord, merci !", "Je vous réponds dès que possible.", "Pouvez-vous m'en dire plus ?"]
