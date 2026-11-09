package com.petsitter.messaging.enums;

/** Niveau de risque d'un message, évalué par l'assistant IA à l'envoi. */
public enum MessageRisk {
    /** Message ordinaire. */
    NONE,
    /** À surveiller (paiement hors application, coordonnées partagées) : simple information. */
    LOW,
    /** Arnaque au paiement ou insulte : confirmation demandée à l'expéditeur, avertissement au destinataire. */
    HIGH
}
