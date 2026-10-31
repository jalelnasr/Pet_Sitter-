package com.petsitter.adoption.entity;

import com.petsitter.adoption.enums.HousingType;
import com.petsitter.adoption.enums.RequestStatus;
import com.petsitter.user.entity.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

@Entity
@Table(name = "adoption_requests")
public class AdoptionRequest {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "listing_id", nullable = false)
    private AdoptionListing listing;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "applicant_id", nullable = false)
    private UserEntity applicant;

    // Contact details captured by the existing Flutter form.
    @NotBlank
    @Size(max = 120)
    @Column(name = "full_name", length = 120, nullable = false)
    private String fullName;

    @NotBlank
    @Size(max = 40)
    @Column(name = "phone", length = 40, nullable = false)
    private String phone;

    @NotBlank
    @Size(max = 255)
    @Column(name = "address", length = 255, nullable = false)
    private String address;

    @NotBlank
    @Size(max = 2000)
    @Column(name = "message", length = 2000, nullable = false)
    private String message;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "housing_type", length = 20, nullable = false)
    private HousingType housingType;

    @NotNull
    @Column(name = "has_garden", nullable = false)
    private Boolean hasGarden;

    @NotNull
    @Column(name = "has_other_pets", nullable = false)
    private Boolean hasOtherPets;

    @Size(max = 500)
    @Column(name = "other_pets_details", length = 500)
    private String otherPetsDetails;

    @Size(max = 2000)
    @Column(name = "experience", length = 2000)
    private String experience;

    @Column(name = "ai_score")
    private Integer aiScore;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private RequestStatus status;

    @Size(max = 1000)
    @Column(name = "response_message", length = 1000)
    private String responseMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "processed_at")
    private Instant processedAt;

    protected AdoptionRequest() {
        // Required by JPA.
    }

    public AdoptionRequest(String id, AdoptionListing listing, UserEntity applicant) {
        this.id = id;
        this.listing = listing;
        this.applicant = applicant;
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
        if (status == null) {
            status = RequestStatus.PENDING;
        }
    }

    public String getId() {
        return id;
    }

    public AdoptionListing getListing() {
        return listing;
    }

    public UserEntity getApplicant() {
        return applicant;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public HousingType getHousingType() {
        return housingType;
    }

    public void setHousingType(HousingType housingType) {
        this.housingType = housingType;
    }

    public Boolean getHasGarden() {
        return hasGarden;
    }

    public void setHasGarden(Boolean hasGarden) {
        this.hasGarden = hasGarden;
    }

    public Boolean getHasOtherPets() {
        return hasOtherPets;
    }

    public void setHasOtherPets(Boolean hasOtherPets) {
        this.hasOtherPets = hasOtherPets;
    }

    public String getOtherPetsDetails() {
        return otherPetsDetails;
    }

    public void setOtherPetsDetails(String otherPetsDetails) {
        this.otherPetsDetails = otherPetsDetails;
    }

    public String getExperience() {
        return experience;
    }

    public void setExperience(String experience) {
        this.experience = experience;
    }

    public Integer getAiScore() {
        return aiScore;
    }

    public void setAiScore(Integer aiScore) {
        this.aiScore = aiScore;
    }

    public RequestStatus getStatus() {
        return status;
    }

    public void setStatus(RequestStatus status) {
        this.status = status;
    }

    public String getResponseMessage() {
        return responseMessage;
    }

    public void setResponseMessage(String responseMessage) {
        this.responseMessage = responseMessage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getProcessedAt() {
        return processedAt;
    }

    public void setProcessedAt(Instant processedAt) {
        this.processedAt = processedAt;
    }
}
