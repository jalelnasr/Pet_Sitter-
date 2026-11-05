package com.petsitter.event.dto;

import com.petsitter.event.enums.ReservationStatus;

import java.time.Instant;

public record ReservationResponse(
        String id,
        String eventId,
        String eventTitle,
        String userId,
        String participantName,
        String phone,
        Integer numberOfPlaces,
        String comment,
        ReservationStatus status,
        Instant createdAt,
        EventSummaryResponse event
) {}
