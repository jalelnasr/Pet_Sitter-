package com.petsitter.petsitter.repository;

import com.petsitter.petsitter.entity.PetSitterReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PetSitterReviewRepository extends JpaRepository<PetSitterReview, String> {

    List<PetSitterReview> findBySitterIdOrderByCreatedAtDesc(String sitterId);

    Optional<PetSitterReview> findByReservationId(String reservationId);

    long countBySitterId(String sitterId);
}
