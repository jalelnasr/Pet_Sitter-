package com.petsitter.event;

import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.event.dto.EventAiSuggestRequest;
import com.petsitter.event.dto.EventAiSuggestResponse;
import com.petsitter.event.service.EventAiService;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class EventAiServiceTest {

    private EventAiService service;

    @BeforeEach
    void setUp() {
        // Points to an unreachable port to test graceful fallback
        service = new EventAiService("http://localhost:59999", 500, 500);
    }

    @Test
    void suggest_withAdminUser_returnsFallbackWhenFastApiIsDown() {
        UserEntity admin = new UserEntity("ADMIN_USER", "Admin", "admin@petsitter.tn", UserRole.ADMIN);

        EventAiSuggestRequest request = new EventAiSuggestRequest(
                "Atelier Chiot",
                List.of("chiot", "socialisation"),
                "Éducation",
                "Tunis",
                "Apprendre les bases du rappel"
        );

        EventAiSuggestResponse response = service.suggest(request, admin);

        assertNotNull(response);
        assertEquals("fallback", response.source());
        assertEquals("Éducation", response.suggestedCategory());
        assertFalse(response.titles().isEmpty());
        assertFalse(response.checklist().isEmpty());
        assertNotNull(response.description());
        assertNotNull(response.summary());
        assertNotNull(response.tip());
    }

    @Test
    void suggest_withOwnerUser_throwsUnauthorizedActionException() {
        UserEntity owner = new UserEntity("OWNER_USER", "Owner", "owner@petsitter.tn", UserRole.OWNER);

        EventAiSuggestRequest request = new EventAiSuggestRequest(
                "Promenade",
                List.of("chien"),
                "Promenade",
                "Marsa",
                null
        );

        assertThrows(UnauthorizedActionException.class, () -> service.suggest(request, owner));
    }
}
