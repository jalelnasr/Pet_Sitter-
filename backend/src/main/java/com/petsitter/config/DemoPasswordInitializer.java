package com.petsitter.config;

import com.petsitter.auth.service.AuthService;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;

/**
 * Donne un mot de passe aux comptes de démonstration créés par les autres modules
 * (OWNER_DEMO, sami, samira…) pour qu'on puisse s'y connecter depuis l'application.
 *
 * <p>S'exécute une fois l'application prête, donc après tous les initialiseurs de données.
 * Seuls les comptes en {@code @petsitter.test} / {@code @petsitter.tn} sans mot de
 * passe sont concernés ; un mot de passe déjà choisi n'est jamais écrasé.
 * Désactivé si {@code DEMO_PASSWORD} est vide.</p>
 */
@Component
public class DemoPasswordInitializer {

    private static final Logger log = LoggerFactory.getLogger(DemoPasswordInitializer.class);

    private final UserRepository users;
    private final AuthService auth;
    private final TransactionTemplate tx;
    private final String demoPassword;

    public DemoPasswordInitializer(
            UserRepository users,
            AuthService auth,
            TransactionTemplate tx,
            @Value("${petsitter.auth.demo-password:}") String demoPassword) {
        this.users = users;
        this.auth = auth;
        this.tx = tx;
        this.demoPassword = demoPassword;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void seedDemoPasswords() {
        if (demoPassword == null || demoPassword.isBlank()) {
            return;
        }
        tx.executeWithoutResult(status -> {
            List<UserEntity> demo = users.findAll().stream()
                    .filter(u -> !u.hasPassword())
                    .filter(u -> u.getEmail().endsWith("@petsitter.test") || u.getEmail().endsWith("@petsitter.tn"))
                    .toList();
            demo.forEach(u -> u.setPasswordHash(auth.hash(demoPassword)));
            if (!demo.isEmpty()) {
                log.info("Mot de passe de démonstration attribué à {} compte(s).", demo.size());
            }
        });
    }
}
