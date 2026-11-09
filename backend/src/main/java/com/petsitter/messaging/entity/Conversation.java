package com.petsitter.messaging.entity;

import com.petsitter.user.entity.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;

/**
 * Conversation privée entre deux membres.
 *
 * <p>Les deux participants sont rangés par identifiant croissant
 * ({@code participantA < participantB}) : la contrainte d'unicité garantit
 * une seule conversation par paire, quel que soit celui qui l'a ouverte.
 * Le dernier message est recopié ici pour afficher la liste sans requête lourde.</p>
 */
@Entity
@Table(name = "conversations", uniqueConstraints = @UniqueConstraint(
        name = "uk_conversation_pair", columnNames = {"participant_a_id", "participant_b_id"}))
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant_a_id", nullable = false)
    private UserEntity participantA;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant_b_id", nullable = false)
    private UserEntity participantB;

    /** Contexte facultatif affiché sous le nom (ex. « Garde du 1er au 4 nov. »). */
    @Column(name = "subject", length = 160)
    private String subject;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "last_message_at")
    private Instant lastMessageAt;

    @Column(name = "last_message_preview", length = 200)
    private String lastMessagePreview;

    @Column(name = "last_message_sender_id", length = 64)
    private String lastMessageSenderId;

    protected Conversation() {
        // Requis par JPA.
    }

    /** Crée la conversation en rangeant les participants dans l'ordre canonique. */
    public static Conversation between(UserEntity first, UserEntity second, String subject, Instant now) {
        Conversation c = new Conversation();
        boolean ordered = first.getId().compareTo(second.getId()) < 0;
        c.participantA = ordered ? first : second;
        c.participantB = ordered ? second : first;
        c.subject = subject;
        c.createdAt = now;
        return c;
    }

    public boolean involves(String userId) {
        return participantA.getId().equals(userId) || participantB.getId().equals(userId);
    }

    public UserEntity otherParticipant(String userId) {
        return participantA.getId().equals(userId) ? participantB : participantA;
    }

    public void recordMessage(Message message) {
        this.lastMessageAt = message.getSentAt();
        String content = message.getContent();
        this.lastMessagePreview = content.length() > 200 ? content.substring(0, 197) + "…" : content;
        this.lastMessageSenderId = message.getSender() == null ? null : message.getSender().getId();
    }

    /** Le dernier message vient d'être supprimé : l'aperçu de la liste l'indique. */
    public void lastMessageDeleted() {
        this.lastMessagePreview = DELETED_PREVIEW;
    }

    public static final String DELETED_PREVIEW = "Message supprimé";

    public Long getId() {
        return id;
    }

    public UserEntity getParticipantA() {
        return participantA;
    }

    public UserEntity getParticipantB() {
        return participantB;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getLastMessageAt() {
        return lastMessageAt;
    }

    public String getLastMessagePreview() {
        return lastMessagePreview;
    }

    public String getLastMessageSenderId() {
        return lastMessageSenderId;
    }
}
