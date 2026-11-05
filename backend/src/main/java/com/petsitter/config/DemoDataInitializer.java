package com.petsitter.config;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Inserts the synthetic demo users required to test the Adoption workflow.
 * The operation is idempotent: existing users are left untouched, so
 * restarting the backend never creates duplicates.
 */
@Configuration
public class DemoDataInitializer {

    private static final Logger log = LoggerFactory.getLogger(DemoDataInitializer.class);

    @Bean
    CommandLineRunner seedDemoUsers(UserRepository users) {
        return args -> {
            seed(users, new UserEntity(
                    "OWNER_DEMO", "Amira", "amira@petsitter.test", UserRole.OWNER));
            seed(users, new UserEntity(
                    "PETSITTER_DEMO", "Sami", "sami@petsitter.test", UserRole.PETSITTER));
            seed(users, new UserEntity(
                    "ADMIN_DEMO", "Admin", "admin@petsitter.test", UserRole.ADMIN));
        };
    }

    private void seed(UserRepository users, UserEntity user) {
        if (users.existsById(user.getId())) {
            return;
        }
        users.save(user);
        log.info("Demo user created: {} ({})", user.getId(), user.getRole());
    }
}
