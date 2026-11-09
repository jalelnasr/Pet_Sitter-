package tn.lammapets.backend.store.insights;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.insights.SalesCommentator.Commentary;
import tn.lammapets.backend.store.insights.SalesDtos.SalesStats;
import tn.lammapets.backend.store.insights.SalesDtos.SalesSummaryResponse;

@Service
public class SalesSummaryService {

	private static final int MAX_CACHED = 50;

	private final SalesStatsService stats;

	private final SalesCommentator commentator;

	/** Mêmes chiffres, même texte : on ne repaie pas l'IA à chaque ouverture de l'écran. */
	private final Map<String, Commentary> cache = new ConcurrentHashMap<>();

	public SalesSummaryService(SalesStatsService stats, @Value("${app.assistant.api-key}") String apiKey,
			@Value("${app.assistant.model}") String model, @Value("${app.assistant.demo}") boolean demo) {
		this.stats = stats;
		this.commentator = !apiKey.isBlank() ? new ClaudeSalesCommentator(apiKey, model)
				: demo ? new DemoSalesCommentator() : null;
	}

	/** Les chiffres s'affichent toujours ; seul le commentaire peut manquer. */
	public SalesSummaryResponse summary(int days) {
		if (days < 1 || days > 90) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "La période doit faire de 1 à 90 jours.");
		}
		SalesStats s = stats.compute(days);
		if (commentator == null) {
			return new SalesSummaryResponse(s, null, List.of(), false, "L'analyse par IA n'est pas encore activée.");
		}
		try {
			Commentary c = cache.get(key(s));
			if (c == null) {
				c = commentator.comment(s);
				if (cache.size() >= MAX_CACHED) {
					cache.clear();
				}
				cache.put(key(s), c);
			}
			return new SalesSummaryResponse(s, c.summary(), c.points(), commentator.isDemo(), null);
		}
		catch (ApiException e) {
			return new SalesSummaryResponse(s, null, List.of(), commentator.isDemo(), e.getMessage());
		}
	}

	/** Tout sauf les dates de début et de fin, qui changent à chaque appel. */
	private static String key(SalesStats s) {
		return SalesCommentator.describe(s);
	}

}
