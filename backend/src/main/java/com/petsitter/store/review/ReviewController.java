package com.petsitter.store.review;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.store.review.ReviewDtos.MyReviewResponse;
import com.petsitter.store.review.ReviewDtos.ReviewListResponse;
import com.petsitter.store.review.ReviewDtos.ReviewRequest;
import com.petsitter.store.review.ReviewDtos.ReviewResponse;
import com.petsitter.user.enums.UserRole;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/** Avis sur les produits de la boutique (distincts des avis sur les pet sitters). */
@RestController
public class ReviewController {

	private final ReviewService service;

	private final CurrentUserResolver users;

	public ReviewController(ReviewService service, CurrentUserResolver users) {
		this.service = service;
		this.users = users;
	}

	@GetMapping("/api/products/{productId}/reviews")
	ReviewListResponse list(@PathVariable String productId, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		return service.list(productId, page, size);
	}

	@GetMapping("/api/products/{productId}/reviews/me")
	MyReviewResponse mine(HttpServletRequest request, @PathVariable String productId) {
		return service.mine(productId, users.require(request).getId());
	}

	@PutMapping("/api/products/{productId}/reviews/me")
	ReviewResponse save(HttpServletRequest request, @PathVariable String productId,
			@Valid @RequestBody ReviewRequest req) {
		return service.save(productId, users.require(request).getId(), req);
	}

	@DeleteMapping("/api/products/{productId}/reviews/me")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void deleteMine(HttpServletRequest request, @PathVariable String productId) {
		service.deleteMine(productId, users.require(request).getId());
	}

	@DeleteMapping("/api/admin/reviews/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void adminDelete(HttpServletRequest request, @PathVariable Long id) {
		users.requireRole(request, UserRole.ADMIN);
		service.adminDelete(id);
	}

}
