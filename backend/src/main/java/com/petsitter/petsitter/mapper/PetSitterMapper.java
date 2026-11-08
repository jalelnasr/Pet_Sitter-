package com.petsitter.petsitter.mapper;

import com.petsitter.petsitter.dto.ReservationResponse;
import com.petsitter.petsitter.dto.ReviewResponse;
import com.petsitter.petsitter.dto.SitterResponse;
import com.petsitter.petsitter.dto.SitterSummaryResponse;
import com.petsitter.petsitter.entity.PetSitterProfile;
import com.petsitter.petsitter.entity.PetSitterReservation;
import com.petsitter.petsitter.entity.PetSitterReview;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashSet;

@Component
public class PetSitterMapper {

    public SitterResponse toResponse(PetSitterProfile entity) {
        if (entity == null) return null;
        SitterResponse res = new SitterResponse();
        res.setId(entity.getId());
        res.setUserId(entity.getUserId());
        res.setFullName(entity.getFullName());
        res.setBio(entity.getBio());
        res.setGovernorate(entity.getGovernorate());
        res.setCity(entity.getCity());
        res.setAddress(entity.getAddress());
        res.setPhone(entity.getPhone());
        res.setPhotoUrl(entity.getPhotoUrl());
        res.setGallery(entity.getGallery() != null ? new ArrayList<>(entity.getGallery()) : new ArrayList<>());
        res.setExperienceYears(entity.getExperienceYears());
        res.setPricePerHour(entity.getPricePerHour());
        res.setPricePerDay(entity.getPricePerDay());
        res.setServices(entity.getServices() != null ? new HashSet<>(entity.getServices()) : new HashSet<>());
        res.setAcceptedPetTypes(entity.getAcceptedPetTypes() != null ? new HashSet<>(entity.getAcceptedPetTypes()) : new HashSet<>());
        res.setAcceptedSizes(entity.getAcceptedSizes() != null ? new HashSet<>(entity.getAcceptedSizes()) : new HashSet<>());
        res.setHasGarden(entity.isHasGarden());
        res.setHasOwnPets(entity.isHasOwnPets());
        res.setAvailability(entity.getAvailability());
        res.setVerified(entity.isVerified());
        res.setActive(entity.isActive());
        res.setAverageRating(entity.getAverageRating() != null ? entity.getAverageRating() : 0.0);
        res.setReviewsCount(entity.getReviewsCount());
        res.setCreatedAt(entity.getCreatedAt());
        res.setUpdatedAt(entity.getUpdatedAt());
        return res;
    }

    public SitterSummaryResponse toSummaryResponse(PetSitterProfile entity) {
        if (entity == null) return null;
        SitterSummaryResponse res = new SitterSummaryResponse();
        res.setId(entity.getId());
        res.setUserId(entity.getUserId());
        res.setFullName(entity.getFullName());
        res.setGovernorate(entity.getGovernorate());
        res.setCity(entity.getCity());
        res.setPhotoUrl(entity.getPhotoUrl());
        res.setPricePerHour(entity.getPricePerHour());
        res.setPricePerDay(entity.getPricePerDay());
        res.setServices(entity.getServices() != null ? new HashSet<>(entity.getServices()) : new HashSet<>());
        res.setAcceptedPetTypes(entity.getAcceptedPetTypes() != null ? new HashSet<>(entity.getAcceptedPetTypes()) : new HashSet<>());
        res.setVerified(entity.isVerified());
        res.setActive(entity.isActive());
        res.setAverageRating(entity.getAverageRating() != null ? entity.getAverageRating() : 0.0);
        res.setReviewsCount(entity.getReviewsCount());
        return res;
    }

    public ReservationResponse toReservationResponse(PetSitterReservation entity, PetSitterProfile sitter, String ownerName, boolean hasReview) {
        if (entity == null) return null;
        ReservationResponse res = new ReservationResponse();
        res.setId(entity.getId());
        res.setSitterId(entity.getSitterId());
        if (sitter != null) {
            res.setSitterName(sitter.getFullName());
            res.setSitterPhoto(sitter.getPhotoUrl());
            res.setSitterCity(sitter.getCity());
        }
        res.setOwnerId(entity.getOwnerId());
        res.setOwnerName(ownerName != null ? ownerName : "Propriétaire (" + entity.getOwnerId() + ")");
        res.setPetName(entity.getPetName());
        res.setPetType(entity.getPetType());
        res.setPetSize(entity.getPetSize());
        res.setService(entity.getService());
        res.setStartDate(entity.getStartDate());
        res.setEndDate(entity.getEndDate());
        res.setStartTime(entity.getStartTime());
        res.setEndTime(entity.getEndTime());
        res.setNotes(entity.getNotes());
        res.setTotalPrice(entity.getTotalPrice());
        res.setStatus(entity.getStatus());
        res.setRejectionReason(entity.getRejectionReason());
        res.setHasReview(hasReview);
        res.setCreatedAt(entity.getCreatedAt());
        res.setUpdatedAt(entity.getUpdatedAt());
        return res;
    }

    public ReviewResponse toReviewResponse(PetSitterReview entity) {
        if (entity == null) return null;
        ReviewResponse res = new ReviewResponse();
        res.setId(entity.getId());
        res.setSitterId(entity.getSitterId());
        res.setReservationId(entity.getReservationId());
        res.setOwnerId(entity.getOwnerId());
        res.setOwnerName(entity.getOwnerName());
        res.setRating(entity.getRating());
        res.setComment(entity.getComment());
        res.setCreatedAt(entity.getCreatedAt());
        return res;
    }
}
