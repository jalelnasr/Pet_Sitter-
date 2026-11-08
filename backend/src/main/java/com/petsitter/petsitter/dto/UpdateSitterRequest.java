package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Set;

public class UpdateSitterRequest {

    @Size(max = 100)
    private String fullName;

    @Size(max = 2000)
    private String bio;

    @Size(max = 80)
    private String governorate;

    @Size(max = 80)
    private String city;

    @Size(max = 160)
    private String address;

    @Size(max = 30)
    private String phone;

    private String photoUrl;
    private List<String> gallery;

    @PositiveOrZero
    private Integer experienceYears;

    @PositiveOrZero
    private Double pricePerHour;

    @PositiveOrZero
    private Double pricePerDay;

    private Set<SitterServiceType> services;
    private Set<PetSpeciesType> acceptedPetTypes;
    private Set<PetSizeType> acceptedSizes;

    private Boolean hasGarden;
    private Boolean hasOwnPets;

    @Size(max = 255)
    private String availability;

    private Boolean active;

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

    public Integer getExperienceYears() { return experienceYears; }
    public void setExperienceYears(Integer experienceYears) { this.experienceYears = experienceYears; }

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

    public Boolean getHasGarden() { return hasGarden; }
    public void setHasGarden(Boolean hasGarden) { this.hasGarden = hasGarden; }

    public Boolean getHasOwnPets() { return hasOwnPets; }
    public void setHasOwnPets(Boolean hasOwnPets) { this.hasOwnPets = hasOwnPets; }

    public String getAvailability() { return availability; }
    public void setAvailability(String availability) { this.availability = availability; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }
}
