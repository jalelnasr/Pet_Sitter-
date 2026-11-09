package tn.lammapets.backend.store.assistant;

import java.util.List;

import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;

/** Service qui choisit des produits : changer de fournisseur d'IA revient à écrire une autre implémentation. */
public interface AssistantProvider {

	Answer recommend(String question, List<ProductResponse> catalogue);

	/** Vrai quand la réponse ne vient pas d'une IA : l'écran le signale. */
	default boolean isDemo() {
		return false;
	}

	/** Réponse brute du fournisseur : elle n'est jamais renvoyée au client sans vérification. */
	record Answer(String message, List<Pick> picks) {
	}

	record Pick(String productId, String reason) {
	}

}
