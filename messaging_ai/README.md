# Assistant IA de la messagerie (FastAPI, port 8002)

Deux fonctions pour la messagerie Pet Sitter :

1. **Protection contre les messages à risque** (`POST /analyze`) : arnaque au paiement
   (Western Union, recharge, code de carte, paiement d'avance), insultes, liens douteux,
   coordonnées partagées trop tôt.
   - Risque **élevé** (arnaque, insulte) : le backend refuse l'envoi tant que l'expéditeur ne
     confirme pas (`409 RISKY_MESSAGE`), puis le destinataire voit un avertissement « Prudence ».
   - Risque **faible** (virement, RIB, numéro de téléphone) : le message part, avec une information.
2. **Réponses suggérées** (`POST /suggest-replies`) : 3 réponses courtes adaptées aux derniers
   messages et au rôle (propriétaire ou pet sitter). Bouton ✨ dans la conversation.

```
Flutter ──► Spring Boot :8081 ──► messaging_ai :8002 ──► Groq (llama-3.1-8b-instant)
                 │                       └─ règles locales (sans clé ou si Groq échoue)
                 └─ règles locales Java (si ce service est arrêté)
```

L'application ne parle jamais directement à ce service. La messagerie fonctionne même
quand il est arrêté : le backend applique alors ses propres règles.

## Gros mots en 6 langues (`profanity.json`)

Plus de 250 termes : français, anglais, arabe, **tunisien** (lettres arabes et arabizi : 9a7ba,
zebi, ta77an, mibboun, na3l bouk…), italien, espagnol. Deux niveaux :

- `high` (insulte, obscénité) → catégorie `INSULTE`, risque élevé : confirmation demandée ;
- `low` (merde, putain, khra…) → catégorie `GROSSIERETE`, risque faible : simple information.

Le détecteur (`profanity.py`) ignore accents, majuscules, lettres répétées (« connnnard »),
tashkeel et tatweel arabes, et comprend les contournements : `c0nnard`, `$alope`, `p u t e`,
`f.u.c.k`, `f*ck`. Il compare mot par mot : « conseil », « Nicolas », « mon chien », « كلب لطيف »
ne sont jamais signalés. L'explication montre le mot masqué et la langue :
« Gros mot ou insulte détecté (« 9***a », tunisien) ».

Pour ajouter un mot : l'écrire sous sa forme simple dans `profanity.json` (`*` final = radical,
espaces = expression), puis **copier le fichier** vers `backend/src/main/resources/messaging/`
(le backend applique la même liste quand ce service est arrêté ; un test vérifie que les deux
copies sont identiques).

## Lancer (Windows)

```powershell
cd messaging_ai
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8002
```

- Santé : <http://localhost:8002/health> (`"llm": true` quand la clé Groq est chargée)
- Documentation : <http://localhost:8002/docs>

## Clé Groq (facultative)

Sans clé, les règles locales répondent (`"source": "fallback"`). Pour utiliser le modèle Groq :
copier `.env.example` en `.env` (ignoré par git), y mettre sa clé (<https://console.groq.com/keys>),
puis relancer le service. Les règles restent appliquées en plus de l'IA.

## Tests (sans réseau ni clé)

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```
