package com.petsitter.store.insights;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.petsitter.store.insights.SalesDtos.LowStock;
import com.petsitter.store.insights.SalesDtos.SalesStats;
import com.petsitter.store.insights.SalesDtos.TopProduct;
import com.petsitter.store.order.Order;
import com.petsitter.store.order.OrderEnums.OrderStatus;
import com.petsitter.store.order.OrderItem;
import com.petsitter.store.order.OrderRepository;
import com.petsitter.store.product.ProductOptionRepository;

@Service
public class SalesStatsService {

	static final int LOW_STOCK = 5;

	private static final int TOP = 5;

	private final OrderRepository orders;

	private final ProductOptionRepository options;

	public SalesStatsService(OrderRepository orders, ProductOptionRepository options) {
		this.orders = orders;
		this.options = options;
	}

	@Transactional(readOnly = true)
	public SalesStats compute(int days) {
		Instant to = Instant.now();
		Instant from = to.minus(Duration.ofDays(days));
		Instant previousFrom = from.minus(Duration.ofDays(days));
		List<Order> recent = orders.findByCreatedAtGreaterThanEqual(previousFrom);

		List<Order> current = recent.stream().filter(o -> !o.getCreatedAt().isBefore(from)).toList();
		List<Order> sold = current.stream().filter(o -> o.getStatus() != OrderStatus.CANCELLED).toList();
		int revenue = sold.stream().mapToInt(Order::getTotal).sum();
		int previousRevenue = recent.stream()
			.filter(o -> o.getCreatedAt().isBefore(from) && o.getStatus() != OrderStatus.CANCELLED)
			.mapToInt(Order::getTotal)
			.sum();

		Map<String, TopProduct> byProduct = new LinkedHashMap<>();
		for (Order o : sold) {
			for (OrderItem i : o.getItems()) {
				byProduct.merge(i.getProductId(),
						new TopProduct(i.getProductId(), i.getProductName(), i.getQuantity(), i.getLineTotal()),
						(a, b) -> new TopProduct(a.productId(), a.name(), a.quantity() + b.quantity(),
								a.revenue() + b.revenue()));
			}
		}
		List<TopProduct> top = byProduct.values()
			.stream()
			.sorted(Comparator.comparingInt(TopProduct::quantity).reversed().thenComparing(TopProduct::name))
			.limit(TOP)
			.toList();

		List<LowStock> low = options.findLowStock(LOW_STOCK)
			.stream()
			.map(o -> new LowStock(o.getProduct().getId(), o.getProduct().getName(), o.getLabel(), o.getStock()))
			.toList();

		return new SalesStats(days, from, to, sold.size(), revenue, previousRevenue,
				changePercent(revenue, previousRevenue), sold.isEmpty() ? 0 : Math.round((float) revenue / sold.size()),
				current.size() - sold.size(), sold.stream().mapToInt(Order::getItemCount).sum(), top, low);
	}

	/** Sans ventes sur la période précédente, l'évolution n'a pas de sens : null plutôt qu'un pourcentage infini. */
	static Integer changePercent(int current, int previous) {
		if (previous == 0) {
			return null;
		}
		return Math.round((current - previous) * 100f / previous);
	}

}
