package com.petsitter.adoption.dto.matching;

import com.petsitter.adoption.enums.HousingType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MatchingAdviceRequest(
        @NotBlank String listingId,
        HousingType housingType,
        Boolean hasGarden,
        Boolean hasOtherPets,
        @Size(max = 500) String otherPetsDetails,
        @Size(max = 2000) String experience,
        @Size(max = 2000) String motivation
) {
}
