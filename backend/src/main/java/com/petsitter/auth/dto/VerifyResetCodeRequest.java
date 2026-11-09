package com.petsitter.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyResetCodeRequest(
        @NotBlank(message = "Indiquez votre adresse e-mail.") String email,
        @NotBlank(message = "Saisissez le code reçu.")
        @Pattern(regexp = "^\\d{6}$", message = "Le code contient 6 chiffres.") String code
) {
}
