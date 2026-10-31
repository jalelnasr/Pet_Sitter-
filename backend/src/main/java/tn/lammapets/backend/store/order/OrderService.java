package tn.lammapets.backend.store.order;

import java.util.Map;
import java.util.TreeMap;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.order.OrderDtos.CreateOrderRequest;
import tn.lammapets.backend.store.order.OrderDtos.ItemRequest;
import tn.lammapets.backend.store.order.OrderDtos.OrderResponse;
import tn.lammapets.backend.store.order.OrderEnums.OrderStatus;
import tn.lammapets.backend.store.order.OrderEnums.PaymentMethod;
import tn.lammapets.backend.store.product.ProductDtos.PageResponse;
import tn.lammapets.backend.store.product.ProductOption;
import tn.lammapets.backend.store.product.ProductOptionRepository;
import tn.lammapets.backend.user.User;
import tn.lammapets.backend.user.UserRepository;

@Service
public class OrderService {

	/** Mêmes règles que CartRepository dans l'application. */
	static final int FREE_SHIPPING_FROM = 80;

	static final int SHIPPING_FEE = 7;

	private static final int MAX_PAGE_SIZE = 100;

	private final OrderRepository orders;

	private final ProductOptionRepository options;

	private final UserRepository users;

	public OrderService(OrderRepository orders, ProductOptionRepository options, UserRepository users) {
		this.orders = orders;
		this.options = options;
		this.users = users;
	}

	@Transactional
	public OrderResponse create(String userId, CreateOrderRequest req) {
		if (req.payment() == PaymentMethod.CARD) {
			throw new ApiException(HttpStatus.BAD_REQUEST,
					"Le paiement par carte n'est pas encore disponible. Choisissez le paiement à la livraison.");
		}
		User user = users.findById(userId)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Compte introuvable."));

		// Même format envoyé deux fois : une seule ligne. Tri par id : verrous toujours pris dans le même ordre.
		Map<Long, Integer> quantities = new TreeMap<>();
		for (ItemRequest item : req.items()) {
			quantities.merge(item.optionId(), item.quantity(), Integer::sum);
		}

		Order order = new Order(user, req);
		for (Map.Entry<Long, Integer> line : quantities.entrySet()) {
			ProductOption option = options.findById(line.getKey())
				.filter(o -> o.isActive() && o.getProduct().isActive())
				.orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "Un article du panier n'est plus en vente."));
			if (options.decrementStock(option.getId(), line.getValue()) == 0) {
				throw new ApiException(HttpStatus.CONFLICT, "Stock insuffisant pour « %s · %s ».".formatted(
						option.getProduct().getName(), option.getLabel()));
			}
			order.addItem(option, line.getValue());
		}
		order.applyShipping(order.getSubtotal() >= FREE_SHIPPING_FROM ? 0 : SHIPPING_FEE);

		orders.saveAndFlush(order);
		order.assignNumber();
		return OrderResponse.of(order);
	}

	@Transactional(readOnly = true)
	public PageResponse<OrderResponse> mine(String userId, int page, int size) {
		return PageResponse.of(orders.findByUserId(userId, pageable(page, size)).map(OrderResponse::of));
	}

	@Transactional(readOnly = true)
	public OrderResponse get(Long id, String userId, boolean admin) {
		return OrderResponse.of(findVisible(id, userId, admin));
	}

	/** Le client peut annuler tant que la préparation n'a pas commencé. */
	@Transactional
	public OrderResponse cancel(Long id, String userId, boolean admin) {
		Order order = findVisible(id, userId, admin);
		if (order.getStatus() != OrderStatus.CONFIRMED) {
			throw new ApiException(HttpStatus.CONFLICT, "Cette commande est déjà en préparation et ne peut plus être annulée.");
		}
		return move(order, OrderStatus.CANCELLED);
	}

	@Transactional(readOnly = true)
	public PageResponse<OrderResponse> search(OrderStatus status, int page, int size) {
		return PageResponse.of(orders.search(status, pageable(page, size)).map(OrderResponse::of));
	}

	@Transactional
	public OrderResponse changeStatus(Long id, OrderStatus next) {
		Order order = orders.findById(id).orElseThrow(OrderService::notFound);
		if (!order.getStatus().next().contains(next)) {
			throw new ApiException(HttpStatus.CONFLICT,
					"Passage de %s à %s impossible.".formatted(order.getStatus(), next));
		}
		return move(order, next);
	}

	private OrderResponse move(Order order, OrderStatus next) {
		order.moveTo(next);
		// Flush d'abord : si une autre requête a changé la commande, @Version échoue avant la remise en stock.
		orders.flush();
		if (next == OrderStatus.CANCELLED) {
			order.getItems().forEach(i -> options.incrementStock(i.getOptionId(), i.getQuantity()));
		}
		return OrderResponse.of(order);
	}

	private Order findVisible(Long id, String userId, boolean admin) {
		Order order = orders.findById(id).orElseThrow(OrderService::notFound);
		// 404 et non 403 : ne pas révéler l'existence des commandes des autres.
		if (!admin && !order.getUser().getId().equals(userId)) {
			throw notFound();
		}
		return order;
	}

	private static PageRequest pageable(int page, int size) {
		return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
				Sort.by(Sort.Direction.DESC, "createdAt"));
	}

	private static ApiException notFound() {
		return new ApiException(HttpStatus.NOT_FOUND, "Commande introuvable.");
	}

}
