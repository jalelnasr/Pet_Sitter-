package tn.lammapets.backend.store.insights;

import java.time.Instant;
import java.util.List;

public final class SalesDtos {

	private SalesDtos() {
	}

	public record TopProduct(String productId, String name, int quantity, int revenue) {
	}

	public record LowStock(String productId, String name, String option, int stock) {
	}

	/**
	 * Chiffres calculés par le serveur à partir de la base. Les commandes annulées ne comptent ni dans le chiffre
	 * d'affaires ni dans le nombre de commandes.
	 */
	public record SalesStats(int days, Instant from, Instant to, int orders, int revenue, int previousRevenue,
			Integer revenueChangePercent, int averageBasket, int cancelled, int itemsSold, List<TopProduct> topProducts,
			List<LowStock> lowStock) {
	}

	/** Commentaire rédigé par l'IA à partir des seuls chiffres ; il peut manquer si le service est indisponible. */
	public record SalesSummaryResponse(SalesStats stats, String commentary, List<String> points, boolean demo,
			String commentaryError) {
	}

}
