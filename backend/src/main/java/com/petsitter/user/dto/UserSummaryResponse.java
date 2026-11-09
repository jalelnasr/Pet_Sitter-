package com.petsitter.user.dto;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;

/** Fiche publique d'un utilisateur (annuaire, messagerie) : ni e-mail ni téléphone. */
public record UserSummaryResponse(
        String id,
        String firstName,
        String lastName,
        String fullName,
        String photoUrl,
        String city,
        UserRole role
) {
    public static UserSummaryResponse from(UserEntity u) {
        return new UserSummaryResponse(u.getId(), u.getFirstName(), u.getLastName(), u.getFullName(),
                u.getPhotoUrl(), u.getCity(), u.getRole());
    }
}
