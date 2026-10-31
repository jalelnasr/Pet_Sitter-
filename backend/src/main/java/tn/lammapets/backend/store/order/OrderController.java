package tn.lammapets.backend.store.order;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import tn.lammapets.backend.store.order.OrderDtos.CreateOrderRequest;
import tn.lammapets.backend.store.order.OrderDtos.OrderResponse;
import tn.lammapets.backend.store.order.OrderDtos.StatusRequest;
import tn.lammapets.backend.store.order.OrderEnums.OrderStatus;
import tn.lammapets.backend.store.product.ProductDtos.PageResponse;

import jakarta.validation.Valid;

@RestController
public class OrderController {

	private final OrderService service;

	public OrderController(OrderService service) {
		this.service = service;
	}

	@PostMapping("/api/orders")
	@ResponseStatus(HttpStatus.CREATED)
	OrderResponse create(Authentication auth, @Valid @RequestBody CreateOrderRequest req) {
		return service.create(userId(auth), req);
	}

	@GetMapping("/api/orders/me")
	PageResponse<OrderResponse> mine(Authentication auth, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		return service.mine(userId(auth), page, size);
	}

	@GetMapping("/api/orders/{id}")
	OrderResponse get(Authentication auth, @PathVariable Long id) {
		return service.get(id, userId(auth), isAdmin(auth));
	}

	@PostMapping("/api/orders/{id}/cancel")
	OrderResponse cancel(Authentication auth, @PathVariable Long id) {
		return service.cancel(id, userId(auth), isAdmin(auth));
	}

	@GetMapping("/api/admin/orders")
	PageResponse<OrderResponse> search(@RequestParam(required = false) OrderStatus status,
			@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
		return service.search(status, page, size);
	}

	@PatchMapping("/api/admin/orders/{id}/status")
	OrderResponse changeStatus(@PathVariable Long id, @Valid @RequestBody StatusRequest req) {
		return service.changeStatus(id, req.status());
	}

	private static String userId(Authentication auth) {
		return ((Jwt) auth.getPrincipal()).getSubject();
	}

	private static boolean isAdmin(Authentication auth) {
		return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
	}

}
