package com.petsitter.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Indiquez votre adresse e-mail.") String email,
        @NotBlank(message = "Saisissez votre mot de passe.") String password
) {
}
