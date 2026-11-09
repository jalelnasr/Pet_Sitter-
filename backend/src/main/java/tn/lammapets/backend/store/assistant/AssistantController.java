package tn.lammapets.backend.store.assistant;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import tn.lammapets.backend.store.assistant.AssistantDtos.AssistantRequest;
import tn.lammapets.backend.store.assistant.AssistantDtos.AssistantResponse;

import jakarta.validation.Valid;

@RestController
public class AssistantController {

	private final AssistantService service;

	public AssistantController(AssistantService service) {
		this.service = service;
	}

	@PostMapping("/api/assistant")
	AssistantResponse ask(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody AssistantRequest req) {
		return service.ask(jwt.getSubject(), req.question());
	}

}
