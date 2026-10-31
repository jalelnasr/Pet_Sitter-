package com.petsitter.user.entity;

import com.petsitter.user.enums.UserRole;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Temporary synthetic user used only to exercise the Adoption workflow.
 *
 * <p>This entity will be replaced by the real User module later. Adoption
 * only depends on the id, firstName and role, so the future module can
 * extend this table without rewriting the adoption business rules.</p>
 */
@Entity
@Table(name = "users")
public class UserEntity {

    @Id
    @Column(name = "id", length = 64, nullable = false)
    private String id;

    @NotBlank
    @Column(name = "first_name", length = 80, nullable = false)
    private String firstName;

    @Email
    @NotBlank
    @Column(name = "email", length = 160, nullable = false, unique = true)
    private String email;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "role", length = 20, nullable = false)
    private UserRole role;

    protected UserEntity() {
        // Required by JPA.
    }

    public UserEntity(String id, String firstName, String email, UserRole role) {
        this.id = id;
        this.firstName = firstName;
        this.email = email;
        this.role = role;
    }

    public String getId() {
        return id;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getEmail() {
        return email;
    }

    public UserRole getRole() {
        return role;
    }
}
