package com.petsitter.petsitter.controller;

import com.petsitter.petsitter.dto.CreateSitterRequest;
import com.petsitter.petsitter.dto.SitterResponse;
import com.petsitter.petsitter.dto.SitterSummaryResponse;
import com.petsitter.petsitter.dto.UpdateSitterRequest;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.SitterServiceType;
import com.petsitter.petsitter.service.PetSitterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
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

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/sitters")
@Tag(name = "Pet Sitters", description = "Endpoints pour la recherche et la gestion des profils pet sitters")
public class PetSitterController {

    private final PetSitterService sitterService;

    public PetSitterController(PetSitterService sitterService) {
        this.sitterService = sitterService;
    }

    private String resolveUserId(HttpServletRequest request) {
        String h = request.getHeader("X-User-Id");
        if (h == null || h.isBlank()) {
            h = request.getHeader("X-Demo-User-Id");
        }
        return (h != null && !h.isBlank()) ? h.trim() : "PETSITTER_DEMO";
    }

    private boolean checkIsAdmin(HttpServletRequest request) {
        String uid = resolveUserId(request);
        return "ADMIN_DEMO".equalsIgnoreCase(uid) || "admin".equalsIgnoreCase(uid);
    }

    @GetMapping
    @Operation(summary = "Lister les pet sitters avec filtres et pagination")
    public Page<SitterSummaryResponse> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String governorate,
            @RequestParam(required = false) SitterServiceType service,
            @RequestParam(required = false) PetSpeciesType petType,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) Double minRating,
            @RequestParam(required = false) Boolean verifiedOnly,
            @RequestParam(required = false) LocalDate availableDate,
            @RequestParam(required = false, defaultValue = "rating") String sortBy,
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "20") int size
    ) {
        return sitterService.list(search, governorate, service, petType, minPrice, maxPrice, minRating, verifiedOnly, availableDate, sortBy, page, size, false);
    }

    @GetMapping("/me")
    @Operation(summary = "Obtenir le profil du pet sitter connecté")
    public SitterResponse getMyProfile(HttpServletRequest request) {
        String userId = resolveUserId(request);
        return sitterService.getByUserId(userId);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Consulter la fiche détaillée d'un pet sitter")
    public SitterResponse getById(@PathVariable String id) {
        return sitterService.getById(id);
    }

    @PostMapping
    @Operation(summary = "Créer son profil pet sitter")
    public ResponseEntity<SitterResponse> createProfile(
            @Valid @RequestBody CreateSitterRequest request,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        SitterResponse res = sitterService.createProfile(request, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Mettre à jour son profil pet sitter")
    public SitterResponse updateProfile(
            @PathVariable String id,
            @Valid @RequestBody UpdateSitterRequest request,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        boolean isAdmin = checkIsAdmin(httpRequest);
        return sitterService.updateProfile(id, request, userId, isAdmin);
    }

    @PatchMapping("/{id}/visibility")
    @Operation(summary = "Activer ou désactiver la visibilité du profil")
    public SitterResponse toggleVisibility(
            @PathVariable String id,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        return sitterService.toggleVisibility(id, userId);
    }

    @PostMapping(value = "/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Téléverser une photo pour son profil ou sa galerie")
    public Map<String, String> uploadImage(@RequestParam("file") MultipartFile file) {
        String url = sitterService.storeImage(file);
        return Map.of("url", url);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Supprimer son profil pet sitter")
    public ResponseEntity<Void> deleteProfile(
            @PathVariable String id,
            HttpServletRequest httpRequest
    ) {
        String userId = resolveUserId(httpRequest);
        boolean isAdmin = checkIsAdmin(httpRequest);
        sitterService.deleteProfile(id, userId, isAdmin);
        return ResponseEntity.noContent().build();
    }
}
