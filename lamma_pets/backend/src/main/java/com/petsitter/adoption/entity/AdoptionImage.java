package com.petsitter.adoption.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;

/**
 * Image attached to a listing. Only the URL is stored in MySQL, never binary
 * data: real file upload is out of scope for this version.
 */
@Entity
@Table(name = "adoption_images")
public class AdoptionImage {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "listing_id", nullable = false)
    private AdoptionListing listing;

    @NotBlank
    @Column(name = "image_url", length = 1000, nullable = false)
    private String imageUrl;

    @Column(name = "display_order", nullable = false)
    private Integer displayOrder;

    protected AdoptionImage() {
        // Required by JPA.
    }

    AdoptionImage(AdoptionListing listing, String imageUrl, int displayOrder) {
        this.id = java.util.UUID.randomUUID().toString();
        this.listing = listing;
        this.imageUrl = imageUrl;
        this.displayOrder = displayOrder;
    }

    public String getId() {
        return id;
    }

    public AdoptionListing getListing() {
        return listing;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }
}
