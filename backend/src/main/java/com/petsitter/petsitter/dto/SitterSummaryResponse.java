package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;

import java.util.Set;

public class SitterSummaryResponse {

    private String id;
    private String userId;
    private String fullName;
    private String governorate;
    private String city;
    private String photoUrl;
    private Double pricePerHour;
    private Double pricePerDay;
    private Set<SitterServiceType> services;
    private Set<PetSpeciesType> acceptedPetTypes;
    private boolean verified;
    private boolean active;
    private Double averageRating;
    private int reviewsCount;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getGovernorate() { return governorate; }
    public void setGovernorate(String governorate) { this.governorate = governorate; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }

    public Double getPricePerHour() { return pricePerHour; }
    public void setPricePerHour(Double pricePerHour) { this.pricePerHour = pricePerHour; }

    public Double getPricePerDay() { return pricePerDay; }
    public void setPricePerDay(Double pricePerDay) { this.pricePerDay = pricePerDay; }

    public Set<SitterServiceType> getServices() { return services; }
    public void setServices(Set<SitterServiceType> services) { this.services = services; }

    public Set<PetSpeciesType> getAcceptedPetTypes() { return acceptedPetTypes; }
    public void setAcceptedPetTypes(Set<PetSpeciesType> acceptedPetTypes) { this.acceptedPetTypes = acceptedPetTypes; }

    public boolean isVerified() { return verified; }
    public void setVerified(boolean verified) { this.verified = verified; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Double getAverageRating() { return averageRating; }
    public void setAverageRating(Double averageRating) { this.averageRating = averageRating; }

    public int getReviewsCount() { return reviewsCount; }
    public void setReviewsCount(int reviewsCount) { this.reviewsCount = reviewsCount; }
}
