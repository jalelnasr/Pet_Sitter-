package com.petsitter.adoption.service;

import com.petsitter.adoption.dto.listing.CreateListingRequest;
import com.petsitter.adoption.dto.listing.ListingResponse;
import com.petsitter.adoption.dto.listing.ListingSummaryResponse;
import com.petsitter.adoption.dto.listing.UpdateListingRequest;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.adoption.mapper.AdoptionMapper;
import com.petsitter.adoption.repository.AdoptionListingRepository;
import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class AdoptionListingService {

    private static final String DEFAULT_IMAGE =
            "https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=600&q=70&fm=jpg&fit=crop";

    private static final Logger log = LoggerFactory.getLogger(AdoptionListingService.class);

    private final AdoptionListingRepository listings;
    private final AdoptionMapper mapper;

    @Value("${petsitter.upload.dir:uploads}")
    private String uploadDir;

    public AdoptionListingService(AdoptionListingRepository listings, AdoptionMapper mapper) {
        this.listings = listings;
        this.mapper = mapper;
    }

    @Transactional
    public ListingResponse create(CreateListingRequest request, UserEntity publisher) {
        requirePublisherRole(publisher);

        AdoptionListing listing = new AdoptionListing(UUID.randomUUID().toString(), publisher);
        apply(listing, request);
        listing.setStatus(request.status() == ListingStatus.DRAFT
                ? ListingStatus.DRAFT
                : ListingStatus.PUBLISHED);
        listings.save(listing);
        return mapper.toResponse(listing);
    }

    @Transactional(readOnly = true)
    public Page<ListingSummaryResponse> publicList(
            PetSpecies species, String location, int page, int size, String requesterId) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.min(Math.max(size, 1), 50),
                Sort.by(Sort.Direction.DESC, "createdAt")
        );
        String normalizedLocation = location == null || location.isBlank() ? null : location.trim();
        return listings.searchPublic(ListingStatus.PUBLISHED, species, normalizedLocation, requesterId, pageable)
                .map(mapper::toSummary);
    }

    @Transactional(readOnly = true)
    public ListingResponse get(String id, UserEntity requester) {
        AdoptionListing listing = find(id);
        if ((listing.getStatus() == ListingStatus.HIDDEN
                || listing.getStatus() == ListingStatus.ARCHIVED)
                && !canModerate(listing, requester)) {
            throw new ResourceNotFoundException("Adoption listing not found: " + id);
        }
        return mapper.toResponse(listing);
    }

    @Transactional(readOnly = true)
    public List<ListingSummaryResponse> mine(UserEntity publisher) {
        return listings.findByPublisherIdOrderByCreatedAtDesc(publisher.getId())
                .stream().map(mapper::toSummary).toList();
    }

    @Transactional
    public ListingResponse update(String id, UpdateListingRequest request, UserEntity actor) {
        AdoptionListing listing = requireOwnership(id, actor);
        if (listing.getStatus() == ListingStatus.ADOPTED
                || listing.getStatus() == ListingStatus.ARCHIVED
                || listing.getStatus() == ListingStatus.HIDDEN) {
            throw new BusinessException(
                    "LISTING_NOT_EDITABLE",
                    "Adopted, archived or hidden listings cannot be edited.");
        }
        apply(listing, request);
        return mapper.toResponse(listing);
    }

    @Transactional
    public ListingResponse publish(String id, UserEntity actor) {
        AdoptionListing listing = requireOwnership(id, actor);
        if (listing.getStatus() != ListingStatus.DRAFT
                && listing.getStatus() != ListingStatus.PAUSED) {
            throw new BusinessException(
                    "INVALID_STATUS_TRANSITION",
                    "Only a draft or paused listing can be published.");
        }
        listing.setStatus(ListingStatus.PUBLISHED);
        return mapper.toResponse(listing);
    }

    @Transactional
    public ListingResponse pause(String id, UserEntity actor) {
        AdoptionListing listing = requireOwnership(id, actor);
        if (listing.getStatus() != ListingStatus.PUBLISHED) {
            throw new BusinessException(
                    "INVALID_STATUS_TRANSITION",
                    "Only a published listing can be paused.");
        }
        listing.setStatus(ListingStatus.PAUSED);
        return mapper.toResponse(listing);
    }

    @Transactional
    public ListingResponse archive(String id, UserEntity actor) {
        AdoptionListing listing = requireOwnership(id, actor);
        if (listing.getStatus() == ListingStatus.ARCHIVED) {
            throw new BusinessException(
                    "INVALID_STATUS_TRANSITION",
                    "This listing is already archived.");
        }
        listing.setStatus(ListingStatus.ARCHIVED);
        return mapper.toResponse(listing);
    }

    // â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€” ADMIN MODERATION

    @Transactional(readOnly = true)
    public List<ListingSummaryResponse> adminList(UserEntity admin) {
        requireAdmin(admin);
        return listings.findAllByOrderByCreatedAtDesc()
                .stream().map(mapper::toSummary).toList();
    }

    @Transactional
    public ListingResponse adminHide(String id, UserEntity admin) {
        requireAdmin(admin);
        AdoptionListing listing = find(id);
        if (listing.getStatus() == ListingStatus.ARCHIVED) {
            throw new BusinessException(
                    "INVALID_STATUS_TRANSITION",
                    "An archived listing cannot be hidden.");
        }
        listing.setStatus(ListingStatus.HIDDEN);
        return mapper.toResponse(listing);
    }

    @Transactional
    public ListingResponse adminArchive(String id, UserEntity admin) {
        requireAdmin(admin);
        AdoptionListing listing = find(id);
        listing.setStatus(ListingStatus.ARCHIVED);
        return mapper.toResponse(listing);
    }

    @Transactional
    public String storeImage(MultipartFile file, UserEntity actor) {
        requirePublisherRole(actor);
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("INVALID_IMAGE", "Image file is required.");
        }
        if (file.getSize() > 5L * 1024 * 1024) {
            throw new BadRequestException("IMAGE_TOO_LARGE", "Image must be 5 MB or smaller.");
        }
        String contentType = file.getContentType();
        if (contentType == null || contentType.isBlank()
                || "application/octet-stream".equalsIgnoreCase(contentType)) {
            String name = file.getOriginalFilename();
            if (name != null) {
                String lower = name.toLowerCase();
                if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
                    contentType = "image/jpeg";
                } else if (lower.endsWith(".png")) {
                    contentType = "image/png";
                } else if (lower.endsWith(".webp")) {
                    contentType = "image/webp";
                }
            }
        }
        String extension;
        if ("image/jpeg".equalsIgnoreCase(contentType)) {
            extension = ".jpg";
        } else if ("image/png".equalsIgnoreCase(contentType)) {
            extension = ".png";
        } else if ("image/webp".equalsIgnoreCase(contentType)) {
            extension = ".webp";
        } else {
            throw new BadRequestException("INVALID_IMAGE_TYPE", "Only JPEG, PNG or WebP images are allowed.");
        }
        try {
            Path dir = Paths.get(uploadDir, "adoption").toAbsolutePath().normalize();
            Files.createDirectories(dir);
            String filename = UUID.randomUUID().toString() + extension;
            Path target = dir.resolve(filename);
            file.transferTo(target.toFile());
            if (!Files.exists(target) || Files.size(target) == 0) {
                throw new BusinessException("IMAGE_STORAGE_ERROR", "Uploaded image is empty.");
            }
            log.info("Stored adoption image: {} ({} bytes)", target, Files.size(target));
            return "/uploads/adoption/" + filename;
        } catch (IOException ex) {
            throw new BusinessException("IMAGE_STORAGE_ERROR", "Could not store the image.");
        }
    }

    // â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€” HELPERS

    @Transactional(readOnly = true)
    public AdoptionListing find(String id) {
        return listings.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Adoption listing not found: " + id));
    }

    private AdoptionListing requireOwnership(String id, UserEntity actor) {
        AdoptionListing listing = find(id);
        if (!listing.getPublisher().getId().equals(actor.getId())) {
            throw new UnauthorizedActionException(
                    "Only the publisher can modify this adoption listing.");
        }
        return listing;
    }

    private void requirePublisherRole(UserEntity user) {
        if (user.getRole() != UserRole.OWNER && user.getRole() != UserRole.PETSITTER) {
            throw new UnauthorizedActionException(
                    "Only an owner or a pet sitter can publish an adoption listing.");
        }
    }

    private void requireAdmin(UserEntity user) {
        if (user.getRole() != UserRole.ADMIN) {
            throw new UnauthorizedActionException(
                    "This operation is reserved to administrators.");
        }
    }

    private boolean canModerate(AdoptionListing listing, UserEntity user) {
        if (user == null) {
            return false;
        }
        return user.getRole() == UserRole.ADMIN
                || listing.getPublisher().getId().equals(user.getId());
    }

    private void apply(AdoptionListing listing, CreateListingRequest request) {
        listing.setPetName(request.petName().trim());
        listing.setSpecies(request.species());
        listing.setBreed(trimToNull(request.breed()));
        listing.setAge(request.age());
        listing.setGender(request.gender());
        listing.setDescription(request.description().trim());
        listing.setHealthInformation(trimToNull(request.healthInformation()));
        listing.setVaccinated(request.vaccinated());
        listing.setSterilized(request.sterilized());
        listing.setLocation(request.location().trim());
        replaceImages(listing, request.imageUrls());
    }

    private void apply(AdoptionListing listing, UpdateListingRequest request) {
        listing.setPetName(request.petName().trim());
        listing.setSpecies(request.species());
        listing.setBreed(trimToNull(request.breed()));
        listing.setAge(request.age());
        listing.setGender(request.gender());
        listing.setDescription(request.description().trim());
        listing.setHealthInformation(trimToNull(request.healthInformation()));
        listing.setVaccinated(request.vaccinated());
        listing.setSterilized(request.sterilized());
        listing.setLocation(request.location().trim());
        replaceImages(listing, request.imageUrls());
    }

    private void replaceImages(AdoptionListing listing, List<String> urls) {
        listing.clearImages();
        if (urls == null) {
            return;
        }
        for (int i = 0; i < urls.size(); i++) {
            String url = urls.get(i);
            if (url != null && !url.trim().isEmpty()) {
                listing.addImage(url.trim(), i);
            }
        }
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
