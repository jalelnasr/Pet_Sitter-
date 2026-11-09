package com.petsitter.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ResetPasswordRequest(
        @NotBlank(message = "Indiquez votre adresse e-mail.") String email,
        @NotBlank(message = "Saisissez le code reçu.")
        @Pattern(regexp = "^\\d{6}$", message = "Le code contient 6 chiffres.") String code,
        @NotBlank(message = "Choisissez un nouveau mot de passe.")
        @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE) String newPassword
) {
}
