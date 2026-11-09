package com.petsitter.messaging.entity;

import com.petsitter.messaging.enums.MessageRisk;
import com.petsitter.messaging.enums.MessageType;
import com.petsitter.user.entity.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;

/** Message d'une conversation. {@code readAt} nul = pas encore lu par le destinataire. */
@Entity
@Table(name = "messages", indexes = @Index(name = "idx_message_conversation", columnList = "conversation_id, id"))
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    /** Nul pour un message système (« Réservation confirmée »…). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id")
    private UserEntity sender;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 20, nullable = false)
    private MessageType type;

    @Column(name = "content", length = 2000, nullable = false)
    private String content;

    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;

    @Column(name = "read_at")
    private Instant readAt;

    /** Évaluation de l'assistant IA à l'envoi (nulle pour les anciens messages). */
    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", length = 10)
    private MessageRisk riskLevel;

    @Column(name = "risk_reason", length = 300)
    private String riskReason;

    /**
     * Texte d'origine quand des gros mots ont été remplacés par des étoiles dans {@code content}.
     * Gardé pour la modération ; jamais renvoyé à l'application.
     */
    @Column(name = "original_content", length = 2000)
    private String originalContent;

    /** Supprimé par son expéditeur : le texte est conservé pour la modération mais n'est plus renvoyé. */
    @Column(name = "deleted_at")
    private Instant deletedAt;

    protected Message() {
        // Requis par JPA.
    }

    public Message(Conversation conversation, UserEntity sender, MessageType type, String content, Instant sentAt) {
        this.conversation = conversation;
        this.sender = sender;
        this.type = type;
        this.content = content;
        this.sentAt = sentAt;
    }

    /** Remplace le texte affiché par sa version censurée et garde l'original pour la modération. */
    public void censor(String censoredContent) {
        if (censoredContent != null && !censoredContent.equals(content)) {
            this.originalContent = content;
            this.content = censoredContent;
        }
    }

    public void markDeleted(Instant now) {
        if (deletedAt == null) {
            deletedAt = now;
        }
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public String getOriginalContent() {
        return originalContent;
    }

    public void flag(MessageRisk risk, String reason) {
        this.riskLevel = risk;
        this.riskReason = risk == MessageRisk.NONE ? null : reason;
    }

    public MessageRisk getRiskLevel() {
        return riskLevel == null ? MessageRisk.NONE : riskLevel;
    }

    public String getRiskReason() {
        return riskReason;
    }

    public Long getId() {
        return id;
    }

    public Conversation getConversation() {
        return conversation;
    }

    public UserEntity getSender() {
        return sender;
    }

    public MessageType getType() {
        return type;
    }

    public String getContent() {
        return content;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public Instant getReadAt() {
        return readAt;
    }
}
