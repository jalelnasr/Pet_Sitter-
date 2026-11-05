package com.petsitter.event.controller;

import com.petsitter.event.dto.ReservationResponse;
import com.petsitter.event.security.EventUserResolver;
import com.petsitter.event.service.EventReservationService;
import com.petsitter.user.entity.UserEntity;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/event-reservations")
@Tag(name = "Event Reservations", description = "Endpoints for managing event reservations")
public class EventReservationController {

    private final EventReservationService reservationService;
    private final EventUserResolver userResolver;

    public EventReservationController(
            EventReservationService reservationService,
            EventUserResolver userResolver
    ) {
        this.reservationService = reservationService;
        this.userResolver = userResolver;
    }

    @GetMapping("/mine")
    @Operation(summary = "List reservations made by current user")
    public List<ReservationResponse> mine(HttpServletRequest request) {
        UserEntity user = userResolver.resolve(request);
        return reservationService.myReservations(user);
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel a reservation")
    public ReservationResponse cancel(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity user = userResolver.resolve(request);
        return reservationService.cancel(id, user);
    }

    @PatchMapping("/{id}/cancel")
    @Operation(summary = "Cancel a reservation (compatibility)")
    public ReservationResponse cancelPatch(
            @PathVariable String id,
            HttpServletRequest request
    ) {
        UserEntity user = userResolver.resolve(request);
        return reservationService.cancel(id, user);
    }

    @GetMapping("/events/{eventId}")
    @Operation(summary = "List all reservations for an event (ADMIN only)")
    public List<ReservationResponse> forEvent(
            @PathVariable String eventId,
            HttpServletRequest request
    ) {
        UserEntity user = userResolver.resolve(request);
        return reservationService.eventReservations(eventId, user);
    }
}
