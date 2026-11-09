package com.petsitter.messaging.ai;

import com.petsitter.messaging.enums.MessageRisk;

import java.util.List;

/**
 * Évaluation d'un message par l'assistant IA.
 *
 * @param risk       NONE, LOW ou HIGH
 * @param categories ARNAQUE_PAIEMENT, PAIEMENT_EXTERNE, INSULTE, LIEN_SUSPECT, COORDONNEES
 * @param reason     explication lisible, affichée à l'utilisateur
 * @param source     "llm" (Groq), "fallback" (règles du service Python) ou "local" (règles du backend)
 */
public record MessageAnalysis(MessageRisk risk, List<String> categories, String reason, String source) {

    public boolean isHigh() {
        return risk == MessageRisk.HIGH;
    }
}
