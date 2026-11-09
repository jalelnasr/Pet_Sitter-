package com.petsitter.user.dto;

import jakarta.validation.constraints.NotNull;

/** Suspension ou réactivation d'un compte par un administrateur. */
public record UpdateUserStatusRequest(@NotNull(message = "Indiquez l'état du compte.") Boolean disabled) {
}
