package com.petsitter.petsitter.service;

import com.petsitter.common.exception.BadRequestException;
import com.petsitter.common.exception.ResourceNotFoundException;
import com.petsitter.petsitter.dto.CreateReviewRequest;
import com.petsitter.petsitter.dto.ReviewResponse;
import com.petsitter.petsitter.entity.PetSitterProfile;
import com.petsitter.petsitter.entity.PetSitterReservation;
import com.petsitter.petsitter.entity.PetSitterReview;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.mapper.PetSitterMapper;
import com.petsitter.petsitter.repository.PetSitterProfileRepository;
import com.petsitter.petsitter.repository.PetSitterReservationRepository;
import com.petsitter.petsitter.repository.PetSitterReviewRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PetSitterReviewService {

    private final PetSitterReviewRepository reviewRepository;
    private final PetSitterProfileRepository profileRepository;
    private final PetSitterReservationRepository reservationRepository;
    private final PetSitterMapper mapper;

    public PetSitterReviewService(
            PetSitterReviewRepository reviewRepository,
            PetSitterProfileRepository profileRepository,
            PetSitterReservationRepository reservationRepository,
            PetSitterMapper mapper) {
        this.reviewRepository = reviewRepository;
        this.profileRepository = profileRepository;
        this.reservationRepository = reservationRepository;
        this.mapper = mapper;
    }

    @Transactional
    public ReviewResponse addReview(String sitterId, CreateReviewRequest req, String ownerId, String ownerName) {
        PetSitterProfile sitter = profileRepository.findById(sitterId)
                .orElseThrow(() -> new ResourceNotFoundException("Pet sitter introuvable : " + sitterId));

        if (req.getReservationId() != null && !req.getReservationId().isBlank()) {
            PetSitterReservation res = reservationRepository.findById(req.getReservationId())
                    .orElseThrow(() -> new ResourceNotFoundException("Réservation introuvable : " + req.getReservationId()));

            if (!res.getOwnerId().equalsIgnoreCase(ownerId)) {
                throw new BadRequestException("FORBIDDEN", "Vous ne pouvez laisser un avis que pour vos propres réservations.");
            }

            if (res.getStatus() != ReservationStatus.COMPLETED) {
                throw new BadRequestException("INVALID_STATUS", "Un avis ne peut être déposé que sur une réservation terminée.");
            }

            if (reviewRepository.findByReservationId(req.getReservationId()).isPresent()) {
                throw new BadRequestException("REVIEW_EXISTS", "Un avis a déjà été soumis pour cette réservation.");
            }
        }

        PetSitterReview review = new PetSitterReview();
        review.setSitterId(sitter.getId());
        review.setReservationId(req.getReservationId());
        review.setOwnerId(ownerId);
        review.setOwnerName(ownerName != null ? ownerName : "Propriétaire");
        review.setRating(req.getRating());
        review.setComment(req.getComment() != null ? req.getComment().trim() : "");

        PetSitterReview saved = reviewRepository.save(review);
        recalculateSitterRating(sitter);

        return mapper.toReviewResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> listBySitter(String sitterId) {
        return reviewRepository.findBySitterIdOrderByCreatedAtDesc(sitterId).stream()
                .map(mapper::toReviewResponse)
                .toList();
    }

    @Transactional
    public void deleteReview(String reviewId, String currentUserId, boolean isAdmin) {
        PetSitterReview review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Avis introuvable : " + reviewId));

        if (!isAdmin && !review.getOwnerId().equalsIgnoreCase(currentUserId)) {
            throw new BadRequestException("FORBIDDEN", "Vous ne pouvez supprimer que votre propre avis.");
        }

        String sitterId = review.getSitterId();
        reviewRepository.delete(review);

        profileRepository.findById(sitterId).ifPresent(this::recalculateSitterRating);
    }

    private void recalculateSitterRating(PetSitterProfile sitter) {
        List<PetSitterReview> reviews = reviewRepository.findBySitterIdOrderByCreatedAtDesc(sitter.getId());
        if (reviews.isEmpty()) {
            sitter.setAverageRating(0.0);
            sitter.setReviewsCount(0);
        } else {
            double sum = 0.0;
            for (PetSitterReview r : reviews) {
                sum += r.getRating();
            }
            double avg = Math.round((sum / reviews.size()) * 10.0) / 10.0;
            sitter.setAverageRating(avg);
            sitter.setReviewsCount(reviews.size());
        }
        profileRepository.save(sitter);
    }
}
