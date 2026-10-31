from matching_logic import (
    MODEL_NAME,
    advice_from_similarity,
    candidate_profile,
    cosine_to_score,
    listing_profile,
)


def test_profiles_exclude_personal_fields():
    listing = listing_profile(
        {
            "species": "CAT",
            "description": "Calme",
            "location": "Ariana",
        }
    )
    candidate = candidate_profile(
        {
            "housingType": "APARTMENT",
            "hasGarden": False,
            "experience": "J'ai eu un chat",
            "motivation": "Foyer calme",
            "fullName": "must-not-appear",
            "phone": "22000000",
            "address": "12 rue secrete",
        }
    )
    assert "must-not-appear" not in candidate
    assert "22000000" not in candidate
    assert "rue secrete" not in candidate
    assert "CAT" in listing
    assert "APARTMENT" in candidate


def test_cosine_to_score_is_bounded():
    assert cosine_to_score(-1) == 0
    assert cosine_to_score(1) == 100
    assert 0 <= cosine_to_score(0.4) <= 100


def test_advice_shape_and_tip_limit():
    advice = advice_from_similarity(
        {"species": "DOG", "description": "Actif"},
        {
            "housingType": "APARTMENT",
            "hasGarden": False,
            "experience": "ok",
            "motivation": "ok",
        },
        0.2,
    )
    assert advice["model"] == MODEL_NAME
    assert 0 <= advice["score"] <= 100
    assert advice["summary"]
    assert 1 <= len(advice["tips"]) <= 3
