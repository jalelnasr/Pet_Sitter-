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
import tn.lammapets.backend.auth.AuthDtos.RoleRequest;
import tn.lammapets.backend.auth.AuthDtos.UserResponse;
import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.user.Role;
import tn.lammapets.backend.user.User;
import tn.lammapets.backend.user.UserRepository;

/**
 * Connexion provisoire, pour tester la boutique : la gestion des utilisateurs appartient au module « User ».
 * La boutique ne dépend que du jeton (sujet = users.id, revendication role), voir backend/README.md.
 */
@Service
public class AuthService {

	private final UserRepository users;

	private final PasswordEncoder passwords;

	private final TokenService tokens;

	public AuthService(UserRepository users, PasswordEncoder passwords, TokenService tokens) {
		this.users = users;
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
		User user = users.save(new User(UUID.randomUUID().toString(), req.name().trim(), email,
				passwords.encode(req.password()), req.role()));
		return new AuthResponse(tokens.issue(user), UserResponse.of(user));
	}

	@Transactional(readOnly = true)
	public AuthResponse login(LoginRequest req) {
		User user = users.findByEmail(normalize(req.email()))
			.filter(u -> u.getPasswordHash() != null && passwords.matches(req.password(), u.getPasswordHash()))
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "E-mail ou mot de passe incorrect."));
		return new AuthResponse(tokens.issue(user), UserResponse.of(user));
	}

	@Transactional(readOnly = true)
	public UserResponse me(String id) {
		return users.findById(id)
			.map(UserResponse::of)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Compte introuvable."));
	}

	/** Propriétaire et pet sitter peuvent changer de profil ; un admin reste admin et personne ne le devient ainsi. */
	@Transactional
	public AuthResponse changeRole(String id, RoleRequest req) {
		User user = users.findById(id)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Compte introuvable."));
		if (req.role() == Role.ADMIN || user.getRole() == Role.ADMIN) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Ce changement de profil n'est pas possible.");
		}
		user.changeRole(req.role());
		return new AuthResponse(tokens.issue(user), UserResponse.of(user));
	}

	private static String normalize(String email) {
		return email.trim().toLowerCase(Locale.ROOT);
	}

}
