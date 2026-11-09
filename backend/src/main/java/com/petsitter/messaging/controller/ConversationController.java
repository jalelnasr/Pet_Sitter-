package com.petsitter.messaging.controller;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.common.response.InfoResponse;
import com.petsitter.messaging.ai.MessageAnalysis;
import com.petsitter.messaging.ai.MessagingAiClient;
import com.petsitter.messaging.dto.ConversationResponse;
import com.petsitter.messaging.dto.MessageResponse;
import com.petsitter.messaging.dto.ReplySuggestionsResponse;
import com.petsitter.messaging.dto.SendMessageRequest;
import com.petsitter.messaging.dto.StartConversationRequest;
import com.petsitter.messaging.dto.UnreadCountResponse;
import com.petsitter.messaging.service.MessagingService;
import com.petsitter.user.entity.UserEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Messagerie entre membres. Connexion requise sur toutes les routes. */
@RestController
@RequestMapping("/api/conversations")
@Tag(name = "Messagerie", description = "Conversations privées entre propriétaires et pet sitters")
public class ConversationController {

    private final MessagingService messaging;
    private final CurrentUserResolver currentUser;
    private final MessagingAiClient ai;

    public ConversationController(MessagingService messaging, CurrentUserResolver currentUser, MessagingAiClient ai) {
        this.messaging = messaging;
        this.currentUser = currentUser;
        this.ai = ai;
    }

    @GetMapping
    @Operation(summary = "Mes conversations, la plus récente d'abord, avec le nombre de non-lus")
    public List<ConversationResponse> list(HttpServletRequest http) {
        return messaging.list(currentUser.require(http));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Ouvrir (ou retrouver) la conversation avec un membre, avec un premier message facultatif")
    public ConversationResponse start(HttpServletRequest http, @Valid @RequestBody StartConversationRequest request) {
        UserEntity me = currentUser.require(http);
        MessageAnalysis analysis = request.message() == null || request.message().isBlank()
                ? null : ai.analyze(request.message());
        return messaging.start(me, request, analysis);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Nombre total de messages non lus")
    public UnreadCountResponse unreadCount(HttpServletRequest http) {
        return messaging.unreadCount(currentUser.require(http));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Détail d'une conversation")
    public ConversationResponse get(HttpServletRequest http, @PathVariable Long id) {
        return messaging.get(currentUser.require(http), id);
    }

    @GetMapping("/{id}/messages")
    @Operation(summary = "Messages (du plus ancien au plus récent). afterId = nouveaux messages, beforeId = plus anciens")
    public List<MessageResponse> messages(
            HttpServletRequest http,
            @PathVariable Long id,
            @RequestParam(required = false) Long afterId,
            @RequestParam(required = false) Long beforeId,
            @RequestParam(required = false) Integer limit) {
        return messaging.messages(currentUser.require(http), id, afterId, beforeId, limit);
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Envoyer un message. L'assistant IA l'analyse : arnaque ou insulte → 409 RISKY_MESSAGE "
            + "(rien n'est envoyé), à renvoyer avec confirmRisk=true pour confirmer.")
    public MessageResponse send(HttpServletRequest http, @PathVariable Long id,
                                @Valid @RequestBody SendMessageRequest request) {
        UserEntity me = currentUser.require(http);
        // Analyse hors transaction : l'appel à l'IA ne doit pas retenir de connexion à la base.
        MessageAnalysis analysis = ai.analyze(request.content());
        return messaging.send(me, id, request.content(), request.riskConfirmed(), analysis);
    }

    @GetMapping("/{id}/ai/replies")
    @Operation(summary = "Assistant IA : 3 réponses suggérées selon les derniers messages")
    public ReplySuggestionsResponse suggestReplies(HttpServletRequest http, @PathVariable Long id) {
        MessagingService.ReplyContext context = messaging.replyContext(currentUser.require(http), id);
        return ai.suggestReplies(context.lines(), context.petsitter(), context.otherName(), context.subject());
    }

    @DeleteMapping("/{id}/messages/{messageId}")
    @Operation(summary = "Supprimer un de ses messages, pour tout le monde (« Message supprimé »)")
    public MessageResponse deleteMessage(HttpServletRequest http, @PathVariable Long id,
                                         @PathVariable Long messageId) {
        return messaging.delete(currentUser.require(http), id, messageId);
    }

    @PostMapping("/{id}/read")
    @Operation(summary = "Marquer comme lus les messages reçus")
    public InfoResponse markRead(HttpServletRequest http, @PathVariable Long id) {
        int count = messaging.markRead(currentUser.require(http), id);
        return InfoResponse.of(count + " message(s) marqué(s) comme lu(s).");
    }
}
