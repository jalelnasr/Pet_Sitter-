package com.petsitter.event.mapper;

import com.petsitter.event.dto.EventResponse;
import com.petsitter.event.dto.EventSummaryResponse;
import com.petsitter.event.dto.ReservationResponse;
import com.petsitter.event.entity.Event;
import com.petsitter.event.entity.EventReservation;
import org.springframework.stereotype.Component;

@Component
public class EventMapper {

    public EventResponse toResponse(Event event, String currentUserId) {
        boolean isMine = currentUserId != null
                && event.getOrganizer() != null
                && currentUserId.equals(event.getOrganizer().getId());

        String organizerName = event.getOrganizer() != null
                ? event.getOrganizer().getFirstName()
                : "Organisateur";

        String organizerId = event.getOrganizer() != null
                ? event.getOrganizer().getId()
                : null;

        return new EventResponse(
                event.getId(),
                event.getTitle(),
                event.getDescription(),
                event.getCategory(),
                event.getLocation(),
                event.getDate(),
                event.getStartTime(),
                event.getEndTime(),
                event.getStartDateTime(),
                event.getEndDateTime(),
                event.getCapacity(),
                event.getRemainingPlaces(),
                event.getCurrentParticipants(),
                event.getImageUrl(),
                organizerId,
                organizerName,
                event.getEffectiveStatus(),
                event.getVisibility(),
                event.getRejectionReason(),
                isMine,
                event.getCreatedAt(),
                event.getUpdatedAt()
        );
    }

    public EventSummaryResponse toSummary(Event event, String currentUserId) {
        boolean isMine = currentUserId != null
                && event.getOrganizer() != null
                && currentUserId.equals(event.getOrganizer().getId());

        String organizerName = event.getOrganizer() != null
                ? event.getOrganizer().getFirstName()
                : "Organisateur";

        String organizerId = event.getOrganizer() != null
                ? event.getOrganizer().getId()
                : null;

        return new EventSummaryResponse(
                event.getId(),
                event.getTitle(),
                event.getDescription(),
                event.getCategory(),
                event.getLocation(),
                event.getDate(),
                event.getStartTime(),
                event.getEndTime(),
                event.getStartDateTime(),
                event.getEndDateTime(),
                event.getCapacity(),
                event.getRemainingPlaces(),
                event.getCurrentParticipants(),
                event.getImageUrl(),
                organizerId,
                organizerName,
                event.getEffectiveStatus(),
                event.getRejectionReason(),
                isMine,
                event.getCreatedAt()
        );
    }

    public ReservationResponse toReservationResponse(EventReservation reservation, String currentUserId) {
        Event event = reservation.getEvent();
        EventSummaryResponse summary = event != null ? toSummary(event, currentUserId) : null;
        String eventTitle = event != null ? event.getTitle() : null;

        return new ReservationResponse(
                reservation.getId(),
                event != null ? event.getId() : null,
                eventTitle,
                reservation.getUser() != null ? reservation.getUser().getId() : null,
                reservation.getParticipantName(),
                reservation.getPhone(),
                reservation.getNumberOfPlaces(),
                reservation.getComment(),
                reservation.getStatus(),
                reservation.getCreatedAt(),
                summary
        );
    }
}
