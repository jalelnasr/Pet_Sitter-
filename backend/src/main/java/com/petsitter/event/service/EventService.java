package com.petsitter.event.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.event.dto.CreateEventRequest;
import com.petsitter.event.dto.EventResponse;
import com.petsitter.event.dto.EventSummaryResponse;
import com.petsitter.event.dto.UpdateEventRequest;
import com.petsitter.event.entity.Event;
import com.petsitter.event.entity.EventReservation;
import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.EventVisibility;
import com.petsitter.event.enums.ReservationStatus;
import com.petsitter.event.mapper.EventMapper;
import com.petsitter.event.repository.EventRepository;
import com.petsitter.event.repository.EventReservationRepository;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class EventService {

    private static final Logger log = LoggerFactory.getLogger(EventService.class);

    private final EventRepository eventRepository;
    private final EventReservationRepository reservationRepository;
    private final EventMapper mapper;

    @Value("${petsitter.upload.dir:uploads}")
    private String uploadDir;

    public EventService(
            EventRepository eventRepository,
            EventReservationRepository reservationRepository,
            EventMapper mapper
    ) {
        this.eventRepository = eventRepository;
        this.reservationRepository = reservationRepository;
        this.mapper = mapper;
    }

    // ==========================================
    // Public / Non-Admin & Admin Event Endpoints
    // ==========================================

    @Transactional(readOnly = true)
    public List<EventSummaryResponse> list(
            EventCategory category,
            String query,
            Boolean upcomingOnly,
            EventStatus status,
            UserEntity requester
    ) {
        String requesterId = requester != null ? requester.getId() : null;
        LocalDate minDate = Boolean.TRUE.equals(upcomingOnly) ? LocalDate.now() : null;
        String cleanQuery = (query != null && !query.isBlank()) ? query.trim() : null;

        boolean isAdmin = requester != null && requester.getRole() == UserRole.ADMIN;

        List<Event> events;
        if (isAdmin) {
            if (status != null) {
                events = eventRepository.search(status, category, cleanQuery, minDate);
            } else {
                // Admin gets published, drafts, cancelled (proposals are managed on dedicated screen)
                events = eventRepository.search(null, category, cleanQuery, minDate);
            }
        } else {
            // Non-admins only get PUBLISHED events (which dynamically computes to COMPLETED when past)
            events = eventRepository.search(EventStatus.PUBLISHED, category, cleanQuery, minDate);
        }

        return events.stream()
                .filter(event -> canView(event, requester))
                .map(event -> mapper.toSummary(event, requesterId))
                .toList();
    }

    @Transactional(readOnly = true)
    public EventResponse get(String id, UserEntity requester) {
        Event event = find(id);
        if (!canView(event, requester)) {
            throw new ResourceNotFoundException("Événement non trouvé : " + id);
        }
        String requesterId = requester != null ? requester.getId() : null;
        return mapper.toResponse(event, requesterId);
    }

    // ==========================================
    // Admin Event Management
    // ==========================================

    @Transactional
    public EventResponse create(CreateEventRequest request, UserEntity actor) {
        requireAdmin(actor);

        if (request.endTime().isBefore(request.startTime())) {
            throw new BadRequestException("INVALID_TIME_RANGE", "L'heure de fin doit être après l'heure de début.");
        }

        Event event = new Event(UUID.randomUUID().toString(), actor);
        event.setTitle(request.title().trim());
        event.setDescription(request.description().trim());
        event.setCategory(request.category());
        event.setLocation(request.location().trim());
        event.setDate(request.date());
        event.setStartTime(request.startTime());
        event.setEndTime(request.endTime());
        event.setCapacity(request.capacity());
        event.setRemainingPlaces(request.capacity());
        event.setImageUrl(trimToNull(request.imageUrl()));
        // Admin can set DRAFT or PUBLISHED
        EventStatus initialStatus = request.status() != null ? request.status() : EventStatus.PUBLISHED;
        if (initialStatus != EventStatus.DRAFT && initialStatus != EventStatus.PUBLISHED) {
            initialStatus = EventStatus.PUBLISHED;
        }
        event.setStatus(initialStatus);
        event.setVisibility(request.visibility() != null ? request.visibility() : EventVisibility.PUBLIC);

        eventRepository.save(event);
        log.info("Admin {} created event: {} ({}) with status {}", actor.getId(), event.getId(), event.getTitle(), event.getStatus());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public EventResponse update(String id, UpdateEventRequest request, UserEntity actor) {
        requireAdmin(actor);

        Event event = find(id);
        if (request.endTime().isBefore(request.startTime())) {
            throw new BadRequestException("INVALID_TIME_RANGE", "L'heure de fin doit être après l'heure de début.");
        }

        int taken = event.getCapacity() - event.getRemainingPlaces();
        if (request.capacity() < taken) {
            throw new BusinessException(
                    "CAPACITY_TOO_LOW",
                    "La nouvelle capacité (" + request.capacity()
                            + ") ne peut pas être inférieure aux places déjà réservées (" + taken + ")."
            );
        }

        event.setTitle(request.title().trim());
        event.setDescription(request.description().trim());
        event.setCategory(request.category());
        event.setLocation(request.location().trim());
        event.setDate(request.date());
        event.setStartTime(request.startTime());
        event.setEndTime(request.endTime());
        event.setCapacity(request.capacity());
        event.setRemainingPlaces(request.capacity() - taken);
        if (request.imageUrl() != null) {
            event.setImageUrl(trimToNull(request.imageUrl()));
        }
        if (request.status() != null) {
            event.setStatus(request.status());
        }
        if (request.visibility() != null) {
            event.setVisibility(request.visibility());
        }

        eventRepository.save(event);
        log.info("Admin {} updated event: {}", actor.getId(), event.getId());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public EventResponse cancel(String id, UserEntity actor) {
        requireAdmin(actor);

        Event event = find(id);
        event.setStatus(EventStatus.CANCELLED);
        eventRepository.save(event);

        // All active reservations set to CANCELLED_BY_ADMIN
        List<EventReservation> activeReservations =
                reservationRepository.findByEventIdAndStatusOrderByCreatedAtDesc(id, ReservationStatus.CONFIRMED);
        for (EventReservation r : activeReservations) {
            r.setStatus(ReservationStatus.CANCELLED_BY_ADMIN);
            reservationRepository.save(r);
        }

        log.info("Admin {} cancelled event {} and updated {} reservations to CANCELLED_BY_ADMIN",
                actor.getId(), id, activeReservations.size());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public void delete(String id, UserEntity actor) {
        requireAdmin(actor);

        Event event = find(id);
        long activeReservations = reservationRepository.countByEventIdAndStatus(id, ReservationStatus.CONFIRMED);
        if (activeReservations > 0) {
            throw new BusinessException(
                    "EVENT_HAS_RESERVATIONS",
                    "Impossible de supprimer un événement avec des réservations actives. Veuillez l'annuler à la place."
            );
        }

        eventRepository.delete(event);
        log.info("Admin {} deleted event: {}", actor.getId(), id);
    }

    @Transactional(readOnly = true)
    public List<EventSummaryResponse> mine(UserEntity actor) {
        requireAdmin(actor);
        return eventRepository.findByOrganizerIdOrderByDateDescCreatedAtDesc(actor.getId())
                .stream()
                .map(event -> mapper.toSummary(event, actor.getId()))
                .toList();
    }

    // ==========================================
    // Proposal Workflow
    // ==========================================

    @Transactional
    public EventResponse propose(CreateEventRequest request, UserEntity actor) {
        requirePetsitter(actor);

        if (request.endTime().isBefore(request.startTime())) {
            throw new BadRequestException("INVALID_TIME_RANGE", "L'heure de fin doit être après l'heure de début.");
        }

        long pendingCount = eventRepository.countByOrganizerIdAndStatus(actor.getId(), EventStatus.PENDING);
        if (pendingCount >= 3) {
            throw new BusinessException(
                    "MAX_PENDING_PROPOSALS",
                    "Vous avez déjà 3 propositions en attente. Veuillez attendre la validation de l'administrateur avant d'en soumettre une nouvelle."
            );
        }

        Event event = new Event(UUID.randomUUID().toString(), actor);
        event.setTitle(request.title().trim());
        event.setDescription(request.description().trim());
        event.setCategory(request.category());
        event.setLocation(request.location().trim());
        event.setDate(request.date());
        event.setStartTime(request.startTime());
        event.setEndTime(request.endTime());
        event.setCapacity(request.capacity());
        event.setRemainingPlaces(request.capacity());
        event.setImageUrl(trimToNull(request.imageUrl()));
        event.setStatus(EventStatus.PENDING);
        event.setVisibility(EventVisibility.PUBLIC);
        event.setRejectionReason(null);

        eventRepository.save(event);
        log.info("Pet sitter {} proposed event: {} ({})", actor.getId(), event.getId(), event.getTitle());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public EventResponse updateProposal(String id, UpdateEventRequest request, UserEntity actor) {
        requirePetsitter(actor);

        Event event = find(id);
        requireOrganizer(event, actor);

        if (event.getStatus() == EventStatus.PUBLISHED) {
            throw new BusinessException(
                    "PROPOSAL_ALREADY_PUBLISHED",
                    "Cette proposition a déjà été publiée et ne peut être modifiée que par un administrateur."
            );
        }

        if (event.getStatus() != EventStatus.PENDING && event.getStatus() != EventStatus.REJECTED) {
            throw new BusinessException(
                    "CANNOT_EDIT_PROPOSAL",
                    "Seules les propositions en attente ou refusées peuvent être modifiées."
            );
        }

        if (request.endTime().isBefore(request.startTime())) {
            throw new BadRequestException("INVALID_TIME_RANGE", "L'heure de fin doit être après l'heure de début.");
        }

        event.setTitle(request.title().trim());
        event.setDescription(request.description().trim());
        event.setCategory(request.category());
        event.setLocation(request.location().trim());
        event.setDate(request.date());
        event.setStartTime(request.startTime());
        event.setEndTime(request.endTime());
        event.setCapacity(request.capacity());
        event.setRemainingPlaces(request.capacity());
        if (request.imageUrl() != null) {
            event.setImageUrl(trimToNull(request.imageUrl()));
        }

        // If it was rejected, resubmitting sets it back to PENDING and clears reason
        if (event.getStatus() == EventStatus.REJECTED) {
            long pendingCount = eventRepository.countByOrganizerIdAndStatus(actor.getId(), EventStatus.PENDING);
            if (pendingCount >= 3) {
                throw new BusinessException(
                        "MAX_PENDING_PROPOSALS",
                        "Vous avez déjà 3 propositions en attente. Impossible de resoumettre cette proposition pour le moment."
                );
            }
            event.setStatus(EventStatus.PENDING);
            event.setRejectionReason(null);
        }

        eventRepository.save(event);
        log.info("Pet sitter {} updated proposal: {}", actor.getId(), event.getId());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public void withdrawProposal(String id, UserEntity actor) {
        requirePetsitter(actor);

        Event event = find(id);
        requireOrganizer(event, actor);

        if (event.getStatus() != EventStatus.PENDING && event.getStatus() != EventStatus.REJECTED) {
            throw new BusinessException(
                    "CANNOT_WITHDRAW",
                    "Seules les propositions en attente ou refusées peuvent être retirées."
            );
        }

        eventRepository.delete(event);
        log.info("Pet sitter {} withdrew proposal: {}", actor.getId(), id);
    }

    @Transactional(readOnly = true)
    public List<EventSummaryResponse> myProposals(UserEntity actor) {
        requirePetsitter(actor);
        return eventRepository.findByOrganizerIdOrderByCreatedAtDesc(actor.getId())
                .stream()
                .filter(e -> e.getStatus() == EventStatus.PENDING
                        || e.getStatus() == EventStatus.REJECTED
                        || e.getStatus() == EventStatus.PUBLISHED)
                .map(event -> mapper.toSummary(event, actor.getId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EventSummaryResponse> allProposals(EventStatus status, UserEntity actor) {
        requireAdmin(actor);

        List<Event> proposals;
        if (status != null) {
            proposals = eventRepository.findByStatusOrderByCreatedAtDesc(status);
        } else {
            proposals = eventRepository.findByStatusInOrderByCreatedAtDesc(
                    List.of(EventStatus.PENDING, EventStatus.REJECTED)
            );
        }

        return proposals.stream()
                .map(event -> mapper.toSummary(event, actor.getId()))
                .toList();
    }

    @Transactional
    public EventResponse approveProposal(String id, UserEntity actor) {
        requireAdmin(actor);

        Event event = find(id);
        if (event.getStatus() != EventStatus.PENDING && event.getStatus() != EventStatus.REJECTED) {
            throw new BusinessException(
                    "INVALID_STATUS",
                    "Seules les propositions en attente ou refusées peuvent être approuvées."
            );
        }

        event.setStatus(EventStatus.PUBLISHED);
        event.setRejectionReason(null);
        // Organizer remains the pet sitter who proposed it
        eventRepository.save(event);

        log.info("Admin {} approved proposal: {} (organizer: {})",
                actor.getId(), event.getId(), event.getOrganizer().getId());
        return mapper.toResponse(event, actor.getId());
    }

    @Transactional
    public EventResponse rejectProposal(String id, String reason, UserEntity actor) {
        requireAdmin(actor);

        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("REASON_REQUIRED", "Un motif de refus doit obligatoirement être fourni.");
        }

        Event event = find(id);
        if (event.getStatus() != EventStatus.PENDING) {
            throw new BusinessException(
                    "INVALID_STATUS",
                    "Seule une proposition en attente peut être refusée."
            );
        }

        event.setStatus(EventStatus.REJECTED);
        event.setRejectionReason(reason.trim());
        eventRepository.save(event);

        log.info("Admin {} rejected proposal {} with reason: {}", actor.getId(), id, reason.trim());
        return mapper.toResponse(event, actor.getId());
    }

    // ==========================================
    // Image Upload
    // ==========================================

    public String storeImage(MultipartFile file, UserEntity actor) {
        if (actor == null) {
            throw new UnauthorizedActionException("Authentification requise.");
        }
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("EMPTY_FILE", "Veuillez sélectionner un fichier image.");
        }

        String contentType = file.getContentType();
        String extension;
        if ("image/jpeg".equalsIgnoreCase(contentType) || "image/jpg".equalsIgnoreCase(contentType)) {
            extension = ".jpg";
        } else if ("image/png".equalsIgnoreCase(contentType)) {
            extension = ".png";
        } else if ("image/webp".equalsIgnoreCase(contentType)) {
            extension = ".webp";
        } else {
            throw new BadRequestException("INVALID_IMAGE_TYPE", "Seules les images JPEG, PNG et WebP sont acceptées.");
        }

        try {
            Path dir = Paths.get(uploadDir, "events").toAbsolutePath().normalize();
            Files.createDirectories(dir);
            String filename = UUID.randomUUID().toString() + extension;
            Path target = dir.resolve(filename);
            file.transferTo(target.toFile());
            if (!Files.exists(target) || Files.size(target) == 0) {
                throw new BusinessException("IMAGE_STORAGE_ERROR", "L'image enregistrée est vide.");
            }
            log.info("Stored event image: {} ({} bytes)", target, Files.size(target));
            return "/uploads/events/" + filename;
        } catch (IOException ex) {
            log.error("Failed to store event image", ex);
            throw new BusinessException("IMAGE_STORAGE_ERROR", "Impossible d'enregistrer l'image.");
        }
    }

    @Transactional(readOnly = true)
    public Event find(String id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Événement non trouvé : " + id));
    }

    // ==========================================
    // Permission Helpers
    // ==========================================

    private boolean canView(Event event, UserEntity user) {
        // Published or Completed events are visible to all
        if (event.getStatus() == EventStatus.PUBLISHED || event.isCompleted()) {
            return true;
        }
        if (user == null) {
            return false;
        }
        // Admin can view any event
        if (user.getRole() == UserRole.ADMIN) {
            return true;
        }
        // Organizer can view their own draft, pending or rejected event
        return event.getOrganizer() != null && event.getOrganizer().getId().equals(user.getId());
    }

    private void requireAdmin(UserEntity actor) {
        if (actor == null || actor.getRole() != UserRole.ADMIN) {
            throw new UnauthorizedActionException("Cette action est réservée aux administrateurs.");
        }
    }

    private void requirePetsitter(UserEntity actor) {
        if (actor == null || actor.getRole() != UserRole.PETSITTER) {
            throw new UnauthorizedActionException("Cette action est réservée aux pet sitters.");
        }
    }

    private void requireOrganizer(Event event, UserEntity actor) {
        if (actor == null || event.getOrganizer() == null || !event.getOrganizer().getId().equals(actor.getId())) {
            throw new UnauthorizedActionException("Vous n'êtes pas l'auteur de cette proposition.");
        }
    }

    private String trimToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
