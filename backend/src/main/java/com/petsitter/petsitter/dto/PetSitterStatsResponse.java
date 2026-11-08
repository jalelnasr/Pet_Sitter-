package com.petsitter.petsitter.dto;

import java.util.Map;

public class PetSitterStatsResponse {

    private long totalSitters;
    private long activeSitters;
    private long verifiedSitters;
    private long totalReservations;
    private Map<String, Long> reservationsByStatus;

    public PetSitterStatsResponse() {}

    public PetSitterStatsResponse(long totalSitters, long activeSitters, long verifiedSitters, long totalReservations, Map<String, Long> reservationsByStatus) {
        this.totalSitters = totalSitters;
        this.activeSitters = activeSitters;
        this.verifiedSitters = verifiedSitters;
        this.totalReservations = totalReservations;
        this.reservationsByStatus = reservationsByStatus;
    }

    public long getTotalSitters() { return totalSitters; }
    public void setTotalSitters(long totalSitters) { this.totalSitters = totalSitters; }

    public long getActiveSitters() { return activeSitters; }
    public void setActiveSitters(long activeSitters) { this.activeSitters = activeSitters; }

    public long getVerifiedSitters() { return verifiedSitters; }
    public void setVerifiedSitters(long verifiedSitters) { this.verifiedSitters = verifiedSitters; }

    public long getTotalReservations() { return totalReservations; }
    public void setTotalReservations(long totalReservations) { this.totalReservations = totalReservations; }

    public Map<String, Long> getReservationsByStatus() { return reservationsByStatus; }
    public void setReservationsByStatus(Map<String, Long> reservationsByStatus) { this.reservationsByStatus = reservationsByStatus; }
}
