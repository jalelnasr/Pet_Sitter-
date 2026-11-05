package com.petsitter.adoption.dto.request;

import com.petsitter.adoption.enums.HousingType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateAdoptionRequest(
        @NotBlank String listingId,
        @NotBlank @Size(max = 120) String fullName,
        @NotBlank @Size(max = 40) String phone,
        @NotBlank @Size(max = 255) String address,
        @NotBlank @Size(max = 2000) String message,
        @NotNull HousingType housingType,
        @NotNull Boolean hasGarden,
        @NotNull Boolean hasOtherPets,
        @Size(max = 500) String otherPetsDetails,
        @Size(max = 2000) String experience,
        @Min(0) @Max(100) Integer aiScore
) {
}
