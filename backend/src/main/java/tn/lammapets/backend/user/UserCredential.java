package tn.lammapets.backend.user;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Mot de passe d'un compte, à part car la table users commune n'en a pas. */
@Entity
@Table(name = "user_credentials")
public class UserCredential {

	@Id
	@Column(name = "user_id")
	private String userId;

	@Column(name = "password_hash")
	private String passwordHash;

	@Column(name = "created_at")
	private Instant createdAt;

	protected UserCredential() {
	}

	public UserCredential(String userId, String passwordHash) {
		this.userId = userId;
		this.passwordHash = passwordHash;
		this.createdAt = Instant.now();
	}

	public String getPasswordHash() {
		return passwordHash;
	}

}
