package com.petsitter.messaging.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Ouvre (ou retrouve) la conversation avec un membre.
 * {@code message} facultatif : premier message envoyé dans la foulée.
 */
public record StartConversationRequest(
        @NotBlank(message = "Choisissez un destinataire.") String participantId,
        @Size(max = 160) String subject,
        @Size(max = 2000, message = "2000 caractères au maximum.") String message
) {
}
