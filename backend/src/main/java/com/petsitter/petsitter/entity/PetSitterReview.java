package com.petsitter.petsitter.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ps_sitter_reviews")
public class PetSitterReview {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotBlank
    @Column(name = "sitter_id", length = 36, nullable = false)
    private String sitterId;

    @Column(name = "reservation_id", length = 36)
    private String reservationId;

    @NotBlank
    @Column(name = "owner_id", length = 64, nullable = false)
    private String ownerId;

    @NotBlank
    @Size(max = 100)
    @Column(name = "owner_name", length = 100, nullable = false)
    private String ownerName;

    @NotNull
    @Min(1)
    @Max(5)
    @Column(name = "rating", nullable = false)
    private Integer rating;

    @Size(max = 1000)
    @Column(name = "comment", length = 1000)
    private String comment;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public PetSitterReview() {
        this.id = UUID.randomUUID().toString();
    }

    public PetSitterReview(String id) {
        this.id = (id != null && !id.isBlank()) ? id : UUID.randomUUID().toString();
    }

    @PrePersist
    public void prePersist() {
        if (id == null || id.isBlank()) {
            id = UUID.randomUUID().toString();
        }
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getSitterId() { return sitterId; }
    public void setSitterId(String sitterId) { this.sitterId = sitterId; }

    public String getReservationId() { return reservationId; }
    public void setReservationId(String reservationId) { this.reservationId = reservationId; }

    public String getOwnerId() { return ownerId; }
    public void setOwnerId(String ownerId) { this.ownerId = ownerId; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }

    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
