package com.petsitter.user.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.user.dto.UpdateProfileRequest;
import com.petsitter.user.dto.UserResponse;
import com.petsitter.user.dto.UserSummaryResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import com.petsitter.common.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/** Profil, annuaire et modération des comptes. */
@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    /** Dossier public des photos de profil, servi sous /uploads/users/. */
    private static final String PHOTO_FOLDER = "users";

    private final UserRepository users;
    private final String uploadDir;

    public UserService(UserRepository users, @Value("${petsitter.upload.dir:uploads}") String uploadDir) {
        this.users = users;
        this.uploadDir = uploadDir;
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

    // ———— Photo de profil

    /** Enregistre la photo envoyée depuis la galerie et remplace l'ancienne. */
    @Transactional
    public UserResponse updatePhoto(UserEntity current, MultipartFile file) {
        UserEntity user = load(current.getId());
        String extension = imageExtension(file);
        try {
            Path dir = Paths.get(uploadDir, PHOTO_FOLDER).toAbsolutePath().normalize();
            Files.createDirectories(dir);
            String filename = UUID.randomUUID() + extension;
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, dir.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
            }
            deleteStoredPhoto(user.getPhotoUrl());
            user.setPhotoUrl("/uploads/" + PHOTO_FOLDER + "/" + filename);
            return UserResponse.from(user);
        } catch (IOException ex) {
            log.error("Photo de profil non enregistrée pour {}", user.getId(), ex);
            throw new BusinessException("IMAGE_STORAGE_ERROR", "Impossible d'enregistrer la photo. Réessayez.");
        }
    }

    /** Retire la photo : le profil affiche de nouveau les initiales. */
    @Transactional
    public UserResponse removePhoto(UserEntity current) {
        UserEntity user = load(current.getId());
        deleteStoredPhoto(user.getPhotoUrl());
        user.setPhotoUrl(null);
        return UserResponse.from(user);
    }

    /**
     * Format reconnu au contenu du fichier (et non à son nom) : JPEG, PNG ou WebP.
     */
    private static String imageExtension(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("EMPTY_FILE", "Choisissez une photo.");
        }
        byte[] head = new byte[12];
        int read;
        try (InputStream in = file.getInputStream()) {
            read = in.readNBytes(head, 0, head.length);
        } catch (IOException ex) {
            throw new BadRequestException("INVALID_IMAGE_TYPE", "Photo illisible. Choisissez une image JPEG, PNG ou WebP.");
        }
        if (read >= 3 && (head[0] & 0xFF) == 0xFF && (head[1] & 0xFF) == 0xD8 && (head[2] & 0xFF) == 0xFF) {
            return ".jpg";
        }
        if (read >= 4 && (head[0] & 0xFF) == 0x89 && head[1] == 'P' && head[2] == 'N' && head[3] == 'G') {
            return ".png";
        }
        if (read >= 12 && head[0] == 'R' && head[1] == 'I' && head[2] == 'F' && head[3] == 'F'
                && head[8] == 'W' && head[9] == 'E' && head[10] == 'B' && head[11] == 'P') {
            return ".webp";
        }
        throw new BadRequestException("INVALID_IMAGE_TYPE", "Format non pris en charge. Choisissez une image JPEG, PNG ou WebP.");
    }

    /** Supprime l'ancien fichier, seulement s'il a été enregistré par cette fonction. */
    private void deleteStoredPhoto(String photoUrl) {
        String prefix = "/uploads/" + PHOTO_FOLDER + "/";
        if (photoUrl == null || !photoUrl.startsWith(prefix)) {
            return;
        }
        String name = photoUrl.substring(prefix.length());
        if (name.isBlank() || name.contains("/") || name.contains("\\") || name.contains("..")) {
            return;
        }
        try {
            Files.deleteIfExists(Paths.get(uploadDir, PHOTO_FOLDER, name).toAbsolutePath().normalize());
        } catch (IOException ex) {
            log.warn("Ancienne photo non supprimée : {}", photoUrl, ex);
        }
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
