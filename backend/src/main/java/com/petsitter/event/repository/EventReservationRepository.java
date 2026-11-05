package com.petsitter.event.repository;

import com.petsitter.event.entity.EventReservation;
import com.petsitter.event.enums.ReservationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EventReservationRepository extends JpaRepository<EventReservation, String> {

    List<EventReservation> findByUserIdOrderByCreatedAtDesc(String userId);

    List<EventReservation> findByEventIdOrderByCreatedAtDesc(String eventId);

    List<EventReservation> findByEventIdAndStatusOrderByCreatedAtDesc(String eventId, ReservationStatus status);

    long countByEventIdAndStatus(String eventId, ReservationStatus status);

    Optional<EventReservation> findByEventIdAndUserIdAndStatus(
            String eventId, String userId, ReservationStatus status);

    boolean existsByEventIdAndUserIdAndStatus(
            String eventId, String userId, ReservationStatus status);
}
