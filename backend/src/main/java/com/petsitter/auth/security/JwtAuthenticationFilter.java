package com.petsitter.auth.security;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.Set;

/**
 * Lit l'en-tête {@code Authorization: Bearer <jeton>} de chaque requête {@code /api/**}.
 *
 * <ul>
 *   <li>Jeton valide : l'utilisateur est mémorisé dans la requête
 *       ({@link #ATTR_USER_ID}) et les en-têtes historiques {@code X-Demo-User-Id} /
 *       {@code X-User-Id} sont remplacés par son identifiant. Les modules Adoption,
 *       Événements et Garde fonctionnent ainsi avec les vrais comptes sans
 *       modification, et ces en-têtes ne peuvent plus être usurpés.</li>
 *   <li>Jeton invalide ou expiré : la requête continue en anonyme, avec
 *       {@link #ATTR_TOKEN_ERROR} ; les routes protégées répondent alors 401.</li>
 *   <li>Sans jeton : si {@code petsitter.auth.allow-demo-header=false}, les en-têtes
 *       de démonstration sont ignorés.</li>
 * </ul>
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    public static final String ATTR_USER_ID = "petsitter.auth.userId";
    public static final String ATTR_TOKEN_ERROR = "petsitter.auth.tokenError";
    static final Set<String> IDENTITY_HEADERS = Set.of("x-demo-user-id", "x-user-id");

    private final JwtService jwt;
    private final UserRepository users;
    private final boolean allowDemoHeader;

    public JwtAuthenticationFilter(
            JwtService jwt,
            UserRepository users,
            @Value("${petsitter.auth.allow-demo-header:true}") boolean allowDemoHeader) {
        this.jwt = jwt;
        this.users = users;
        this.allowDemoHeader = allowDemoHeader;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith(request.getContextPath() + "/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.regionMatches(true, 0, "Bearer ", 0, 7)) {
            Optional<UserEntity> user = authenticate(header.substring(7).trim());
            if (user.isPresent()) {
                request.setAttribute(ATTR_USER_ID, user.get().getId());
                chain.doFilter(new IdentityRequest(request, user.get().getId()), response);
                return;
            }
            request.setAttribute(ATTR_TOKEN_ERROR, Boolean.TRUE);
        }
        chain.doFilter(allowDemoHeader ? request : new IdentityRequest(request, null), response);
    }

    private Optional<UserEntity> authenticate(String token) {
        return jwt.verify(token)
                .flatMap(claims -> users.findById(claims.userId())
                        .filter(u -> !u.isDisabled())
                        .filter(u -> jwt.passwordVersion(u).equals(claims.passwordVersion())));
    }

    /** Remplace (ou supprime si {@code userId} est nul) les en-têtes d'identité. */
    static final class IdentityRequest extends HttpServletRequestWrapper {

        private final String userId;

        IdentityRequest(HttpServletRequest request, String userId) {
            super(request);
            this.userId = userId;
        }

        private static boolean isIdentity(String name) {
            return name != null && IDENTITY_HEADERS.contains(name.toLowerCase());
        }

        @Override
        public String getHeader(String name) {
            return isIdentity(name) ? userId : super.getHeader(name);
        }

        @Override
        public Enumeration<String> getHeaders(String name) {
            if (!isIdentity(name)) {
                return super.getHeaders(name);
            }
            return userId == null ? Collections.emptyEnumeration() : Collections.enumeration(Set.of(userId));
        }

        @Override
        public Enumeration<String> getHeaderNames() {
            Set<String> names = new LinkedHashSet<>();
            Enumeration<String> original = super.getHeaderNames();
            while (original != null && original.hasMoreElements()) {
                String name = original.nextElement();
                if (!isIdentity(name)) {
                    names.add(name);
                }
            }
            if (userId != null) {
                names.add("X-Demo-User-Id");
                names.add("X-User-Id");
            }
            return Collections.enumeration(names);
        }
    }
}
