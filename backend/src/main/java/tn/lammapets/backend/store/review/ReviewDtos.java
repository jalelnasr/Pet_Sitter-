package tn.lammapets.backend.store.review;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

public final class ReviewDtos {

	private ReviewDtos() {
	}

	public record ReviewRequest(
			@Min(value = 1, message = "Donnez une note de 1 à 5.") @Max(value = 5, message = "Donnez une note de 1 à 5.") int rating,
			@Size(max = 1000, message = "Le commentaire est limité à 1000 caractères.") String comment) {
	}

	public record ReviewResponse(Long id, String authorName, int rating, String comment, Instant createdAt) {
		static ReviewResponse of(ProductReview r) {
			return new ReviewResponse(r.getId(), r.getUser().getFirstName(), r.getRating(), r.getComment(),
					r.getUpdatedAt());
		}
	}

	/** L'e-mail et l'identifiant de l'auteur ne sont jamais renvoyés : les avis sont publics. */
	public record ReviewListResponse(BigDecimal average, long count, List<ReviewResponse> items, int page,
			int totalPages) {
	}

	public record MyReviewResponse(boolean canReview, ReviewResponse review) {
	}

}
