package com.petsitter.event.dto;

import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.EventVisibility;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public record CreateEventRequest(
        @NotBlank @Size(max = 160)
        String title,

        @NotBlank @Size(max = 2000)
        String description,

        @NotNull
        EventCategory category,

        @NotBlank @Size(max = 160)
        String location,

        @NotNull
        LocalDate date,

        @NotNull
        LocalTime startTime,

        @NotNull
        LocalTime endTime,

        @NotNull @Min(1)
        Integer capacity,

        String imageUrl,

        EventStatus status,

        EventVisibility visibility
) {}
