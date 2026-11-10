package com.petsitter.petsitter.security;

import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rôle d'un utilisateur du module Garde, lu sur son compte.
 *
 * <p>Avant, seuls les identifiants de démonstration « ADMIN_DEMO » et « admin » étaient
 * reconnus comme administrateurs : un vrai compte administrateur était refusé. Ces deux
 * identifiants restent acceptés pour les tests qui créent les comptes de démonstration.</p>
 */
@Component
public class PetSitterRoles {

    private final UserRepository users;

    public PetSitterRoles(UserRepository users) {
        this.users = users;
    }

    @Transactional(readOnly = true)
    public boolean isAdmin(String userId) {
        if (userId == null || userId.isBlank()) {
            return false;
        }
        String id = userId.trim();
        if ("ADMIN_DEMO".equalsIgnoreCase(id) || "admin".equalsIgnoreCase(id)) {
            return true;
        }
        return users.findById(id).map(u -> u.getRole() == UserRole.ADMIN).orElse(false);
    }
}
