"""Pure matching helpers. No model download, so unit tests stay offline."""

from __future__ import annotations

from typing import Any

MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

SPECIES_FR = {
    "DOG": "chien",
    "CAT": "chat",
    "BIRD": "oiseau",
    "RABBIT": "lapin",
    "OTHER": "animal",
}


def listing_profile(listing: dict[str, Any]) -> str:
    species = str(listing.get("species") or "OTHER")
    parts = [
        f"species={species}",
        f"breed={listing.get('breed') or ''}",
        f"age={listing.get('age') if listing.get('age') is not None else ''}",
        f"gender={listing.get('gender') or ''}",
        f"location={listing.get('location') or ''}",
        f"vaccinated={bool(listing.get('vaccinated'))}",
        f"sterilized={bool(listing.get('sterilized'))}",
        f"description={listing.get('description') or ''}",
        f"health={listing.get('healthInformation') or ''}",
    ]
    return " ".join(parts).strip()


def candidate_profile(candidate: dict[str, Any]) -> str:
    parts = [
        f"housing={candidate.get('housingType') or 'OTHER'}",
        f"garden={bool(candidate.get('hasGarden'))}",
        f"otherPets={bool(candidate.get('hasOtherPets'))}",
        f"otherPetsDetails={candidate.get('otherPetsDetails') or ''}",
        f"experience={candidate.get('experience') or ''}",
        f"motivation={candidate.get('motivation') or ''}",
    ]
    return " ".join(parts).strip()


def cosine_to_score(similarity: float) -> int:
    """Map typical sentence-transformer cosine (~0.05–0.85) to 0–100."""
    scaled = (float(similarity) - 0.12) / 0.73
    score = int(round(scaled * 100))
    return max(0, min(100, score))


def build_summary(score: int, species: str) -> str:
    animal = SPECIES_FR.get(species, "animal")
    if score >= 80:
        return (
            f"Très bon match : le profil du candidat correspond bien aux besoins "
            f"de cet {animal}."
        )
    if score >= 60:
        return (
            f"Bon potentiel : plusieurs points du foyer s'alignent avec cet {animal}, "
            "avec quelques précisions utiles."
        )
    if score >= 40:
        return (
            f"Compatibilité moyenne : le texte du candidat recoupe partiellement "
            f"le profil de l'{animal}."
        )
    return (
        f"Faible correspondance pour le moment : l'expérience et la motivation "
        f"couvrent peu les besoins de cet {animal}."
    )


def build_tips(listing: dict[str, Any], candidate: dict[str, Any], score: int) -> list[str]:
    species = str(listing.get("species") or "OTHER")
    experience = str(candidate.get("experience") or "")
    motivation = str(candidate.get("motivation") or "")
    text = f"{experience} {motivation}".lower()
    housing = str(candidate.get("housingType") or "")
    has_garden = bool(candidate.get("hasGarden"))
    tips: list[str] = []

    if len(experience.strip()) < 40:
        tips.append("Détaillez davantage votre expérience quotidienne avec cette espèce.")
    if len(motivation.strip()) < 40:
        tips.append("Expliquez le rythme de vie et le temps que vous pourrez consacrer à l'animal.")
    if species == "DOG" and not has_garden and "promenade" not in text:
        tips.append("Précisez la fréquence et la durée des promenades quotidiennes.")
    if species == "CAT" and "intérieur" not in text and "fenêtre" not in text:
        tips.append("Indiquez si l'animal vivra à l'intérieur et si les ouvertures sont sécurisées.")
    if species == "RABBIT" and "foin" not in text:
        tips.append("Mentionnez l'espace, le foin et la litière prévus pour le lapin.")
    if housing == "APARTMENT" and species == "DOG" and not has_garden:
        tips.append("Décrivez comment un chien sera dépensé depuis un appartement.")
    if score < 50:
        tips.append("Ajoutez des éléments concrets (logement, absences, soins vétérinaires).")
    if not tips:
        tips.append("Votre dossier est déjà solide : préparez une visite de rencontre.")
        tips.append("Listez les questions à poser à la famille d'accueil.")
        tips.append("Préparez l'espace et le matériel avant l'arrivée de l'animal.")

    unique: list[str] = []
    for tip in tips:
        if tip not in unique:
            unique.append(tip)
        if len(unique) == 3:
            break
    return unique


def advice_from_similarity(
    listing: dict[str, Any],
    candidate: dict[str, Any],
    similarity: float,
) -> dict[str, Any]:
    score = cosine_to_score(similarity)
    species = str(listing.get("species") or "OTHER")
    return {
        "score": score,
        "summary": build_summary(score, species),
        "tips": build_tips(listing, candidate, score),
        "model": MODEL_NAME,
    }
