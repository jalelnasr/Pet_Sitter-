package com.petsitter.adoption.dto.listing;

import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;

import java.time.Instant;
import java.util.List;

/** Lightweight listing representation used by list endpoints. */
public record ListingSummaryResponse(
        String id,
        UserSummaryResponse publisher,
        String petName,
        PetSpecies species,
        String breed,
        Integer age,
        PetGender gender,
        String location,
        ListingStatus status,
        List<String> imageUrls,
        Instant createdAt
) {
}
