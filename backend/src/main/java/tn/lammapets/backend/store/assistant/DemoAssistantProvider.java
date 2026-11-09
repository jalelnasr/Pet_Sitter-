package tn.lammapets.backend.store.assistant;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;
import tn.lammapets.backend.store.product.Species;

/** Sans clé API, en développement : simple recherche par espèce, sans aucune IA, pour tester le parcours. */
class DemoAssistantProvider implements AssistantProvider {

	private static final Map<String, Species> WORDS = Map.of("chat", Species.chat, "chien", Species.chien, "oiseau",
			Species.oiseau, "perruche", Species.oiseau, "lapin", Species.lapin, "poisson", Species.poisson);

	private static final Pattern HEALTH = Pattern.compile("malade|vomi|sang|bless|douleur|fièvre|médicament");

	@Override
	public boolean isDemo() {
		return true;
	}

	@Override
	public Answer recommend(String question, List<ProductResponse> catalogue) {
		String text = question.toLowerCase(Locale.ROOT);
		if (HEALTH.matcher(text).find()) {
			return new Answer("Pour un problème de santé, consultez un vétérinaire.", List.of());
		}
		for (Map.Entry<String, Species> word : WORDS.entrySet()) {
			if (Pattern.compile("\\b" + word.getKey() + "s?\\b").matcher(text).find()) {
				List<Pick> picks = catalogue.stream()
					.filter(p -> p.species().contains(word.getValue()))
					.limit(3)
					.map(p -> new Pick(p.id(), "Prévu pour : " + word.getKey() + "."))
					.toList();
				return new Answer("Voici des produits pour votre " + word.getKey() + ".", picks);
			}
		}
		return new Answer("Dites-moi quel animal vous avez : chat, chien, oiseau, lapin ou poisson.", List.of());
	}

}
