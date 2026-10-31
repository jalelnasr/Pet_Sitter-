package com.petsitter.adoption.dto.request;

import jakarta.validation.constraints.Size;

public record ProcessAdoptionRequest(
        @Size(max = 1000) String responseMessage
) {
}
