"""Tests des règles locales et des routes (sans clé Groq, sans réseau). Lancer : pytest -q"""
from fastapi.testclient import TestClient

from main import app
from rules import analyze_rules, suggest_rules

client = TestClient(app)


def test_message_normal_sans_risque():
    r = analyze_rules("Bonjour, Simba mange deux fois par jour, merci beaucoup !")
    assert r["risk"] == "NONE" and r["categories"] == []


def test_arnaque_au_paiement_risque_eleve():
    for text in [
        "Envoyez l'argent par Western Union avant la garde",
        "Donne-moi le code de ta carte pour réserver",
        "Il faut payer d'avance, recharge Ooredoo de 50 DT",
    ]:
        r = analyze_rules(text)
        assert r["risk"] == "HIGH", text
        assert "ARNAQUE_PAIEMENT" in r["categories"]


def test_paiement_externe_risque_faible():
    r = analyze_rules("Je préfère un virement, voici mon RIB")
    assert r["risk"] == "LOW" and r["categories"] == ["PAIEMENT_EXTERNE"]


def test_insulte():
    r = analyze_rules("T'es vraiment un connard")
    assert r["risk"] == "HIGH" and "INSULTE" in r["categories"]


def test_coordonnees_et_lien_suspect():
    assert analyze_rules("Appelle-moi au 22 333 444")["categories"] == ["COORDONNEES"]
    assert analyze_rules("Écris-moi : leila@exemple.tn")["categories"] == ["COORDONNEES"]
    assert "LIEN_SUSPECT" in analyze_rules("Clique ici bit.ly/xyz https://bit.ly/xyz")["categories"]


def test_prix_et_dates_ne_sont_pas_des_numeros():
    assert analyze_rules("35 DT par nuit du 12 au 15 novembre 2026")["risk"] == "NONE"


def test_raison_la_plus_grave_en_premier():
    r = analyze_rules("Paie d'avance par Western Union, mon numéro 22 333 444")
    assert r["risk"] == "HIGH"
    assert r["reason"].startswith("Demande de paiement")


def test_suggestions_selon_le_dernier_message():
    msgs = [{"fromMe": True, "text": "Bonjour"}, {"fromMe": False, "text": "Êtes-vous disponible ce week-end ?"}]
    replies = suggest_rules(msgs, "PETSITTER", "Leïla")
    assert len(replies) == 3 and "disponible" in replies[0]
    thanks = suggest_rules([{"fromMe": False, "text": "Merci beaucoup !"}], "OWNER")
    assert thanks[0] == "Avec plaisir !"
    assert len(suggest_rules([], "OWNER", "Amira")) == 3


def test_routes_sans_cle_groq(monkeypatch):
    monkeypatch.delenv("GROQ_API_KEY", raising=False)
    assert client.get("/health").json()["status"] == "UP"
    r = client.post("/analyze", json={"text": "Envoie l'argent par Western Union"}).json()
    assert r["risk"] == "HIGH" and r["source"] == "fallback"
    s = client.post("/suggest-replies", json={
        "messages": [{"fromMe": False, "text": "Combien pour 3 nuits ?"}], "myRole": "PETSITTER"}).json()
    assert len(s["replies"]) == 3 and s["source"] == "fallback"
