package com.petsitter.adoption.entity;

import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.user.entity.UserEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "adoption_listings")
public class AdoptionListing {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "publisher_id", nullable = false)
    private UserEntity publisher;

    @NotBlank
    @Size(max = 80)
    @Column(name = "pet_name", length = 80, nullable = false)
    private String petName;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "species", length = 20, nullable = false)
    private PetSpecies species;

    @Size(max = 80)
    @Column(name = "breed", length = 80)
    private String breed;

    @PositiveOrZero
    @Column(name = "age")
    private Integer age;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "gender", length = 20, nullable = false)
    private PetGender gender;

    @NotBlank
    @Size(max = 2000)
    @Column(name = "description", length = 2000, nullable = false)
    private String description;

    @Size(max = 1000)
    @Column(name = "health_information", length = 1000)
    private String healthInformation;

    @NotNull
    @Column(name = "vaccinated", nullable = false)
    private Boolean vaccinated;

    @NotNull
    @Column(name = "sterilized", nullable = false)
    private Boolean sterilized;

    @NotBlank
    @Size(max = 160)
    @Column(name = "location", length = 160, nullable = false)
    private String location;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private ListingStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @OneToMany(mappedBy = "listing", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("displayOrder ASC")
    private List<AdoptionImage> images = new ArrayList<>();

    @OneToMany(mappedBy = "listing", fetch = FetchType.LAZY)
    private List<AdoptionRequest> requests = new ArrayList<>();

    protected AdoptionListing() {
        // Required by JPA.
    }

    public AdoptionListing(String id, UserEntity publisher) {
        this.id = id;
        this.publisher = publisher;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
        if (status == null) {
            status = ListingStatus.DRAFT;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public void addImage(String imageUrl, int displayOrder) {
        images.add(new AdoptionImage(this, imageUrl, displayOrder));
    }

    public void clearImages() {
        images.clear();
    }

    public String getId() {
        return id;
    }

    public UserEntity getPublisher() {
        return publisher;
    }

    public String getPetName() {
        return petName;
    }

    public void setPetName(String petName) {
        this.petName = petName;
    }

    public PetSpecies getSpecies() {
        return species;
    }

    public void setSpecies(PetSpecies species) {
        this.species = species;
    }

    public String getBreed() {
        return breed;
    }

    public void setBreed(String breed) {
        this.breed = breed;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public PetGender getGender() {
        return gender;
    }

    public void setGender(PetGender gender) {
        this.gender = gender;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getHealthInformation() {
        return healthInformation;
    }

    public void setHealthInformation(String healthInformation) {
        this.healthInformation = healthInformation;
    }

    public Boolean getVaccinated() {
        return vaccinated;
    }

    public void setVaccinated(Boolean vaccinated) {
        this.vaccinated = vaccinated;
    }

    public Boolean getSterilized() {
        return sterilized;
    }

    public void setSterilized(Boolean sterilized) {
        this.sterilized = sterilized;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public ListingStatus getStatus() {
        return status;
    }

    public void setStatus(ListingStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public List<AdoptionImage> getImages() {
        return images;
    }
}
