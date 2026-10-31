package com.petsitter.adoption.repository;

import com.petsitter.adoption.entity.AdoptionRequest;
import com.petsitter.adoption.enums.RequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AdoptionRequestRepository extends JpaRepository<AdoptionRequest, String> {

    List<AdoptionRequest> findByApplicantIdOrderByCreatedAtDesc(String applicantId);

    List<AdoptionRequest> findByListingPublisherIdOrderByCreatedAtDesc(String publisherId);

    boolean existsByListingIdAndApplicantIdAndStatus(
            String listingId, String applicantId, RequestStatus status);

    List<AdoptionRequest> findByListingIdAndStatusAndIdNot(
            String listingId, RequestStatus status, String excludedId);
}
