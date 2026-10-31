package com.petsitter.adoption.ai;

import com.petsitter.adoption.dto.matching.MatchingAdviceResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
public class PythonAdoptionAiClient implements AdoptionAiClient {

    private static final Logger log = LoggerFactory.getLogger(PythonAdoptionAiClient.class);
    private static final String EXPECTED_MODEL =
            "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2";

    private final RestClient pythonAiRestClient;

    public PythonAdoptionAiClient(RestClient pythonAiRestClient) {
        this.pythonAiRestClient = pythonAiRestClient;
    }

    @Override
    public Optional<MatchingAdviceResponse> match(PythonMatchPayload payload) {
        try {
            MatchingAdviceResponse raw = pythonAiRestClient.post()
                    .uri("/match")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(payload)
                    .retrieve()
                    .body(MatchingAdviceResponse.class);
            return validate(raw);
        } catch (RestClientException ex) {
            log.warn("Adoption AI Python service unavailable: {}", ex.getMessage());
            return Optional.empty();
        }
    }

    private Optional<MatchingAdviceResponse> validate(MatchingAdviceResponse raw) {
        if (raw == null || raw.summary() == null || raw.summary().isBlank()) {
            return Optional.empty();
        }
        if (raw.score() < 0 || raw.score() > 100) {
            return Optional.empty();
        }
        List<String> tips = raw.tips() == null ? List.of() : raw.tips().stream()
                .filter(tip -> tip != null && !tip.isBlank())
                .limit(3)
                .toList();
        if (tips.isEmpty()) {
            return Optional.empty();
        }
        String model = raw.model() == null || raw.model().isBlank() ? EXPECTED_MODEL : raw.model();
        return Optional.of(new MatchingAdviceResponse(
                raw.score(),
                raw.summary().trim(),
                new ArrayList<>(tips),
                model
        ));
    }
}
