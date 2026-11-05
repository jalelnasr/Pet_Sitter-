package com.petsitter.adoption.dto.listing;

import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.util.List;

public record UpdateListingRequest(
        @NotBlank @Size(max = 80) String petName,
        @NotNull PetSpecies species,
        @Size(max = 80) String breed,
        @PositiveOrZero Integer age,
        @NotNull PetGender gender,
        @NotBlank @Size(max = 2000) String description,
        @Size(max = 1000) String healthInformation,
        @NotNull Boolean vaccinated,
        @NotNull Boolean sterilized,
        @NotBlank @Size(max = 160) String location,
        @Size(max = 6) List<@NotBlank @Size(max = 1000) String> imageUrls
) {
}
