package com.petsitter.event.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record EventAiSuggestRequest(
        @NotBlank(message = "Le titre est requis pour obtenir des suggestions.")
        String title,

        List<String> keywords,

        String category,

        String location,

        String description
) {}
