package tn.lammapets.backend.auth;

import java.util.Locale;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.lammapets.backend.auth.AuthDtos.AuthResponse;
import tn.lammapets.backend.auth.AuthDtos.LoginRequest;
import tn.lammapets.backend.auth.AuthDtos.RegisterRequest;
import tn.lammapets.backend.auth.AuthDtos.UserResponse;
import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.user.Role;
import tn.lammapets.backend.user.User;
import tn.lammapets.backend.user.UserCredential;
import tn.lammapets.backend.user.UserCredentialRepository;
import tn.lammapets.backend.user.UserRepository;

@Service
public class AuthService {

	private final UserRepository users;

	private final UserCredentialRepository credentials;

	private final PasswordEncoder passwords;

	private final TokenService tokens;

	public AuthService(UserRepository users, UserCredentialRepository credentials, PasswordEncoder passwords,
			TokenService tokens) {
		this.users = users;
		this.credentials = credentials;
		this.passwords = passwords;
		this.tokens = tokens;
	}

	@Transactional
	public AuthResponse register(RegisterRequest req) {
		if (req.role() == Role.ADMIN) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Ce profil ne peut pas être choisi à l'inscription.");
		}
		String email = normalize(req.email());
		if (users.existsByEmail(email)) {
			throw new ApiException(HttpStatus.CONFLICT,
					"Un compte existe déjà avec cette adresse. Connectez-vous ou réinitialisez votre mot de passe.");
		}
		User user = users.save(new User(UUID.randomUUID().toString(), req.name().trim(), email, req.role()));
		credentials.save(new UserCredential(user.getId(), passwords.encode(req.password())));
		return new AuthResponse(tokens.issue(user), UserResponse.of(user));
	}

	@Transactional(readOnly = true)
	public AuthResponse login(LoginRequest req) {
		User user = users.findByEmail(normalize(req.email()))
			.filter(u -> credentials.findById(u.getId())
				.filter(c -> passwords.matches(req.password(), c.getPasswordHash()))
				.isPresent())
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "E-mail ou mot de passe incorrect."));
		return new AuthResponse(tokens.issue(user), UserResponse.of(user));
	}

	@Transactional(readOnly = true)
	public UserResponse me(String id) {
		return users.findById(id)
			.map(UserResponse::of)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Compte introuvable."));
	}

	private static String normalize(String email) {
		return email.trim().toLowerCase(Locale.ROOT);
	}

}
