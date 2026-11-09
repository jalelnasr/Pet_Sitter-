package com.petsitter.store.insights;

import java.util.ArrayList;
import java.util.List;

import com.petsitter.store.insights.SalesDtos.SalesStats;

/** Sans clé API, en développement : un texte construit à partir des chiffres, sans aucune IA. */
class DemoSalesCommentator implements SalesCommentator {

	@Override
	public boolean isDemo() {
		return true;
	}

	@Override
	public Commentary comment(SalesStats s) {
		String trend = s.revenueChangePercent() == null ? ""
				: " (%+d %% par rapport à la période précédente)".formatted(s.revenueChangePercent());
		String summary = "Sur les %d derniers jours : %d commande%s pour %d DT%s.".formatted(s.days(), s.orders(),
				s.orders() > 1 ? "s" : "", s.revenue(), trend);
		List<String> points = new ArrayList<>();
		s.lowStock().stream().findFirst().ifPresent(l -> points.add("Réapprovisionner « %s · %s » (%s)."
			.formatted(l.name(), l.option(), l.stock() == 0 ? "épuisé" : l.stock() + " restants")));
		if (s.cancelled() > 0) {
			points.add(s.cancelled() == 1 ? "Vérifier la cause de l'annulation."
					: "Vérifier la cause des %d annulations.".formatted(s.cancelled()));
		}
		return new Commentary(summary, points);
	}

}
