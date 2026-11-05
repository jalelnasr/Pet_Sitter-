"""Local FastAPI matcher. The model is downloaded into the Hugging Face cache on first start."""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import Any

import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from matching_logic import (
    MODEL_NAME,
    advice_from_similarity,
    candidate_profile,
    listing_profile,
)

_model = None


class ListingIn(BaseModel):
    species: str | None = None
    breed: str | None = None
    age: int | None = None
    gender: str | None = None
    location: str | None = None
    vaccinated: bool | None = None
    sterilized: bool | None = None
    description: str | None = None
    healthInformation: str | None = None


class CandidateIn(BaseModel):
    housingType: str | None = None
    hasGarden: bool | None = None
    hasOtherPets: bool | None = None
    otherPetsDetails: str | None = Field(default=None, max_length=500)
    experience: str | None = Field(default=None, max_length=2000)
    motivation: str | None = Field(default=None, max_length=2000)


class MatchRequest(BaseModel):
    listing: ListingIn
    candidate: CandidateIn


def _load_model():
    from sentence_transformers import SentenceTransformer

    return SentenceTransformer(MODEL_NAME)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    global _model
    _model = _load_model()
    yield
    _model = None


app = FastAPI(title="PetSitter Adoption AI", lifespan=lifespan)


@app.get("/health")
def health() -> dict[str, Any]:
    return {"status": "ok" if _model is not None else "loading", "model": MODEL_NAME}


@app.post("/match")
def match(body: MatchRequest) -> dict[str, Any]:
    if _model is None:
        raise HTTPException(status_code=503, detail="Model is not loaded.")

    listing = body.listing.model_dump()
    candidate = body.candidate.model_dump()
    texts = [listing_profile(listing), candidate_profile(candidate)]
    vectors = _model.encode(texts, normalize_embeddings=True)
    similarity = float(np.dot(vectors[0], vectors[1]))
    return advice_from_similarity(listing, candidate, similarity)
