package tn.lammapets.backend.user;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Table commune à toute l'équipe. */
@Entity
@Table(name = "users")
public class User {

	@Id
	private String id;

	private String email;

	@Column(name = "first_name")
	private String firstName;

	@Column(name = "password_hash")
	private String passwordHash;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private Role role;

	protected User() {
	}

	public User(String id, String firstName, String email, String passwordHash, Role role) {
		this.id = id;
		this.firstName = firstName;
		this.email = email;
		this.passwordHash = passwordHash;
		this.role = role;
	}

	public void setPasswordHash(String passwordHash) {
		this.passwordHash = passwordHash;
	}

	public void changeRole(Role role) {
		this.role = role;
	}

	public String getId() {
		return id;
	}

	public String getEmail() {
		return email;
	}

	public String getFirstName() {
		return firstName;
	}

	public String getPasswordHash() {
		return passwordHash;
	}

	public Role getRole() {
		return role;
	}

}
