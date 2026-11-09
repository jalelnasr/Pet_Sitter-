package com.petsitter.messaging;

import com.petsitter.messaging.ai.MessageAnalysis;
import com.petsitter.messaging.ai.MessagingAiFallback;
import com.petsitter.messaging.enums.MessageRisk;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/** Règles locales de l'assistant de messagerie (utilisées quand le service Python est arrêté). */
class MessagingAiFallbackTest {

    @Test
    @DisplayName("message ordinaire, prix et dates : aucun risque")
    void ordinaryMessages() {
        assertThat(MessagingAiFallback.analyze("Bonjour, Simba est très calme.").risk()).isEqualTo(MessageRisk.NONE);
        assertThat(MessagingAiFallback.analyze("35 DT par nuit du 12 au 15 novembre 2026").risk())
                .isEqualTo(MessageRisk.NONE);
    }

    @Test
    @DisplayName("arnaque au paiement et insultes : risque élevé, accents et majuscules ignorés")
    void highRisk() {
        assertThat(MessagingAiFallback.analyze("Envoyez L’ARGENT par Western Union").categories())
                .contains("ARNAQUE_PAIEMENT");
        assertThat(MessagingAiFallback.analyze("Donne-moi le code de ta carte").isHigh()).isTrue();
        assertThat(MessagingAiFallback.analyze("Espèce de crétin").categories()).contains("INSULTE");
    }

    @Test
    @DisplayName("virement, coordonnées, lien raccourci : risque faible")
    void lowRisk() {
        assertThat(MessagingAiFallback.analyze("Je préfère un virement").risk()).isEqualTo(MessageRisk.LOW);
        assertThat(MessagingAiFallback.analyze("Appelle-moi au +216 22 333 444").categories())
                .containsExactly("COORDONNEES");
        assertThat(MessagingAiFallback.analyze("Regarde https://bit.ly/abc").categories()).contains("LIEN_SUSPECT");
    }

    @Test
    @DisplayName("catégories renvoyées par l'IA : inconnues ignorées, la plus grave expliquée")
    void buildFromLlmCategories() {
        MessageAnalysis a = MessagingAiFallback.build(List.of("COORDONNEES", "INVENTEE", "INSULTE"), "llm");
        assertThat(a.risk()).isEqualTo(MessageRisk.HIGH);
        assertThat(a.categories()).containsExactly("COORDONNEES", "INSULTE");
        assertThat(a.reason()).contains("insultants");
        assertThat(MessagingAiFallback.build(List.of("INVENTEE"), "llm").risk()).isEqualTo(MessageRisk.NONE);
    }

    @Test
    @DisplayName("suggestions : adaptées au dernier message et au rôle")
    void suggestions() {
        assertThat(MessagingAiFallback.suggest("Êtes-vous disponible samedi ?", true).get(0)).contains("disponible");
        assertThat(MessagingAiFallback.suggest("Merci beaucoup", false).get(0)).isEqualTo("Avec plaisir !");
        assertThat(MessagingAiFallback.suggest("", false)).hasSize(3);
    }
}
