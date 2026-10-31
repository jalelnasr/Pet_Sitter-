package com.petsitter.adoption.repository;

import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetSpecies;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface AdoptionListingRepository extends JpaRepository<AdoptionListing, String> {

    @Query("""
            select l from AdoptionListing l
            where l.status = :status
              and (:species is null or l.species = :species)
              and (:location is null or lower(l.location) like lower(concat('%', :location, '%')))
              and (:requesterId is null or l.publisher.id <> :requesterId)
            order by l.createdAt desc
            """)
    Page<AdoptionListing> searchPublic(
            @Param("status") ListingStatus status,
            @Param("species") PetSpecies species,
            @Param("location") String location,
            @Param("requesterId") String requesterId,
            Pageable pageable
    );

    List<AdoptionListing> findByPublisherIdOrderByCreatedAtDesc(String publisherId);

    List<AdoptionListing> findAllByOrderByCreatedAtDesc();
}
