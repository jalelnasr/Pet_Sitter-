"""Détection des gros mots en plusieurs langues : français, anglais, arabe, tunisien (lettres arabes
et arabizi : 9a7ba, ta77an…), italien, espagnol. La liste est dans profanity.json.

Résiste aux contournements courants :
- accents, majuscules, lettres répétées (« connnnard »), tashkeel et tatweel arabes, variantes d'alif ;
- chiffres et symboles à la place des lettres (« c0nnard », « pu7e », « $alope ») ;
- lettres séparées (« p u t e », « f.u.c.k ») et étoiles (« f*ck », « c*nnard »).

Ne signale pas les mots ordinaires qui contiennent un gros mot (« conseil », « Nicolas »…) :
la comparaison se fait mot par mot, jamais à l'intérieur d'un mot.

Le backend Java applique exactement le même algorithme (ProfanityDetector.java).
"""
from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

DATA_FILE = Path(__file__).resolve().with_name("profanity.json")

ARABIC_MAP = str.maketrans({
    "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ى": "ي", "ة": "ه", "ؤ": "و", "ئ": "ي", "ـ": "",
})
# Langage « leet » : seulement pour la deuxième lecture (l'arabizi garde ses chiffres).
LEET_MAP = str.maketrans({
    "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s", "€": "e", "!": "i",
})
TOKEN = re.compile(r"[\w*@$€!]+")
REPEATS = re.compile(r"([^*])\1+")


def canon(text: str) -> str:
    """Minuscules, sans accents ni tashkeel, alif/ya/ta marbuta unifiés."""
    text = text.replace("’", "'").lower().translate(ARABIC_MAP)
    return "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")


def tokens(text: str) -> List[str]:
    """Mots normalisés ; les lettres isolées consécutives (« p u t e ») sont recollées."""
    raw = TOKEN.findall(canon(text))
    merged: List[str] = []
    singles: List[str] = []
    for t in raw + [""]:
        if len(t) == 1:
            singles.append(t)
            continue
        if len(singles) >= 3:
            merged.append("".join(singles))
        else:
            merged.extend(singles)
        singles = []
        if t:
            merged.append(t)
    # Ponctuation collée au mot (« connard! », « !idiot ») ; les mots faits seulement de symboles sont ignorés.
    cleaned = (t.strip("!") for t in merged)
    return [REPEATS.sub(r"\1", t) for t in cleaned if t.strip("*!")]


@dataclass(frozen=True)
class Term:
    words: Tuple[str, ...]  # forme normalisée, un élément par mot
    stem: bool               # dernier mot = radical
    lang: str
    level: str               # "high" ou "low"
    text: str                # terme tel qu'écrit dans la liste


@dataclass(frozen=True)
class Hit:
    term: Term
    matched: str    # mot du message, normalisé
    index: int = 0  # position dans le message (pour l'ordre d'affichage)

    @property
    def masked(self) -> str:
        """Mot masqué pour l'affichage : « c****d », « ya 7**r » (les petits mots d'une expression restent lisibles)."""
        words = self.matched.split(" ")
        if len(words) == 1:
            return _mask(words[0], keep_short=False)
        return " ".join(_mask(w, keep_short=True) for w in words)


def _mask(word: str, keep_short: bool) -> str:
    if len(word) <= 2:
        return word if keep_short else word[0] + "*"
    return word[0] + "*" * (len(word) - 2) + word[-1]


def _token_matches(token: str, word: str, stem: bool) -> bool:
    """Compare un mot du message à un mot de la liste ; « * » dans le message remplace une lettre."""
    if stem:
        if len(token) < len(word):
            return False
        token = token[: len(word)]
    elif len(token) != len(word):
        return False
    return all(t == w or t == "*" for t, w in zip(token, word))


class ProfanityDetector:
    def __init__(self, data: Dict):
        self.languages: Dict[str, str] = data.get("languages", {})
        self.terms: List[Term] = []
        for lang, levels in data["words"].items():
            for level in ("high", "low"):
                for raw in levels.get(level, []):
                    stem = raw.endswith("*")
                    words = tuple(tokens(raw.rstrip("*")))
                    if words:
                        self.terms.append(Term(words, stem, lang, level, raw))
        # Les insultes d'abord : un mot présent dans les deux niveaux compte comme insulte.
        self.terms.sort(key=lambda t: 0 if t.level == "high" else 1)

    @classmethod
    def load(cls, path: Path = DATA_FILE) -> "ProfanityDetector":
        return cls(json.loads(path.read_text(encoding="utf-8")))

    def find(self, text: str) -> List[Hit]:
        base = tokens(text)
        variants = [base]
        leet = [REPEATS.sub(r"\1", t.translate(LEET_MAP)) for t in base]
        if leet != base:
            variants.append(leet)
        hits: List[Hit] = []
        seen = set()  # termes et mots déjà signalés
        for toks in variants:
            for term in self.terms:
                n = len(term.words)
                for i in range(len(toks) - n + 1):
                    ok = all(
                        _token_matches(toks[i + k], term.words[k], term.stem and k == n - 1)
                        for k in range(n))
                    matched = " ".join(toks[i:i + n])
                    if ok and term.text not in seen and matched not in seen:
                        seen.update((term.text, matched))
                        hits.append(Hit(term, matched, i))
                        break
        hits.sort(key=lambda h: (0 if h.term.level == "high" else 1, h.index))
        return hits

    def language_name(self, lang: str) -> str:
        return self.languages.get(lang, lang)


_DEFAULT: Optional[ProfanityDetector] = None


def detector() -> ProfanityDetector:
    global _DEFAULT
    if _DEFAULT is None:
        _DEFAULT = ProfanityDetector.load()
    return _DEFAULT
