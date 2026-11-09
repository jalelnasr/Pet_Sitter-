"""Détection des gros mots en plusieurs langues (dont le tunisien). Lancer : pytest -q"""
import pytest

from profanity import detector
from rules import analyze_rules


def langs(text):
    return {(h.term.lang, h.term.level) for h in detector().find(text)}


@pytest.mark.parametrize("text, lang", [
    ("T'es vraiment un connard", "fr"),
    ("Espèce d'enculé", "fr"),
    ("fuck you", "en"),
    ("you are a bitch", "en"),
    ("يا كلب", "ar"),
    ("شرموطة", "ar"),
    ("يلعن ابوك", "ar"),
    ("ya 9a7ba", "tn"),
    ("enti kahba", "tn"),
    ("zebi 3lik", "tn"),
    ("nayek", "tn"),
    ("ya 7mar", "tn"),
    ("enti ta77an", "tn"),
    ("na3l bouk", "tn"),
    ("قحبة", "ar"),
    ("ميبون", "tn"),
    ("نعل بوك", "tn"),
    ("vaffanculo", "it"),
    ("Ya jalel ya miboune", "tn"),   # terminaisons : miboune, mibounek, ta77ana, naykek
    ("enti mibounek", "tn"),
    ("enti ta77ana", "tn"),
    ("naykek", "tn"),
    ("ميبونة", "tn"),
    ("hijo de puta", "es"),
])
def test_insultes_toutes_langues(text, lang):
    assert (lang, "high") in langs(text), text


@pytest.mark.parametrize("text", [
    "c0nnard", "C O N N A R D", "c.o.n.n.a.r.d", "connnnnard", "CONNARD!!!", "c*nnard",  # français
    "f*ck", "fuuuuck", "F.U.C.K", "b!tch",                                              # anglais
    "9a7baaaa", "KAHBA", "z e b i",                                                     # arabizi
    "قَحْبَة", "قـــحبة", "قحبه",                                                          # arabe : tashkeel, tatweel, ta marbuta
    "$alope", "pu7e",                                                                   # chiffres et symboles
])
def test_contournements(text):
    assert any(level == "high" for _, level in langs(text)), text


@pytest.mark.parametrize("text", [
    "Mon chien est très calme, il ne mord pas.",
    "Does your dog bite?",
    "Le chat de Leïla dort.",
    "كلب لطيف جدا",                       # un chien très gentil
    "kelb mte3i mrigel",                  # mon chien va bien (tunisien)
    "Le conseil municipal confirme.",
    "Nicolas viendra demain.",
    "نيكولا سيأتي غدا",
    "zebda w 3sal",                       # beurre et miel
    "Je confirme : 35 DT par nuit du 12 au 15 novembre.",
    "Bonjour, je peux garder votre lapin ce week-end ?",
    "Shukran, ya3tik essa7a",
    "Alf tahani, mabrouk !",              # félicitations
    "Jibli tabouna m3ak",                 # le pain tabouna
    "شكرا على العطايا",                    # merci pour les cadeaux
])
def test_pas_de_faux_positif(text):
    assert detector().find(text) == [], text


def test_putin_faute_de_frappe_de_putain():
    assert ("fr", "low") in langs("Putin j'ai oublié")


def test_grossierete_niveau_faible():
    r = analyze_rules("Merde, j'ai raté le bus")
    assert r["risk"] == "LOW" and r["categories"] == ["GROSSIERETE"]
    assert "m***e" in r["reason"] and "français" in r["reason"]


def test_raison_avec_mot_masque_et_langue():
    r = analyze_rules("ya 9a7ba")
    assert r["risk"] == "HIGH" and "INSULTE" in r["categories"]
    assert "tunisien" in r["reason"] and "9***a" in r["reason"]
    assert "9a7ba" not in r["reason"]  # jamais le mot en clair


def test_expression_masquee_mot_par_mot():
    hit = next(h for h in detector().find("ya 7mar") if h.term.text == "ya 7mar")
    assert hit.masked == "ya 7**r"


def test_un_mot_signale_une_seule_fois():
    assert len(detector().find("Ta77an")) == 1
