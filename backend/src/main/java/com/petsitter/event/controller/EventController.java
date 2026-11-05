package com.petsitter.event.controller;

import com.petsitter.event.dto.CreateEventRequest;
import com.petsitter.event.dto.CreateReservationRequest;
import com.petsitter.event.dto.EventResponse;
import com.petsitter.event.dto.EventSummaryResponse;
import com.petsitter.event.dto.RejectProposalRequest;
import com.petsitter.event.dto.ReservationResponse;
import com.petsitter.event.dto.UpdateEventRequest;
import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.security.EventUserResolver;
import com.petsitter.event.service.EventReservationService;
import com.petsitter.event.service.EventService;
import com.petsitter.user.entity.UserEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/events")
@Tag(name = "Events", description = "Endpoints for managing pet events, proposals, and reservations")
public class EventController {

    private final EventService eventService;
    private final EventReservationService reservationService;
    private final EventUserResolver userResolver;

    public EventController(
            EventService eventService,
            EventReservationService reservationService,
            EventUserResolver userResolver
    ) {
        this.eventService = eventService;
        this.reservationService = reservationService;
        this.userResolver = userResolver;
    }

    // ==========================================
    // Events Core Endpoints
    // ==========================================

    @GetMapping
    @Operation(summary = "List events with optional filters (category, search, upcoming, status for admin)")
    public List<EventSummaryResponse> list(
            @RequestParam(required = false) EventCategory category,
            @RequestParam(required = false) String search,
            @RequestParam(required = false, defaultValue = "false") Boolean upcomingOnly,
            @RequestParam(required = false) EventStatus status,
            HttpServletRequest request
    ) {
        UserEntity requester = userResolver.resolve(request);
        return eventService.list(category, search, upcomingOnly, status, requester);
    }

    @GetMapping("/{id:^(?!proposals$).+}")
    @Operation(summary = "Get event details by id")
    public EventResponse get(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity requester = userResolver.resolve(request);
        return eventService.get(id, requester);
    }

    @PostMapping
    @Operation(summary = "Create an event (admin only)")
    public ResponseEntity<EventResponse> create(
            @Valid @RequestBody CreateEventRequest createRequest,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(eventService.create(createRequest, actor));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an event (admin only)")
    public EventResponse update(
            @PathVariable String id,
            @Valid @RequestBody UpdateEventRequest updateRequest,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.update(id, updateRequest, actor);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete an event (admin only)")
    public ResponseEntity<Void> delete(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        eventService.delete(id, actor);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel an event (admin only)")
    public EventResponse cancel(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.cancel(id, actor);
    }

    @PatchMapping("/{id}/cancel")
    @Operation(summary = "Cancel an event (admin only - compatibility)")
    public EventResponse cancelPatch(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.cancel(id, actor);
    }

    @GetMapping("/mine")
    @Operation(summary = "List events organized by admin (Mes événements)")
    public List<EventSummaryResponse> mine(HttpServletRequest request) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.mine(actor);
    }

    @PostMapping(value = "/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload an event image")
    public Map<String, String> uploadImage(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return Map.of("url", eventService.storeImage(file, actor));
    }

    // ==========================================
    // Proposals Endpoints
    // ==========================================

    @PostMapping("/proposals")
    @Operation(summary = "Submit a proposal for an event (PETSITTER)")
    public ResponseEntity<EventResponse> propose(
            @Valid @RequestBody CreateEventRequest proposeRequest,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(eventService.propose(proposeRequest, actor));
    }

    @PutMapping("/proposals/{id}")
    @Operation(summary = "Update own proposal while PENDING or REJECTED (PETSITTER)")
    public EventResponse updateProposal(
            @PathVariable String id,
            @Valid @RequestBody UpdateEventRequest updateRequest,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.updateProposal(id, updateRequest, actor);
    }

    @DeleteMapping("/proposals/{id}")
    @Operation(summary = "Withdraw own proposal while PENDING or REJECTED (PETSITTER)")
    public ResponseEntity<Void> withdrawProposal(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        eventService.withdrawProposal(id, actor);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/proposals/mine")
    @Operation(summary = "List my proposals (PETSITTER)")
    public List<EventSummaryResponse> myProposals(HttpServletRequest request) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.myProposals(actor);
    }

    @GetMapping("/proposals")
    @Operation(summary = "List all proposals with optional status filter (ADMIN)")
    public List<EventSummaryResponse> allProposals(
            @RequestParam(required = false) EventStatus status,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.allProposals(status, actor);
    }

    @PostMapping("/proposals/{id}/approve")
    @Operation(summary = "Approve a proposal (ADMIN)")
    public EventResponse approveProposal(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.approveProposal(id, actor);
    }

    @PostMapping("/proposals/{id}/reject")
    @Operation(summary = "Reject a proposal with reason (ADMIN)")
    public EventResponse rejectProposal(
            @PathVariable String id,
            @Valid @RequestBody RejectProposalRequest rejectRequest,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return eventService.rejectProposal(id, rejectRequest.reason(), actor);
    }

    // ==========================================
    // Event Reservations Endpoints
    // ==========================================

    @PostMapping("/{id}/reservations")
    @Operation(summary = "Reserve places for an event")
    public ResponseEntity<ReservationResponse> reserve(
            @PathVariable String id,
            @Valid @RequestBody CreateReservationRequest reservationRequest,
            HttpServletRequest request
    ) {
        UserEntity user = userResolver.resolve(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(reservationService.reserve(id, reservationRequest, user));
    }

    @GetMapping("/{id}/reservations")
    @Operation(summary = "List all reservations/participants for an event (ADMIN only)")
    public List<ReservationResponse> eventReservations(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity actor = userResolver.resolve(request);
        return reservationService.eventReservations(id, actor);
    }
}
