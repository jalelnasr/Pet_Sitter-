package com.petsitter.petsitter.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.petsitter.dto.CreateSitterRequest;
import com.petsitter.petsitter.dto.PetSitterStatsResponse;
import com.petsitter.petsitter.dto.SitterResponse;
import com.petsitter.petsitter.dto.SitterSummaryResponse;
import com.petsitter.petsitter.dto.UpdateSitterRequest;
import com.petsitter.petsitter.entity.PetSitterProfile;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.enums.SitterServiceType;
import com.petsitter.petsitter.mapper.PetSitterMapper;
import com.petsitter.petsitter.repository.PetSitterProfileRepository;
import com.petsitter.petsitter.repository.PetSitterReservationRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class PetSitterService {

    private final PetSitterProfileRepository profileRepository;
    private final PetSitterReservationRepository reservationRepository;
    private final PetSitterMapper mapper;

    @Value("${petsitter.upload.dir:uploads}")
    private String uploadDir;

    public PetSitterService(
            PetSitterProfileRepository profileRepository,
            PetSitterReservationRepository reservationRepository,
            PetSitterMapper mapper) {
        this.profileRepository = profileRepository;
        this.reservationRepository = reservationRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public Page<SitterSummaryResponse> list(
            String search,
            String governorate,
            SitterServiceType service,
            PetSpeciesType petType,
            Double minPrice,
            Double maxPrice,
            Double minRating,
            Boolean verifiedOnly,
            LocalDate availableDate,
            String sortBy,
            int page,
            int size,
            boolean includeInactive
    ) {
        Sort sort = switch (sortBy != null ? sortBy.toLowerCase() : "") {
            case "price_asc" -> Sort.by(Sort.Direction.ASC, "pricePerDay");
            case "price_desc" -> Sort.by(Sort.Direction.DESC, "pricePerDay");
            case "newest" -> Sort.by(Sort.Direction.DESC, "createdAt");
            default -> Sort.by(Sort.Direction.DESC, "averageRating").and(Sort.by(Sort.Direction.DESC, "reviewsCount"));
        };

        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size), sort);

        Specification<PetSitterProfile> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (!includeInactive) {
                predicates.add(cb.isTrue(root.get("active")));
            }

            if (search != null && !search.isBlank()) {
                String term = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("fullName")), term),
                        cb.like(cb.lower(root.get("city")), term),
                        cb.like(cb.lower(root.get("governorate")), term),
                        cb.like(cb.lower(root.get("bio")), term)
                ));
            }

            if (governorate != null && !governorate.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("governorate")), governorate.trim().toLowerCase()));
            }

            if (minPrice != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("pricePerDay"), minPrice));
            }

            if (maxPrice != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("pricePerDay"), maxPrice));
            }

            if (minRating != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("averageRating"), minRating));
            }

            if (Boolean.TRUE.equals(verifiedOnly)) {
                predicates.add(cb.isTrue(root.get("verified")));
            }

            if (service != null) {
                predicates.add(cb.isMember(service, root.get("services")));
            }

            if (petType != null) {
                predicates.add(cb.isMember(petType, root.get("acceptedPetTypes")));
            }

            query.distinct(true);
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<PetSitterProfile> resultPage = profileRepository.findAll(spec, pageable);
        return resultPage.map(mapper::toSummaryResponse);
    }

    @Transactional(readOnly = true)
    public SitterResponse getById(String id) {
        PetSitterProfile profile = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));
        return mapper.toResponse(profile);
    }

    @Transactional(readOnly = true)
    public SitterResponse getByUserId(String userId) {
        PetSitterProfile profile = profileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Profil pet sitter introuvable pour l'utilisateur: " + userId));
        return mapper.toResponse(profile);
    }

    @Transactional
    public SitterResponse createProfile(CreateSitterRequest req, String userId) {
        if (profileRepository.existsByUserId(userId)) {
            throw new BadRequestException("PROFILE_EXISTS", "Un profil pet sitter existe déjà pour cet utilisateur.");
        }

        PetSitterProfile p = new PetSitterProfile();
        p.setUserId(userId);
        p.setFullName(req.getFullName());
        p.setBio(req.getBio());
        p.setGovernorate(req.getGovernorate());
        p.setCity(req.getCity());
        p.setAddress(req.getAddress());
        p.setPhone(req.getPhone());
        p.setPhotoUrl(req.getPhotoUrl());
        p.setGallery(req.getGallery());
        p.setExperienceYears(req.getExperienceYears());
        p.setPricePerHour(req.getPricePerHour());
        p.setPricePerDay(req.getPricePerDay());
        p.setServices(req.getServices());
        p.setAcceptedPetTypes(req.getAcceptedPetTypes());
        p.setAcceptedSizes(req.getAcceptedSizes());
        p.setHasGarden(req.isHasGarden());
        p.setHasOwnPets(req.isHasOwnPets());
        p.setAvailability(req.getAvailability());
        p.setActive(true);
        p.setVerified(false);

        PetSitterProfile saved = profileRepository.save(p);
        return mapper.toResponse(saved);
    }

    @Transactional
    public SitterResponse updateProfile(String id, UpdateSitterRequest req, String userId, boolean isAdmin) {
        PetSitterProfile p = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));

        if (!isAdmin && !p.getUserId().equalsIgnoreCase(userId)) {
            throw new BadRequestException("FORBIDDEN", "Vous n'êtes pas autorisé à modifier ce profil.");
        }

        if (req.getFullName() != null && !req.getFullName().isBlank()) p.setFullName(req.getFullName().trim());
        if (req.getBio() != null) p.setBio(req.getBio().trim());
        if (req.getGovernorate() != null && !req.getGovernorate().isBlank()) p.setGovernorate(req.getGovernorate().trim());
        if (req.getCity() != null && !req.getCity().isBlank()) p.setCity(req.getCity().trim());
        if (req.getAddress() != null) p.setAddress(req.getAddress().trim());
        if (req.getPhone() != null) p.setPhone(req.getPhone().trim());
        if (req.getPhotoUrl() != null) p.setPhotoUrl(req.getPhotoUrl().trim());
        if (req.getGallery() != null) p.setGallery(req.getGallery());
        if (req.getExperienceYears() != null) p.setExperienceYears(req.getExperienceYears());
        if (req.getPricePerHour() != null) p.setPricePerHour(req.getPricePerHour());
        if (req.getPricePerDay() != null) p.setPricePerDay(req.getPricePerDay());
        if (req.getServices() != null) p.setServices(req.getServices());
        if (req.getAcceptedPetTypes() != null) p.setAcceptedPetTypes(req.getAcceptedPetTypes());
        if (req.getAcceptedSizes() != null) p.setAcceptedSizes(req.getAcceptedSizes());
        if (req.getHasGarden() != null) p.setHasGarden(req.getHasGarden());
        if (req.getHasOwnPets() != null) p.setHasOwnPets(req.getHasOwnPets());
        if (req.getAvailability() != null) p.setAvailability(req.getAvailability());
        if (req.getActive() != null) p.setActive(req.getActive());

        PetSitterProfile updated = profileRepository.save(p);
        return mapper.toResponse(updated);
    }

    @Transactional
    public SitterResponse toggleVisibility(String id, String userId) {
        PetSitterProfile p = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));

        if (!p.getUserId().equalsIgnoreCase(userId)) {
            throw new BadRequestException("FORBIDDEN", "Vous n'êtes pas autorisé à modifier ce profil.");
        }

        p.setActive(!p.isActive());
        PetSitterProfile updated = profileRepository.save(p);
        return mapper.toResponse(updated);
    }

    @Transactional
    public SitterResponse setVerification(String id, boolean verified) {
        PetSitterProfile p = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));
        p.setVerified(verified);
        return mapper.toResponse(profileRepository.save(p));
    }

    @Transactional
    public SitterResponse setActiveStatus(String id, boolean active) {
        PetSitterProfile p = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));
        p.setActive(active);
        return mapper.toResponse(profileRepository.save(p));
    }

    @Transactional
    public void deleteProfile(String id, String userId, boolean isAdmin) {
        PetSitterProfile p = profileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter non trouvé avec l'id: " + id));

        if (!isAdmin && !p.getUserId().equalsIgnoreCase(userId)) {
            throw new BadRequestException("FORBIDDEN", "Vous n'êtes pas autorisé à supprimer ce profil.");
        }

        profileRepository.delete(p);
    }

    public String storeImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("INVALID_IMAGE", "Le fichier image est obligatoire.");
        }
        if (file.getSize() > 5L * 1024 * 1024) {
            throw new BadRequestException("IMAGE_TOO_LARGE", "L'image ne doit pas dépasser 5 Mo.");
        }

        String original = file.getOriginalFilename();
        String ext = ".jpg";
        if (original != null && original.contains(".")) {
            ext = original.substring(original.lastIndexOf(".")).toLowerCase();
        }

        String filename = "sitter_" + UUID.randomUUID() + ext;
        Path targetDir = Paths.get(uploadDir).toAbsolutePath().normalize();

        try {
            Files.createDirectories(targetDir);
            Path targetFile = targetDir.resolve(filename);
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
            return "/uploads/" + filename;
        } catch (IOException e) {
            throw new BadRequestException("UPLOAD_FAILED", "Échec de l'enregistrement de l'image.");
        }
    }

    @Transactional(readOnly = true)
    public PetSitterStatsResponse getStats() {
        long totalSitters = profileRepository.count();
        long activeSitters = profileRepository.count((root, query, cb) -> cb.isTrue(root.get("active")));
        long verifiedSitters = profileRepository.count((root, query, cb) -> cb.isTrue(root.get("verified")));
        long totalReservations = reservationRepository.count();

        Map<String, Long> byStatus = new HashMap<>();
        for (ReservationStatus status : ReservationStatus.values()) {
            long count = reservationRepository.findAll().stream().filter(r -> r.getStatus() == status).count();
            byStatus.put(status.name(), count);
        }

        return new PetSitterStatsResponse(totalSitters, activeSitters, verifiedSitters, totalReservations, byStatus);
    }
}
