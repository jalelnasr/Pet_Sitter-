package com.petsitter.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.petsitter.auth.service.PasswordResetMailer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Un événement créé ou proposé ne peut pas être daté dans le passé (il serait aussitôt « Terminé »). */
@SpringBootTest(properties = {
        "petsitter.demo-data=true", // comptes ADMIN_DEMO et PETSITTER_DEMO utilisés par le test
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.datasource.url=jdbc:h2:mem:petsitter-event-dates;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.show-sql=false",
        "events.ai.url=http://127.0.0.1:1",
        "messaging.ai.url=http://127.0.0.1:1"
})
@AutoConfigureMockMvc
class EventDateValidationTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @MockBean
    private PasswordResetMailer mailer;

    private static Map<String, Object> event(LocalDate date) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("title", "Balade canine");
        body.put("description", "Balade de deux heures avec les chiens du quartier.");
        body.put("category", "MEETUP");
        body.put("location", "Sidi Bou Saïd");
        body.put("date", date.toString());
        body.put("startTime", "10:00");
        body.put("endTime", "12:00");
        body.put("capacity", 20);
        body.put("status", "PUBLISHED");
        return body;
    }

    private ResultActions send(String url, String userId, Map<String, Object> body) throws Exception {
        return mvc.perform(post(url)
                .header("X-Demo-User-Id", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(body)));
    }

    @Test
    @DisplayName("l'administrateur ne peut pas publier un événement à une date passée")
    void adminCannotCreateInThePast() throws Exception {
        send("/api/events", "ADMIN_DEMO", event(LocalDate.now().minusDays(3)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("EVENT_DATE_PAST"));

        send("/api/events", "ADMIN_DEMO", event(LocalDate.now().plusDays(1)))
                .andExpect(status().is2xxSuccessful());
        send("/api/events", "ADMIN_DEMO", event(LocalDate.now()))
                .andExpect(status().is2xxSuccessful());
    }

    @Test
    @DisplayName("un pet sitter ne peut pas proposer un événement à une date passée")
    void petsitterCannotProposeInThePast() throws Exception {
        send("/api/events/proposals", "PETSITTER_DEMO", event(LocalDate.now().minusDays(1)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("EVENT_DATE_PAST"));

        send("/api/events/proposals", "PETSITTER_DEMO", event(LocalDate.now().plusDays(7)))
                .andExpect(status().is2xxSuccessful());
    }
}
