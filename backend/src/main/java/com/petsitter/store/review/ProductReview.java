package com.petsitter.store.review;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import com.petsitter.user.entity.UserEntity;

@Entity
@Table(name = "product_reviews")
public class ProductReview {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "product_id", length = 60)
	private String productId;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id")
	private UserEntity user;

	private int rating;

	private String comment;

	@Column(name = "created_at")
	private Instant createdAt = Instant.now();

	@Column(name = "updated_at")
	private Instant updatedAt = Instant.now();

	protected ProductReview() {
	}

	ProductReview(String productId, UserEntity user) {
		this.productId = productId;
		this.user = user;
	}

	void update(int rating, String comment) {
		this.rating = rating;
		this.comment = comment;
		this.updatedAt = Instant.now();
	}

	public Long getId() {
		return id;
	}

	public String getProductId() {
		return productId;
	}

	public UserEntity getUser() {
		return user;
	}

	public int getRating() {
		return rating;
	}

	public String getComment() {
		return comment;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

}
