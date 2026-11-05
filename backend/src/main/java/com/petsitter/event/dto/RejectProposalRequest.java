package com.petsitter.event.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RejectProposalRequest(
        @NotBlank(message = "Le motif de refus est obligatoire")
        @Size(max = 1000, message = "Le motif ne peut pas dépasser 1000 caractères")
        String reason
) {}
