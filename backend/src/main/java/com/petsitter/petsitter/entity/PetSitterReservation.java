package com.petsitter.petsitter.entity;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.enums.SitterServiceType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "ps_sitter_reservations")
public class PetSitterReservation {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotBlank
    @Column(name = "sitter_id", length = 36, nullable = false)
    private String sitterId;

    @NotBlank
    @Column(name = "owner_id", length = 64, nullable = false)
    private String ownerId;

    @NotBlank
    @Size(max = 80)
    @Column(name = "pet_name", length = 80, nullable = false)
    private String petName;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "pet_type", length = 30, nullable = false)
    private PetSpeciesType petType;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "pet_size", length = 30, nullable = false)
    private PetSizeType petSize;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "service", length = 30, nullable = false)
    private SitterServiceType service;

    @NotNull
    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @NotNull
    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Size(max = 1000)
    @Column(name = "notes", length = 1000)
    private String notes;

    @NotNull
    @PositiveOrZero
    @Column(name = "total_price", nullable = false)
    private Double totalPrice = 0.0;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private ReservationStatus status = ReservationStatus.PENDING;

    @Size(max = 500)
    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public PetSitterReservation() {
        this.id = UUID.randomUUID().toString();
    }

    public PetSitterReservation(String id) {
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
        if (status == null) {
            status = ReservationStatus.PENDING;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getSitterId() { return sitterId; }
    public void setSitterId(String sitterId) { this.sitterId = sitterId; }

    public String getOwnerId() { return ownerId; }
    public void setOwnerId(String ownerId) { this.ownerId = ownerId; }

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

    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
