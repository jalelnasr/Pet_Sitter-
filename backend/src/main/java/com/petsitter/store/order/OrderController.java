package com.petsitter.store.order;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.store.order.OrderDtos.CreateOrderRequest;
import com.petsitter.store.order.OrderDtos.OrderResponse;
import com.petsitter.store.order.OrderDtos.StatusRequest;
import com.petsitter.store.order.OrderEnums.OrderStatus;
import com.petsitter.store.product.ProductDtos.PageResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/** Commandes du compte connecté, et leur suivi par les administrateurs. */
@RestController
public class OrderController {

	private final OrderService service;

	private final CurrentUserResolver users;

	public OrderController(OrderService service, CurrentUserResolver users) {
		this.service = service;
		this.users = users;
	}

	@PostMapping("/api/orders")
	@ResponseStatus(HttpStatus.CREATED)
	OrderResponse create(HttpServletRequest request, @Valid @RequestBody CreateOrderRequest req) {
		return service.create(users.require(request).getId(), req);
	}

	@GetMapping("/api/orders/me")
	PageResponse<OrderResponse> mine(HttpServletRequest request, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		return service.mine(users.require(request).getId(), page, size);
	}

	@GetMapping("/api/orders/{id}")
	OrderResponse get(HttpServletRequest request, @PathVariable Long id) {
		UserEntity user = users.require(request);
		return service.get(id, user.getId(), user.getRole() == UserRole.ADMIN);
	}

	@PostMapping("/api/orders/{id}/cancel")
	OrderResponse cancel(HttpServletRequest request, @PathVariable Long id) {
		UserEntity user = users.require(request);
		return service.cancel(id, user.getId(), user.getRole() == UserRole.ADMIN);
	}

	@GetMapping("/api/admin/orders")
	PageResponse<OrderResponse> search(HttpServletRequest request, @RequestParam(required = false) OrderStatus status,
			@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
		users.requireRole(request, UserRole.ADMIN);
		return service.search(status, page, size);
	}

	@PatchMapping("/api/admin/orders/{id}/status")
	OrderResponse changeStatus(HttpServletRequest request, @PathVariable Long id,
			@Valid @RequestBody StatusRequest req) {
		users.requireRole(request, UserRole.ADMIN);
		return service.changeStatus(id, req.status());
	}

}
