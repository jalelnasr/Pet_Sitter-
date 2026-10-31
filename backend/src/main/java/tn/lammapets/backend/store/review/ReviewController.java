package tn.lammapets.backend.store.review;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import tn.lammapets.backend.store.review.ReviewDtos.MyReviewResponse;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewListResponse;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewRequest;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewResponse;

import jakarta.validation.Valid;

@RestController
public class ReviewController {

	private final ReviewService service;

	public ReviewController(ReviewService service) {
		this.service = service;
	}

	@GetMapping("/api/products/{productId}/reviews")
	ReviewListResponse list(@PathVariable String productId, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		return service.list(productId, page, size);
	}

	@GetMapping("/api/products/{productId}/reviews/me")
	MyReviewResponse mine(@AuthenticationPrincipal Jwt jwt, @PathVariable String productId) {
		return service.mine(productId, jwt.getSubject());
	}

	@PutMapping("/api/products/{productId}/reviews/me")
	ReviewResponse save(@AuthenticationPrincipal Jwt jwt, @PathVariable String productId,
			@Valid @RequestBody ReviewRequest req) {
		return service.save(productId, jwt.getSubject(), req);
	}

	@DeleteMapping("/api/products/{productId}/reviews/me")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void deleteMine(@AuthenticationPrincipal Jwt jwt, @PathVariable String productId) {
		service.deleteMine(productId, jwt.getSubject());
	}

	@DeleteMapping("/api/admin/reviews/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void adminDelete(@PathVariable Long id) {
		service.adminDelete(id);
	}

}
