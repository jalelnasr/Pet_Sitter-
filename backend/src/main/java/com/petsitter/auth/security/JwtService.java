package com.petsitter.auth.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petsitter.user.entity.UserEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Émet et vérifie les jetons de session (JWT signé HMAC-SHA256).
 *
 * <p>Le jeton contient l'identifiant de l'utilisateur ({@code sub}), son rôle et
 * une empreinte de son mot de passe ({@code pwv}) : changer ou réinitialiser le
 * mot de passe invalide donc toutes les sessions ouvertes.</p>
 */
@Service
public class JwtService {

    private static final Logger log = LoggerFactory.getLogger(JwtService.class);
    private static final String ISSUER = "petsitter";
    static final String DEV_SECRET = "dev-only-secret-change-me-with-JWT_SECRET-32b";

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();

    private final byte[] secret;
    private final Duration validity;
    private final ObjectMapper json;

    public JwtService(
            @Value("${petsitter.jwt.secret}") String secret,
            @Value("${petsitter.jwt.validity-hours:72}") long validityHours,
            ObjectMapper json) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("petsitter.jwt.secret (JWT_SECRET) doit contenir au moins 32 octets.");
        }
        if (DEV_SECRET.equals(secret)) {
            log.warn("JWT_SECRET non défini : clé de développement utilisée. À changer avant tout déploiement.");
        }
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.validity = Duration.ofHours(validityHours);
        this.json = json;
    }

    /** Jeton émis et sa date d'expiration. */
    public record IssuedToken(String value, Instant expiresAt) {
    }

    /** Contenu vérifié d'un jeton. */
    public record TokenClaims(String userId, String role, String passwordVersion, Instant expiresAt) {
    }

    public IssuedToken issue(UserEntity user) {
        Instant now = Instant.now();
        Instant exp = now.plus(validity);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("iss", ISSUER);
        payload.put("sub", user.getId());
        payload.put("role", user.getRole().name());
        payload.put("pwv", passwordVersion(user));
        payload.put("iat", now.getEpochSecond());
        payload.put("exp", exp.getEpochSecond());
        try {
            String header = B64.encodeToString(
                    "{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
            String body = B64.encodeToString(json.writeValueAsBytes(payload));
            String signingInput = header + "." + body;
            return new IssuedToken(signingInput + "." + B64.encodeToString(sign(signingInput)), exp);
        } catch (Exception e) {
            throw new IllegalStateException("Impossible d'émettre le jeton.", e);
        }
    }

    /** Vérifie la signature, l'émetteur et l'expiration. Vide si le jeton est refusé. */
    public Optional<TokenClaims> verify(String token) {
        if (token == null) {
            return Optional.empty();
        }
        String[] parts = token.trim().split("\\.");
        if (parts.length != 3) {
            return Optional.empty();
        }
        try {
            byte[] expected = sign(parts[0] + "." + parts[1]);
            if (!MessageDigest.isEqual(expected, B64D.decode(parts[2]))) {
                return Optional.empty();
            }
            Map<String, Object> claims = json.readValue(B64D.decode(parts[1]), new TypeReference<>() {
            });
            if (!ISSUER.equals(claims.get("iss")) || !(claims.get("exp") instanceof Number exp)) {
                return Optional.empty();
            }
            Instant expiresAt = Instant.ofEpochSecond(exp.longValue());
            if (!expiresAt.isAfter(Instant.now())) {
                return Optional.empty();
            }
            return Optional.of(new TokenClaims(
                    String.valueOf(claims.get("sub")),
                    String.valueOf(claims.get("role")),
                    String.valueOf(claims.get("pwv")),
                    expiresAt));
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    /** Empreinte courte du mot de passe : change à chaque nouveau mot de passe. */
    public String passwordVersion(UserEntity user) {
        String source = user.hasPassword() ? user.getPasswordHash() : "no-password:" + user.getId();
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(source.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest, 0, 8);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }

    private byte[] sign(String input) throws GeneralSecurityException {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret, "HmacSHA256"));
        return mac.doFinal(input.getBytes(StandardCharsets.UTF_8));
    }
}
