package com.petsitter.petsitter.entity;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "ps_sitter_profiles")
public class PetSitterProfile {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotBlank
    @Column(name = "user_id", length = 64, nullable = false)
    private String userId;

    @NotBlank
    @Size(max = 100)
    @Column(name = "full_name", length = 100, nullable = false)
    private String fullName;

    @Size(max = 2000)
    @Column(name = "bio", length = 2000)
    private String bio;

    @NotBlank
    @Size(max = 80)
    @Column(name = "governorate", length = 80, nullable = false)
    private String governorate;

    @NotBlank
    @Size(max = 80)
    @Column(name = "city", length = 80, nullable = false)
    private String city;

    @Size(max = 160)
    @Column(name = "address", length = 160)
    private String address;

    @Size(max = 30)
    @Column(name = "phone", length = 30)
    private String phone;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ps_sitter_gallery", joinColumns = @JoinColumn(name = "sitter_id"))
    @Column(name = "image_url", length = 500)
    private List<String> gallery = new ArrayList<>();

    @PositiveOrZero
    @Column(name = "experience_years")
    private int experienceYears = 0;

    @NotNull
    @PositiveOrZero
    @Column(name = "price_per_hour", nullable = false)
    private Double pricePerHour = 10.0;

    @NotNull
    @PositiveOrZero
    @Column(name = "price_per_day", nullable = false)
    private Double pricePerDay = 35.0;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ps_sitter_services", joinColumns = @JoinColumn(name = "sitter_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "service", length = 30)
    private Set<SitterServiceType> services = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ps_sitter_accepted_pets", joinColumns = @JoinColumn(name = "sitter_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "species", length = 30)
    private Set<PetSpeciesType> acceptedPetTypes = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "ps_sitter_accepted_sizes", joinColumns = @JoinColumn(name = "sitter_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "size", length = 30)
    private Set<PetSizeType> acceptedSizes = new HashSet<>();

    @Column(name = "has_garden", nullable = false)
    private boolean hasGarden = false;

    @Column(name = "has_own_pets", nullable = false)
    private boolean hasOwnPets = false;

    @Size(max = 255)
    @Column(name = "availability", length = 255)
    private String availability;

    @Column(name = "verified", nullable = false)
    private boolean verified = false;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "average_rating")
    private Double averageRating = 0.0;

    @Column(name = "reviews_count", nullable = false)
    private int reviewsCount = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public PetSitterProfile() {
        this.id = UUID.randomUUID().toString();
    }

    public PetSitterProfile(String id) {
        this.id = (id != null && !id.isBlank()) ? id : UUID.randomUUID().toString();
    }

    @PrePersist
    public void prePersist() {
        if (id == null || id.isBlank()) {
            id = UUID.randomUUID().toString();
        }
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
        if (averageRating == null) {
            averageRating = 0.0;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public String getGovernorate() { return governorate; }
    public void setGovernorate(String governorate) { this.governorate = governorate; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }

    public List<String> getGallery() { return gallery; }
    public void setGallery(List<String> gallery) { this.gallery = gallery != null ? gallery : new ArrayList<>(); }

    public int getExperienceYears() { return experienceYears; }
    public void setExperienceYears(int experienceYears) { this.experienceYears = experienceYears; }

    public Double getPricePerHour() { return pricePerHour; }
    public void setPricePerHour(Double pricePerHour) { this.pricePerHour = pricePerHour; }

    public Double getPricePerDay() { return pricePerDay; }
    public void setPricePerDay(Double pricePerDay) { this.pricePerDay = pricePerDay; }

    public Set<SitterServiceType> getServices() { return services; }
    public void setServices(Set<SitterServiceType> services) { this.services = services != null ? services : new HashSet<>(); }

    public Set<PetSpeciesType> getAcceptedPetTypes() { return acceptedPetTypes; }
    public void setAcceptedPetTypes(Set<PetSpeciesType> acceptedPetTypes) { this.acceptedPetTypes = acceptedPetTypes != null ? acceptedPetTypes : new HashSet<>(); }

    public Set<PetSizeType> getAcceptedSizes() { return acceptedSizes; }
    public void setAcceptedSizes(Set<PetSizeType> acceptedSizes) { this.acceptedSizes = acceptedSizes != null ? acceptedSizes : new HashSet<>(); }

    public boolean isHasGarden() { return hasGarden; }
    public void setHasGarden(boolean hasGarden) { this.hasGarden = hasGarden; }

    public boolean isHasOwnPets() { return hasOwnPets; }
    public void setHasOwnPets(boolean hasOwnPets) { this.hasOwnPets = hasOwnPets; }

    public String getAvailability() { return availability; }
    public void setAvailability(String availability) { this.availability = availability; }

    public boolean isVerified() { return verified; }
    public void setVerified(boolean verified) { this.verified = verified; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Double getAverageRating() { return averageRating; }
    public void setAverageRating(Double averageRating) { this.averageRating = averageRating; }

    public int getReviewsCount() { return reviewsCount; }
    public void setReviewsCount(int reviewsCount) { this.reviewsCount = reviewsCount; }

    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
