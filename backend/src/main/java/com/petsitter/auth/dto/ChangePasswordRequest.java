package com.petsitter.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ChangePasswordRequest(
        @NotBlank(message = "Saisissez votre mot de passe actuel.") String currentPassword,
        @NotBlank(message = "Choisissez un nouveau mot de passe.")
        @Pattern(regexp = PasswordPolicy.REGEX, message = PasswordPolicy.MESSAGE) String newPassword
) {
}
