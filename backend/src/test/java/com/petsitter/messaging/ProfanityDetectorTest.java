package com.petsitter.messaging;

import com.petsitter.messaging.ai.MessageAnalysis;
import com.petsitter.messaging.ai.MessagingAiFallback;
import com.petsitter.messaging.ai.ProfanityDetector;
import com.petsitter.messaging.enums.MessageRisk;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/** Mêmes cas que messaging_ai/test_profanity.py : les deux détecteurs doivent répondre pareil. */
class ProfanityDetectorTest {

    private final ProfanityDetector detector = ProfanityDetector.instance();

    private boolean hasHigh(String text, String lang) {
        return detector.find(text).stream().anyMatch(h -> h.term().isHigh() && h.term().lang().equals(lang));
    }

    @ParameterizedTest(name = "{0} ({1})")
    @CsvSource(delimiter = '|', value = {
            "T'es vraiment un connard|fr", "Espèce d'enculé|fr", "fuck you|en", "you are a bitch|en",
            "يا كلب|ar", "شرموطة|ar", "يلعن ابوك|ar", "ya 9a7ba|tn", "enti kahba|tn", "zebi 3lik|tn",
            "nayek|tn", "ya 7mar|tn", "enti ta77an|tn", "na3l bouk|tn", "قحبة|ar", "ميبون|tn", "نعل بوك|tn",
            "vaffanculo|it", "hijo de puta|es", "Ya jalel ya miboune|tn", "enti mibounek|tn", "enti ta77ana|tn",
            "naykek|tn", "ميبونة|tn"})
    @DisplayName("insultes dans toutes les langues, dont le tunisien")
    void insultsInAllLanguages(String text, String lang) {
        assertThat(hasHigh(text, lang)).as(text).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {"c0nnard", "C O N N A R D", "c.o.n.n.a.r.d", "connnnnard", "CONNARD!!!", "c*nnard",
            "f*ck", "fuuuuck", "F.U.C.K", "b!tch", "9a7baaaa", "KAHBA", "z e b i", "قَحْبَة", "قـــحبة", "قحبه",
            "$alope", "pu7e"})
    @DisplayName("contournements : chiffres, symboles, lettres séparées ou répétées, tashkeel")
    void evasions(String text) {
        assertThat(detector.find(text)).as(text).anyMatch(h -> h.term().isHigh());
    }

    @ParameterizedTest
    @ValueSource(strings = {"Mon chien est très calme, il ne mord pas.", "Does your dog bite?", "Le chat de Leïla dort.",
            "كلب لطيف جدا", "kelb mte3i mrigel", "Le conseil municipal confirme.", "Nicolas viendra demain.",
            "نيكولا سيأتي غدا", "zebda w 3sal", "Je confirme : 35 DT par nuit du 12 au 15 novembre.",
            "Bonjour, je peux garder votre lapin ce week-end ?", "Shukran, ya3tik essa7a", "Alf tahani, mabrouk !",
            "Jibli tabouna m3ak", "شكرا على العطايا"})
    @DisplayName("pas de faux positif sur les mots ordinaires de l'application")
    void noFalsePositive(String text) {
        assertThat(detector.find(text)).as(text).isEmpty();
    }

    @Test
    @DisplayName("raison : mot masqué et langue, jamais le mot en clair ; grossièreté = risque faible")
    void reasons() {
        MessageAnalysis insult = MessagingAiFallback.analyze("ya 9a7ba");
        assertThat(insult.risk()).isEqualTo(MessageRisk.HIGH);
        assertThat(insult.reason()).contains("9***a").contains("tunisien").doesNotContain("9a7ba");

        MessageAnalysis vulgar = MessagingAiFallback.analyze("Merde, j'ai raté le bus");
        assertThat(vulgar.risk()).isEqualTo(MessageRisk.LOW);
        assertThat(vulgar.categories()).containsExactly("GROSSIERETE");
        assertThat(vulgar.reason()).contains("m***e").contains("français");
    }

    @Test
    @DisplayName("expression masquée mot par mot ; un mot signalé une seule fois")
    void masking() {
        assertThat(detector.find("ya 7mar")).anyMatch(h -> h.masked().equals("ya 7**r"));
        assertThat(detector.find("Ta77an")).hasSize(1);
    }

    @ParameterizedTest(name = "{0} → {1}")
    @CsvSource(delimiter = '|', value = {
            "Si zebi|Si z**i",
            "T'es un c0nnard!|T'es un c*****d!",
            "ya 7mar|ya 7**r",
            "يا كلب|يا ك*ب",
            "zebi zebi|z**i z**i",
            "Merde alors|M***e alors",
            "f*ck you|f**k you",
            "enti ta77an w mibboun|enti t****n w m*****n",
            "vaffanculo !|v********o !",
            "Ya jalel ya miboune|Ya jalel ya m*****e",
            "Putin j'ai oublié|P***n j'ai oublié",
            "Mon chien ne mord pas|Mon chien ne mord pas",
            "Le conseil confirme 35 DT|Le conseil confirme 35 DT"})
    @DisplayName("gros mots remplacés par des étoiles, le reste du message intact")
    void censor(String text, String expected) {
        assertThat(detector.censor(text)).isEqualTo(expected);
    }

    @Test
    @DisplayName("censure des contournements : lettres séparées et arabe avec tatweel")
    void censorEvasions() {
        assertThat(detector.censor("p u t e")).isEqualTo("p*****e");
        String arabic = detector.censor("قـــحبة");
        assertThat(arabic).startsWith("ق").endsWith("ة").contains("*").doesNotContain("حب");
    }

    @Test
    @DisplayName("la liste du backend est identique à celle du service Python")
    void listIsInSyncWithPythonService() throws Exception {
        Path python = Path.of("..", "messaging_ai", "profanity.json");
        Assumptions.assumeTrue(Files.exists(python), "messaging_ai absent : vérification ignorée");
        Path backend = Path.of("src", "main", "resources", "messaging", "profanity.json");
        assertThat(Files.readString(backend))
                .as("Copier messaging_ai/profanity.json vers backend/src/main/resources/messaging/")
                .isEqualTo(Files.readString(python));
    }
}
