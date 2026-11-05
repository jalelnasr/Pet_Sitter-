package com.petsitter.adoption;

import com.petsitter.adoption.dto.listing.CreateListingRequest;
import com.petsitter.adoption.dto.listing.ListingResponse;
import com.petsitter.adoption.dto.request.AdoptionRequestResponse;
import com.petsitter.adoption.dto.request.CreateAdoptionRequest;
import com.petsitter.adoption.dto.request.ProcessAdoptionRequest;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.entity.AdoptionRequest;
import com.petsitter.adoption.enums.HousingType;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.adoption.enums.RequestStatus;
import com.petsitter.adoption.mapper.AdoptionMapper;
import com.petsitter.adoption.repository.AdoptionListingRepository;
import com.petsitter.adoption.repository.AdoptionRequestRepository;
import com.petsitter.adoption.service.AdoptionListingService;
import com.petsitter.adoption.service.AdoptionMatchingService;
import com.petsitter.adoption.service.AdoptionRequestService;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the adoption business rules. Repositories are mocked so the
 * suite runs without MySQL or XAMPP.
 */
@ExtendWith(MockitoExtension.class)
class AdoptionServiceTest {

    @Mock
    private AdoptionListingRepository listings;

    @Mock
    private AdoptionRequestRepository requests;

    @Mock
    private AdoptionMatchingService matching;

    private AdoptionListingService listingService;
    private AdoptionRequestService requestService;

    private final UserEntity owner = new UserEntity(
            "OWNER_DEMO", "Amira", "amira@petsitter.test", UserRole.OWNER);
    private final UserEntity sitter = new UserEntity(
            "PETSITTER_DEMO", "Sami", "sami@petsitter.test", UserRole.PETSITTER);
    private final UserEntity admin = new UserEntity(
            "ADMIN_DEMO", "Admin", "admin@petsitter.test", UserRole.ADMIN);

    @BeforeEach
    void setUp() {
        AdoptionMapper mapper = new AdoptionMapper();
        listingService = new AdoptionListingService(listings, mapper);
        requestService = new AdoptionRequestService(requests, listings, mapper, matching);
        lenient().when(matching.scoreForCreate(any(AdoptionListing.class), any(CreateAdoptionRequest.class)))
                .thenReturn(Optional.empty());
    }

    // ————————————————————————————————————————————— LISTINGS

