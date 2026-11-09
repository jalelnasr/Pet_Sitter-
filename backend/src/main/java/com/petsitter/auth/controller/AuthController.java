package com.petsitter.auth.controller;

import com.petsitter.auth.dto.AuthResponse;
import com.petsitter.auth.dto.ChangePasswordRequest;
import com.petsitter.auth.dto.ChangeRoleRequest;
import com.petsitter.auth.dto.ForgotPasswordRequest;
import com.petsitter.auth.dto.LoginRequest;
import com.petsitter.auth.dto.RegisterRequest;
import com.petsitter.auth.dto.ResetPasswordRequest;
import com.petsitter.auth.dto.VerifyResetCodeRequest;
import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.auth.service.AuthService;
import com.petsitter.common.response.InfoResponse;
import com.petsitter.user.dto.UpdateProfileRequest;
import com.petsitter.user.dto.UserResponse;
import com.petsitter.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Compte : inscription, connexion, profil, mot de passe (y compris oublié) et rôle.
 * Les routes « me » exigent {@code Authorization: Bearer <jeton>}.
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentification", description = "Inscription, connexion, mot de passe oublié, profil")
public class AuthController {

    private final AuthService auth;
    private final UserService userService;
    private final CurrentUserResolver currentUser;

    public AuthController(AuthService auth, UserService userService, CurrentUserResolver currentUser) {
        this.auth = auth;
        this.userService = userService;
        this.currentUser = currentUser;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Créer un compte (OWNER par défaut, ou PETSITTER) et ouvrir la session")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return auth.register(request);
    }

    @PostMapping("/login")
    @Operation(summary = "Se connecter avec e-mail et mot de passe")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return auth.login(request);
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Recevoir un code de réinitialisation à 6 chiffres par e-mail")
    public InfoResponse forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        return auth.requestPasswordReset(request.email());
    }

    @PostMapping("/verify-reset-code")
    @Operation(summary = "Vérifier le code reçu (sans le consommer)")
    public InfoResponse verifyResetCode(@Valid @RequestBody VerifyResetCodeRequest request) {
        return auth.verifyResetCode(request.email(), request.code());
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Choisir un nouveau mot de passe avec le code, puis ouvrir la session")
    public AuthResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return auth.resetPassword(request);
    }

    @GetMapping("/me")
    @Operation(summary = "Profil de l'utilisateur connecté")
    public UserResponse me(HttpServletRequest http) {
        return userService.me(currentUser.require(http));
    }

    @PutMapping("/me")
    @Operation(summary = "Modifier son profil")
    public UserResponse updateMe(HttpServletRequest http, @Valid @RequestBody UpdateProfileRequest request) {
        return userService.updateProfile(currentUser.require(http), request);
    }

    @PutMapping("/me/password")
    @Operation(summary = "Changer son mot de passe (renvoie un nouveau jeton, les autres sessions sont fermées)")
    public AuthResponse changePassword(HttpServletRequest http, @Valid @RequestBody ChangePasswordRequest request) {
        return auth.changePassword(currentUser.require(http), request);
    }

    @PutMapping("/me/role")
    @Operation(summary = "Passer de propriétaire à pet sitter, ou l'inverse")
    public AuthResponse changeRole(HttpServletRequest http, @Valid @RequestBody ChangeRoleRequest request) {
        return auth.changeRole(currentUser.require(http), request.role());
    }
}
