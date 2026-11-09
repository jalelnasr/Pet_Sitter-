package com.petsitter.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record ForgotPasswordRequest(
        @NotBlank(message = "Indiquez votre adresse e-mail.")
        @Email(message = "Adresse e-mail invalide.") String email
) {
}
