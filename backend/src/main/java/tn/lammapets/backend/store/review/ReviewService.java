package tn.lammapets.backend.store.review;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.order.OrderEnums.OrderStatus;
import tn.lammapets.backend.store.order.OrderRepository;
import tn.lammapets.backend.store.product.Product;
import tn.lammapets.backend.store.product.ProductRepository;
import tn.lammapets.backend.store.review.ReviewDtos.MyReviewResponse;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewListResponse;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewRequest;
import tn.lammapets.backend.store.review.ReviewDtos.ReviewResponse;
import tn.lammapets.backend.user.User;
import tn.lammapets.backend.user.UserRepository;

@Service
public class ReviewService {

	private static final int MAX_PAGE_SIZE = 50;

	private final ProductReviewRepository reviews;

	private final ProductRepository products;

	private final OrderRepository orders;

	private final UserRepository users;

	public ReviewService(ProductReviewRepository reviews, ProductRepository products, OrderRepository orders,
			UserRepository users) {
		this.reviews = reviews;
		this.products = products;
		this.orders = orders;
		this.users = users;
	}

	@Transactional(readOnly = true)
	public ReviewListResponse list(String productId, int page, int size) {
		Product product = findProduct(productId);
		PageRequest pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
				Sort.by(Sort.Direction.DESC, "updatedAt"));
		Page<ProductReview> found = reviews.findByProductId(productId, pageable);
		return new ReviewListResponse(product.getRating(), product.getReviews(),
				found.map(ReviewResponse::of).getContent(), found.getNumber(), found.getTotalPages());
	}

	@Transactional(readOnly = true)
	public MyReviewResponse mine(String productId, String userId) {
		findProduct(productId);
		return new MyReviewResponse(hasReceived(userId, productId),
				reviews.findByProductIdAndUserId(productId, userId).map(ReviewResponse::of).orElse(null));
	}

	/** Un seul avis par client et par produit : le renvoyer le met à jour. */
	@Transactional
	public ReviewResponse save(String productId, String userId, ReviewRequest req) {
		Product product = findProduct(productId);
		if (!hasReceived(userId, productId)) {
			throw new ApiException(HttpStatus.CONFLICT, "Vous pourrez donner votre avis après avoir reçu ce produit.");
		}
		User user = users.findById(userId)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Compte introuvable."));
		ProductReview review = reviews.findByProductIdAndUserId(productId, userId)
			.orElseGet(() -> new ProductReview(productId, user));
		String comment = req.comment() == null || req.comment().isBlank() ? null : req.comment().trim();
		review.update(req.rating(), comment);
		reviews.saveAndFlush(review);
		refreshStats(product);
		return ReviewResponse.of(review);
	}

	@Transactional
	public void deleteMine(String productId, String userId) {
		ProductReview review = reviews.findByProductIdAndUserId(productId, userId).orElseThrow(ReviewService::notFound);
		delete(review);
	}

	@Transactional
	public void adminDelete(Long id) {
		delete(reviews.findById(id).orElseThrow(ReviewService::notFound));
	}

	private void delete(ProductReview review) {
		reviews.delete(review);
		reviews.flush();
		refreshStats(findAnyProduct(review.getProductId()));
	}

	private void refreshStats(Product product) {
		Double average = reviews.averageRating(product.getId());
		BigDecimal rating = average == null ? BigDecimal.ZERO : BigDecimal.valueOf(average).setScale(1, RoundingMode.HALF_UP);
		product.setReviewStats(rating, (int) reviews.countByProductId(product.getId()));
	}

	private boolean hasReceived(String userId, String productId) {
		return orders.hasProductWithStatus(userId, productId, OrderStatus.DELIVERED);
	}

	private Product findProduct(String id) {
		Product product = findAnyProduct(id);
		if (!product.isActive()) {
			throw new ApiException(HttpStatus.NOT_FOUND, "Produit introuvable.");
		}
		return product;
	}

	private Product findAnyProduct(String id) {
		return products.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Produit introuvable."));
	}

	private static ApiException notFound() {
		return new ApiException(HttpStatus.NOT_FOUND, "Avis introuvable.");
	}

}
