package com.petsitter.event.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.event.dto.CreateReservationRequest;
import com.petsitter.event.dto.ReservationResponse;
import com.petsitter.event.entity.Event;
import com.petsitter.event.entity.EventReservation;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.ReservationStatus;
import com.petsitter.event.mapper.EventMapper;
import com.petsitter.event.repository.EventRepository;
import com.petsitter.event.repository.EventReservationRepository;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class EventReservationService {

    private static final Logger log = LoggerFactory.getLogger(EventReservationService.class);

    private final EventRepository eventRepository;
    private final EventReservationRepository reservationRepository;
    private final EventMapper mapper;

    public EventReservationService(
            EventRepository eventRepository,
            EventReservationRepository reservationRepository,
            EventMapper mapper
    ) {
        this.eventRepository = eventRepository;
        this.reservationRepository = reservationRepository;
        this.mapper = mapper;
    }

    @Transactional
    public ReservationResponse reserve(
            String eventId,
            CreateReservationRequest request,
            UserEntity user
    ) {
        if (user == null) {
            throw new UnauthorizedActionException("Authentification requise pour réserver.");
        }

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Événement non trouvé : " + eventId));

        if (event.getStatus() != EventStatus.PUBLISHED || event.isCompleted()) {
            throw new BusinessException(
                    "EVENT_NOT_OPEN",
                    "Cet événement n'est pas ouvert aux réservations."
            );
        }

        LocalDateTime start = event.getStartDateTime();
        if (start != null && start.isBefore(LocalDateTime.now())) {
            throw new BusinessException(
                    "EVENT_ALREADY_STARTED",
                    "Cet événement a déjà commencé ou est terminé."
            );
        }

        int requestedSeats = request.numberOfPlaces();
        if (requestedSeats < 1 || requestedSeats > 5) {
            throw new BadRequestException(
                    "INVALID_SEATS",
                    "Le nombre de places doit être compris entre 1 et 5 par réservation."
            );
        }

        // Check if user already has an active reservation
        boolean alreadyReserved = reservationRepository.existsByEventIdAndUserIdAndStatus(
                eventId, user.getId(), ReservationStatus.CONFIRMED);
        if (alreadyReserved) {
            throw new BusinessException(
                    "ALREADY_RESERVED",
                    "Vous avez déjà une réservation confirmée pour cet événement."
            );
        }

        if (requestedSeats > event.getRemainingPlaces()) {
            throw new BusinessException(
                    "NOT_ENOUGH_SEATS",
                    "Nombre de places insuffisant. Places restantes : " + event.getRemainingPlaces()
            );
        }

        // Decrement remaining places
        event.setRemainingPlaces(event.getRemainingPlaces() - requestedSeats);
        eventRepository.save(event);

        EventReservation reservation = new EventReservation(
                UUID.randomUUID().toString(),
                event,
                user
        );
        reservation.setParticipantName(request.participantName().trim());
        reservation.setPhone(request.phone().trim());
        reservation.setNumberOfPlaces(requestedSeats);
        reservation.setComment(request.comment() != null ? request.comment().trim() : "");
        reservation.setStatus(ReservationStatus.CONFIRMED);

        reservationRepository.save(reservation);
        log.info("Reservation {} created for event {} by user {} ({} places)",
                reservation.getId(), event.getId(), user.getId(), requestedSeats);

        return mapper.toReservationResponse(reservation, user.getId());
    }

    @Transactional
    public ReservationResponse cancel(String reservationId, UserEntity user) {
        if (user == null) {
            throw new UnauthorizedActionException("Authentification requise.");
        }

        EventReservation reservation = reservationRepository.findById(reservationId)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation non trouvée : " + reservationId));

        boolean isReserver = reservation.getUser() != null
                && reservation.getUser().getId().equals(user.getId());
        boolean isAdmin = user.getRole() == UserRole.ADMIN;

        if (!isReserver && !isAdmin) {
            throw new UnauthorizedActionException(
                    "Vous n'êtes pas autorisé à annuler cette réservation."
            );
        }

        if (reservation.getStatus() == ReservationStatus.CANCELLED
                || reservation.getStatus() == ReservationStatus.CANCELLED_BY_ADMIN) {
            return mapper.toReservationResponse(reservation, user.getId());
        }

        Event event = reservation.getEvent();

        // Non-admin can only cancel before the event starts
        if (!isAdmin) {
            if (event != null && event.getStartDateTime() != null && event.getStartDateTime().isBefore(LocalDateTime.now())) {
                throw new BusinessException(
                        "EVENT_ALREADY_STARTED",
                        "Vous ne pouvez pas annuler une réservation pour un événement qui a déjà commencé."
                );
            }
            reservation.setStatus(ReservationStatus.CANCELLED);
        } else {
            // Admin cancelled
            if (isReserver) {
                reservation.setStatus(ReservationStatus.CANCELLED);
            } else {
                reservation.setStatus(ReservationStatus.CANCELLED_BY_ADMIN);
            }
        }

        reservationRepository.save(reservation);

        // Restore remaining places
        if (event != null) {
            int newRemaining = Math.min(
                    event.getCapacity(),
                    event.getRemainingPlaces() + reservation.getNumberOfPlaces()
            );
            event.setRemainingPlaces(newRemaining);
            eventRepository.save(event);
        }

        log.info("Reservation {} cancelled by user {} (status: {})",
                reservationId, user.getId(), reservation.getStatus());
        return mapper.toReservationResponse(reservation, user.getId());
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> myReservations(UserEntity user) {
        if (user == null) {
            throw new UnauthorizedActionException("Authentification requise.");
        }
        return reservationRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(r -> mapper.toReservationResponse(r, user.getId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> eventReservations(String eventId, UserEntity user) {
        if (user == null || user.getRole() != UserRole.ADMIN) {
            throw new UnauthorizedActionException(
                    "Seul un administrateur peut consulter la liste de tous les participants d'un événement."
            );
        }

        return reservationRepository.findByEventIdOrderByCreatedAtDesc(eventId)
                .stream()
                .map(r -> mapper.toReservationResponse(r, user.getId()))
                .toList();
    }
}
