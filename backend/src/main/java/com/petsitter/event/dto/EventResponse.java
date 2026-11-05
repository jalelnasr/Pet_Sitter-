package com.petsitter.event.dto;

import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.EventVisibility;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record EventResponse(
        String id,
        String title,
        String description,
        EventCategory category,
        String location,
        LocalDate date,
        LocalTime startTime,
        LocalTime endTime,
        LocalDateTime startDate,
        LocalDateTime endDate,
        Integer capacity,
        Integer remainingPlaces,
        Integer currentParticipants,
        String imageUrl,
        String organizerId,
        String organizerName,
        EventStatus status,
        EventVisibility visibility,
        String rejectionReason,
        boolean isMine,
        Instant createdAt,
        Instant updatedAt
) {}
