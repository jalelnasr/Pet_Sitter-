package com.petsitter.petsitter.repository;

import com.petsitter.petsitter.entity.PetSitterReservation;
import com.petsitter.petsitter.enums.ReservationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface PetSitterReservationRepository extends JpaRepository<PetSitterReservation, String> {

    List<PetSitterReservation> findByOwnerIdOrderByCreatedAtDesc(String ownerId);

    List<PetSitterReservation> findBySitterIdOrderByCreatedAtDesc(String sitterId);

    List<PetSitterReservation> findBySitterIdAndStatusOrderByCreatedAtDesc(String sitterId, ReservationStatus status);

    List<PetSitterReservation> findAllByOrderByCreatedAtDesc();

    @Query("SELECT r FROM PetSitterReservation r WHERE r.sitterId = :sitterId " +
           "AND r.status = 'ACCEPTED' " +
           "AND r.startDate <= :endDate AND r.endDate >= :startDate")
    List<PetSitterReservation> findOverlappingAccepted(
            @Param("sitterId") String sitterId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    long countBySitterIdAndStatus(String sitterId, ReservationStatus status);
}
