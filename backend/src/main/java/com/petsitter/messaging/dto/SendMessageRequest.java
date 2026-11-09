package com.petsitter.messaging.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(
        @NotBlank(message = "Le message est vide.")
        @Size(max = 2000, message = "2000 caractères au maximum.") String content,
        /** Vrai quand l'expéditeur confirme l'envoi d'un message jugé à risque. */
        Boolean confirmRisk
) {
    public boolean riskConfirmed() {
        return Boolean.TRUE.equals(confirmRisk);
    }
}
