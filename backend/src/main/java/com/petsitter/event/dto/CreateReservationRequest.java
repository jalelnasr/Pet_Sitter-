package com.petsitter.event.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateReservationRequest(
        @NotBlank @Size(max = 120)
        String participantName,

        @NotBlank @Size(max = 40)
        String phone,

        @NotNull @Min(1) @Max(5)
        Integer numberOfPlaces,

        @Size(max = 1000)
        String comment
) {}
