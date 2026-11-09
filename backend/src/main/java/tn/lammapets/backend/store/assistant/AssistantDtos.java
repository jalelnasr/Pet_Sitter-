package tn.lammapets.backend.store.assistant;

import java.util.List;

import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AssistantDtos {

	private AssistantDtos() {
	}

	public record AssistantRequest(
			@NotBlank(message = "Écrivez votre question.") @Size(max = 500, message = "Votre question est limitée à 500 caractères.") String question) {
	}

	public record Recommendation(ProductResponse product, String reason) {
	}

	public record AssistantResponse(String message, List<Recommendation> recommendations, boolean demo) {
	}

}
