package com.petsitter.adoption.dto.request;

import com.petsitter.adoption.dto.listing.ListingSummaryResponse;
import com.petsitter.adoption.dto.listing.UserSummaryResponse;
import com.petsitter.adoption.enums.HousingType;
import com.petsitter.adoption.enums.RequestStatus;

import java.time.Instant;

public record AdoptionRequestResponse(
        String id,
        ListingSummaryResponse listing,
        UserSummaryResponse applicant,
        String fullName,
        String phone,
        String address,
        String message,
        HousingType housingType,
        boolean hasGarden,
        boolean hasOtherPets,
        String otherPetsDetails,
        String experience,
        Integer aiScore,
        RequestStatus status,
        String responseMessage,
        Instant createdAt,
        Instant processedAt
) {
}
