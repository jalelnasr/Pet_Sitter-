package com.petsitter.adoption.controller;

import com.petsitter.adoption.dto.listing.ListingResponse;
import com.petsitter.adoption.dto.listing.ListingSummaryResponse;
import com.petsitter.adoption.service.AdoptionListingService;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.service.DemoUserResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Minimal adoption moderation interface reserved to administrators.
 */
@RestController
@RequestMapping("/api/admin/adoption-listings")
@Tag(name = "Adoption Administration", description = "Administrator moderation of adoption listings")
public class AdminAdoptionController {

    private static final String HEADER_DESCRIPTION =
            "Temporary user identifier used until the real User module and JWT "
                    + "authentication are implemented. Accepted values: OWNER_DEMO, "
                    + "PETSITTER_DEMO, ADMIN_DEMO.";

    private final AdoptionListingService service;
    private final DemoUserResolver demoUsers;

    public AdminAdoptionController(
            AdoptionListingService service, DemoUserResolver demoUsers) {
        this.service = service;
        this.demoUsers = demoUsers;
    }

    @GetMapping
    @Operation(summary = "Get listings for Admin moderation")
    @ApiResponse(responseCode = "200", description = "All listings")
    public List<ListingSummaryResponse> list(
            @Parameter(description = HEADER_DESCRIPTION, example = "ADMIN_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        UserEntity admin = demoUsers.requireRole(demoUserId, UserRole.ADMIN);
        return service.adminList(admin);
    }

    @PatchMapping("/{id}/hide")
    @Operation(summary = "Hide an adoption listing as Admin")
    @ApiResponse(responseCode = "200", description = "Listing hidden")
    public ListingResponse hide(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "ADMIN_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        UserEntity admin = demoUsers.requireRole(demoUserId, UserRole.ADMIN);
        return service.adminHide(id, admin);
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive an adoption listing as Admin")
    @ApiResponse(responseCode = "200", description = "Listing archived")
    public ListingResponse archive(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "ADMIN_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        UserEntity admin = demoUsers.requireRole(demoUserId, UserRole.ADMIN);
        return service.adminArchive(id, admin);
    }
}
