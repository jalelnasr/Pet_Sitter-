package tn.lammapets.backend.store.assistant;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.Test;

import tn.lammapets.backend.store.assistant.AssistantDtos.Recommendation;
import tn.lammapets.backend.store.assistant.AssistantProvider.Answer;
import tn.lammapets.backend.store.assistant.AssistantProvider.Pick;
import tn.lammapets.backend.store.product.PackKind;
import tn.lammapets.backend.store.product.ProductDtos.OptionResponse;
import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;
import tn.lammapets.backend.store.product.ShopCategory;
import tn.lammapets.backend.store.product.Species;

class AssistantServiceTests {

	private static ProductResponse product(String id) {
		return new ProductResponse(id, "Nom " + id, "Marque", ShopCategory.jouets, Set.of(Species.chat),
				List.of(new OptionResponse(1L, "S", 10, 5), new OptionResponse(2L, "L", 20, 0)), BigDecimal.ZERO, 0,
				PackKind.object, "#000000", "#FFFFFF", "cat", null, "Description", List.of(), null, null, true);
	}

	@Test
	void inventedDuplicatedAndNullPicksAreRemoved() {
		Answer answer = new Answer("Voici", java.util.Arrays.asList(new Pick("a", "bien"), new Pick("invente", "faux"),
				new Pick("a", "doublon"), null, new Pick(null, "rien"), new Pick("b", "aussi")));
		List<Recommendation> result = AssistantService.verified(answer, List.of(product("a"), product("b")));
		assertThat(result).extracting(r -> r.product().id()).containsExactly("a", "b");
		assertThat(result.get(0).reason()).isEqualTo("bien");
	}

	@Test
	void noPicksAndTooManyPicksAreHandled() {
		assertThat(AssistantService.verified(new Answer("Non", null), List.of(product("a")))).isEmpty();
		List<ProductResponse> many = List.of(product("1"), product("2"), product("3"), product("4"), product("5"),
				product("6"), product("7"));
		List<Pick> picks = many.stream().map(p -> new Pick(p.id(), "r")).toList();
		assertThat(AssistantService.verified(new Answer("Oui", picks), many)).hasSize(6);
	}

	@Test
	void catalogueTextListsOnlyFormatsInStock() {
		String text = ClaudeAssistantProvider.describe(List.of(product("a")));
		assertThat(text).contains("id=a").contains("formats : S").doesNotContain("formats : S, L");
	}

	@Test
	void demoSendsHealthQuestionsToAVetAndNeverProposesProducts() {
		Answer answer = new DemoAssistantProvider().recommend("Mon chat est malade", List.of(product("a")));
		assertThat(answer.picks()).isEmpty();
		assertThat(answer.message()).contains("vétérinaire");
	}

}
