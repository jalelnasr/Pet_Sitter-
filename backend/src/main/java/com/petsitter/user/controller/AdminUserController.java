package com.petsitter.user.controller;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.user.dto.UpdateUserStatusRequest;
import com.petsitter.user.dto.UserResponse;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Gestion des comptes par un administrateur. */
@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Administration — utilisateurs")
public class AdminUserController {

    private final UserService users;
    private final CurrentUserResolver currentUser;

    public AdminUserController(UserService users, CurrentUserResolver currentUser) {
        this.users = users;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "Lister tous les comptes (recherche par nom ou e-mail, filtre par rôle)")
    public Page<UserResponse> list(
            HttpServletRequest http,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) UserRole role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        currentUser.requireRole(http, UserRole.ADMIN);
        return users.adminList(q, role, page, size);
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "Suspendre ou réactiver un compte")
    public UserResponse setStatus(
            HttpServletRequest http,
            @PathVariable String id,
            @Valid @RequestBody UpdateUserStatusRequest request) {
        return users.setDisabled(currentUser.requireRole(http, UserRole.ADMIN), id, request.disabled());
    }
}
