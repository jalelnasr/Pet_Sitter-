package com.petsitter.adoption.mapper;

import com.petsitter.adoption.dto.listing.ListingResponse;
import com.petsitter.adoption.dto.listing.ListingSummaryResponse;
import com.petsitter.adoption.dto.listing.UserSummaryResponse;
import com.petsitter.adoption.dto.request.AdoptionRequestResponse;
import com.petsitter.adoption.entity.AdoptionImage;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.entity.AdoptionRequest;
import com.petsitter.user.entity.UserEntity;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;

/**
 * Explicit mapping from JPA entities to DTOs. Entities are never serialized
 * directly, which avoids lazy-loading errors and recursive JSON graphs.
 */
@Component
public class AdoptionMapper {

    public UserSummaryResponse toUserSummary(UserEntity user) {
        return new UserSummaryResponse(user.getId(), user.getFirstName(), user.getRole());
    }

    public ListingSummaryResponse toSummary(AdoptionListing listing) {
        return new ListingSummaryResponse(
                listing.getId(),
                toUserSummary(listing.getPublisher()),
                listing.getPetName(),
                listing.getSpecies(),
                listing.getBreed(),
                listing.getAge(),
                listing.getGender(),
                listing.getLocation(),
                listing.getStatus(),
                imageUrls(listing),
                listing.getCreatedAt()
        );
    }

    public ListingResponse toResponse(AdoptionListing listing) {
        return new ListingResponse(
                listing.getId(),
                toUserSummary(listing.getPublisher()),
                listing.getPetName(),
                listing.getSpecies(),
                listing.getBreed(),
                listing.getAge(),
                listing.getGender(),
                listing.getDescription(),
                listing.getHealthInformation(),
                Boolean.TRUE.equals(listing.getVaccinated()),
                Boolean.TRUE.equals(listing.getSterilized()),
                listing.getLocation(),
                listing.getStatus(),
                imageUrls(listing),
                listing.getCreatedAt(),
                listing.getUpdatedAt()
        );
    }

    public AdoptionRequestResponse toResponse(AdoptionRequest request) {
        return new AdoptionRequestResponse(
                request.getId(),
                toSummary(request.getListing()),
                toUserSummary(request.getApplicant()),
                request.getFullName(),
                request.getPhone(),
                request.getAddress(),
                request.getMessage(),
                request.getHousingType(),
                Boolean.TRUE.equals(request.getHasGarden()),
                Boolean.TRUE.equals(request.getHasOtherPets()),
                request.getOtherPetsDetails(),
                request.getExperience(),
                request.getAiScore(),
                request.getStatus(),
                request.getResponseMessage(),
                request.getCreatedAt(),
                request.getProcessedAt()
        );
    }

    private List<String> imageUrls(AdoptionListing listing) {
        return listing.getImages().stream()
                .sorted(Comparator.comparing(AdoptionImage::getDisplayOrder))
                .map(AdoptionImage::getImageUrl)
                .toList();
    }
}
