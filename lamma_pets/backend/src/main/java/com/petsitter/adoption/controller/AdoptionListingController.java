package com.petsitter.adoption.controller;

import com.petsitter.adoption.dto.listing.CreateListingRequest;
import com.petsitter.adoption.dto.listing.ListingResponse;
import com.petsitter.adoption.dto.listing.ListingSummaryResponse;
import com.petsitter.adoption.dto.listing.UpdateListingRequest;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.adoption.service.AdoptionListingService;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.service.DemoUserResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/adoption-listings")
@Tag(name = "Adoption Listings", description = "Publish and browse adoption listings")
public class AdoptionListingController {

    private static final String HEADER_DESCRIPTION =
            "Temporary user identifier used until the real User module and JWT "
                    + "authentication are implemented. Accepted values: OWNER_DEMO, "
                    + "PETSITTER_DEMO, ADMIN_DEMO.";

    private final AdoptionListingService service;
    private final DemoUserResolver demoUsers;

    public AdoptionListingController(
            AdoptionListingService service, DemoUserResolver demoUsers) {
        this.service = service;
        this.demoUsers = demoUsers;
    }

    @PostMapping
    @Operation(summary = "Create an adoption listing")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Listing created"),
            @ApiResponse(responseCode = "400", description = "Invalid payload"),
            @ApiResponse(responseCode = "403", description = "Role not allowed"),
            @ApiResponse(responseCode = "404", description = "Demo user not found")
    })
    public ResponseEntity<ListingResponse> create(
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @Valid @RequestBody CreateListingRequest body) {
        UserEntity publisher = demoUsers.requireRole(
                demoUserId, UserRole.OWNER, UserRole.PETSITTER);
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(body, publisher));
    }

    @GetMapping
    @Operation(summary = "Get published adoption listings")
    @ApiResponse(responseCode = "200", description = "Published listings page")
    public Page<ListingSummaryResponse> list(
            @RequestParam(required = false) PetSpecies species,
            @RequestParam(required = false) String location,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        UserEntity requester = demoUsers.optional(demoUserId);
        String requesterId = requester == null ? null : requester.getId();
        return service.publicList(species, location, page, size, requesterId);
    }

    @GetMapping("/mine")
    @Operation(summary = "Get my adoption listings")
    public List<ListingSummaryResponse> mine(
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.mine(demoUsers.require(demoUserId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get an adoption listing by id")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listing found"),
            @ApiResponse(responseCode = "404", description = "Listing not found")
    })
    public ListingResponse get(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO")
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.get(id, demoUsers.optional(demoUserId));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an adoption listing")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Listing updated"),
            @ApiResponse(responseCode = "403", description = "Not the publisher"),
            @ApiResponse(responseCode = "404", description = "Listing not found")
    })
    public ListingResponse update(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @Valid @RequestBody UpdateListingRequest body) {
        return service.update(id, body, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/publish")
    @Operation(summary = "Publish an adoption listing")
    public ListingResponse publish(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.publish(id, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/pause")
    @Operation(summary = "Pause an adoption listing")
    public ListingResponse pause(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.pause(id, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive an adoption listing")
    public ListingResponse archive(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.archive(id, demoUsers.require(demoUserId));
    }

    @PostMapping(value = "/images", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload an adoption listing image")
    public java.util.Map<String, String> uploadImage(
            @RequestParam("file") MultipartFile file,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return java.util.Map.of("url", service.storeImage(file, demoUsers.requireRole(
                demoUserId, UserRole.OWNER, UserRole.PETSITTER)));
    }
}
