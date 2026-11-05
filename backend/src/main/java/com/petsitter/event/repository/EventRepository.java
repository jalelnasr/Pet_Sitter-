package com.petsitter.event.repository;

import com.petsitter.event.entity.Event;
import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

public interface EventRepository extends JpaRepository<Event, String> {

    @Query("""
            select e from Event e
            where (:status is null or e.status = :status)
              and (:category is null or e.category = :category)
              and (
                   :query is null or :query = '' or
                   lower(e.title) like lower(concat('%', :query, '%')) or
                   lower(e.description) like lower(concat('%', :query, '%')) or
                   lower(e.location) like lower(concat('%', :query, '%'))
              )
              and (:minDate is null or e.date >= :minDate)
            order by e.date asc, e.startTime asc
            """)
    List<Event> search(
            @Param("status") EventStatus status,
            @Param("category") EventCategory category,
            @Param("query") String query,
            @Param("minDate") LocalDate minDate
    );

    @Query("""
            select e from Event e
            where e.status in :statuses
              and (:category is null or e.category = :category)
              and (
                   :query is null or :query = '' or
                   lower(e.title) like lower(concat('%', :query, '%')) or
                   lower(e.description) like lower(concat('%', :query, '%')) or
                   lower(e.location) like lower(concat('%', :query, '%'))
              )
              and (:minDate is null or e.date >= :minDate)
            order by e.date asc, e.startTime asc
            """)
    List<Event> searchWithStatuses(
            @Param("statuses") Collection<EventStatus> statuses,
            @Param("category") EventCategory category,
            @Param("query") String query,
            @Param("minDate") LocalDate minDate
    );

    List<Event> findByOrganizerIdOrderByDateDescCreatedAtDesc(String organizerId);

    List<Event> findByOrganizerIdOrderByCreatedAtDesc(String organizerId);

    List<Event> findByOrganizerIdAndStatusInOrderByCreatedAtDesc(String organizerId, Collection<EventStatus> statuses);

    long countByOrganizerIdAndStatus(String organizerId, EventStatus status);

    List<Event> findByStatusInOrderByCreatedAtDesc(Collection<EventStatus> statuses);

    List<Event> findByStatusOrderByCreatedAtDesc(EventStatus status);

    List<Event> findAllByOrderByDateAscStartTimeAsc();
}
