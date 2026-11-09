package com.petsitter.messaging.repository;

import com.petsitter.messaging.entity.Conversation;
import com.petsitter.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {

    /** Conversations d'un membre, la plus récente d'abord. */
    @Query("""
            select c from Conversation c
            join fetch c.participantA
            join fetch c.participantB
            where c.participantA.id = :userId or c.participantB.id = :userId
            order by coalesce(c.lastMessageAt, c.createdAt) desc
            """)
    List<Conversation> findAllFor(@Param("userId") String userId);

    @Query("""
            select c from Conversation c
            join fetch c.participantA
            join fetch c.participantB
            where c.id = :id
            """)
    Optional<Conversation> findWithParticipants(@Param("id") Long id);

    Optional<Conversation> findByParticipantAAndParticipantB(UserEntity participantA, UserEntity participantB);
}
