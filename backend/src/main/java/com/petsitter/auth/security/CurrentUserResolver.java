package com.petsitter.auth.security;

import com.petsitter.common.exception.UnauthenticatedException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;

/**
 * Donne l'utilisateur connecté d'une requête.
 *
 * <p>Source principale : le jeton vérifié par {@link JwtAuthenticationFilter}.
 * Tant que {@code petsitter.auth.allow-demo-header=true}, l'en-tête
 * {@code X-Demo-User-Id} reste accepté pour tester dans Swagger.</p>
 */
@Component
public class CurrentUserResolver {

    private final UserRepository users;
    private final boolean allowDemoHeader;

    public CurrentUserResolver(
            UserRepository users,
            @Value("${petsitter.auth.allow-demo-header:true}") boolean allowDemoHeader) {
        this.users = users;
        this.allowDemoHeader = allowDemoHeader;
    }

    @Transactional(readOnly = true)
    public UserEntity require(HttpServletRequest request) {
        Object authenticated = request.getAttribute(JwtAuthenticationFilter.ATTR_USER_ID);
        if (authenticated instanceof String id) {
            return users.findById(id).orElseThrow(CurrentUserResolver::sessionExpired);
        }
        if (request.getAttribute(JwtAuthenticationFilter.ATTR_TOKEN_ERROR) != null) {
            throw sessionExpired();
        }
        if (allowDemoHeader) {
            String demo = firstNonBlank(request.getHeader("X-Demo-User-Id"), request.getHeader("X-User-Id"));
            if (demo != null) {
                UserEntity user = users.findById(demo.trim()).orElseThrow(CurrentUserResolver::sessionExpired);
                if (user.isDisabled()) {
                    throw new UnauthenticatedException("ACCOUNT_DISABLED", "Ce compte a été suspendu.");
                }
                return user;
            }
        }
        throw new UnauthenticatedException("AUTH_REQUIRED", "Connectez-vous pour continuer.");
    }

    @Transactional(readOnly = true)
    public UserEntity requireRole(HttpServletRequest request, UserRole... allowed) {
        UserEntity user = require(request);
        if (Arrays.stream(allowed).noneMatch(r -> r == user.getRole())) {
            throw new UnauthorizedActionException("Votre rôle ne permet pas cette opération.");
        }
        return user;
    }

    private static UnauthenticatedException sessionExpired() {
        return new UnauthenticatedException("SESSION_EXPIRED", "Votre session a expiré. Reconnectez-vous.");
    }

    private static String firstNonBlank(String a, String b) {
        if (a != null && !a.isBlank()) {
            return a;
        }
        return b != null && !b.isBlank() ? b : null;
    }
}
