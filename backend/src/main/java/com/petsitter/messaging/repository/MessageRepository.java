package com.petsitter.messaging.repository;

import com.petsitter.messaging.entity.Message;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {

    /** Derniers messages (ordre décroissant) : historique initial ou page précédente. */
    @Query("""
            select m from Message m left join fetch m.sender
            where m.conversation.id = :conversationId and (:beforeId is null or m.id < :beforeId)
            order by m.id desc
            """)
    List<Message> findLatest(@Param("conversationId") Long conversationId,
                             @Param("beforeId") Long beforeId,
                             Pageable pageable);

    /** Messages arrivés après un identifiant (rafraîchissement de la conversation ouverte). */
    @Query("""
            select m from Message m left join fetch m.sender
            where m.conversation.id = :conversationId and m.id > :afterId
            order by m.id asc
            """)
    List<Message> findAfter(@Param("conversationId") Long conversationId,
                            @Param("afterId") Long afterId,
                            Pageable pageable);

    /** Non lus par conversation : lignes [conversationId, nombre]. */
    @Query("""
            select m.conversation.id, count(m) from Message m
            where m.conversation.id in :conversationIds
              and m.sender.id <> :userId and m.readAt is null and m.deletedAt is null
            group by m.conversation.id
            """)
    List<Object[]> countUnreadByConversation(@Param("conversationIds") Collection<Long> conversationIds,
                                             @Param("userId") String userId);

    @Query("""
            select count(m) from Message m
            where (m.conversation.participantA.id = :userId or m.conversation.participantB.id = :userId)
              and m.sender.id <> :userId and m.readAt is null and m.deletedAt is null
            """)
    long countUnread(@Param("userId") String userId);

    @Modifying
    @Query("""
            update Message m set m.readAt = :now
            where m.conversation.id = :conversationId
              and m.sender.id <> :userId and m.readAt is null and m.deletedAt is null
            """)
    int markRead(@Param("conversationId") Long conversationId, @Param("userId") String userId,
                 @Param("now") Instant now);
}
