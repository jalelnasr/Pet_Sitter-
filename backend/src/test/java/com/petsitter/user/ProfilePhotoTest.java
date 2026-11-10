package com.petsitter.user;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petsitter.auth.service.PasswordResetMailer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Photo de profil : envoi depuis la galerie, affichage, format refusé, retrait. */
@SpringBootTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.datasource.url=jdbc:h2:mem:petsitter-photo;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.show-sql=false",
        "petsitter.upload.dir=target/test-uploads",
        "messaging.ai.url=http://127.0.0.1:1"
})
@AutoConfigureMockMvc
class ProfilePhotoTest {

    /** Image PNG de 1 × 1 pixel. */
    private static final byte[] PNG = Base64.getDecoder().decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==");

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @MockBean
    private PasswordResetMailer mailer;

    private String token() throws Exception {
        String email = "photo-" + UUID.randomUUID().toString().substring(0, 8) + "@exemple.tn";
        String body = mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("firstName", "Aziz", "email", email, "password", "motdepasse1"))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return json.readTree(body).get("token").asText();
    }

    private ResultActions upload(String token, byte[] bytes, String name) throws Exception {
        // Type annoncé volontairement générique : le serveur reconnaît le format au contenu.
        return mvc.perform(multipart("/api/auth/me/photo")
                .file(new MockMultipartFile("file", name, "application/octet-stream", bytes))
                .header("Authorization", "Bearer " + token));
    }

    @Test
    @DisplayName("la photo envoyée est enregistrée sur le compte, servie, puis retirée")
    void uploadServeAndRemove() throws Exception {
        String token = token();

        JsonNode user = json.readTree(upload(token, PNG, "moi.png")
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        String photoUrl = user.get("photoUrl").asText();
        assertThat(photoUrl).startsWith("/uploads/users/").endsWith(".png");

        mvc.perform(get(photoUrl)).andExpect(status().isOk());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.photoUrl").value(photoUrl));

        // Une nouvelle photo remplace l'ancienne (l'ancien fichier est supprimé).
        String second = json.readTree(upload(token, PNG, "moi2.png")
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8)).get("photoUrl").asText();
        assertThat(second).isNotEqualTo(photoUrl);
        mvc.perform(get(photoUrl)).andExpect(status().isNotFound());

        mvc.perform(delete("/api/auth/me/photo").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.photoUrl").doesNotExist());
    }

    @Test
    @DisplayName("un fichier qui n'est pas une image est refusé ; la connexion est obligatoire")
    void rejectsNonImages() throws Exception {
        String token = token();
        upload(token, "bonjour".getBytes(StandardCharsets.UTF_8), "photo.jpg")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_IMAGE_TYPE"));

        mvc.perform(multipart("/api/auth/me/photo").file(new MockMultipartFile("file", "moi.png", "image/png", PNG)))
                .andExpect(status().isUnauthorized());
    }
}
