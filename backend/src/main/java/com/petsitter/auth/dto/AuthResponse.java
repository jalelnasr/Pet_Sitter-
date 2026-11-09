package com.petsitter.auth.dto;

import com.petsitter.user.dto.UserResponse;

import java.time.Instant;

/** Session ouverte : jeton à envoyer dans {@code Authorization: Bearer <token>}. */
public record AuthResponse(String token, String tokenType, Instant expiresAt, UserResponse user) {

    public static AuthResponse bearer(String token, Instant expiresAt, UserResponse user) {
        return new AuthResponse(token, "Bearer", expiresAt, user);
    }
}
