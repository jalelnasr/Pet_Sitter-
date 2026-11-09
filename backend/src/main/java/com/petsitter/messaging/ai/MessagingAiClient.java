package com.petsitter.messaging.ai;

import com.petsitter.messaging.dto.ReplySuggestionsResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

/**
 * Appelle le service Python {@code messaging_ai} (FastAPI, port 8002).
 *
 * <p>Si le service est arrêté, lent ou renvoie une erreur, les règles locales de
 * {@link MessagingAiFallback} répondent : la messagerie ne tombe jamais à cause de l'IA.</p>
 */
@Component
public class MessagingAiClient {

    private static final Logger log = LoggerFactory.getLogger(MessagingAiClient.class);

    private final RestClient rest;
    private final String baseUrl;

    public MessagingAiClient(
            @Value("${messaging.ai.url:http://localhost:8002}") String baseUrl,
            @Value("${messaging.ai.connect-timeout-ms:800}") int connectTimeoutMs,
            @Value("${messaging.ai.read-timeout-ms:6000}") int readTimeoutMs) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeoutMs);
        factory.setReadTimeout(readTimeoutMs);
        this.baseUrl = baseUrl;
        this.rest = RestClient.builder().baseUrl(baseUrl).requestFactory(factory).build();
    }

    /** Ligne de conversation envoyée à l'IA ({@code fromMe} = écrite par l'utilisateur courant). */
    public record ChatLine(boolean fromMe, String text) {
    }

    private record AnalyzePayload(String risk, List<String> categories, String reason, String source) {
    }

    private record SuggestPayload(List<String> replies, String source) {
    }

    public MessageAnalysis analyze(String text) {
        try {
            AnalyzePayload body = rest.post().uri("/analyze")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("text", text))
                    .retrieve()
                    .body(AnalyzePayload.class);
            if (body == null) {
                return MessagingAiFallback.analyze(text);
            }
            // Risque recalculé côté backend (seules les catégories connues comptent) ; l'explication
            // précise du service (mot masqué, langue) est gardée quand elle existe.
            MessageAnalysis analysis = MessagingAiFallback.build(body.categories(), body.source());
            if (analysis.risk() != com.petsitter.messaging.enums.MessageRisk.NONE
                    && body.reason() != null && !body.reason().isBlank()) {
                return new MessageAnalysis(analysis.risk(), analysis.categories(), body.reason(), analysis.source());
            }
            return analysis;
        } catch (Exception e) {
            log.debug("messaging_ai indisponible ({}) : règles locales", e.getMessage());
            return MessagingAiFallback.analyze(text);
        }
    }

    public ReplySuggestionsResponse suggestReplies(List<ChatLine> lines, boolean petsitter, String otherName,
                                                   String subject) {
        String lastReceived = lines.stream().filter(l -> !l.fromMe()).reduce((a, b) -> b).map(ChatLine::text)
                .orElse("");
        try {
            SuggestPayload body = rest.post().uri("/suggest-replies")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "messages", lines,
                            "myRole", petsitter ? "PETSITTER" : "OWNER",
                            "otherName", otherName == null ? "" : otherName,
                            "subject", subject == null ? "" : subject))
                    .retrieve()
                    .body(SuggestPayload.class);
            if (body != null && body.replies() != null && !body.replies().isEmpty()) {
                return new ReplySuggestionsResponse(body.replies().stream().limit(3).toList(), body.source());
            }
        } catch (Exception e) {
            log.debug("messaging_ai indisponible ({}) : suggestions locales", e.getMessage());
        }
        return new ReplySuggestionsResponse(MessagingAiFallback.suggest(lastReceived, petsitter), "local");
    }

    public String baseUrl() {
        return baseUrl;
    }
}
