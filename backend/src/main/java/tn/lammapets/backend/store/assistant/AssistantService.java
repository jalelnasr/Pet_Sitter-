package tn.lammapets.backend.store.assistant;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.assistant.AssistantDtos.AssistantResponse;
import tn.lammapets.backend.store.assistant.AssistantDtos.Recommendation;
import tn.lammapets.backend.store.assistant.AssistantProvider.Answer;
import tn.lammapets.backend.store.assistant.AssistantProvider.Pick;
import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;
import tn.lammapets.backend.store.product.ProductService;

@Service
public class AssistantService {

	private static final int MAX_RECOMMENDATIONS = 6;

	private static final Duration WINDOW = Duration.ofHours(1);

	private final AssistantProvider provider;

	private final ProductService products;

	private final int maxPerHour;

	private final Map<String, Deque<Instant>> calls = new ConcurrentHashMap<>();

	public AssistantService(AssistantProvider provider, ProductService products,
			@Value("${app.assistant.max-per-hour}") int maxPerHour) {
		this.provider = provider;
		this.products = products;
		this.maxPerHour = maxPerHour;
	}

	/** Pas de transaction ici : la base ne reste pas occupée pendant l'appel au fournisseur, qui peut durer. */
	public AssistantResponse ask(String userId, String question) {
		checkLimit(userId);
		List<ProductResponse> catalogue = products.inStock();
		Answer answer = provider.recommend(question.trim(), catalogue);
		return new AssistantResponse(answer.message(), verified(answer, catalogue), provider.isDemo());
	}

	/** Le fournisseur peut se tromper : seuls les produits réellement en vente sortent, avec les prix de la base. */
	static List<Recommendation> verified(Answer answer, List<ProductResponse> catalogue) {
		if (answer.picks() == null) {
			return List.of();
		}
		Set<String> seen = new HashSet<>();
		List<Recommendation> result = new ArrayList<>();
		for (Pick pick : answer.picks()) {
			if (pick == null || !seen.add(String.valueOf(pick.productId())) || result.size() == MAX_RECOMMENDATIONS) {
				continue;
			}
			catalogue.stream()
				.filter(p -> p.id().equals(pick.productId()))
				.findFirst()
				.ifPresent(p -> result.add(new Recommendation(p, pick.reason())));
		}
		return result;
	}

	/** Chaque question peut coûter de l'argent : on limite le nombre d'appels par compte. */
	private void checkLimit(String userId) {
		Instant now = Instant.now();
		Deque<Instant> history = calls.computeIfAbsent(userId, id -> new ArrayDeque<>());
		synchronized (history) {
			while (!history.isEmpty() && history.peekFirst().isBefore(now.minus(WINDOW))) {
				history.removeFirst();
			}
			if (history.size() >= maxPerHour) {
				throw new ApiException(HttpStatus.TOO_MANY_REQUESTS,
						"Vous avez posé beaucoup de questions. Réessayez dans un moment.");
			}
			history.addLast(now);
		}
	}

}
