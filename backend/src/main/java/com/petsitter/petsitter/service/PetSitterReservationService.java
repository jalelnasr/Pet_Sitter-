package com.petsitter.petsitter.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.petsitter.dto.CreateReservationRequest;
import com.petsitter.petsitter.dto.RejectReservationRequest;
import com.petsitter.petsitter.dto.ReservationResponse;
import com.petsitter.petsitter.dto.UpdateReservationRequest;
import com.petsitter.petsitter.entity.PetSitterProfile;
import com.petsitter.petsitter.entity.PetSitterReservation;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.mapper.PetSitterMapper;
import com.petsitter.petsitter.repository.PetSitterProfileRepository;
import com.petsitter.petsitter.repository.PetSitterReservationRepository;
import com.petsitter.petsitter.repository.PetSitterReviewRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class PetSitterReservationService {

    private final PetSitterReservationRepository reservationRepository;
    private final PetSitterProfileRepository profileRepository;
    private final PetSitterReviewRepository reviewRepository;
    private final PetSitterMapper mapper;

    public PetSitterReservationService(
            PetSitterReservationRepository reservationRepository,
            PetSitterProfileRepository profileRepository,
            PetSitterReviewRepository reviewRepository,
            PetSitterMapper mapper) {
        this.reservationRepository = reservationRepository;
        this.profileRepository = profileRepository;
        this.reviewRepository = reviewRepository;
        this.mapper = mapper;
    }

    @Transactional
    public ReservationResponse createReservation(CreateReservationRequest req, String ownerId, String ownerName) {
        PetSitterProfile sitter = profileRepository.findById(req.getSitterId())
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable : " + req.getSitterId()));

        if (!sitter.isActive()) {
            throw new BadRequestException("SITTER_INACTIVE", "Ce pet sitter n'accepte pas de réservations actuellement.");
        }

        validateDates(req.getStartDate(), req.getEndDate());

        // Check if pet type is accepted
        if (sitter.getAcceptedPetTypes() != null && !sitter.getAcceptedPetTypes().isEmpty()
                && !sitter.getAcceptedPetTypes().contains(req.getPetType())) {
            throw new BadRequestException("PET_NOT_ACCEPTED", "Le pet sitter n'accepte pas ce type d'animal (" + req.getPetType() + ").");
        }

        // Check if service is offered
        if (sitter.getServices() != null && !sitter.getServices().isEmpty()
                && !sitter.getServices().contains(req.getService())) {
            throw new BadRequestException("SERVICE_NOT_OFFERED", "Le pet sitter ne propose pas ce service (" + req.getService() + ").");
        }

        // Check overlapping accepted bookings
        List<PetSitterReservation> overlaps = reservationRepository.findOverlappingAccepted(
                sitter.getId(), req.getStartDate(), req.getEndDate());
        if (!overlaps.isEmpty()) {
            throw new BadRequestException("DATE_UNAVAILABLE", "Le pet sitter a déjà une réservation confirmée sur cette période.");
        }

        // Compute total price
        double totalPrice = calculatePrice(sitter, req.getStartDate(), req.getEndDate(), req.getStartTime(), req.getEndTime());

        PetSitterReservation res = new PetSitterReservation();
        res.setSitterId(sitter.getId());
        res.setOwnerId(ownerId);
        res.setPetName(req.getPetName().trim());
        res.setPetType(req.getPetType());
        res.setPetSize(req.getPetSize());
        res.setService(req.getService());
        res.setStartDate(req.getStartDate());
        res.setEndDate(req.getEndDate());
        res.setStartTime(req.getStartTime());
        res.setEndTime(req.getEndTime());
        res.setNotes(req.getNotes());
        res.setTotalPrice(totalPrice);
        res.setStatus(ReservationStatus.PENDING);

        PetSitterReservation saved = reservationRepository.save(res);
        return mapper.toReservationResponse(saved, sitter, ownerName, false);
    }

    @Transactional
    public ReservationResponse updateReservation(String id, UpdateReservationRequest req, String ownerId) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));

        if (!res.getOwnerId().equalsIgnoreCase(ownerId)) {
            throw new BadRequestException("FORBIDDEN", "Vous n'êtes pas autorisé à modifier cette réservation.");
        }

        if (res.getStatus() != ReservationStatus.PENDING) {
            throw new BadRequestException("CANNOT_UPDATE", "Seules les réservations en attente peuvent être modifiées.");
        }

        PetSitterProfile sitter = profileRepository.findById(res.getSitterId())
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable."));

        if (req.getPetName() != null && !req.getPetName().isBlank()) res.setPetName(req.getPetName().trim());
        if (req.getPetType() != null) res.setPetType(req.getPetType());
        if (req.getPetSize() != null) res.setPetSize(req.getPetSize());
        if (req.getService() != null) res.setService(req.getService());

        LocalDate start = req.getStartDate() != null ? req.getStartDate() : res.getStartDate();
        LocalDate end = req.getEndDate() != null ? req.getEndDate() : res.getEndDate();
        validateDates(start, end);
        res.setStartDate(start);
        res.setEndDate(end);

        if (req.getStartTime() != null) res.setStartTime(req.getStartTime());
        if (req.getEndTime() != null) res.setEndTime(req.getEndTime());
        if (req.getNotes() != null) res.setNotes(req.getNotes());

        double price = calculatePrice(sitter, res.getStartDate(), res.getEndDate(), res.getStartTime(), res.getEndTime());
        res.setTotalPrice(price);

        PetSitterReservation updated = reservationRepository.save(res);
        boolean hasReview = reviewRepository.findByReservationId(id).isPresent();
        return mapper.toReservationResponse(updated, sitter, null, hasReview);
    }

    @Transactional
    public ReservationResponse acceptReservation(String id, String sitterUserId) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));

        PetSitterProfile sitter = profileRepository.findById(res.getSitterId())
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable."));

        if (!sitter.getUserId().equalsIgnoreCase(sitterUserId)) {
            throw new BadRequestException("FORBIDDEN", "Cette réservation ne vous est pas destinée.");
        }

        if (res.getStatus() != ReservationStatus.PENDING) {
            throw new BadRequestException("INVALID_STATUS", "Cette réservation ne peut plus être acceptée (statut actuel : " + res.getStatus() + ").");
        }

        // Verify overlapping again before accepting
        List<PetSitterReservation> overlaps = reservationRepository.findOverlappingAccepted(
                sitter.getId(), res.getStartDate(), res.getEndDate());
        overlaps.removeIf(r -> r.getId().equals(res.getId()));
        if (!overlaps.isEmpty()) {
            throw new BadRequestException("CONFLICT", "Vous avez déjà une autre réservation confirmée sur cette même période.");
        }

        res.setStatus(ReservationStatus.ACCEPTED);
        PetSitterReservation updated = reservationRepository.save(res);
        return mapper.toReservationResponse(updated, sitter, null, false);
    }

    @Transactional
    public ReservationResponse rejectReservation(String id, RejectReservationRequest req, String sitterUserId) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));

        PetSitterProfile sitter = profileRepository.findById(res.getSitterId())
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable."));

        if (!sitter.getUserId().equalsIgnoreCase(sitterUserId)) {
            throw new BadRequestException("FORBIDDEN", "Cette réservation ne vous est pas destinée.");
        }

        if (res.getStatus() != ReservationStatus.PENDING) {
            throw new BadRequestException("INVALID_STATUS", "Cette réservation ne peut plus être refusée.");
        }

        res.setStatus(ReservationStatus.REJECTED);
        res.setRejectionReason(req != null && req.getReason() != null ? req.getReason().trim() : "Non disponible");

        PetSitterReservation updated = reservationRepository.save(res);
        return mapper.toReservationResponse(updated, sitter, null, false);
    }

    @Transactional
    public ReservationResponse cancelReservation(String id, String currentUserId, boolean isAdmin) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));

        PetSitterProfile sitter = profileRepository.findById(res.getSitterId()).orElse(null);

        boolean isOwner = res.getOwnerId().equalsIgnoreCase(currentUserId);
        boolean isSitter = sitter != null && sitter.getUserId().equalsIgnoreCase(currentUserId);

        if (!isAdmin && !isOwner && !isSitter) {
            throw new BadRequestException("FORBIDDEN", "Vous n'avez pas le droit d'annuler cette réservation.");
        }

        if (res.getStatus() == ReservationStatus.COMPLETED || res.getStatus() == ReservationStatus.REJECTED || res.getStatus() == ReservationStatus.CANCELLED) {
            throw new BadRequestException("INVALID_STATUS", "La réservation ne peut pas être annulée dans son état actuel : " + res.getStatus());
        }

        res.setStatus(ReservationStatus.CANCELLED);
        PetSitterReservation updated = reservationRepository.save(res);
        return mapper.toReservationResponse(updated, sitter, null, false);
    }

    @Transactional
    public ReservationResponse completeReservation(String id, String sitterUserId) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));

        PetSitterProfile sitter = profileRepository.findById(res.getSitterId())
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable."));

        if (!sitter.getUserId().equalsIgnoreCase(sitterUserId)) {
            throw new BadRequestException("FORBIDDEN", "Cette réservation ne vous appartient pas.");
        }

        if (res.getStatus() != ReservationStatus.ACCEPTED) {
            throw new BadRequestException("INVALID_STATUS", "Seule une réservation confirmée peut être marquée comme terminée.");
        }

        res.setStatus(ReservationStatus.COMPLETED);
        PetSitterReservation updated = reservationRepository.save(res);
        boolean hasReview = reviewRepository.findByReservationId(id).isPresent();
        return mapper.toReservationResponse(updated, sitter, null, hasReview);
    }

    @Transactional(readOnly = true)
    public ReservationResponse getById(String id) {
        PetSitterReservation res = reservationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + id));
        PetSitterProfile sitter = profileRepository.findById(res.getSitterId()).orElse(null);
        boolean hasReview = reviewRepository.findByReservationId(id).isPresent();
        return mapper.toReservationResponse(res, sitter, null, hasReview);
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> listByOwner(String ownerId) {
        List<PetSitterReservation> list = reservationRepository.findByOwnerIdOrderByCreatedAtDesc(ownerId);
        return list.stream().map(r -> {
            PetSitterProfile sitter = profileRepository.findById(r.getSitterId()).orElse(null);
            boolean hasReview = reviewRepository.findByReservationId(r.getId()).isPresent();
            return mapper.toReservationResponse(r, sitter, null, hasReview);
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> listBySitterUserId(String sitterUserId) {
        PetSitterProfile sitter = profileRepository.findByUserId(sitterUserId).orElse(null);
        if (sitter == null) {
            return List.of();
        }
        List<PetSitterReservation> list = reservationRepository.findBySitterIdOrderByCreatedAtDesc(sitter.getId());
        return list.stream().map(r -> {
            boolean hasReview = reviewRepository.findByReservationId(r.getId()).isPresent();
            return mapper.toReservationResponse(r, sitter, null, hasReview);
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> listAll() {
        return reservationRepository.findAllByOrderByCreatedAtDesc().stream().map(r -> {
            PetSitterProfile sitter = profileRepository.findById(r.getSitterId()).orElse(null);
            boolean hasReview = reviewRepository.findByReservationId(r.getId()).isPresent();
            return mapper.toReservationResponse(r, sitter, null, hasReview);
        }).toList();
    }

    @Transactional
    public void deleteReservation(String id) {
        if (!reservationRepository.existsById(id)) {
            throw new ResourceNotFoundException("Réservation introuvable : " + id);
        }
        reservationRepository.deleteById(id);
    }

    private void validateDates(LocalDate start, LocalDate end) {
        if (start == null || end == null) {
            throw new BadRequestException("INVALID_DATES", "Les dates de début et de fin sont obligatoires.");
        }
        if (start.isBefore(LocalDate.now())) {
            throw new BadRequestException("INVALID_DATES", "La date de début ne peut pas être dans le passé.");
        }
        if (end.isBefore(start)) {
            throw new BadRequestException("INVALID_DATES", "La date de fin ne peut pas être antérieure à la date de début.");
        }
    }

    private double calculatePrice(PetSitterProfile sitter, LocalDate start, LocalDate end, java.time.LocalTime startTime, java.time.LocalTime endTime) {
        long days = Math.max(1, ChronoUnit.DAYS.between(start, end) + 1);

        if (startTime != null && endTime != null) {
            long hours = Duration.between(startTime, endTime).toHours();
            if (hours <= 0) hours = 1;
            return days * hours * sitter.getPricePerHour();
        }

        return days * sitter.getPricePerDay();
    }
}
