package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;

import java.time.Instant;
import java.util.List;
import java.util.Set;

public class SitterResponse {

    private String id;
    private String userId;
    private String fullName;
    private String bio;
    private String governorate;
    private String city;
    private String address;
    private String phone;
    private String photoUrl;
    private List<String> gallery;
    private int experienceYears;
    private Double pricePerHour;
    private Double pricePerDay;
    private Set<SitterServiceType> services;
    private Set<PetSpeciesType> acceptedPetTypes;
    private Set<PetSizeType> acceptedSizes;
    private boolean hasGarden;
    private boolean hasOwnPets;
    private String availability;
    private boolean verified;
    private boolean active;
    private Double averageRating;
    private int reviewsCount;
    private Instant createdAt;
    private Instant updatedAt;

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
    public void setGallery(List<String> gallery) { this.gallery = gallery; }

    public int getExperienceYears() { return experienceYears; }
    public void setExperienceYears(int experienceYears) { this.experienceYears = experienceYears; }

    public Double getPricePerHour() { return pricePerHour; }
    public void setPricePerHour(Double pricePerHour) { this.pricePerHour = pricePerHour; }

    public Double getPricePerDay() { return pricePerDay; }
    public void setPricePerDay(Double pricePerDay) { this.pricePerDay = pricePerDay; }

    public Set<SitterServiceType> getServices() { return services; }
    public void setServices(Set<SitterServiceType> services) { this.services = services; }

    public Set<PetSpeciesType> getAcceptedPetTypes() { return acceptedPetTypes; }
    public void setAcceptedPetTypes(Set<PetSpeciesType> acceptedPetTypes) { this.acceptedPetTypes = acceptedPetTypes; }

    public Set<PetSizeType> getAcceptedSizes() { return acceptedSizes; }
    public void setAcceptedSizes(Set<PetSizeType> acceptedSizes) { this.acceptedSizes = acceptedSizes; }

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
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
