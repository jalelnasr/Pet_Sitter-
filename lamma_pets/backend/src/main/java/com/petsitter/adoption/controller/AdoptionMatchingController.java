package com.petsitter.adoption.controller;

import com.petsitter.adoption.dto.matching.MatchingAdviceRequest;
import com.petsitter.adoption.dto.matching.MatchingAdviceResponse;
import com.petsitter.adoption.service.AdoptionMatchingService;
import com.petsitter.user.service.DemoUserResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/adoption-matching")
@Tag(name = "Adoption Matching", description = "Offline listing/candidate compatibility advice")
public class AdoptionMatchingController {

    private final AdoptionMatchingService matching;
    private final DemoUserResolver demoUsers;

    public AdoptionMatchingController(
            AdoptionMatchingService matching, DemoUserResolver demoUsers) {
        this.matching = matching;
        this.demoUsers = demoUsers;
    }

    @PostMapping("/advice")
    @Operation(summary = "Get local AI matching advice for an adoption listing")
    public MatchingAdviceResponse advice(
            @Parameter(required = true, example = "PETSITTER_DEMO")
            @RequestHeader(value = DemoUserResolver.HEADER, required = false) String demoUserId,
            @Valid @RequestBody MatchingAdviceRequest body) {
        demoUsers.require(demoUserId);
        return matching.advise(body);
    }
}
