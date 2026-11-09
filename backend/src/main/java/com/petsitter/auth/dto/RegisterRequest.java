package com.petsitter.auth.dto;

import com.petsitter.user.enums.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Inscription. {@code role} vaut OWNER par défaut ; ADMIN est refusé. */
public record RegisterRequest(
        @NotBlank(message = "Indiquez votre prénom.") @Size(max = 80) String firstName,
        @Size(max = 80) String lastName,
        @NotBlank(message = "Indiquez votre adresse e-mail.")
        @Email(message = "Adresse e-mail invalide.") @Size(max = 160) String email,
        @NotBlank(message = "Choisissez un mot de passe.")
        @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE) String password,
        UserRole role
) {
}
