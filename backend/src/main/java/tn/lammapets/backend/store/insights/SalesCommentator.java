package tn.lammapets.backend.store.insights;

import java.util.List;
import java.util.stream.Collectors;

import tn.lammapets.backend.store.insights.SalesDtos.SalesStats;

/** Rédige un commentaire à partir des chiffres : changer de fournisseur d'IA revient à écrire une autre implémentation. */
public interface SalesCommentator {

	Commentary comment(SalesStats stats);

	/** Vrai quand le texte ne vient pas d'une IA : l'écran le signale. */
	default boolean isDemo() {
		return false;
	}

	record Commentary(String summary, List<String> points) {
	}

	/** Les chiffres en texte : c'est tout ce que le fournisseur reçoit, aucune donnée de client. */
	static String describe(SalesStats s) {
		String top = s.topProducts()
			.stream()
			.map(p -> "%s : %d vendus, %d DT".formatted(p.name(), p.quantity(), p.revenue()))
			.collect(Collectors.joining(" ; "));
		String low = s.lowStock()
			.stream()
			.map(l -> "%s (%s) : %d restants".formatted(l.name(), l.option(), l.stock()))
			.collect(Collectors.joining(" ; "));
		return """
				Période : %d derniers jours
				Commandes (hors annulées) : %d
				Chiffre d'affaires : %d DT
				Chiffre d'affaires de la période précédente : %d DT
				Évolution : %s
				Panier moyen : %d DT
				Commandes annulées : %d
				Articles vendus : %d
				Produits les plus vendus : %s
				Stocks bas (5 ou moins) : %s
				""".formatted(s.days(), s.orders(), s.revenue(), s.previousRevenue(),
				s.revenueChangePercent() == null ? "non calculable (aucune vente avant)" : s.revenueChangePercent() + " %",
				s.averageBasket(), s.cancelled(), s.itemsSold(), top.isEmpty() ? "aucun" : top,
				low.isEmpty() ? "aucun" : low);
	}

}
