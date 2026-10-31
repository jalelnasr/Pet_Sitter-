package tn.lammapets.backend.store.review;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ProductReviewRepository extends JpaRepository<ProductReview, Long> {

	Page<ProductReview> findByProductId(String productId, Pageable pageable);

	Optional<ProductReview> findByProductIdAndUserId(String productId, String userId);

	long countByProductId(String productId);

	@Query("select avg(r.rating) from ProductReview r where r.productId = :productId")
	Double averageRating(String productId);

}
