package com.petsitter.messaging.dto;

import com.petsitter.messaging.entity.Message;
import com.petsitter.messaging.enums.MessageRisk;
import com.petsitter.messaging.enums.MessageType;

import java.time.Instant;

/** Message vu par l'utilisateur courant ({@code mine} = envoyé par lui). */
public record MessageResponse(
        Long id,
        Long conversationId,
        String senderId,
        boolean mine,
        MessageType type,
        String content,
        Instant sentAt,
        Instant readAt,
        MessageRisk risk,
        String riskReason,
        boolean deleted
) {
    public static MessageResponse from(Message m, String currentUserId) {
        String senderId = m.getSender() == null ? null : m.getSender().getId();
        if (m.isDeleted()) {
            return new MessageResponse(m.getId(), m.getConversation().getId(), senderId,
                    currentUserId.equals(senderId), m.getType(), "", m.getSentAt(), m.getReadAt(),
                    MessageRisk.NONE, null, true);
        }
        return new MessageResponse(m.getId(), m.getConversation().getId(), senderId,
                currentUserId.equals(senderId), m.getType(), m.getContent(), m.getSentAt(), m.getReadAt(),
                m.getRiskLevel(), m.getRiskReason(), false);
    }
}
