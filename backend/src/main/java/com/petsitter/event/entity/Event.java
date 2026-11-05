package com.petsitter.event.entity;

import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.EventVisibility;
import com.petsitter.user.entity.UserEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "events")
public class Event {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organizer_id", nullable = false)
    private UserEntity organizer;

    @NotBlank
    @Size(max = 160)
    @Column(name = "title", length = 160, nullable = false)
    private String title;

    @NotBlank
    @Size(max = 2000)
    @Column(name = "description", length = 2000, nullable = false)
    private String description;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "category", length = 30, nullable = false)
    private EventCategory category;

    @NotBlank
    @Size(max = 160)
    @Column(name = "location", length = 160, nullable = false)
    private String location;

    @NotNull
    @Column(name = "event_date", nullable = false)
    private LocalDate date;

    @NotNull
    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @NotNull
    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @NotNull
    @PositiveOrZero
    @Column(name = "capacity", nullable = false)
    private Integer capacity;

    @NotNull
    @PositiveOrZero
    @Column(name = "remaining_places", nullable = false)
    private Integer remainingPlaces;

    @Size(max = 500)
    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private EventStatus status;

    @Size(max = 1000)
    @Column(name = "rejection_reason", length = 1000)
    private String rejectionReason;

    @Column(nullable = true)
    private Double latitude;

    @Column(nullable = true)
    private Double longitude;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "visibility", length = 20, nullable = false)
    private EventVisibility visibility;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Event() {
        // JPA requirement
    }

    public Event(String id, UserEntity organizer) {
        this.id = id;
        this.organizer = organizer;
        this.status = EventStatus.PUBLISHED;
        this.visibility = EventVisibility.PUBLIC;
    }

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
        if (visibility == null) {
            visibility = EventVisibility.PUBLIC;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public LocalDateTime getStartDateTime() {
        return (date != null && startTime != null) ? LocalDateTime.of(date, startTime) : null;
    }

    public LocalDateTime getEndDateTime() {
        return (date != null && endTime != null) ? LocalDateTime.of(date, endTime) : null;
    }

    public int getCurrentParticipants() {
        return (capacity != null && remainingPlaces != null)
                ? Math.max(0, capacity - remainingPlaces)
                : 0;
    }

    // Getters and Setters

    public String getId() {
        return id;
    }

    public UserEntity getOrganizer() {
        return organizer;
    }

    public void setOrganizer(UserEntity organizer) {
        this.organizer = organizer;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public EventCategory getCategory() {
        return category;
    }

    public void setCategory(EventCategory category) {
        this.category = category;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalTime startTime) {
        this.startTime = startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalTime endTime) {
        this.endTime = endTime;
    }

    public Integer getCapacity() {
        return capacity;
    }

    public void setCapacity(Integer capacity) {
        this.capacity = capacity;
    }

    public Integer getRemainingPlaces() {
        return remainingPlaces;
    }

    public void setRemainingPlaces(Integer remainingPlaces) {
        this.remainingPlaces = remainingPlaces;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public EventStatus getStatus() {
        return status;
    }

    public void setStatus(EventStatus status) {
        this.status = status;
    }

    public EventVisibility getVisibility() {
        return visibility;
    }

    public void setVisibility(EventVisibility visibility) {
        this.visibility = visibility;
    }

    public boolean isCompleted() {
        if (status == EventStatus.COMPLETED) {
            return true;
        }
        LocalDateTime end = getEndDateTime();
        return status == EventStatus.PUBLISHED && end != null && end.isBefore(LocalDateTime.now());
    }

    public EventStatus getEffectiveStatus() {
        if (isCompleted()) {
            return EventStatus.COMPLETED;
        }
        return status;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
