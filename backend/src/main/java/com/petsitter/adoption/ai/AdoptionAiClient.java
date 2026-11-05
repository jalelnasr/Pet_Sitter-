package com.petsitter.adoption.ai;

import com.petsitter.adoption.dto.matching.MatchingAdviceResponse;

import java.util.Optional;

public interface AdoptionAiClient {

    Optional<MatchingAdviceResponse> match(PythonMatchPayload payload);
}
