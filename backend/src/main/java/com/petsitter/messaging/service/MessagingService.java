package com.petsitter.messaging.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.BusinessException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.common.exception.UnauthorizedActionException;
import com.petsitter.messaging.ai.MessageAnalysis;
import com.petsitter.messaging.ai.MessagingAiClient.ChatLine;
import com.petsitter.messaging.ai.ProfanityDetector;
import com.petsitter.messaging.dto.ConversationResponse;
import com.petsitter.messaging.dto.MessageResponse;
import com.petsitter.messaging.dto.StartConversationRequest;
import com.petsitter.messaging.dto.UnreadCountResponse;
import com.petsitter.messaging.entity.Conversation;
import com.petsitter.messaging.entity.Message;
import com.petsitter.messaging.enums.MessageType;
import com.petsitter.messaging.repository.ConversationRepository;
import com.petsitter.messaging.repository.MessageRepository;
import com.petsitter.user.dto.UserSummaryResponse;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Règles de la messagerie : seuls les deux participants lisent et écrivent,
 * une seule conversation par paire, pas de message à soi-même ni à un compte suspendu.
 */
@Service
public class MessagingService {

    static final int MAX_PAGE = 100;
    static final int DEFAULT_PAGE = 50;

    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final UserRepository users;
    private final Clock clock;

    @Autowired
    public MessagingService(ConversationRepository conversations, MessageRepository messages, UserRepository users) {
        this(conversations, messages, users, Clock.systemUTC());
    }

