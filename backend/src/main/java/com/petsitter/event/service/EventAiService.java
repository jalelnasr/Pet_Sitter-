package com.petsitter.event.service;

import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.event.dto.EventAiSuggestRequest;
import com.petsitter.event.dto.EventAiSuggestResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;

@Service
public class EventAiService {

    private static final Logger log = LoggerFactory.getLogger(EventAiService.class);

    private final RestClient restClient;

    public EventAiService(
            @Value("${events.ai.url:http://localhost:8001}") String eventsAiUrl,
            @Value("${events.ai.connect-timeout-ms:2000}") int connectTimeoutMs,
            @Value("${events.ai.read-timeout-ms:20000}") int readTimeoutMs
    ) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(connectTimeoutMs);
        requestFactory.setReadTimeout(readTimeoutMs);

        this.restClient = RestClient.builder()
                .baseUrl(eventsAiUrl)
                .requestFactory(requestFactory)
                .build();
    }

    public EventAiSuggestResponse suggest(EventAiSuggestRequest request, UserEntity actor) {
        requireAuthorizedRole(actor);

        try {
            EventAiSuggestResponse response = restClient.post()
                    .uri("/suggest")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(EventAiSuggestResponse.class);

            if (response != null && response.titles() != null && !response.titles().isEmpty()) {
                return response;
            }
            log.warn("Empty response received from FastAPI events_ai service, falling back to local generation");
            return buildFallbackResponse(request);
        } catch (Exception ex) {
            log.warn("FastAPI events_ai service call failed ({}), returning local fallback: {}",
                    ex.getClass().getSimpleName(), ex.getMessage());
            return buildFallbackResponse(request);
        }
    }

    private void requireAuthorizedRole(UserEntity actor) {
        if (actor == null || (actor.getRole() != UserRole.ADMIN && actor.getRole() != UserRole.PETSITTER)) {
            throw new UnauthorizedActionException(
                    "Cette fonctionnalité d'aide IA est réservée aux administrateurs et aux pet sitters."
            );
        }
    }

    public EventAiSuggestResponse buildFallbackResponse(EventAiSuggestRequest request) {
        String title = (request.title() != null && !request.title().isBlank())
                ? request.title().trim()
                : "Événement Pet Sitter";
        String locationSuffix = (request.location() != null && !request.location().isBlank())
                ? " à " + request.location().trim()
                : "";

        String category = resolveCategory(request.category(), title);

        List<String> titles = List.of(
                "Grand rassemblement : " + title + locationSuffix,
                title + " – Moments complices avec nos compagnons",
                "Atelier convivial : " + title
        );

        String description = "Rejoignez-nous pour " + title.toLowerCase() + locationSuffix + " ! " +
                "Un rendez-vous pensé spécialement pour nos fidèles boules de poils et leurs propriétaires passionnés. " +
                "Profitez d'un moment chaleureux de partage, d'échanges de conseils et de jeux en toute sécurité. " +
                "Nous avons hâte de vous retrouver nombreux avec vos animaux !";

        String summary = "Rejoignez notre événement " + title.toLowerCase() + locationSuffix + " pour un moment de partage inoubliable.";
        if (summary.length() > 120) {
            summary = summary.substring(0, 117) + "...";
        }

        List<String> tags = new ArrayList<>(List.of("petsitter", "animaux", category.toLowerCase()));
        if (request.keywords() != null) {
            for (String kw : request.keywords()) {
                if (kw != null && !kw.isBlank()) {
                    tags.add(kw.trim().toLowerCase());
                }
            }
        }
        if (request.location() != null && !request.location().isBlank()) {
            tags.add(request.location().trim().toLowerCase().replaceAll("\\s+", ""));
        }
        List<String> cleanTags = tags.stream().distinct().limit(5).toList();

        List<String> checklist = switch (category) {
            case "Adoption" -> List.of(
                    "Gamelles d'eau fraîche",
                    "Dossiers d'adoption et formulaires",
                    "Laisses et harnais de sécurité",
                    "Friandises et jouets d'accueil",
                    "Kit de premiers secours vétérinaire"
            );
            case "Éducation" -> List.of(
                    "Friandises appétentes de récompense",
                    "Saccoche à friandises et clicker",
                    "Longes d'éducation (5-10m)",
                    "Tapis de repos pour chaque chien",
                    "Gamelles d'eau individuelles"
            );
            case "Bien-être" -> List.of(
                    "Brosses et serviettes douces",
                    "Tapis confortables et coussins",
                    "Espace calme et ombragé",
                    "Diffuseurs ou sprays apaisants naturels",
                    "Eau fraîche à volonté"
            );
            case "Promenade" -> List.of(
                    "Laisses solides et colliers ajustés",
                    "Gourdes de voyage et gamelles pliables",
                    "Sacs à déjections en quantité",
                    "Gilets fluorescents ou foulards repères",
                    "Trousse de secours pour pattes et coussinets"
            );
            default -> List.of(
                    "Gamelles d'eau partagées et bouteilles",
                    "Sacs à déjections canines",
                    "Jouets d'interaction adaptés",
                    "Trousse de premiers secours",
                    "Badges nominatifs pour les propriétaires"
            );
        };

        String tip = switch (category) {
            case "Adoption" -> "Limitez à 15 participants simultanés pour ne pas stresser les animaux candidats.";
            case "Éducation" -> "Prévoyez un espace de 3 à 5 mètres entre chaque binôme maître-chien pour favoriser la concentration.";
            case "Bien-être" -> "Maintenez un volume sonore bas et une température ambiante agréable tout au long de la session.";
            case "Promenade" -> "Vérifiez la météo avant le départ et prévoyez une pause boisson toutes les 20 minutes.";
            default -> "Favorisez un terrain clos et prévoyez une zone de décompression pour les animaux timides.";
        };

        return new EventAiSuggestResponse(
                titles,
                description,
                summary,
                cleanTags,
                checklist,
                category,
                tip,
                "fallback"
        );
    }

    private String resolveCategory(String userCategory, String title) {
        if (userCategory != null && !userCategory.isBlank()) {
            return userCategory.trim();
        }
        String t = title.toLowerCase();
        if (t.contains("adopt")) return "Adoption";
        if (t.contains("éduc") || t.contains("dress") || t.contains("train")) return "Éducation";
        if (t.contains("balad") || t.contains("promenad") || t.contains("marche")) return "Promenade";
        if (t.contains("soin") || t.contains("sant") || t.contains("bien")) return "Bien-être";
        return "Rencontre";
    }
}
