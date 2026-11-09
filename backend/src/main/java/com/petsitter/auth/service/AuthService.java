package com.petsitter.auth.service;

import com.petsitter.auth.dto.AuthResponse;
import com.petsitter.auth.dto.ChangePasswordRequest;
import com.petsitter.auth.dto.LoginRequest;
import com.petsitter.auth.dto.RegisterRequest;
import com.petsitter.auth.dto.ResetPasswordRequest;
import com.petsitter.auth.entity.PasswordResetCode;
import com.petsitter.auth.repository.PasswordResetCodeRepository;
import com.petsitter.auth.security.JwtService;
import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.UnauthenticatedException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.common.response.InfoResponse;
import com.petsitter.user.dto.UserResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

/**
 * Inscription, connexion, mot de passe et rôle.
 *
 * <p>Règles : e-mail unique (sans tenir compte de la casse), mot de passe haché
 * avec BCrypt, verrouillage temporaire après {@value #MAX_LOGIN_ATTEMPTS} échecs,
 * code de réinitialisation à usage unique, limité dans le temps et en essais.</p>
 */
@Service
public class AuthService {

    static final int MAX_LOGIN_ATTEMPTS = 5;
    static final Duration LOCK_DURATION = Duration.ofMinutes(15);
    static final int MAX_CODE_ATTEMPTS = 5;
    static final int RESEND_DELAY_SECONDS = 60;

    private static final String INVALID_CREDENTIALS = "E-mail ou mot de passe incorrect.";
    private static final String RESET_SENT =
            "Si un compte existe pour cette adresse, un code à 6 chiffres vient d'y être envoyé.";

    private final UserRepository users;
    private final PasswordResetCodeRepository resetCodes;
    private final JwtService jwt;
    private final PasswordResetMailer mailer;
    private final PasswordEncoder encoder = new BCryptPasswordEncoder();
    private final SecureRandom random = new SecureRandom();
    private final Duration codeValidity;
    private final Clock clock;

    @Autowired
    public AuthService(
            UserRepository users,
            PasswordResetCodeRepository resetCodes,
            JwtService jwt,
            PasswordResetMailer mailer,
            @Value("${petsitter.auth.reset-code-validity-minutes:15}") long codeValidityMinutes) {
        this(users, resetCodes, jwt, mailer, Duration.ofMinutes(codeValidityMinutes), Clock.systemUTC());
    }

    AuthService(UserRepository users, PasswordResetCodeRepository resetCodes, JwtService jwt,
                PasswordResetMailer mailer, Duration codeValidity, Clock clock) {
        this.users = users;
        this.resetCodes = resetCodes;
        this.jwt = jwt;
        this.mailer = mailer;
        this.codeValidity = codeValidity;
        this.clock = clock;
    }