    MessagingService(ConversationRepository conversations, MessageRepository messages, UserRepository users,
                     Clock clock) {
        this.conversations = conversations;
        this.messages = messages;
        this.users = users;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> list(UserEntity me) {
        List<Conversation> mine = conversations.findAllFor(me.getId());
        if (mine.isEmpty()) {
            return List.of();
        }
        Map<Long, Long> unread = new HashMap<>();
        for (Object[] row : messages.countUnreadByConversation(mine.stream().map(Conversation::getId).toList(),
                me.getId())) {
            unread.put((Long) row[0], (Long) row[1]);
        }
        return mine.stream().map(c -> toResponse(c, me, unread.getOrDefault(c.getId(), 0L))).toList();
    }

    @Transactional
    public ConversationResponse start(UserEntity me, StartConversationRequest req) {
        return start(me, req, null);
    }

    /** {@code firstMessageAnalysis} : évaluation IA du premier message (le message est signalé, pas bloqué). */
    @Transactional
    public ConversationResponse start(UserEntity me, StartConversationRequest req, MessageAnalysis firstMessageAnalysis) {
        String targetId = req.participantId().trim();
        if (targetId.equals(me.getId())) {
            throw new BadRequestException("SELF_CONVERSATION", "Vous ne pouvez pas vous écrire à vous-même.");
        }
        UserEntity target = users.findById(targetId)
                .orElseThrow(() -> new ResourceNotFoundException("Ce membre est introuvable."));
        if (target.isDisabled()) {
            throw new BusinessException("RECIPIENT_UNAVAILABLE", "Ce membre ne peut plus recevoir de messages.");
        }
        UserEntity self = users.getReferenceById(me.getId());
        Conversation probe = Conversation.between(self, target, null, now());
        Conversation conversation = conversations
                .findByParticipantAAndParticipantB(probe.getParticipantA(), probe.getParticipantB())
                .orElseGet(() -> create(self, target, req.subject()));
        if (conversation.getSubject() == null && req.subject() != null && !req.subject().isBlank()) {
            conversation.setSubject(req.subject().trim());
        }
        if (req.message() != null && !req.message().isBlank()) {
            append(conversation, self, req.message(), firstMessageAnalysis);
        }
        return toResponse(conversation, me, 0);
    }

    @Transactional(readOnly = true)
    public ConversationResponse get(UserEntity me, Long conversationId) {
        Conversation conversation = requireParticipant(me, conversationId);
        long unread = messages.countUnreadByConversation(List.of(conversationId), me.getId()).stream()
                .findFirst().map(row -> (Long) row[1]).orElse(0L);
        return toResponse(conversation, me, unread);
    }

    /**
     * Historique d'une conversation, du plus ancien au plus récent.
     * {@code afterId} : seulement les nouveaux messages ; {@code beforeId} : page précédente.
     */
    @Transactional(readOnly = true)
    public List<MessageResponse> messages(UserEntity me, Long conversationId, Long afterId, Long beforeId,
                                          Integer limit) {
        requireParticipant(me, conversationId);
        int size = limit == null ? DEFAULT_PAGE : Math.min(Math.max(limit, 1), MAX_PAGE);
        List<Message> page;
        if (afterId != null) {
            page = messages.findAfter(conversationId, afterId, PageRequest.of(0, size));
        } else {
            page = new ArrayList<>(messages.findLatest(conversationId, beforeId, PageRequest.of(0, size)));
            Collections.reverse(page);
        }
        return page.stream().map(m -> MessageResponse.from(m, me.getId())).toList();
    }

    @Transactional
    public MessageResponse send(UserEntity me, Long conversationId, String content) {
        return send(me, conversationId, content, false, null);
    }

    /**
     * Envoie un message évalué par l'assistant IA ({@code analysis}, calculée avant la transaction).
     * Risque élevé non confirmé : 409 {@code RISKY_MESSAGE} avec l'explication, rien n'est enregistré ;
     * l'application affiche l'avertissement et renvoie avec {@code confirmRisk=true}.
     */
    @Transactional
    public MessageResponse send(UserEntity me, Long conversationId, String content, boolean confirmRisk,
                                MessageAnalysis analysis) {
        Conversation conversation = requireParticipant(me, conversationId);
        if (conversation.otherParticipant(me.getId()).isDisabled()) {
            throw new BusinessException("RECIPIENT_UNAVAILABLE", "Ce membre ne peut plus recevoir de messages.");
        }
        if (analysis != null && analysis.isHigh() && !confirmRisk) {
            throw new BusinessException("RISKY_MESSAGE", analysis.reason());
        }
        Message message = append(conversation, users.getReferenceById(me.getId()), content, analysis);
        return MessageResponse.from(message, me.getId());
    }

    /**
     * Supprime un message pour tout le monde. Seul son expéditeur le peut ; un message système ne se supprime pas.
     * Sans effet sur un message déjà supprimé.
     */
    @Transactional
    public MessageResponse delete(UserEntity me, Long conversationId, Long messageId) {
        Conversation conversation = requireParticipant(me, conversationId);
        Message message = messages.findById(messageId)
                .filter(m -> m.getConversation().getId().equals(conversationId))
                .orElseThrow(() -> new ResourceNotFoundException("Message introuvable."));
        if (message.getSender() == null || !message.getSender().getId().equals(me.getId())) {
            throw new UnauthorizedActionException("Vous ne pouvez supprimer que vos propres messages.");
        }
        if (!message.isDeleted()) {
            message.markDeleted(now());
            boolean isLast = messages.findLatest(conversationId, null, PageRequest.of(0, 1)).stream()
                    .findFirst().map(last -> last.getId().equals(messageId)).orElse(false);
            if (isLast) {
                conversation.lastMessageDeleted();
            }
        }
        return MessageResponse.from(message, me.getId());
    }

    /** Contexte envoyé à l'IA pour suggérer des réponses : 12 derniers messages écrits, rôle, interlocuteur. */
    public record ReplyContext(List<ChatLine> lines, boolean petsitter, String otherName, String subject) {
    }

    @Transactional(readOnly = true)
    public ReplyContext replyContext(UserEntity me, Long conversationId) {
        Conversation conversation = requireParticipant(me, conversationId);
        List<Message> latest = new ArrayList<>(messages.findLatest(conversationId, null, PageRequest.of(0, 12)));
        Collections.reverse(latest);
        List<ChatLine> lines = latest.stream()
                .filter(m -> m.getType() == MessageType.TEXT && m.getSender() != null && !m.isDeleted())
                .map(m -> new ChatLine(m.getSender().getId().equals(me.getId()), m.getContent()))
                .toList();
        return new ReplyContext(lines, me.getRole() == UserRole.PETSITTER,
                conversation.otherParticipant(me.getId()).getFirstName(), conversation.getSubject());
    }

    /** Marque comme lus les messages reçus ; renvoie le nombre de messages concernés. */
    @Transactional
    public int markRead(UserEntity me, Long conversationId) {
        requireParticipant(me, conversationId);
        return messages.markRead(conversationId, me.getId(), now());
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse unreadCount(UserEntity me) {
        return new UnreadCountResponse(messages.countUnread(me.getId()));
    }

    /** Message automatique (réservation confirmée…), utilisable par les autres modules. */
    @Transactional
    public void postSystemMessage(Long conversationId, String content) {
        Conversation conversation = conversations.findById(conversationId)
                .orElseThrow(() -> new ResourceNotFoundException("Conversation introuvable."));
        Message message = messages.save(new Message(conversation, null, MessageType.SYSTEM, content.trim(), now()));
        conversation.recordMessage(message);
    }

    // ———— Outils

    private Conversation create(UserEntity self, UserEntity target, String subject) {
        // Si l'autre membre l'ouvre au même instant, la contrainte d'unicité répond 409
        // (GlobalExceptionHandler) et l'application n'a qu'à réessayer.
        String cleanSubject = subject == null || subject.isBlank() ? null : subject.trim();
        return conversations.save(Conversation.between(self, target, cleanSubject, now()));
    }

    private Message append(Conversation conversation, UserEntity sender, String rawContent, MessageAnalysis analysis) {
        String content = rawContent == null ? "" : rawContent.trim();
        if (content.isEmpty()) {
            throw new BadRequestException("EMPTY_MESSAGE", "Le message est vide.");
        }
        if (content.length() > 2000) {
            throw new BadRequestException("MESSAGE_TOO_LONG", "2000 caractères au maximum.");
        }
        Message message = new Message(conversation, sender, MessageType.TEXT, content, now());
        // Les gros mots sont remplacés par des étoiles (« Si zebi » → « Si z**i ») pour tout le monde.
        message.censor(ProfanityDetector.instance().censor(content));
        if (analysis != null) {
            message.flag(analysis.risk(), analysis.reason());
        }
        message = messages.save(message);
        conversation.recordMessage(message);
        return message;
    }

    private Conversation requireParticipant(UserEntity me, Long conversationId) {
        Conversation conversation = conversations.findWithParticipants(conversationId)
                .orElseThrow(() -> new ResourceNotFoundException("Conversation introuvable."));
        if (!conversation.involves(me.getId())) {
            throw new UnauthorizedActionException("Vous ne participez pas à cette conversation.");
        }
        return conversation;
    }

    private ConversationResponse toResponse(Conversation c, UserEntity me, long unread) {
        return new ConversationResponse(
                c.getId(),
                UserSummaryResponse.from(c.otherParticipant(me.getId())),
                c.getSubject(),
                c.getLastMessagePreview(),
                c.getLastMessageAt(),
                me.getId().equals(c.getLastMessageSenderId()),
                unread,
                c.getCreatedAt());
    }

    private Instant now() {
        return clock.instant();
    }
}
