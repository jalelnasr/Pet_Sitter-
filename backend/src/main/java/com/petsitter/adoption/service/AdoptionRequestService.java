package com.petsitter.adoption.service;

import com.petsitter.adoption.dto.request.AdoptionRequestResponse;
import com.petsitter.adoption.dto.request.CreateAdoptionRequest;
import com.petsitter.adoption.dto.request.ProcessAdoptionRequest;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.entity.AdoptionRequest;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.RequestStatus;
import com.petsitter.adoption.mapper.AdoptionMapper;
import com.petsitter.adoption.repository.AdoptionListingRepository;
import com.petsitter.adoption.repository.AdoptionRequestRepository;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Adoption request workflow.
 *
 * <p>Every authorization and business rule is enforced here, independently of
 * the buttons hidden or shown by the Flutter client.</p>
 */
@Service
public class AdoptionRequestService {

    private final AdoptionRequestRepository requests;
    private final AdoptionListingRepository listings;
    private final AdoptionMapper mapper;
    private final AdoptionMatchingService matching;

    public AdoptionRequestService(
            AdoptionRequestRepository requests,
            AdoptionListingRepository listings,
            AdoptionMapper mapper,
            AdoptionMatchingService matching) {
        this.requests = requests;
        this.listings = listings;
        this.mapper = mapper;
        this.matching = matching;
    }

    @Transactional
    public AdoptionRequestResponse create(CreateAdoptionRequest body, UserEntity applicant) {
        requireApplicantRole(applicant);

        AdoptionListing listing = listings.findById(body.listingId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Adoption listing not found: " + body.listingId()));

        if (listing.getPublisher().getId().equals(applicant.getId())) {
            throw new BusinessException(
                    "OWN_LISTING_NOT_ALLOWED",
                    "You cannot request the adoption of your own listing.");
        }
        if (listing.getStatus() != ListingStatus.PUBLISHED) {
            throw new BusinessException(
                    "LISTING_NOT_AVAILABLE",
                    "This listing is not open for adoption requests.");
        }
        boolean duplicate = requests.existsByListingIdAndApplicantIdAndStatus(
                listing.getId(), applicant.getId(), RequestStatus.PENDING);
        if (duplicate) {
            throw new BusinessException(
                    "ACTIVE_REQUEST_ALREADY_EXISTS",
                    "You already have a pending adoption request for this listing.");
        }

        AdoptionRequest request = new AdoptionRequest(
                UUID.randomUUID().toString(), listing, applicant);
        request.setFullName(body.fullName().trim());
        request.setPhone(body.phone().trim());
        request.setAddress(body.address().trim());
        request.setMessage(body.message().trim());
        request.setHousingType(body.housingType());
        request.setHasGarden(body.hasGarden());
        request.setHasOtherPets(body.hasOtherPets());
        request.setOtherPetsDetails(trimToNull(body.otherPetsDetails()));
        request.setExperience(trimToNull(body.experience()));
        // Client-supplied aiScore is ignored; the local matcher recomputes it.
        request.setAiScore(matching.scoreForCreate(listing, body).orElse(null));
        request.setStatus(RequestStatus.PENDING);

        requests.save(request);
        return mapper.toResponse(request);
    }

    @Transactional(readOnly = true)
    public List<AdoptionRequestResponse> sent(UserEntity applicant) {
        return requests.findByApplicantIdOrderByCreatedAtDesc(applicant.getId())
                .stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<AdoptionRequestResponse> received(UserEntity publisher) {
        return requests.findByListingPublisherIdOrderByCreatedAtDesc(publisher.getId())
                .stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public AdoptionRequestResponse get(String id, UserEntity viewer) {
        AdoptionRequest request = find(id);
        boolean applicant = request.getApplicant().getId().equals(viewer.getId());
        boolean publisher = request.getListing().getPublisher().getId().equals(viewer.getId());
        boolean admin = viewer.getRole() == UserRole.ADMIN;
        if (!applicant && !publisher && !admin) {
            throw new UnauthorizedActionException(
                    "You are not allowed to view this adoption request.");
        }
        return mapper.toResponse(request);
    }

    @Transactional
    public AdoptionRequestResponse accept(
            String id, ProcessAdoptionRequest body, UserEntity actor) {
        AdoptionRequest request = requirePublisherRequest(id, actor);
        requirePending(request);

        Instant now = Instant.now();
        request.setStatus(RequestStatus.ACCEPTED);
        request.setProcessedAt(now);
        request.setResponseMessage(responseMessage(body));

        AdoptionListing listing = request.getListing();
        listing.setStatus(ListingStatus.ADOPTED);

        // Every other pending request for the same listing is rejected.
        List<AdoptionRequest> otherPending = requests.findByListingIdAndStatusAndIdNot(
                listing.getId(), RequestStatus.PENDING, request.getId());
        for (AdoptionRequest other : otherPending) {
            other.setStatus(RequestStatus.REJECTED);
            other.setProcessedAt(now);
            other.setResponseMessage(
                    "Another adoption request was accepted for this listing.");
        }
        requests.saveAll(otherPending);

        return mapper.toResponse(request);
    }

    @Transactional
    public AdoptionRequestResponse reject(
            String id, ProcessAdoptionRequest body, UserEntity actor) {
        AdoptionRequest request = requirePublisherRequest(id, actor);
        requirePending(request);
        request.setStatus(RequestStatus.REJECTED);
        request.setProcessedAt(Instant.now());
        request.setResponseMessage(responseMessage(body));
        return mapper.toResponse(request);
    }

    @Transactional
    public AdoptionRequestResponse cancel(
            String id, ProcessAdoptionRequest body, UserEntity actor) {
        AdoptionRequest request = find(id);
        if (!request.getApplicant().getId().equals(actor.getId())) {
            throw new UnauthorizedActionException(
                    "Only the applicant can cancel this adoption request.");
        }
        requirePending(request);
        request.setStatus(RequestStatus.CANCELLED);
        request.setProcessedAt(Instant.now());
        request.setResponseMessage(responseMessage(body));
        return mapper.toResponse(request);
    }

    // ————————————————————————————————————————————— HELPERS

    private AdoptionRequest find(String id) {
        return requests.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Adoption request not found: " + id));
    }

    private AdoptionRequest requirePublisherRequest(String id, UserEntity actor) {
        AdoptionRequest request = find(id);
        if (!request.getListing().getPublisher().getId().equals(actor.getId())) {
            throw new UnauthorizedActionException(
                    "Only the listing publisher can process this adoption request.");
        }
        return request;
    }

    private void requirePending(AdoptionRequest request) {
        if (request.getStatus() != RequestStatus.PENDING) {
            throw new BusinessException(
                    "REQUEST_NOT_PENDING",
                    "Only a pending adoption request can be processed.");
        }
    }

    private void requireApplicantRole(UserEntity user) {
        if (user.getRole() != UserRole.OWNER && user.getRole() != UserRole.PETSITTER) {
            throw new UnauthorizedActionException(
                    "Only an owner or a pet sitter can send an adoption request.");
        }
    }

    private String responseMessage(ProcessAdoptionRequest body) {
        return body == null ? null : trimToNull(body.responseMessage());
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
