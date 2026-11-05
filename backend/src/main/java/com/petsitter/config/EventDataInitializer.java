package com.petsitter.config;

import com.petsitter.event.entity.Event;
import com.petsitter.event.entity.EventReservation;
import com.petsitter.event.enums.EventCategory;
import com.petsitter.event.enums.EventStatus;
import com.petsitter.event.enums.EventVisibility;
import com.petsitter.event.enums.ReservationStatus;
import com.petsitter.event.repository.EventRepository;
import com.petsitter.event.repository.EventReservationRepository;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;

@Configuration
public class EventDataInitializer {

    private static final Logger log = LoggerFactory.getLogger(EventDataInitializer.class);

    @Bean
    @Order(20)
    CommandLineRunner seedDemoEvents(
            EventRepository eventRepository,
            EventReservationRepository reservationRepository,
            UserRepository userRepository
    ) {
        return args -> {
            if (eventRepository.count() > 0) {
                log.info("Events table is not empty, skipping event seed.");
                return;
            }

            Optional<UserEntity> adminOpt = userRepository.findById("ADMIN_DEMO");
            Optional<UserEntity> petsitterOpt = userRepository.findById("PETSITTER_DEMO");
            Optional<UserEntity> ownerOpt = userRepository.findById("OWNER_DEMO");

            if (adminOpt.isEmpty() || petsitterOpt.isEmpty() || ownerOpt.isEmpty()) {
                log.warn("Demo users not available, skipping event seed.");
                return;
            }

            UserEntity admin = adminOpt.get();
            UserEntity petsitter = petsitterOpt.get();
            UserEntity owner = ownerOpt.get();

            // 1. Adoption Day (PUBLISHED, organized by ADMIN_DEMO)
            Event adoptionDay = new Event("adoption-day", admin);
            adoptionDay.setTitle("Adoption Day");
            adoptionDay.setDescription("Une journée portes ouvertes pour rencontrer les chats et les chiens du refuge. Les bénévoles présentent chaque animal, son caractère et ses besoins, puis organisent des rencontres calmes avec les familles intéressées. Stands conseils sur les premiers jours à la maison, la stérilisation et les soins vétérinaires.");
            adoptionDay.setCategory(EventCategory.ADOPTION);
            adoptionDay.setLocation("Parc de la Marsa, Tunis");
            adoptionDay.setDate(LocalDate.now().plusDays(7));
            adoptionDay.setStartTime(LocalTime.of(10, 0));
            adoptionDay.setEndTime(LocalTime.of(17, 0));
            adoptionDay.setCapacity(40);
            adoptionDay.setRemainingPlaces(37); // 3 reserved (2 by owner, 1 by petsitter)
            adoptionDay.setImageUrl("https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=900&q=80&fm=jpg&fit=crop");
            adoptionDay.setStatus(EventStatus.PUBLISHED);
            adoptionDay.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(adoptionDay);

            // 2. Dog Training Workshop (PUBLISHED, organized by ADMIN_DEMO)
            Event dogTraining = new Event("dog-training", admin);
            dogTraining.setTitle("Dog Training Workshop");
            dogTraining.setDescription("Atelier pratique pour apprendre les ordres de base : assis, au pied, rappel et marche en laisse sans tirer. Les exercices se font en petits groupes avec des éducateurs canins bénévoles. Prévoyez une laisse, des friandises et de l'eau pour votre chien.");
            dogTraining.setCategory(EventCategory.TRAINING);
            dogTraining.setLocation("Parc du Belvédère, Tunis");
            dogTraining.setDate(LocalDate.now().plusDays(14));
            dogTraining.setStartTime(LocalTime.of(9, 30));
            dogTraining.setEndTime(LocalTime.of(12, 30));
            dogTraining.setCapacity(20);
            dogTraining.setRemainingPlaces(19); // 1 reserved by owner
            dogTraining.setImageUrl("https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=900&q=80&fm=jpg&fit=crop");
            dogTraining.setStatus(EventStatus.PUBLISHED);
            dogTraining.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(dogTraining);

            // 3. Pet Meetup (PUBLISHED, organized by ADMIN_DEMO)
            Event petMeetup = new Event("pet-meetup", admin);
            petMeetup.setTitle("Pet Meetup au Belvédère");
            petMeetup.setDescription("Rencontre conviviale entre propriétaires d'animaux. Au programme : échanges d'expériences, conseils de sociabilisation et jeux interactifs pour vos compagnons.");
            petMeetup.setCategory(EventCategory.MEETUP);
            petMeetup.setLocation("Parc du Belvédère, Tunis");
            petMeetup.setDate(LocalDate.now().plusDays(21));
            petMeetup.setStartTime(LocalTime.of(15, 0));
            petMeetup.setEndTime(LocalTime.of(18, 0));
            petMeetup.setCapacity(30);
            petMeetup.setRemainingPlaces(30);
            petMeetup.setImageUrl("https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=900&q=80&fm=jpg&fit=crop");
            petMeetup.setStatus(EventStatus.PUBLISHED);
            petMeetup.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(petMeetup);

            // 4. Chiens & Cafés (DRAFT, organized by ADMIN_DEMO)
            Event draftEvent = new Event("chiens-et-cafes", admin);
            draftEvent.setTitle("Chiens & Cafés");
            draftEvent.setDescription("Petit-déjeuner entre propriétaires de chiens dans une terrasse accueillante. Échange de bonnes adresses et de conseils.");
            draftEvent.setCategory(EventCategory.MEETUP);
            draftEvent.setLocation("Café El Manara, Tunis");
            draftEvent.setDate(LocalDate.now().plusDays(28));
            draftEvent.setStartTime(LocalTime.of(9, 0));
            draftEvent.setEndTime(LocalTime.of(11, 0));
            draftEvent.setCapacity(15);
            draftEvent.setRemainingPlaces(15);
            draftEvent.setImageUrl("https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=900&q=80&fm=jpg&fit=crop");
            draftEvent.setStatus(EventStatus.DRAFT);
            draftEvent.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(draftEvent);

            // 5. PENDING proposal by PETSITTER_DEMO (Sami)
            Event pendingProposal = new Event("proposal-sidi-bou-said", petsitter);
            pendingProposal.setTitle("Balade Collective à Sidi Bou Saïd");
            pendingProposal.setDescription("Une promenade matinale le long des ruelles et belvédères de Sidi Bou Saïd avec nos chiens en laisse. Rythme tranquille adapté à tous les chiens.");
            pendingProposal.setCategory(EventCategory.WALK);
            pendingProposal.setLocation("Sidi Bou Saïd, Tunis");
            pendingProposal.setDate(LocalDate.now().plusDays(10));
            pendingProposal.setStartTime(LocalTime.of(8, 30));
            pendingProposal.setEndTime(LocalTime.of(10, 30));
            pendingProposal.setCapacity(12);
            pendingProposal.setRemainingPlaces(12);
            pendingProposal.setImageUrl("https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=900&q=80&fm=jpg&fit=crop");
            pendingProposal.setStatus(EventStatus.PENDING);
            pendingProposal.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(pendingProposal);

            // 6. REJECTED proposal by PETSITTER_DEMO (Sami)
            Event rejectedProposal = new Event("proposal-toilettage-express", petsitter);
            rejectedProposal.setTitle("Atelier Toilettage et Soins Express");
            rejectedProposal.setDescription("Initiation au brossage, à la coupe des griffes et aux soins d'hygiène de base.");
            rejectedProposal.setCategory(EventCategory.TRAINING);
            rejectedProposal.setLocation("Centre Ville, Tunis");
            rejectedProposal.setDate(LocalDate.now().plusDays(5));
            rejectedProposal.setStartTime(LocalTime.of(14, 0));
            rejectedProposal.setEndTime(LocalTime.of(16, 0));
            rejectedProposal.setCapacity(10);
            rejectedProposal.setRemainingPlaces(10);
            rejectedProposal.setImageUrl("https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=900&q=80&fm=jpg&fit=crop");
            rejectedProposal.setStatus(EventStatus.REJECTED);
            rejectedProposal.setRejectionReason("Le local choisi ne permet pas d'accueillir des grands chiens en toute sécurité.");
            rejectedProposal.setVisibility(EventVisibility.PUBLIC);
            eventRepository.save(rejectedProposal);

            // Reservations
            // Owner Amira reserved 2 places on Adoption Day
            EventReservation res1 = new EventReservation("res-owner-adoption", adoptionDay, owner);
            res1.setParticipantName("Amira");
            res1.setPhone("+216 98 123 456");
            res1.setNumberOfPlaces(2);
            res1.setComment("Nous venons en famille avec notre fille.");
            res1.setStatus(ReservationStatus.CONFIRMED);
            reservationRepository.save(res1);

            // Petsitter Sami reserved 1 place on Adoption Day
            EventReservation res2 = new EventReservation("res-petsitter-adoption", adoptionDay, petsitter);
            res2.setParticipantName("Sami");
            res2.setPhone("+216 98 654 321");
            res2.setNumberOfPlaces(1);
            res2.setComment("Je viens pour donner un coup de main aux bénévoles.");
            res2.setStatus(ReservationStatus.CONFIRMED);
            reservationRepository.save(res2);

            // Owner Amira reserved 1 place on Dog Training
            EventReservation res3 = new EventReservation("res-owner-training", dogTraining, owner);
            res3.setParticipantName("Amira");
            res3.setPhone("+216 98 123 456");
            res3.setNumberOfPlaces(1);
            res3.setComment("Pour mon jeune chiot.");
            res3.setStatus(ReservationStatus.CONFIRMED);
            reservationRepository.save(res3);

            log.info("Successfully seeded demo events, proposals, and reservations.");
        };
    }
}
