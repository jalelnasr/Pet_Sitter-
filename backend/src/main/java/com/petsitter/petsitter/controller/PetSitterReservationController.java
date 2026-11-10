package com.petsitter.petsitter.controller;

import com.petsitter.petsitter.security.PetSitterRoles;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.petsitter.dto.CreateReservationRequest;
import com.petsitter.petsitter.dto.RejectReservationRequest;
import com.petsitter.petsitter.dto.ReservationResponse;
import com.petsitter.petsitter.dto.UpdateReservationRequest;
import com.petsitter.petsitter.service.PetSitterReservationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/reservations")
@Tag(name = "Reservations", description = "Endpoints de réservation de garde d'animaux")
public class PetSitterReservationController {

    private final PetSitterReservationService reservationService;
    private final PetSitterRoles roles;

    public PetSitterReservationController(PetSitterReservationService reservationService, PetSitterRoles roles) {
        this.roles = roles;
        this.reservationService = reservationService;
    }

    private String resolveUserId(HttpServletRequest request) {
        String h = request.getHeader("X-User-Id");
        if (h == null || h.isBlank()) {
            h = request.getHeader("X-Demo-User-Id");
        }
        return (h != null && !h.isBlank()) ? h.trim() : "OWNER_DEMO";
    }

    private boolean checkIsAdmin(HttpServletRequest request) {
        return roles.isAdmin(resolveUserId(request));
    }

    @PostMapping
    @Operation(summary = "Créer une demande de réservation (Propriétaire)")
    public ResponseEntity<ReservationResponse> create(
            @Valid @RequestBody CreateReservationRequest request,
            HttpServletRequest httpRequest
    ) {
        String ownerId = resolveUserId(httpRequest);
        if (roles.isAdmin(ownerId)) {
            throw new UnauthorizedActionException("Un administrateur ne réserve pas de garde.");
        }
        ReservationResponse res = reservationService.createReservation(request, ownerId, null);
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @GetMapping("/my")
    @Operation(summary = "Lister mes réservations en tant que propriétaire")
    public List<ReservationResponse> listMyReservations(HttpServletRequest httpRequest) {
        String ownerId = resolveUserId(httpRequest);
        return reservationService.listByOwner(ownerId);
    }

    @GetMapping("/incoming")
    @Operation(summary = "Lister les réservations reçues en tant que pet sitter")
    public List<ReservationResponse> listIncoming(HttpServletRequest httpRequest) {
        String sitterUserId = resolveUserId(httpRequest);
        return reservationService.listBySitterUserId(sitterUserId);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Consulter le détail d'une réservation")
    public ReservationResponse getById(@PathVariable String id) {
        return reservationService.getById(id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Modifier une réservation (tant qu'elle est en attente)")
    public ReservationResponse update(
            @PathVariable String id,
            @Valid @RequestBody UpdateReservationRequest request,
            HttpServletRequest httpRequest
    ) {
        String ownerId = resolveUserId(httpRequest);
        return reservationService.updateReservation(id, request, ownerId);
    }

    @PatchMapping("/{id}/accept")
    @Operation(summary = "Accepter une réservation (Pet sitter)")
    public ReservationResponse accept(
            @PathVariable String id,
            HttpServletRequest httpRequest
    ) {
        String sitterUserId = resolveUserId(httpRequest);
        return reservationService.acceptReservation(id, sitterUserId);
    }

    @PatchMapping("/{id}/reject")
    @Operation(summary = "Refuser une réservation avec motif (Pet sitter)")
    public ReservationResponse reject(
            @PathVariable String id,
            @RequestBody(required = false) RejectReservationRequest request,
            HttpServletRequest httpRequest
    ) {
        String sitterUserId = resolveUserId(httpRequest);
        return reservationService.rejectReservation(id, request, sitterUserId);
    }

    @PatchMapping("/{id}/cancel")
    @Operation(summary = "Annuler une réservation")
    public ReservationResponse cancel(
            @PathVariable String id,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        boolean isAdmin = checkIsAdmin(httpRequest);
        return reservationService.cancelReservation(id, userId, isAdmin);
    }

    @PatchMapping("/{id}/complete")
    @Operation(summary = "Marquer une réservation comme terminée (Pet sitter)")
    public ReservationResponse complete(
            @PathVariable String id,
            HttpServletRequest httpRequest
    ) {
        String sitterUserId = resolveUserId(httpRequest);
        return reservationService.completeReservation(id, sitterUserId);
    }
}
