package com.petsitter.config;

import com.petsitter.petsitter.entity.PetSitterProfile;
import com.petsitter.petsitter.entity.PetSitterReservation;
import com.petsitter.petsitter.entity.PetSitterReview;
import com.petsitter.petsitter.enums.PetSizeType;
import com.petsitter.petsitter.enums.PetSpeciesType;
import com.petsitter.petsitter.enums.ReservationStatus;
import com.petsitter.petsitter.enums.SitterServiceType;
import com.petsitter.petsitter.repository.PetSitterProfileRepository;
import com.petsitter.petsitter.repository.PetSitterReservationRepository;
import com.petsitter.petsitter.repository.PetSitterReviewRepository;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import com.petsitter.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;

@Configuration
public class PetSitterDataInitializer {

    private static final Logger log = LoggerFactory.getLogger(PetSitterDataInitializer.class);

    @Bean
    @Order(30)
    CommandLineRunner seedPetSitters(
            UserRepository userRepository,
            PetSitterProfileRepository profileRepository,
            PetSitterReservationRepository reservationRepository,
            PetSitterReviewRepository reviewRepository
    ) {
        return args -> {
            // Assurer la présence des utilisateurs statiques demandés
            seedUser(userRepository, new UserEntity("admin", "Admin", "admin@petsitter.tn", UserRole.ADMIN));
            seedUser(userRepository, new UserEntity("sami", "Sami", "sami@petsitter.tn", UserRole.OWNER));
            seedUser(userRepository, new UserEntity("samira", "Samira", "samira@petsitter.tn", UserRole.PETSITTER));

            if (profileRepository.count() > 0) {
                log.info("Pet sitters déjà présents en base, étape de seed ignorée.");
                return;
            }

            log.info("Initialisation des données de démonstration Pet Sitters...");

            // 1. Samira Ben Salem (Tunis - La Marsa) - liée à 'samira' et utilisable aussi avec 'PETSITTER_DEMO'
            PetSitterProfile s1 = new PetSitterProfile("sitter-samira-tunis");
            s1.setUserId("samira");
            s1.setFullName("Samira Ben Salem");
            s1.setBio("Passionnée par les animaux depuis mon enfance, j'ai 6 ans d'expérience en garde de chiens et chats. Maison spacieuse avec grand jardin clos à La Marsa, promenades quotidiennes à la plage.");
            s1.setGovernorate("Tunis");
            s1.setCity("La Marsa");
            s1.setAddress("Avenue Habib Bourguiba, La Marsa Corniche");
            s1.setPhone("+216 22 111 222");
            s1.setPhotoUrl("https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&auto=format&fit=crop&q=80");
            s1.setGallery(List.of(
                    "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800&auto=format&fit=crop&q=80",
                    "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800&auto=format&fit=crop&q=80"
            ));
            s1.setExperienceYears(6);
            s1.setPricePerHour(15.0);
            s1.setPricePerDay(45.0);
            s1.setServices(Set.of(SitterServiceType.BOARDING, SitterServiceType.HOME_VISIT, SitterServiceType.WALKING));
            s1.setAcceptedPetTypes(Set.of(PetSpeciesType.CAT, PetSpeciesType.DOG, PetSpeciesType.BIRD));
            s1.setAcceptedSizes(Set.of(PetSizeType.SMALL, PetSizeType.MEDIUM));
            s1.setHasGarden(true);
            s1.setHasOwnPets(true);
            s1.setAvailability("Tous les jours de 8h à 19h");
            s1.setVerified(true);
            s1.setActive(true);
            s1.setAverageRating(4.9);
            s1.setReviewsCount(3);
            profileRepository.save(s1);

            // 2. Mehdi Chaabane (Ariana - Ennasr)
            PetSitterProfile s2 = new PetSitterProfile("sitter-mehdi-ariana");
            s2.setUserId("sitter_mehdi");
            s2.setFullName("Mehdi Chaabane");
            s2.setBio("Éducateur canin certifié à Ennasr 2. J'accueille vos chiens pour des promenades dynamiques au parc et des séances de jeu. Soins attentifs et nouvelles quotidiennes par photos.");
            s2.setGovernorate("Ariana");
            s2.setCity("Ennasr 2");
            s2.setAddress("Rue Hédi Nouira, Ennasr 2");
            s2.setPhone("+216 98 333 444");
            s2.setPhotoUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&auto=format&fit=crop&q=80");
            s2.setGallery(List.of(
                    "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800&auto=format&fit=crop&q=80"
            ));
            s2.setExperienceYears(4);
            s2.setPricePerHour(12.0);
            s2.setPricePerDay(38.0);
            s2.setServices(Set.of(SitterServiceType.WALKING, SitterServiceType.DAY_CARE));
            s2.setAcceptedPetTypes(Set.of(PetSpeciesType.DOG));
            s2.setAcceptedSizes(Set.of(PetSizeType.SMALL, PetSizeType.MEDIUM, PetSizeType.LARGE));
            s2.setHasGarden(false);
            s2.setHasOwnPets(true);
            s2.setAvailability("En semaine et week-ends sur réservation");
            s2.setVerified(true);
            s2.setActive(true);
            s2.setAverageRating(4.8);
            s2.setReviewsCount(2);
            profileRepository.save(s2);

            // 3. Yasmine Trabelsi (Sousse - Kantaoui)
            PetSitterProfile s3 = new PetSitterProfile("sitter-yasmine-sousse");
            s3.setUserId("sitter_yasmine");
            s3.setFullName("Yasmine Trabelsi");
            s3.setBio("Étudiante en médecine vétérinaire à Sousse. Soins médicaux, administration de traitements et hébergement douillet pour chats, lapins et oiseaux.");
            s3.setGovernorate("Sousse");
            s3.setCity("Port El Kantaoui");
            s3.setAddress("Zone touristique El Kantaoui");
            s3.setPhone("+216 24 555 666");
            s3.setPhotoUrl("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80");
            s3.setExperienceYears(3);
            s3.setPricePerHour(10.0);
            s3.setPricePerDay(35.0);
            s3.setServices(Set.of(SitterServiceType.BOARDING, SitterServiceType.GROOMING, SitterServiceType.HOME_VISIT));
            s3.setAcceptedPetTypes(Set.of(PetSpeciesType.CAT, PetSpeciesType.RABBIT, PetSpeciesType.OTHER));
            s3.setAcceptedSizes(Set.of(PetSizeType.SMALL));
            s3.setHasGarden(true);
            s3.setHasOwnPets(false);
            s3.setAvailability("Disponible 7j/7 pendant les vacances");
            s3.setVerified(true);
            s3.setActive(true);
            s3.setAverageRating(5.0);
            s3.setReviewsCount(1);
            profileRepository.save(s3);

            // 4. Karim Bouazizi (Sfax - Route de Téniour)
            PetSitterProfile s4 = new PetSitterProfile("sitter-karim-sfax");
            s4.setUserId("sitter_karim");
            s4.setFullName("Karim Bouazizi");
            s4.setBio("Amoureux des grands chiens, grand terrain sécurisé à Sfax. Expérience de 8 ans avec les chiens de grande taille (Berger Allemand, Golden, etc.). Véhicule équipé pour transport vétérinaire.");
            s4.setGovernorate("Sfax");
            s4.setCity("Route de Téniour");
            s4.setAddress("Km 4 Route de Téniour, Sfax");
            s4.setPhone("+216 55 777 888");
            s4.setPhotoUrl("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&auto=format&fit=crop&q=80");
            s4.setExperienceYears(8);
            s4.setPricePerHour(14.0);
            s4.setPricePerDay(40.0);
            s4.setServices(Set.of(SitterServiceType.BOARDING, SitterServiceType.WALKING, SitterServiceType.VET_TRANSPORT));
            s4.setAcceptedPetTypes(Set.of(PetSpeciesType.DOG, PetSpeciesType.CAT));
            s4.setAcceptedSizes(Set.of(PetSizeType.SMALL, PetSizeType.MEDIUM, PetSizeType.LARGE, PetSizeType.GIANT));
            s4.setHasGarden(true);
            s4.setHasOwnPets(true);
            s4.setAvailability("Disponible toute l'année");
            s4.setVerified(false);
            s4.setActive(true);
            s4.setAverageRating(4.6);
            s4.setReviewsCount(2);
            profileRepository.save(s4);

            // 5. Ines Jaziri (Nabeul - Hammamet)
            PetSitterProfile s5 = new PetSitterProfile("sitter-ines-nabeul");
            s5.setUserId("sitter_ines");
            s5.setFullName("Ines Jaziri");
            s5.setBio("Douce et attentionnée, je me déplace à votre domicile pour nourrir vos chats et petits compagnons, nettoyer les litières et passer du temps de câlins.");
            s5.setGovernorate("Nabeul");
            s5.setCity("Hammamet Nord");
            s5.setAddress("Avenue des Nations Unies, Hammamet");
            s5.setPhone("+216 29 000 111");
            s5.setPhotoUrl("https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80");
            s5.setExperienceYears(5);
            s5.setPricePerHour(10.0);
            s5.setPricePerDay(30.0);
            s5.setServices(Set.of(SitterServiceType.DAY_CARE, SitterServiceType.HOME_VISIT, SitterServiceType.WALKING));
            s5.setAcceptedPetTypes(Set.of(PetSpeciesType.CAT, PetSpeciesType.BIRD, PetSpeciesType.RABBIT));
            s5.setAcceptedSizes(Set.of(PetSizeType.SMALL, PetSizeType.MEDIUM));
            s5.setHasGarden(true);
            s5.setHasOwnPets(false);
            s5.setAvailability("Matinée et fin d'après-midi");
            s5.setVerified(true);
            s5.setActive(true);
            s5.setAverageRating(4.7);
            s5.setReviewsCount(2);
            profileRepository.save(s5);

            // 6. Bilel Gharbi (Bizerte - Corniche)
            PetSitterProfile s6 = new PetSitterProfile("sitter-bilel-bizerte");
            s6.setUserId("sitter_bilel");
            s6.setFullName("Bilel Gharbi");
            s6.setBio("Je garde vos compagnons dans un cadre familial au bord de la mer à Bizerte. Baignades surveillées et jeux de plein air assurés.");
            s6.setGovernorate("Bizerte");
            s6.setCity("Corniche de Bizerte");
            s6.setAddress("Boulevard Hassan Nouri, Bizerte");
            s6.setPhone("+216 93 222 333");
            s6.setPhotoUrl("https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=600&auto=format&fit=crop&q=80");
            s6.setExperienceYears(2);
            s6.setPricePerHour(12.0);
            s6.setPricePerDay(36.0);
            s6.setServices(Set.of(SitterServiceType.BOARDING, SitterServiceType.DAY_CARE, SitterServiceType.VET_TRANSPORT));
            s6.setAcceptedPetTypes(Set.of(PetSpeciesType.DOG, PetSpeciesType.CAT));
            s6.setAcceptedSizes(Set.of(PetSizeType.SMALL, PetSizeType.MEDIUM));
            s6.setHasGarden(false);
            s6.setHasOwnPets(true);
            s6.setAvailability("Week-ends et jours fériés");
            s6.setVerified(false);
            s6.setActive(true);
            s6.setAverageRating(4.5);
            s6.setReviewsCount(1);
            profileRepository.save(s6);

            // Seed des réservations de test
            PetSitterReservation r1 = new PetSitterReservation("res-1");
            r1.setSitterId(s1.getId());
            r1.setOwnerId("sami");
            r1.setPetName("Simba");
            r1.setPetType(PetSpeciesType.CAT);
            r1.setPetSize(PetSizeType.SMALL);
            r1.setService(SitterServiceType.BOARDING);
            r1.setStartDate(LocalDate.now().plusDays(2));
            r1.setEndDate(LocalDate.now().plusDays(5));
            r1.setNotes("Simba prend des croquettes spécifiques le matin et aime les siestes au soleil.");
            r1.setTotalPrice(180.0);
            r1.setStatus(ReservationStatus.PENDING);
            reservationRepository.save(r1);

            PetSitterReservation r2 = new PetSitterReservation("res-2");
            r2.setSitterId(s2.getId());
            r2.setOwnerId("sami");
            r2.setPetName("Rocky");
            r2.setPetType(PetSpeciesType.DOG);
            r2.setPetSize(PetSizeType.MEDIUM);
            r2.setService(SitterServiceType.WALKING);
            r2.setStartDate(LocalDate.now().plusDays(7));
            r2.setEndDate(LocalDate.now().plusDays(9));
            r2.setStartTime(LocalTime.of(10, 0));
            r2.setEndTime(LocalTime.of(12, 0));
            r2.setNotes("Rocky tire un peu en laisse au début de la balade.");
            r2.setTotalPrice(72.0);
            r2.setStatus(ReservationStatus.ACCEPTED);
            reservationRepository.save(r2);

            PetSitterReservation r3 = new PetSitterReservation("res-3");
            r3.setSitterId(s1.getId());
            r3.setOwnerId("sami");
            r3.setPetName("Simba");
            r3.setPetType(PetSpeciesType.CAT);
            r3.setPetSize(PetSizeType.SMALL);
            r3.setService(SitterServiceType.BOARDING);
            r3.setStartDate(LocalDate.now().minusDays(10));
            r3.setEndDate(LocalDate.now().minusDays(7));
            r3.setNotes("Première garde de Simba.");
            r3.setTotalPrice(180.0);
            r3.setStatus(ReservationStatus.COMPLETED);
            reservationRepository.save(r3);

            // Avis sur la réservation r3
            PetSitterReview rev1 = new PetSitterReview("rev-1");
            rev1.setSitterId(s1.getId());
            rev1.setReservationId(r3.getId());
            rev1.setOwnerId("sami");
            rev1.setOwnerName("Sami");
            rev1.setRating(5);
            rev1.setComment("Samira s'est merveilleusement bien occupée de Simba ! Des photos et vidéos tous les jours, un cadre très propre et apaisant. Je recommande les yeux fermés.");
            reviewRepository.save(rev1);

            PetSitterReview rev2 = new PetSitterReview("rev-2");
            rev2.setSitterId(s1.getId());
            rev2.setReservationId(null);
            rev2.setOwnerId("Amira");
            rev2.setOwnerName("Amira");
            rev2.setRating(5);
            rev2.setComment("Très professionnelle et gentille avec mes animaux. Une confiance totale.");
            reviewRepository.save(rev2);

            PetSitterReview rev3 = new PetSitterReview("rev-3");
            rev3.setSitterId(s1.getId());
            rev3.setReservationId(null);
            rev3.setOwnerId("Youssef");
            rev3.setOwnerName("Youssef");
            rev3.setRating(5);
            rev3.setComment("Parfait pour mon chat qui est plutôt craintif, il était très à l'aise.");
            reviewRepository.save(rev3);

            log.info("Données Pet Sitters et réservations initialisées avec succès !");
        };
    }

    private void seedUser(UserRepository users, UserEntity user) {
        if (!users.existsById(user.getId())) {
            users.save(user);
            log.info("Utilisateur statique créé : {} ({})", user.getId(), user.getRole());
        }
    }
}
