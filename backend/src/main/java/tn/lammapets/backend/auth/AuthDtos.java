package tn.lammapets.backend.auth;

import tn.lammapets.backend.user.Role;
import tn.lammapets.backend.user.User;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class AuthDtos {

	private AuthDtos() {
	}

	public record RegisterRequest(
			@NotBlank(message = "Indiquez votre nom.") @Size(max = 80) String name,
			@NotBlank(message = "Indiquez votre adresse e-mail.") @Email(message = "Adresse e-mail invalide.") @Size(max = 160) String email,
			@NotBlank @Size(min = 8, max = 72, message = "Le mot de passe doit contenir de 8 à 72 caractères.") String password,
			@NotNull(message = "Choisissez un profil.") Role role) {
	}

	public record LoginRequest(@NotBlank String email, @NotBlank String password) {
	}

	public record RoleRequest(@NotNull(message = "Choisissez un profil.") Role role) {
	}

	public record UserResponse(String id, String name, String email, Role role) {
		public static UserResponse of(User u) {
			return new UserResponse(u.getId(), u.getFirstName(), u.getEmail(), u.getRole());
		}
	}

	public record AuthResponse(String token, UserResponse user) {
	}

}
