package com.petsitter.user.controller;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.user.dto.UserSummaryResponse;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Annuaire des membres (connexion requise) : sert à démarrer une conversation. */
@RestController
@RequestMapping("/api/users")
@Tag(name = "Utilisateurs", description = "Annuaire et fiches publiques")
public class UserController {

    private final UserService users;
    private final CurrentUserResolver currentUser;

    public UserController(UserService users, CurrentUserResolver currentUser) {
        this.users = users;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "Rechercher un membre par prénom ou nom")
    public Page<UserSummaryResponse> search(
            HttpServletRequest http,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) UserRole role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return users.directory(currentUser.require(http), q, role, page, size);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Fiche publique d'un membre")
    public UserSummaryResponse get(HttpServletRequest http, @PathVariable String id) {
        currentUser.require(http);
        return users.publicProfile(id);
    }
}
