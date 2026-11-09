package com.petsitter.user.repository;

import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserRepository extends JpaRepository<UserEntity, String> {

    Optional<UserEntity> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    /** Annuaire : recherche par prénom, nom ou e-mail, rôle facultatif. */
    @Query("""
            select u from UserEntity u
            where (:role is null or u.role = :role)
              and (:q is null
                   or lower(u.firstName) like lower(concat('%', :q, '%'))
                   or lower(coalesce(u.lastName, '')) like lower(concat('%', :q, '%'))
                   or lower(u.email) like lower(concat('%', :q, '%')))
            order by u.firstName asc
            """)
    Page<UserEntity> search(@Param("q") String q, @Param("role") UserRole role, Pageable pageable);

    /** Comptes actifs visibles dans l'annuaire, sans l'utilisateur courant. */
    @Query("""
            select u from UserEntity u
            where u.disabled = false
              and u.id <> :excludeId
              and (:role is null or u.role = :role)
              and (:q is null
                   or lower(u.firstName) like lower(concat('%', :q, '%'))
                   or lower(coalesce(u.lastName, '')) like lower(concat('%', :q, '%')))
            order by u.firstName asc
            """)
    Page<UserEntity> directory(@Param("q") String q, @Param("role") UserRole role,
                               @Param("excludeId") String excludeId, Pageable pageable);
}
