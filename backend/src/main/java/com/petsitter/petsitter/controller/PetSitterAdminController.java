package com.petsitter.petsitter.controller;

import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.petsitter.dto.PetSitterStatsResponse;
import com.petsitter.petsitter.dto.ReservationResponse;
import com.petsitter.petsitter.dto.SitterResponse;
import com.petsitter.petsitter.dto.SitterSummaryResponse;
import com.petsitter.petsitter.service.PetSitterReservationService;
import com.petsitter.petsitter.service.PetSitterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin Pet Sitters", description = "Endpoints d'administration pour la gestion des sitters et réservations")
public class PetSitterAdminController {

    private final PetSitterService sitterService;
    private final PetSitterReservationService reservationService;

    public PetSitterAdminController(PetSitterService sitterService, PetSitterReservationService reservationService) {
        this.sitterService = sitterService;
        this.reservationService = reservationService;
    }

    private void requireAdmin(HttpServletRequest request) {
        String h = request.getHeader("X-User-Id");
        if (h == null || h.isBlank()) {
            h = request.getHeader("X-Demo-User-Id");
        }
        String uid = (h != null && !h.isBlank()) ? h.trim() : "";
        if (!"ADMIN_DEMO".equalsIgnoreCase(uid) && !"admin".equalsIgnoreCase(uid)) {
            throw new UnauthorizedActionException("Accès réservé aux administrateurs.");
        }
    }

    @GetMapping("/sitters")
    @Operation(summary = "Lister tous les sitters (actifs et inactifs)")
    public Page<SitterSummaryResponse> listAllSitters(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String governorate,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "50") int size,
            HttpServletRequest request
    ) {
        requireAdmin(request);
        return sitterService.list(search, governorate, null, null, null, null, null, null, null, "newest", page, size, true);
    }

    @PatchMapping("/sitters/{id}/verify")
    @Operation(summary = "Vérifier ou retirer la vérification d'un sitter")
    public SitterResponse setVerification(
            @PathVariable String id,
            @RequestParam boolean verified,
            HttpServletRequest request
    ) {
        requireAdmin(request);
        return sitterService.setVerification(id, verified);
    }

    @PatchMapping("/sitters/{id}/activate")
    @Operation(summary = "Activer ou désactiver le profil d'un sitter")
    public SitterResponse setActive(
            @PathVariable String id,
            @RequestParam boolean active,
            HttpServletRequest request
    ) {
        requireAdmin(request);
        return sitterService.setActiveStatus(id, active);
    }

    @DeleteMapping("/sitters/{id}")
    @Operation(summary = "Supprimer définitivement un sitter")
    public ResponseEntity<Void> deleteSitter(@PathVariable String id, HttpServletRequest request) {
        requireAdmin(request);
        sitterService.deleteProfile(id, "admin", true);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/reservations")
    @Operation(summary = "Lister toutes les réservations")
    public List<ReservationResponse> listAllReservations(HttpServletRequest request) {
        requireAdmin(request);
        return reservationService.listAll();
    }

    @DeleteMapping("/reservations/{id}")
    @Operation(summary = "Supprimer une réservation")
    public ResponseEntity<Void> deleteReservation(@PathVariable String id, HttpServletRequest request) {
        requireAdmin(request);
        reservationService.deleteReservation(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/sitters/stats")
    @Operation(summary = "Statistiques globales du module Pet Sitter")
    public PetSitterStatsResponse getStats(HttpServletRequest request) {
        requireAdmin(request);
        return sitterService.getStats();
    }
}
