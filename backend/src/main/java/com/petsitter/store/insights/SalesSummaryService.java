package com.petsitter.store.insights;

import org.springframework.stereotype.Service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.store.insights.SalesCommentator.Commentary;
import com.petsitter.store.insights.SalesDtos.SalesStats;
import com.petsitter.store.insights.SalesDtos.SalesSummaryResponse;

/**
 * Chiffres de vente calculés à partir de la base. L'analyse par IA est faite par l'application (API Gemini) :
 * le serveur ne fournit qu'un commentaire de secours, construit sans IA.
 */
@Service
public class SalesSummaryService {

	private final SalesStatsService stats;

	private final SalesCommentator fallback = new DemoSalesCommentator();

	public SalesSummaryService(SalesStatsService stats) {
		this.stats = stats;
	}

	public SalesSummaryResponse summary(int days) {
		if (days < 1 || days > 90) {
			throw new BadRequestException("STORE_INVALID", "La période doit faire de 1 à 90 jours.");
		}
		SalesStats s = stats.compute(days);
		Commentary c = fallback.comment(s);
		return new SalesSummaryResponse(s, c.summary(), c.points(), true, null);
	}

}
