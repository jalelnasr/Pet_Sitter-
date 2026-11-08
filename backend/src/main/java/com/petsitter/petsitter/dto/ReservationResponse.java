package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.enums.SitterServiceType;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

public class ReservationResponse {

    private String id;
    private String sitterId;
    private String sitterName;
    private String sitterPhoto;
    private String sitterCity;
    private String ownerId;
    private String ownerName;
    private String petName;
    private PetSpeciesType petType;
    private PetSizeType petSize;
    private SitterServiceType service;
    private LocalDate startDate;
    private LocalDate endDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private String notes;
    private Double totalPrice;
    private ReservationStatus status;
    private String rejectionReason;
    private boolean hasReview;
    private Instant createdAt;
    private Instant updatedAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getSitterId() { return sitterId; }
    public void setSitterId(String sitterId) { this.sitterId = sitterId; }

    public String getSitterName() { return sitterName; }
    public void setSitterName(String sitterName) { this.sitterName = sitterName; }

    public String getSitterPhoto() { return sitterPhoto; }
    public void setSitterPhoto(String sitterPhoto) { this.sitterPhoto = sitterPhoto; }

    public String getSitterCity() { return sitterCity; }
    public void setSitterCity(String sitterCity) { this.sitterCity = sitterCity; }

    public String getOwnerId() { return ownerId; }
    public void setOwnerId(String ownerId) { this.ownerId = ownerId; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getPetName() { return petName; }
    public void setPetName(String petName) { this.petName = petName; }

    public PetSpeciesType getPetType() { return petType; }
    public void setPetType(PetSpeciesType petType) { this.petType = petType; }

    public PetSizeType getPetSize() { return petSize; }
    public void setPetSize(PetSizeType petSize) { this.petSize = petSize; }

    public SitterServiceType getService() { return service; }
    public void setService(SitterServiceType service) { this.service = service; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public LocalTime getStartTime() { return startTime; }
    public void setStartTime(LocalTime startTime) { this.startTime = startTime; }

    public LocalTime getEndTime() { return endTime; }
    public void setEndTime(LocalTime endTime) { this.endTime = endTime; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Double getTotalPrice() { return totalPrice; }
    public void setTotalPrice(Double totalPrice) { this.totalPrice = totalPrice; }

    public ReservationStatus getStatus() { return status; }
    public void setStatus(ReservationStatus status) { this.status = status; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }

    public boolean isHasReview() { return hasReview; }
    public void setHasReview(boolean hasReview) { this.hasReview = hasReview; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
