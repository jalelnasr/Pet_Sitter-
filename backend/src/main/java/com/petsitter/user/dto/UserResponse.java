package com.petsitter.user.dto;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;

import java.time.Instant;

/** Profil complet de l'utilisateur connecté (jamais le mot de passe). */
public record UserResponse(
        String id,
        String firstName,
        String lastName,
        String fullName,
        String email,
        String phone,
        String city,
        String photoUrl,
        String bio,
        UserRole role,
        boolean disabled,
        Instant createdAt
) {
    public static UserResponse from(UserEntity u) {
        return new UserResponse(u.getId(), u.getFirstName(), u.getLastName(), u.getFullName(), u.getEmail(),
                u.getPhone(), u.getCity(), u.getPhotoUrl(), u.getBio(), u.getRole(), u.isDisabled(),
                u.getCreatedAt());
    }
}
