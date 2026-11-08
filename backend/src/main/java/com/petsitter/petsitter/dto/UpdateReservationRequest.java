package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public class UpdateReservationRequest {

    @Size(max = 80)
    private String petName;

    private PetSpeciesType petType;
    private PetSizeType petSize;
    private SitterServiceType service;

    private LocalDate startDate;
    private LocalDate endDate;
    private LocalTime startTime;
    private LocalTime endTime;

    @Size(max = 1000)
    private String notes;

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
}