    @Test
    @DisplayName("1. OWNER_DEMO can create a listing")
    void ownerCanCreateListing() {
        when(listings.save(any(AdoptionListing.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ListingResponse response = listingService.create(createListing("Milo"), owner);

        assertThat(response.publisher().id()).isEqualTo("OWNER_DEMO");
        assertThat(response.status()).isEqualTo(ListingStatus.PUBLISHED);
        assertThat(response.petName()).isEqualTo("Milo");
        verify(listings).save(any(AdoptionListing.class));
    }

    @Test
    @DisplayName("2. PETSITTER_DEMO can create a listing")
    void petSitterCanCreateListing() {
        when(listings.save(any(AdoptionListing.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ListingResponse response = listingService.create(createListing("Nala"), sitter);

        assertThat(response.publisher().id()).isEqualTo("PETSITTER_DEMO");
        assertThat(response.publisher().role()).isEqualTo(UserRole.PETSITTER);
    }

    @Test
    @DisplayName("7. A non-publisher cannot edit another user's listing")
    void nonPublisherCannotEdit() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        assertThatThrownBy(() -> listingService.update(
                "LISTING_1", updateListing("Milo"), sitter))
                .isInstanceOf(UnauthorizedActionException.class);
    }

    @Test
    @DisplayName("8. A non-publisher cannot pause another user's listing")
    void nonPublisherCannotPause() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        assertThatThrownBy(() -> listingService.pause("LISTING_1", sitter))
                .isInstanceOf(UnauthorizedActionException.class);
        assertThat(listing.getStatus()).isEqualTo(ListingStatus.PUBLISHED);
    }

    @Test
    @DisplayName("9. A non-publisher cannot archive another user's listing")
    void nonPublisherCannotArchive() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        assertThatThrownBy(() -> listingService.archive("LISTING_1", sitter))
                .isInstanceOf(UnauthorizedActionException.class);
        assertThat(listing.getStatus()).isEqualTo(ListingStatus.PUBLISHED);
    }

    @Test
    @DisplayName("The publisher can publish a draft and pause a published listing")
    void publisherCanChangeStatus() {
        AdoptionListing draft = publishedListing(owner);
        draft.setStatus(ListingStatus.DRAFT);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(draft));

        listingService.publish("LISTING_1", owner);
        assertThat(draft.getStatus()).isEqualTo(ListingStatus.PUBLISHED);

        listingService.pause("LISTING_1", owner);
        assertThat(draft.getStatus()).isEqualTo(ListingStatus.PAUSED);
    }

    @Test
    @DisplayName("17. ADMIN can hide a listing")
    void adminCanHideListing() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        ListingResponse response = listingService.adminHide("LISTING_1", admin);

        assertThat(response.status()).isEqualTo(ListingStatus.HIDDEN);
    }

    @Test
    @DisplayName("18. OWNER cannot use Admin moderation")
    void ownerCannotUseAdminModeration() {
        assertThatThrownBy(() -> listingService.adminHide("LISTING_1", owner))
                .isInstanceOf(UnauthorizedActionException.class);
        verify(listings, never()).findById(any());
    }

    @Test
    @DisplayName("19. PETSITTER cannot use Admin moderation")
    void petSitterCannotUseAdminModeration() {
        assertThatThrownBy(() -> listingService.adminList(sitter))
                .isInstanceOf(UnauthorizedActionException.class);
    }

    // ————————————————————————————————————————————— REQUESTS

    @Test
    @DisplayName("3. PETSITTER_DEMO can request OWNER_DEMO's listing")
    void petSitterCanRequestOwnerListing() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));
        when(requests.existsByListingIdAndApplicantIdAndStatus(
                "LISTING_1", "PETSITTER_DEMO", RequestStatus.PENDING))
                .thenReturn(false);
        when(requests.save(any(AdoptionRequest.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(matching.scoreForCreate(any(AdoptionListing.class), any(CreateAdoptionRequest.class)))
                .thenReturn(java.util.Optional.of(72));

        AdoptionRequestResponse response = requestService.create(
                createRequest("LISTING_1"), sitter);

        assertThat(response.status()).isEqualTo(RequestStatus.PENDING);
        assertThat(response.applicant().id()).isEqualTo("PETSITTER_DEMO");
        assertThat(response.listing().id()).isEqualTo("LISTING_1");
        assertThat(response.aiScore()).isEqualTo(72);
        assertThat(response.aiScore()).isNotEqualTo(85);
    }

    @Test
    @DisplayName("Create request keeps working with null aiScore when AI is down")
    void createRequestWithoutAiStillWorks() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));
        when(requests.existsByListingIdAndApplicantIdAndStatus(
                "LISTING_1", "PETSITTER_DEMO", RequestStatus.PENDING))
                .thenReturn(false);
        when(requests.save(any(AdoptionRequest.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(matching.scoreForCreate(any(AdoptionListing.class), any(CreateAdoptionRequest.class)))
                .thenReturn(java.util.Optional.empty());

        AdoptionRequestResponse response = requestService.create(
                createRequest("LISTING_1"), sitter);

        assertThat(response.status()).isEqualTo(RequestStatus.PENDING);
        assertThat(response.aiScore()).isNull();
    }

    @Test
    @DisplayName("4. A publisher cannot request their own listing")
    void publisherCannotRequestOwnListing() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        assertThatThrownBy(() -> requestService.create(createRequest("LISTING_1"), owner))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("own listing");
        verify(requests, never()).save(any());
    }

    @Test
    @DisplayName("5. ADMIN_DEMO cannot send an adoption request")
    void adminCannotSendRequest() {
        assertThatThrownBy(() -> requestService.create(createRequest("LISTING_1"), admin))
                .isInstanceOf(UnauthorizedActionException.class);
        verify(requests, never()).save(any());
    }

    @Test
    @DisplayName("6. Duplicate active requests are rejected")
    void duplicateActiveRequestRejected() {
        AdoptionListing listing = publishedListing(owner);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));
        when(requests.existsByListingIdAndApplicantIdAndStatus(
                "LISTING_1", "PETSITTER_DEMO", RequestStatus.PENDING))
                .thenReturn(true);

        assertThatThrownBy(() -> requestService.create(createRequest("LISTING_1"), sitter))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("pending adoption request");
        verify(requests, never()).save(any());
    }

    @Test
    @DisplayName("Requests are refused when the listing is not PUBLISHED")
    void requestRequiresPublishedListing() {
        AdoptionListing listing = publishedListing(owner);
        listing.setStatus(ListingStatus.PAUSED);
        when(listings.findById("LISTING_1")).thenReturn(Optional.of(listing));

        assertThatThrownBy(() -> requestService.create(createRequest("LISTING_1"), sitter))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("not open for adoption");
    }

    @Test
    @DisplayName("10. A non-publisher cannot accept a request")
    void nonPublisherCannotAccept() {
        AdoptionRequest request = pendingRequest(owner, sitter);
        when(requests.findById("REQUEST_1")).thenReturn(Optional.of(request));

        assertThatThrownBy(() -> requestService.accept(
                "REQUEST_1", new ProcessAdoptionRequest("ok"), sitter))
                .isInstanceOf(UnauthorizedActionException.class);
    }

    @Test
    @DisplayName("11-14. Accepting a request updates request, listing and other pending requests")
    void publisherAcceptanceIsTransactional() {
        AdoptionListing listing = publishedListing(owner);
        AdoptionRequest accepted = pendingRequest(listing, sitter, "REQUEST_1");
        AdoptionRequest other = pendingRequest(listing, admin, "REQUEST_2");

        when(requests.findById("REQUEST_1")).thenReturn(Optional.of(accepted));
        when(requests.findByListingIdAndStatusAndIdNot(
                "LISTING_1", RequestStatus.PENDING, "REQUEST_1"))
                .thenReturn(List.of(other));

        AdoptionRequestResponse response = requestService.accept(
                "REQUEST_1", new ProcessAdoptionRequest("Accepted"), owner);

        assertThat(response.status()).isEqualTo(RequestStatus.ACCEPTED);
        assertThat(accepted.getStatus()).isEqualTo(RequestStatus.ACCEPTED);
        assertThat(accepted.getProcessedAt()).isNotNull();
        assertThat(listing.getStatus()).isEqualTo(ListingStatus.ADOPTED);
        assertThat(other.getStatus()).isEqualTo(RequestStatus.REJECTED);
        assertThat(other.getProcessedAt()).isNotNull();
        verify(requests).saveAll(List.of(other));
    }

    @Test
    @DisplayName("15. The applicant can cancel their own pending request")
    void applicantCanCancel() {
        AdoptionRequest request = pendingRequest(owner, sitter);
        when(requests.findById("REQUEST_1")).thenReturn(Optional.of(request));

        AdoptionRequestResponse response = requestService.cancel(
                "REQUEST_1", new ProcessAdoptionRequest("Changed my mind"), sitter);

        assertThat(response.status()).isEqualTo(RequestStatus.CANCELLED);
        assertThat(request.getProcessedAt()).isNotNull();
    }

    @Test
    @DisplayName("16. Another user cannot cancel the applicant's request")
    void otherUserCannotCancel() {
        AdoptionRequest request = pendingRequest(owner, sitter);
        when(requests.findById("REQUEST_1")).thenReturn(Optional.of(request));

        assertThatThrownBy(() -> requestService.cancel(
                "REQUEST_1", new ProcessAdoptionRequest(null), admin))
                .isInstanceOf(UnauthorizedActionException.class);
        assertThat(request.getStatus()).isEqualTo(RequestStatus.PENDING);
    }

    @Test
    @DisplayName("Only a PENDING request can be accepted")
    void onlyPendingCanBeAccepted() {
        AdoptionRequest request = pendingRequest(owner, sitter);
        request.setStatus(RequestStatus.CANCELLED);
        when(requests.findById("REQUEST_1")).thenReturn(Optional.of(request));

        assertThatThrownBy(() -> requestService.accept(
                "REQUEST_1", new ProcessAdoptionRequest(null), owner))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("pending");
    }

    // ————————————————————————————————————————————— FIXTURES

    private AdoptionListing publishedListing(UserEntity publisher) {
        AdoptionListing listing = new AdoptionListing("LISTING_1", publisher);
        listing.setPetName("Milo");
        listing.setSpecies(PetSpecies.CAT);
        listing.setBreed("Siamese");
        listing.setAge(2);
        listing.setGender(PetGender.MALE);
        listing.setDescription("Friendly cat.");
        listing.setVaccinated(true);
        listing.setSterilized(false);
        listing.setLocation("Ariana");
        listing.setStatus(ListingStatus.PUBLISHED);
        return listing;
    }

    private AdoptionRequest pendingRequest(UserEntity publisher, UserEntity applicant) {
        return pendingRequest(publishedListing(publisher), applicant, "REQUEST_1");
    }

    private AdoptionRequest pendingRequest(
            AdoptionListing listing, UserEntity applicant, String id) {
        AdoptionRequest request = new AdoptionRequest(id, listing, applicant);
        request.setFullName("Sami");
        request.setPhone("+216 20 000 000");
        request.setAddress("Tunis");
        request.setMessage("I would like to adopt.");
        request.setHousingType(HousingType.APARTMENT);
        request.setHasGarden(false);
        request.setHasOtherPets(false);
        request.setStatus(RequestStatus.PENDING);
        return request;
    }

    private CreateListingRequest createListing(String name) {
        return new CreateListingRequest(
                name, PetSpecies.CAT, "Siamese", 2, PetGender.MALE,
                "Friendly cat looking for a family.", "Healthy",
                true, false, "Ariana", null, List.of("https://example.com/milo.jpg"));
    }

    private com.petsitter.adoption.dto.listing.UpdateListingRequest updateListing(String name) {
        return new com.petsitter.adoption.dto.listing.UpdateListingRequest(
                name, PetSpecies.CAT, "Siamese", 2, PetGender.MALE,
                "Updated description.", "Healthy",
                true, false, "Ariana", List.of("https://example.com/milo.jpg"));
    }

    private CreateAdoptionRequest createRequest(String listingId) {
        return new CreateAdoptionRequest(
                listingId, "Sami", "+216 20 000 000", "Tunis",
                "I would like to adopt and provide a caring home.",
                HousingType.APARTMENT, false, false, null,
                "Previous experience with cats.", 85);
    }
}
