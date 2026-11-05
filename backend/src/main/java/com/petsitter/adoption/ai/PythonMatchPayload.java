package com.petsitter.adoption.ai;

import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.enums.HousingType;

/**
 * Payload sent to the local Python matcher. It contains listing profile fields
 * and candidate housing/experience text only — never name, phone, email or address.
 */
public record PythonMatchPayload(Listing listing, Candidate candidate) {

    public record Listing(
            String species,
            String breed,
            Integer age,
            String gender,
            String location,
            Boolean vaccinated,
            Boolean sterilized,
            String description,
            String healthInformation
    ) {
        public static Listing from(AdoptionListing entity) {
            return new Listing(
                    entity.getSpecies() == null ? null : entity.getSpecies().name(),
                    entity.getBreed(),
                    entity.getAge(),
                    entity.getGender() == null ? null : entity.getGender().name(),
                    entity.getLocation(),
                    entity.getVaccinated(),
                    entity.getSterilized(),
                    entity.getDescription(),
                    entity.getHealthInformation()
            );
        }
    }

    public record Candidate(
            String housingType,
            Boolean hasGarden,
            Boolean hasOtherPets,
            String otherPetsDetails,
            String experience,
            String motivation
    ) {
        public static Candidate of(
                HousingType housingType,
                Boolean hasGarden,
                Boolean hasOtherPets,
                String otherPetsDetails,
                String experience,
                String motivation
        ) {
            return new Candidate(
                    housingType == null ? null : housingType.name(),
                    hasGarden,
                    hasOtherPets,
                    otherPetsDetails,
                    experience,
                    motivation
            );
        }
    }
}
