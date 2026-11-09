package com.petsitter.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Modification du profil par son titulaire. */
public record UpdateProfileRequest(
        @NotBlank(message = "Indiquez votre prénom.") @Size(max = 80) String firstName,
        @Size(max = 80) String lastName,
        @Pattern(regexp = "^$|^\\+?[0-9 ]{8,20}$", message = "Numéro de téléphone invalide.") String phone,
        @Size(max = 80) String city,
        @Size(max = 500) String photoUrl,
        @Size(max = 600, message = "600 caractères au maximum.") String bio
) {
}
