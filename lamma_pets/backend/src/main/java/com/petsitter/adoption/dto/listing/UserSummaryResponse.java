package com.petsitter.adoption.dto.listing;

import com.petsitter.user.enums.UserRole;

/** Minimal user information embedded in adoption responses. */
public record UserSummaryResponse(
        String id,
        String firstName,
        UserRole role
) {
}
