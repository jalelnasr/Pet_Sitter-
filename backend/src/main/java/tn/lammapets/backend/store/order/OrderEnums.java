package tn.lammapets.backend.store.order;

import java.util.Set;

public final class OrderEnums {

	private OrderEnums() {
	}

	public enum PaymentMethod {
		CASH, CARD
	}

	public enum PaymentStatus {
		PENDING, PAID, CANCELLED
	}

	/** Les quatre étapes de suivi de l'écran « Commande confirmée », plus l'annulation. */
	public enum OrderStatus {
		CONFIRMED, PREPARING, SHIPPED, DELIVERED, CANCELLED;

		public Set<OrderStatus> next() {
			return switch (this) {
				case CONFIRMED -> Set.of(PREPARING, CANCELLED);
				case PREPARING -> Set.of(SHIPPED, CANCELLED);
				case SHIPPED -> Set.of(DELIVERED);
				case DELIVERED, CANCELLED -> Set.of();
			};
		}
	}

}
