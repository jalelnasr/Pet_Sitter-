package com.petsitter.petsitter.dto;

import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public class CreateReservationRequest {

    @NotBlank(message = "L'identifiant du pet sitter est requis")
    private String sitterId;

    @NotBlank(message = "Le nom de l'animal est obligatoire")
    @Size(max = 80)
    private String petName;

    @NotNull(message = "L'espèce de l'animal est obligatoire")
    private PetSpeciesType petType;

    @NotNull(message = "La taille de l'animal est obligatoire")
    private PetSizeType petSize;

    @NotNull(message = "Le type de prestation est obligatoire")
    private SitterServiceType service;

    @NotNull(message = "La date de début est obligatoire")
    @FutureOrPresent(message = "La date de début ne peut pas être dans le passé")
    private LocalDate startDate;

    @NotNull(message = "La date de fin est obligatoire")
    private LocalDate endDate;

    private LocalTime startTime;
    private LocalTime endTime;

    @Size(max = 1000)
    private String notes;

    public String getSitterId() { return sitterId; }
    public void setSitterId(String sitterId) { this.sitterId = sitterId; }

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
