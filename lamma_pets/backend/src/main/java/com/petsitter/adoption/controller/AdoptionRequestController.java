package com.petsitter.adoption.controller;

import com.petsitter.adoption.dto.request.AdoptionRequestResponse;
import com.petsitter.adoption.dto.request.CreateAdoptionRequest;
import com.petsitter.adoption.dto.request.ProcessAdoptionRequest;
import com.petsitter.adoption.service.AdoptionRequestService;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.service.DemoUserResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/adoption-requests")
@Tag(name = "Adoption Requests", description = "Send and process adoption requests")
public class AdoptionRequestController {

    private static final String HEADER_DESCRIPTION =
            "Temporary user identifier used until the real User module and JWT "
                    + "authentication are implemented. Accepted values: OWNER_DEMO, "
                    + "PETSITTER_DEMO, ADMIN_DEMO.";

    private final AdoptionRequestService service;
    private final DemoUserResolver demoUsers;

    public AdoptionRequestController(
            AdoptionRequestService service, DemoUserResolver demoUsers) {
        this.service = service;
        this.demoUsers = demoUsers;
    }

    @PostMapping
    @Operation(summary = "Send an adoption request")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Request created"),
            @ApiResponse(responseCode = "400", description = "Invalid payload"),
            @ApiResponse(responseCode = "403", description = "Role not allowed"),
            @ApiResponse(responseCode = "409", description = "Business conflict")
    })
    public ResponseEntity<AdoptionRequestResponse> create(
            @Parameter(description = HEADER_DESCRIPTION, example = "PETSITTER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @Valid @RequestBody CreateAdoptionRequest body) {
        UserEntity applicant = demoUsers.require(demoUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(service.create(body, applicant));
    }

    @GetMapping("/sent")
    @Operation(summary = "Get my sent requests")
    public List<AdoptionRequestResponse> sent(
            @Parameter(description = HEADER_DESCRIPTION, example = "PETSITTER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.sent(demoUsers.require(demoUserId));
    }

    @GetMapping("/received")
    @Operation(summary = "Get received requests")
    public List<AdoptionRequestResponse> received(
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.received(demoUsers.require(demoUserId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get an adoption request by id")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Request found"),
            @ApiResponse(responseCode = "403", description = "Not allowed"),
            @ApiResponse(responseCode = "404", description = "Request not found")
    })
    public AdoptionRequestResponse get(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId) {
        return service.get(id, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/accept")
    @Operation(summary = "Accept an adoption request")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Request accepted"),
            @ApiResponse(responseCode = "403", description = "Not the publisher"),
            @ApiResponse(responseCode = "409", description = "Request is not pending")
    })
    public AdoptionRequestResponse accept(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @RequestBody(required = false) ProcessAdoptionRequest body) {
        return service.accept(id, body, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/reject")
    @Operation(summary = "Reject an adoption request")
    public AdoptionRequestResponse reject(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "OWNER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @RequestBody(required = false) ProcessAdoptionRequest body) {
        return service.reject(id, body, demoUsers.require(demoUserId));
    }

    @PatchMapping("/{id}/cancel")
    @Operation(summary = "Cancel an adoption request")
    public AdoptionRequestResponse cancel(
            @PathVariable String id,
            @Parameter(description = HEADER_DESCRIPTION, example = "PETSITTER_DEMO", required = true)
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @RequestBody(required = false) ProcessAdoptionRequest body) {
        return service.cancel(id, body, demoUsers.require(demoUserId));
    }
}
