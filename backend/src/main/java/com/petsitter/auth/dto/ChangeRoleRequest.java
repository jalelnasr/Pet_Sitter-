package com.petsitter.auth.dto;

import com.petsitter.user.enums.UserRole;
import jakarta.validation.constraints.NotNull;

/** Passage propriétaire ↔ pet sitter (le choix fait après l'inscription reste modifiable). */
public record ChangeRoleRequest(@NotNull(message = "Choisissez un profil.") UserRole role) {
}
