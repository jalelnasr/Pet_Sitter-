package com.petsitter.messaging.dto;

import com.petsitter.user.dto.UserSummaryResponse;

import java.time.Instant;

/** Conversation vue par l'utilisateur courant : l'autre participant et l'aperçu du dernier message. */
public record ConversationResponse(
        Long id,
        UserSummaryResponse otherUser,
        String subject,
        String lastMessage,
        Instant lastMessageAt,
        boolean lastMessageMine,
        long unreadCount,
        Instant createdAt
) {
}
