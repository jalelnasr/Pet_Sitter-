package com.petsitter.event.controller;

import com.petsitter.event.dto.EventAiSuggestRequest;
import com.petsitter.event.dto.EventAiSuggestResponse;
import com.petsitter.event.security.EventUserResolver;
import com.petsitter.event.service.EventAiService;
import com.petsitter.user.entity.UserEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/events/ai")
@Tag(name = "Events AI", description = "Endpoints for AI-powered event assistant and content suggestions")
public class EventAiController {

    private final EventAiService eventAiService;
    private final EventUserResolver userResolver;

    public EventAiController(EventAiService eventAiService, EventUserResolver userResolver) {
        this.eventAiService = eventAiService;
        this.userResolver = userResolver;
    }

    @PostMapping("/suggest")
    @Operation(summary = "Generate content suggestions for an event (ADMIN and PETSITTER only)")
    public ResponseEntity<EventAiSuggestResponse> suggest(
            @Valid @RequestBody EventAiSuggestRequest request,
            HttpServletRequest httpRequest
    ) {
        UserEntity actor = userResolver.resolve(httpRequest);
        EventAiSuggestResponse response = eventAiService.suggest(request, actor);
        return ResponseEntity.ok(response);
    }
}
