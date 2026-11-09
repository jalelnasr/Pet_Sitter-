package com.petsitter.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petsitter.auth.service.PasswordResetMailer;
import com.petsitter.user.entity.UserEntity;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Parcours complet sur base H2 en mémoire : inscription, connexion, verrouillage,
 * mot de passe oublié, profil et messagerie entre deux comptes.
 */
@SpringBootTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.datasource.url=jdbc:h2:mem:petsitter-auth;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.show-sql=false",
        // Service Python volontairement injoignable : on vérifie les règles locales du backend.
        "messaging.ai.url=http://127.0.0.1:1"
})
@AutoConfigureMockMvc
class AuthAndMessagingFlowTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @MockBean
    private PasswordResetMailer mailer;

    private static String uniqueEmail(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8) + "@exemple.tn";
    }

    private ResultActions postJson(String url, Object body, String token) throws Exception {
        var request = post(url).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(body));
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        return mvc.perform(request);
    }

    private JsonNode register(String firstName, String email, String password) throws Exception {
        String body = postJson("/api/auth/register",
                Map.of("firstName", firstName, "lastName", "Test", "email", email, "password", password), null)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return json.readTree(body);
    }

    @Test
    @DisplayName("inscription puis connexion : jeton valide, profil accessible, e-mail en double refusé")
    void registerAndLogin() throws Exception {
        String email = uniqueEmail("leila");
        JsonNode session = register("Leïla", email, "chat2025");
        assertThat(session.get("token").asText()).isNotBlank();
        assertThat(session.at("/user/role").asText()).isEqualTo("OWNER");
        assertThat(session.at("/user/fullName").asText()).isEqualTo("Leïla Test");
        assertThat(session.toString()).doesNotContain("password");

        postJson("/api/auth/register",
                Map.of("firstName", "Autre", "email", email.toUpperCase(), "password", "chat2025"), null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_USED"));

        String token = json.readTree(postJson("/api/auth/login", Map.of("email", email, "password", "chat2025"), null)
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("token").asText();

        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(email));

        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer abc.def.ghi"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("SESSION_EXPIRED"));

        mvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_REQUIRED"));
    }

    @Test
    @DisplayName("mot de passe faible refusé par la validation")
    void weakPasswordRejected() throws Exception {
        postJson("/api/auth/register",
                Map.of("firstName", "Sami", "email", uniqueEmail("sami"), "password", "court"), null)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.password").exists());
    }

    @Test
    @DisplayName("5 mauvais mots de passe : compte verrouillé, même avec le bon mot de passe")
    void lockAfterFailedAttempts() throws Exception {
        String email = uniqueEmail("lock");
        register("Lock", email, "bonmotdepasse1");
        for (int i = 1; i <= 4; i++) {
            postJson("/api/auth/login", Map.of("email", email, "password", "mauvais" + i), null)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
        }
        postJson("/api/auth/login", Map.of("email", email, "password", "mauvais5"), null)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED"));
        postJson("/api/auth/login", Map.of("email", email, "password", "bonmotdepasse1"), null)
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("ACCOUNT_LOCKED"));
    }

    @Test
    @DisplayName("mot de passe oublié : code par e-mail, mauvais code refusé, nouveau mot de passe actif, ancien jeton invalidé")
    void forgotPasswordFlow() throws Exception {
        String email = uniqueEmail("oubli");
        String oldToken = register("Oubli", email, "ancien2025").get("token").asText();

        postJson("/api/auth/forgot-password", Map.of("email", email), null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.retryAfterSeconds").value(60));
        // Adresse inconnue : même réponse (pas d'énumération des comptes).
        postJson("/api/auth/forgot-password", Map.of("email", uniqueEmail("inconnu")), null)
                .andExpect(status().isOk());

        ArgumentCaptor<String> code = ArgumentCaptor.forClass(String.class);
        verify(mailer).sendResetCode(any(UserEntity.class), code.capture(), anyLong());
        String wrong = code.getValue().equals("000000") ? "111111" : "000000";

        postJson("/api/auth/verify-reset-code", Map.of("email", email, "code", wrong), null)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("RESET_CODE_INVALID"));
        postJson("/api/auth/verify-reset-code", Map.of("email", email, "code", code.getValue()), null)
                .andExpect(status().isOk());

        String newToken = json.readTree(postJson("/api/auth/reset-password",
                        Map.of("email", email, "code", code.getValue(), "newPassword", "nouveau2025"), null)
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("token").asText();

        // Le code ne sert qu'une fois.
        postJson("/api/auth/reset-password",
                Map.of("email", email, "code", code.getValue(), "newPassword", "encore2025"), null)
                .andExpect(status().isBadRequest());

        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + oldToken))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + newToken))
                .andExpect(status().isOk());
        postJson("/api/auth/login", Map.of("email", email, "password", "ancien2025"), null)
                .andExpect(status().isUnauthorized());
        postJson("/api/auth/login", Map.of("email", email, "password", "nouveau2025"), null)
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("profil, changement de rôle et de mot de passe")
    void profileRoleAndPassword() throws Exception {
        String token = register("Profil", uniqueEmail("profil"), "profil2025").get("token").asText();

        mvc.perform(put("/api/auth/me").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of(
                                "firstName", "Inès", "lastName", "Ben Ali", "city", "La Marsa", "phone", "+216 22 333 444"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Inès Ben Ali"))
                .andExpect(jsonPath("$.city").value("La Marsa"));

        String roleBody = mvc.perform(put("/api/auth/me/role").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"PETSITTER\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertThat(json.readTree(roleBody).at("/user/role").asText()).isEqualTo("PETSITTER");

        mvc.perform(put("/api/auth/me/role").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"ADMIN\"}"))
                .andExpect(status().isForbidden());

        mvc.perform(put("/api/auth/me/password").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("currentPassword", "faux", "newPassword", "autre2025"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("WRONG_PASSWORD"));

        mvc.perform(put("/api/auth/me/password").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("currentPassword", "profil2025", "newPassword", "autre2025"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    @DisplayName("messagerie : une conversation par paire, non-lus, lecture, accès réservé aux participants")
    void messagingFlow() throws Exception {
        JsonNode amira = register("Amira", uniqueEmail("amira"), "amira2025");
        JsonNode sami = register("Sami", uniqueEmail("sami"), "sami20255");
        JsonNode intrus = register("Intrus", uniqueEmail("intrus"), "intrus2025");
        String amiraToken = amira.get("token").asText();
        String samiToken = sami.get("token").asText();
        String samiId = sami.at("/user/id").asText();
        String amiraId = amira.at("/user/id").asText();

        JsonNode conversation = json.readTree(postJson("/api/conversations",
                        Map.of("participantId", samiId, "subject", "Garde de Simba", "message", "Bonjour Sami !"),
                        amiraToken)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        long conversationId = conversation.get("id").asLong();
        assertThat(conversation.at("/otherUser/id").asText()).isEqualTo(samiId);
        assertThat(conversation.get("lastMessage").asText()).isEqualTo("Bonjour Sami !");
        assertThat(conversation.get("lastMessageMine").asBoolean()).isTrue();

        // Sami ouvre la même paire : même conversation.
        JsonNode same = json.readTree(postJson("/api/conversations", Map.of("participantId", amiraId), samiToken)
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(same.get("id").asLong()).isEqualTo(conversationId);

        mvc.perform(get("/api/conversations/unread-count").header("Authorization", "Bearer " + samiToken))
                .andExpect(jsonPath("$.count").value(1));
        mvc.perform(get("/api/conversations").header("Authorization", "Bearer " + samiToken))
                .andExpect(jsonPath("$[0].unreadCount").value(1))
                .andExpect(jsonPath("$[0].otherUser.firstName").value("Amira"))
                .andExpect(jsonPath("$[0].otherUser.email").doesNotExist());

        JsonNode reply = json.readTree(postJson("/api/conversations/" + conversationId + "/messages",
                        Map.of("content", "Avec plaisir, je garde Simba."), samiToken)
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(reply.get("mine").asBoolean()).isTrue();

        mvc.perform(get("/api/conversations/" + conversationId + "/messages")
                        .header("Authorization", "Bearer " + amiraToken))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].content").value("Bonjour Sami !"))
                .andExpect(jsonPath("$[0].mine").value(true))
                .andExpect(jsonPath("$[1].mine").value(false));

        mvc.perform(get("/api/conversations/" + conversationId + "/messages")
                        .param("afterId", String.valueOf(reply.get("id").asLong() - 1))
                        .header("Authorization", "Bearer " + amiraToken))
                .andExpect(jsonPath("$.length()").value(1));

        postJson("/api/conversations/" + conversationId + "/read", Map.of(), samiToken).andExpect(status().isOk());
        mvc.perform(get("/api/conversations/unread-count").header("Authorization", "Bearer " + samiToken))
                .andExpect(jsonPath("$.count").value(0));

        mvc.perform(get("/api/conversations/" + conversationId + "/messages")
                        .header("Authorization", "Bearer " + intrus.get("token").asText()))
                .andExpect(status().isForbidden());
        postJson("/api/conversations/" + conversationId + "/messages", Map.of("content", "   "), amiraToken)
                .andExpect(status().isBadRequest());
        postJson("/api/conversations", Map.of("participantId", amiraId), amiraToken)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("SELF_CONVERSATION"));
    }

    @Test
    @DisplayName("le jeton remplace l'en-tête X-Demo-User-Id des autres modules (pas d'usurpation)")
    void tokenOverridesDemoHeader() throws Exception {
        JsonNode user = register("Reel", uniqueEmail("reel"), "reel20255");
        mvc.perform(get("/api/auth/me")
                        .header("Authorization", "Bearer " + user.get("token").asText())
                        .header("X-Demo-User-Id", "ADMIN_DEMO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(user.at("/user/id").asText()));
    }

    @Test
    @DisplayName("comptes de démonstration : connexion avec le mot de passe par défaut")
    void demoAccountsCanLogIn() throws Exception {
        postJson("/api/auth/login", Map.of("email", "amira@petsitter.test", "password", "Demo1234"), null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.id").value("OWNER_DEMO"));
    }

    @Test
    @DisplayName("suppression : seul l'expéditeur, texte masqué pour tous, aperçu et non-lus mis à jour")
    void messageDeletion() throws Exception {
        JsonNode alice = register("Alice", uniqueEmail("alice-del"), "alice2025");
        JsonNode bob = register("Bob", uniqueEmail("bob-del"), "bobby2025");
        String aliceToken = alice.get("token").asText();
        String bobToken = bob.get("token").asText();
        long conversationId = json.readTree(postJson("/api/conversations",
                        Map.of("participantId", bob.at("/user/id").asText(), "message", "Premier message"), aliceToken)
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("id").asLong();
        String url = "/api/conversations/" + conversationId + "/messages";
        long secret = json.readTree(postJson(url, Map.of("content", "Mon code de porte est 1234"), aliceToken)
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("id").asLong();
        mvc.perform(get("/api/conversations/unread-count").header("Authorization", "Bearer " + bobToken))
                .andExpect(jsonPath("$.count").value(2));

        // Bob ne peut pas supprimer le message d'Alice.
        mvc.perform(delete(url + "/" + secret).header("Authorization", "Bearer " + bobToken))
                .andExpect(status().isForbidden());

        // Alice le supprime : plus de texte, pour personne.
        mvc.perform(delete(url + "/" + secret).header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.deleted").value(true))
                .andExpect(jsonPath("$.content").value(""));
        mvc.perform(get(url).header("Authorization", "Bearer " + bobToken))
                .andExpect(jsonPath("$[1].deleted").value(true))
                .andExpect(jsonPath("$[1].content").value(""))
                .andExpect(jsonPath("$[0].deleted").value(false));
        mvc.perform(get("/api/conversations").header("Authorization", "Bearer " + bobToken))
                .andExpect(jsonPath("$[0].lastMessage").value("Message supprimé"))
                .andExpect(jsonPath("$[0].unreadCount").value(1));

        // Une deuxième suppression ne change rien ; un message inconnu → 404.
        mvc.perform(delete(url + "/" + secret).header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk());
        mvc.perform(delete(url + "/999999").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("assistant IA (service Python arrêté → règles locales) : arnaque confirmée, avertissement, suggestions")
    void messagingAssistant() throws Exception {
        JsonNode owner = register("Leila", uniqueEmail("leila-ai"), "leila2025");
        JsonNode sitter = register("Samir", uniqueEmail("samir-ai"), "samir2025");
        String ownerToken = owner.get("token").asText();
        String sitterToken = sitter.get("token").asText();
        long conversationId = json.readTree(postJson("/api/conversations",
                        Map.of("participantId", owner.at("/user/id").asText(), "message", "Bonjour Leila !"),
                        sitterToken)
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("id").asLong();
        String url = "/api/conversations/" + conversationId + "/messages";

        // Message ordinaire : envoyé, sans risque.
        postJson(url, Map.of("content", "Simba mange deux fois par jour."), sitterToken)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.risk").value("NONE"));

        // Arnaque : refusée tant que l'expéditeur ne confirme pas, et rien n'est enregistré.
        String scam = "Pour réserver, envoie l'argent par Western Union avant samedi";
        postJson(url, Map.of("content", scam), sitterToken)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("RISKY_MESSAGE"))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.startsWith("Demande de paiement")));
        mvc.perform(get(url).header("Authorization", "Bearer " + ownerToken))
                .andExpect(jsonPath("$.length()").value(2));

        // Confirmé : envoyé et signalé au destinataire.
        postJson(url, Map.of("content", scam, "confirmRisk", true), sitterToken)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.risk").value("HIGH"));
        mvc.perform(get(url).header("Authorization", "Bearer " + ownerToken))
                .andExpect(jsonPath("$[2].mine").value(false))
                .andExpect(jsonPath("$[2].risk").value("HIGH"))
                .andExpect(jsonPath("$[2].riskReason").isNotEmpty());

        // Gros mot tunisien : retenu, puis enregistré avec des étoiles pour tout le monde.
        postJson(url, Map.of("content", "Si zebi"), sitterToken)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("tunisien")));
        postJson(url, Map.of("content", "Si zebi", "confirmRisk", true), sitterToken)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.content").value("Si z**i"))
                .andExpect(jsonPath("$.risk").value("HIGH"));
        mvc.perform(get(url).header("Authorization", "Bearer " + ownerToken))
                .andExpect(jsonPath("$[3].content").value("Si z**i"));
        mvc.perform(get("/api/conversations").header("Authorization", "Bearer " + ownerToken))
                .andExpect(jsonPath("$[0].lastMessage").value("Si z**i"));

        // Coordonnées partagées : risque faible, envoyé sans confirmation.
        postJson(url, Map.of("content", "Mon numéro : 22 333 444"), sitterToken)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.risk").value("LOW"));

        // Suggestions de réponse pour la propriétaire.
        postJson(url, Map.of("content", "Êtes-vous disponible ce week-end ?"), sitterToken)
                .andExpect(status().isCreated());
        mvc.perform(get("/api/conversations/" + conversationId + "/ai/replies")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.replies.length()").value(3))
                .andExpect(jsonPath("$.source").value("local"));
    }
}
