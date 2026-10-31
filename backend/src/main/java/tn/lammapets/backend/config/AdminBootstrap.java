package tn.lammapets.backend.config;

import java.util.Locale;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import tn.lammapets.backend.user.Role;
import tn.lammapets.backend.user.User;
import tn.lammapets.backend.user.UserRepository;

/**
 * L'inscription publique ne crée jamais d'admin : le compte vient de la configuration.
 * S'il existe déjà dans users, il reçoit seulement un mot de passe.
 */
@Configuration
public class AdminBootstrap {

	@Bean
	ApplicationRunner createAdmin(UserRepository users, PasswordEncoder passwords,
			@Value("${app.admin.email}") String email, @Value("${app.admin.password}") String password) {
		return args -> {
			if (email.isBlank() || password.isBlank()) {
				return;
			}
			String normalized = email.trim().toLowerCase(Locale.ROOT);
			User admin = users.findByEmail(normalized)
				.orElseGet(() -> users.save(new User(UUID.randomUUID().toString(), "Admin", normalized, null, Role.ADMIN)));
			if (admin.getRole() == Role.ADMIN && admin.getPasswordHash() == null) {
				admin.setPasswordHash(passwords.encode(password));
				users.save(admin);
			}
		};
	}

}
