package com.petsitter.adoption.dto.matching;

import java.util.List;

public record MatchingAdviceResponse(
        int score,
        String summary,
        List<String> tips,
        String model
) {
}
