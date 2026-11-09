package tn.lammapets.backend.store.assistant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;

import tn.lammapets.backend.common.ApiException;

@Configuration
public class AssistantConfig {

	@Bean
	AssistantProvider assistantProvider(@Value("${app.assistant.api-key}") String apiKey,
			@Value("${app.assistant.model}") String model, @Value("${app.assistant.demo}") boolean demo) {
		if (!apiKey.isBlank()) {
			return new ClaudeAssistantProvider(apiKey, model);
		}
		if (demo) {
			return new DemoAssistantProvider();
		}
		return (question, catalogue) -> {
			throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "L'assistant n'est pas encore activé.");
		};
	}

}
