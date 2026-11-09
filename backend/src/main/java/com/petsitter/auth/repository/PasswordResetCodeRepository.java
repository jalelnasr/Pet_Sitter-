package com.petsitter.auth.repository;

import com.petsitter.auth.entity.PasswordResetCode;
import com.petsitter.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, Long> {

    Optional<PasswordResetCode> findFirstByUserOrderByCreatedAtDesc(UserEntity user);

    /** Un seul code valable à la fois : les précédents sont neutralisés. */
    @Modifying
    @Query("update PasswordResetCode c set c.usedAt = :now where c.user = :user and c.usedAt is null")
    int invalidateAll(@Param("user") UserEntity user, @Param("now") Instant now);
}
