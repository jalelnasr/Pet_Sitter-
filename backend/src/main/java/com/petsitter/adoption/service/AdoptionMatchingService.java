package com.petsitter.adoption.service;

import com.petsitter.adoption.ai.AdoptionAiClient;
import com.petsitter.adoption.ai.PythonMatchPayload;
import com.petsitter.adoption.dto.matching.MatchingAdviceRequest;
import com.petsitter.adoption.dto.matching.MatchingAdviceResponse;
import com.petsitter.adoption.dto.request.CreateAdoptionRequest;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.common.exception.ServiceUnavailableException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class AdoptionMatchingService {

    private final AdoptionListingService listings;
    private final AdoptionAiClient aiClient;

    public AdoptionMatchingService(AdoptionListingService listings, AdoptionAiClient aiClient) {
        this.listings = listings;
        this.aiClient = aiClient;
    }

    @Transactional(readOnly = true)
    public MatchingAdviceResponse advise(MatchingAdviceRequest request) {
        AdoptionListing listing = listings.find(request.listingId());
        return match(listing, toCandidate(request))
                .orElseThrow(() -> new ServiceUnavailableException(
                        "AI_UNAVAILABLE",
                        "The local adoption matching service is unavailable."
                ));
    }

    public Optional<Integer> scoreForCreate(AdoptionListing listing, CreateAdoptionRequest body) {
        return match(listing, PythonMatchPayload.Candidate.of(
                body.housingType(),
                body.hasGarden(),
                body.hasOtherPets(),
                body.otherPetsDetails(),
                body.experience(),
                body.message()
        )).map(MatchingAdviceResponse::score);
    }

    private Optional<MatchingAdviceResponse> match(
            AdoptionListing listing, PythonMatchPayload.Candidate candidate) {
        PythonMatchPayload payload = new PythonMatchPayload(
                PythonMatchPayload.Listing.from(listing),
                candidate
        );
        return aiClient.match(payload);
    }

    private PythonMatchPayload.Candidate toCandidate(MatchingAdviceRequest request) {
        return PythonMatchPayload.Candidate.of(
                request.housingType(),
                request.hasGarden(),
                request.hasOtherPets(),
                request.otherPetsDetails(),
                request.experience(),
                request.motivation()
        );
    }
}
