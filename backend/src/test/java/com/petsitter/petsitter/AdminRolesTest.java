package com.petsitter.petsitter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.petsitter.auth.service.PasswordResetMailer;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Un vrai compte administrateur (créé par l'inscription, puis passé ADMIN) est reconnu
 * par le module Garde, et un administrateur ne réserve ni garde ni place d'événement.
 */
@SpringBootTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.datasource.url=jdbc:h2:mem:petsitter-admin-roles;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.show-sql=false",
        "events.ai.url=http://127.0.0.1:1",
        "messaging.ai.url=http://127.0.0.1:1"
})
@AutoConfigureMockMvc
class AdminRolesTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @Autowired
    private UserRepository users;

    @MockBean
    private PasswordResetMailer mailer;

    /** Inscrit un compte et renvoie son identifiant ; [role] est appliqué ensuite si besoin. */
    private String account(String firstName, UserRole role) throws Exception {
        String email = firstName.toLowerCase() + "-" + UUID.randomUUID().toString().substring(0, 8) + "@exemple.tn";
        String body = mvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of(
                                "firstName", firstName, "email", email, "password", "motdepasse1"))))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        String id = json.readTree(body).at("/user/id").asText();
        UserEntity user = users.findById(id).orElseThrow();
        user.setRole(role);
        users.save(user);
        return id;
    }

    @Test
    @DisplayName("un vrai administrateur accède à l'administration des sitters, un propriétaire non")
    void realAdminIsRecognized() throws Exception {
        String dali = account("Dali", UserRole.ADMIN);
        String aziz = account("Aziz", UserRole.OWNER);

        mvc.perform(get("/api/admin/sitters").header("X-User-Id", dali)).andExpect(status().isOk());
        mvc.perform(get("/api/admin/sitters").header("X-User-Id", aziz)).andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("un administrateur ne réserve pas de garde")
    void adminCannotBookASitter() throws Exception {
        String dali = account("Dali", UserRole.ADMIN);
        Map<String, Object> booking = Map.of(
                "sitterId", "sitter-inconnu",
                "petName", "Rex",
                "petType", "DOG",
                "petSize", "MEDIUM",
                "service", "BOARDING",
                "startDate", LocalDate.now().plusDays(2).toString(),
                "endDate", LocalDate.now().plusDays(4).toString());

        mvc.perform(post("/api/reservations")
                        .header("X-User-Id", dali)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(booking)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("un administrateur ne réserve pas de place à un événement")
    void adminCannotReserveAnEventPlace() throws Exception {
        String dali = account("Dali", UserRole.ADMIN);
        Map<String, Object> reservation = Map.of(
                "participantName", "Dali Chrayta",
                "phone", "22 345 678",
                "numberOfPlaces", 1);

        mvc.perform(post("/api/events/un-evenement/reservations")
                        .header("X-User-Id", dali)
                        .header("X-Demo-User-Id", dali)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(reservation)))
                .andExpect(status().isForbidden());
    }
}
