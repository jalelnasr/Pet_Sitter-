package tn.lammapets.backend.user;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Table commune à toute l'équipe : ne pas changer ses colonnes depuis ce module. */
@Entity
@Table(name = "users")
public class User {

	@Id
	private String id;

	private String email;

	@Column(name = "first_name")
	private String firstName;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private Role role;

	protected User() {
	}

	public User(String id, String firstName, String email, Role role) {
		this.id = id;
		this.firstName = firstName;
		this.email = email;
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

	public Role getRole() {
		return role;
	}

}
