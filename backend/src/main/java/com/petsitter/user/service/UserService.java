package com.petsitter.user.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.user.dto.UpdateProfileRequest;
import com.petsitter.user.dto.UserResponse;
import com.petsitter.user.dto.UserSummaryResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Profil, annuaire et modération des comptes. */
@Service
public class UserService {

    private final UserRepository users;

    public UserService(UserRepository users) {
        this.users = users;
    }

    @Transactional(readOnly = true)
    public UserResponse me(UserEntity current) {
        return UserResponse.from(load(current.getId()));
    }

    @Transactional
    public UserResponse updateProfile(UserEntity current, UpdateProfileRequest req) {
        UserEntity user = load(current.getId());
        user.setFirstName(req.firstName().trim());
        user.setLastName(blankToNull(req.lastName()));
        user.setPhone(blankToNull(req.phone()));
        user.setCity(blankToNull(req.city()));
        user.setPhotoUrl(blankToNull(req.photoUrl()));
        user.setBio(blankToNull(req.bio()));
        return UserResponse.from(user);
    }

    /** Annuaire pour démarrer une conversation : comptes actifs, sans l'utilisateur courant. */
    @Transactional(readOnly = true)
    public Page<UserSummaryResponse> directory(UserEntity current, String q, UserRole role, int page, int size) {
        return users.directory(blankToNull(q), role, current.getId(),
                        PageRequest.of(Math.max(page, 0), clamp(size)))
                .map(UserSummaryResponse::from);
    }

    @Transactional(readOnly = true)
    public UserSummaryResponse publicProfile(String id) {
        UserEntity user = load(id);
        if (user.isDisabled()) {
            throw new ResourceNotFoundException("Utilisateur introuvable.");
        }
        return UserSummaryResponse.from(user);
    }

    // ———— Administration

    @Transactional(readOnly = true)
    public Page<UserResponse> adminList(String q, UserRole role, int page, int size) {
        return users.search(blankToNull(q), role, PageRequest.of(Math.max(page, 0), clamp(size)))
                .map(UserResponse::from);
    }

    @Transactional
    public UserResponse setDisabled(UserEntity admin, String id, boolean disabled) {
        if (admin.getId().equals(id)) {
            throw new BadRequestException("SELF_MODERATION", "Vous ne pouvez pas suspendre votre propre compte.");
        }
        UserEntity user = load(id);
        user.setDisabled(disabled);
        return UserResponse.from(user);
    }

    private UserEntity load(String id) {
        return users.findById(id).orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
    }

    private static int clamp(int size) {
        return Math.min(Math.max(size, 1), 50);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
