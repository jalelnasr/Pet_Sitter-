package com.petsitter.petsitter.repository;

import com.petsitter.petsitter.entity.PetSitterProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PetSitterProfileRepository extends JpaRepository<PetSitterProfile, String>, JpaSpecificationExecutor<PetSitterProfile> {

    Optional<PetSitterProfile> findByUserId(String userId);

    Page<PetSitterProfile> findByActiveTrue(Pageable pageable);

    boolean existsByUserId(String userId);
}
