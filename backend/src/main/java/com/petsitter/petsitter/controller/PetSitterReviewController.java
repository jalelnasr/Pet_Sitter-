package com.petsitter.petsitter.controller;

import com.petsitter.petsitter.dto.CreateReviewRequest;
import com.petsitter.petsitter.dto.ReviewResponse;
import com.petsitter.petsitter.service.PetSitterReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/sitters/{sitterId}/reviews")
@Tag(name = "Reviews", description = "Endpoints d'avis et notations sur les pet sitters")
public class PetSitterReviewController {

    private final PetSitterReviewService reviewService;

    public PetSitterReviewController(PetSitterReviewService reviewService) {
        this.reviewService = reviewService;
    }

    private String resolveUserId(HttpServletRequest request) {
        String h = request.getHeader("X-User-Id");
        if (h == null || h.isBlank()) {
            h = request.getHeader("X-Demo-User-Id");
        }
        return (h != null && !h.isBlank()) ? h.trim() : "OWNER_DEMO";
    }

    private boolean checkIsAdmin(HttpServletRequest request) {
        String uid = resolveUserId(request);
        return "ADMIN_DEMO".equalsIgnoreCase(uid) || "admin".equalsIgnoreCase(uid);
    }

    @PostMapping
    @Operation(summary = "Ajouter un avis sur un pet sitter (après réservation terminée)")
    public ResponseEntity<ReviewResponse> addReview(
            @PathVariable String sitterId,
            @Valid @RequestBody CreateReviewRequest request,
            HttpServletRequest httpRequest
    ) {
        String ownerId = resolveUserId(httpRequest);
        ReviewResponse res = reviewService.addReview(sitterId, request, ownerId, null);
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @GetMapping
    @Operation(summary = "Lister les avis d'un pet sitter")
    public List<ReviewResponse> listReviews(@PathVariable String sitterId) {
        return reviewService.listBySitter(sitterId);
    }

    @DeleteMapping("/{reviewId}")
    @Operation(summary = "Supprimer un avis")
    public ResponseEntity<Void> deleteReview(
            @PathVariable String sitterId,
            @PathVariable String reviewId,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        boolean isAdmin = checkIsAdmin(httpRequest);
        reviewService.deleteReview(reviewId, userId, isAdmin);
        return ResponseEntity.noContent().build();
    }
}