    // ———————————————————————————————————— Inscription et connexion

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String email = normalizeEmail(req.email());
        if (users.existsByEmailIgnoreCase(email)) {
            throw new BusinessException("EMAIL_ALREADY_USED",
                    "Un compte existe déjà avec cette adresse. Connectez-vous ou réinitialisez votre mot de passe.");
        }
        UserRole role = req.role() == null ? UserRole.OWNER : req.role();
        if (role == UserRole.ADMIN) {
            throw new BadRequestException("ROLE_NOT_ALLOWED", "Ce profil ne peut pas être choisi à l'inscription.");
        }
        UserEntity user = new UserEntity(UUID.randomUUID().toString(), req.firstName().trim(), email, role);
        user.setLastName(blankToNull(req.lastName()));
        user.setPasswordHash(encoder.encode(req.password()));
        user.setLastLoginAt(now());
        return session(users.save(user));
    }

    /** Pas de transaction annulée en cas d'échec : le compteur d'échecs doit être enregistré. */
    @Transactional(noRollbackFor = UnauthenticatedException.class)
    public AuthResponse login(LoginRequest req) {
        Instant now = now();
        UserEntity user = users.findByEmailIgnoreCase(normalizeEmail(req.email())).orElse(null);
        if (user == null || !user.hasPassword()) {
            encoder.matches(req.password(), "$2a$10$7EqJtq98hPqEX7fNZaFWoOhi5BWX4Z3Ydb1J6JZyZSu0bXDOVr7Hy");
            throw new UnauthenticatedException("INVALID_CREDENTIALS", INVALID_CREDENTIALS);
        }
        if (user.isDisabled()) {
            throw new UnauthenticatedException("ACCOUNT_DISABLED",
                    "Ce compte a été suspendu. Contactez l'assistance Pet Sitter.");
        }
        if (user.isLocked(now)) {
            long minutes = Math.max(1, Duration.between(now, user.getLockedUntil()).toMinutes() + 1);
            throw new UnauthenticatedException("ACCOUNT_LOCKED",
                    "Trop de tentatives. Réessayez dans " + minutes + " min ou réinitialisez votre mot de passe.");
        }
        if (!encoder.matches(req.password(), user.getPasswordHash())) {
            int attempts = user.getFailedLoginAttempts() + 1;
            if (attempts >= MAX_LOGIN_ATTEMPTS) {
                user.setFailedLoginAttempts(0);
                user.setLockedUntil(now.plus(LOCK_DURATION));
                throw new UnauthenticatedException("ACCOUNT_LOCKED",
                        "Trop de tentatives. Compte bloqué " + LOCK_DURATION.toMinutes()
                                + " min. Vous pouvez réinitialiser votre mot de passe.");
            }
            user.setFailedLoginAttempts(attempts);
            int left = MAX_LOGIN_ATTEMPTS - attempts;
            throw new UnauthenticatedException("INVALID_CREDENTIALS", INVALID_CREDENTIALS
                    + " Il vous reste " + left + (left > 1 ? " tentatives." : " tentative."));
        }
        user.setFailedLoginAttempts(0);
        user.setLockedUntil(null);
        user.setLastLoginAt(now);
        return session(user);
    }

    // ———————————————————————————————————— Compte connecté

    @Transactional
    public AuthResponse changePassword(UserEntity current, ChangePasswordRequest req) {
        UserEntity user = reload(current);
        if (user.hasPassword() && !encoder.matches(req.currentPassword(), user.getPasswordHash())) {
            throw new BadRequestException("WRONG_PASSWORD", "Le mot de passe actuel est incorrect.");
        }
        if (user.hasPassword() && encoder.matches(req.newPassword(), user.getPasswordHash())) {
            throw new BadRequestException("SAME_PASSWORD", "Choisissez un mot de passe différent de l'actuel.");
        }
        user.setPasswordHash(encoder.encode(req.newPassword()));
        // Le nouveau jeton remplace l'ancien, devenu invalide.
        return session(user);
    }

    @Transactional
    public AuthResponse changeRole(UserEntity current, UserRole role) {
        UserEntity user = reload(current);
        if (user.getRole() == UserRole.ADMIN || role == UserRole.ADMIN) {
            throw new UnauthorizedActionException("Le rôle administrateur ne se choisit pas depuis l'application.");
        }
        user.setRole(role);
        return session(user);
    }

    // ———————————————————————————————————— Mot de passe oublié

    /** Réponse identique que l'adresse existe ou non (pas d'énumération des comptes). */
    @Transactional
    public InfoResponse requestPasswordReset(String rawEmail) {
        Instant now = now();
        users.findByEmailIgnoreCase(normalizeEmail(rawEmail))
                .filter(u -> !u.isDisabled())
                .ifPresent(user -> {
                    boolean tooSoon = resetCodes.findFirstByUserOrderByCreatedAtDesc(user)
                            .map(last -> last.getCreatedAt().plusSeconds(RESEND_DELAY_SECONDS).isAfter(now))
                            .orElse(false);
                    if (tooSoon) {
                        return;
                    }
                    resetCodes.invalidateAll(user, now);
                    String code = "%06d".formatted(random.nextInt(1_000_000));
                    resetCodes.save(new PasswordResetCode(user, encoder.encode(code), now, now.plus(codeValidity)));
                    mailer.sendResetCode(user, code, codeValidity.toMinutes());
                });
        return new InfoResponse(RESET_SENT + " Il reste valable " + codeValidity.toMinutes() + " minutes.",
                RESEND_DELAY_SECONDS);
    }

    /** Vérifie le code sans le consommer (étape intermédiaire de l'écran). */
    @Transactional(noRollbackFor = BadRequestException.class)
    public InfoResponse verifyResetCode(String email, String code) {
        checkCode(email, code);
        return InfoResponse.of("Code vérifié. Choisissez votre nouveau mot de passe.");
    }

    @Transactional(noRollbackFor = BadRequestException.class)
    public AuthResponse resetPassword(ResetPasswordRequest req) {
        PasswordResetCode code = checkCode(req.email(), req.code());
        UserEntity user = code.getUser();
        user.setPasswordHash(encoder.encode(req.newPassword()));
        user.setFailedLoginAttempts(0);
        user.setLockedUntil(null);
        user.setLastLoginAt(now());
        code.markUsed(now());
        return session(user);
    }

    private PasswordResetCode checkCode(String rawEmail, String rawCode) {
        Instant now = now();
        BadRequestException invalid = new BadRequestException("RESET_CODE_INVALID",
                "Code incorrect ou expiré. Demandez un nouveau code.");
        UserEntity user = users.findByEmailIgnoreCase(normalizeEmail(rawEmail)).orElseThrow(() -> invalid);
        PasswordResetCode code = resetCodes.findFirstByUserOrderByCreatedAtDesc(user).orElseThrow(() -> invalid);
        if (code.getUsedAt() != null) {
            throw invalid;
        }
        if (!code.isActive(now)) {
            throw new BadRequestException("RESET_CODE_EXPIRED", "Ce code a expiré. Demandez-en un nouveau.");
        }
        if (!encoder.matches(rawCode == null ? "" : rawCode.trim(), code.getCodeHash())) {
            code.registerFailedAttempt();
            int left = MAX_CODE_ATTEMPTS - code.getAttempts();
            if (left <= 0) {
                code.markUsed(now);
                throw new BadRequestException("RESET_CODE_BLOCKED",
                        "Trop d'essais. Demandez un nouveau code.");
            }
            throw new BadRequestException("RESET_CODE_INVALID",
                    "Code incorrect. Il vous reste " + left + (left > 1 ? " essais." : " essai."));
        }
        return code;
    }

    // ———————————————————————————————————— Outils

    private AuthResponse session(UserEntity user) {
        JwtService.IssuedToken token = jwt.issue(user);
        return AuthResponse.bearer(token.value(), token.expiresAt(), UserResponse.from(user));
    }

    private UserEntity reload(UserEntity user) {
        return users.findById(user.getId())
                .orElseThrow(() -> new UnauthenticatedException("SESSION_EXPIRED", "Votre session a expiré."));
    }

    private Instant now() {
        return clock.instant();
    }

    static String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    /** Utilisé par l'initialisation des comptes de démonstration. */
    public String hash(String rawPassword) {
        return encoder.encode(rawPassword);
    }
}
