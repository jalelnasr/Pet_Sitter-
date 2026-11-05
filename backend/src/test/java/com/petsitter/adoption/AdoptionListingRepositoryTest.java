package com.petsitter.adoption;

import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.adoption.repository.AdoptionListingRepository;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import jakarta.persistence.EntityManager;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifies the public listing query on an in-memory database (H2, test scope
 * only). MySQL is not required to run this test.
 */
@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.datasource.url=jdbc:h2:mem:petsitter-test;DB_CLOSE_DELAY=-1;MODE=MySQL",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password="
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class AdoptionListingRepositoryTest {

    @Autowired
    private AdoptionListingRepository listings;

    @Autowired
    private EntityManager entityManager;

    private UserEntity owner;

    @BeforeEach
    void setUp() {
        owner = new UserEntity(
                "OWNER_DEMO", "Amira", "amira@petsitter.test", UserRole.OWNER);
        entityManager.persist(owner);
        entityManager.flush();
    }

    @Test
    @DisplayName("20-21. Public queries exclude HIDDEN and ARCHIVED listings")
    void publicQueryExcludesHiddenAndArchived() {
        persistListing("PUBLIC", ListingStatus.PUBLISHED);
        persistListing("HIDDEN", ListingStatus.HIDDEN);
        persistListing("ARCHIVED", ListingStatus.ARCHIVED);
        persistListing("DRAFT", ListingStatus.DRAFT);
        entityManager.flush();

        Page<AdoptionListing> page = listings.searchPublic(
                ListingStatus.PUBLISHED, null, null, null, PageRequest.of(0, 20));

        assertThat(page.getContent())
                .extracting(AdoptionListing::getId)
                .containsExactly("PUBLIC");
    }

    @Test
    @DisplayName("Public queries support a species filter")
    void publicQueryFiltersBySpecies() {
        persistListing("CAT_LISTING", ListingStatus.PUBLISHED, PetSpecies.CAT);
        persistListing("DOG_LISTING", ListingStatus.PUBLISHED, PetSpecies.DOG);
        entityManager.flush();

        Page<AdoptionListing> page = listings.searchPublic(
                ListingStatus.PUBLISHED, PetSpecies.DOG, null, null, PageRequest.of(0, 20));

        assertThat(page.getContent())
                .extracting(AdoptionListing::getId)
                .containsExactly("DOG_LISTING");
    }

    private void persistListing(String id, ListingStatus status) {
        persistListing(id, status, PetSpecies.CAT);
    }

    private void persistListing(String id, ListingStatus status, PetSpecies species) {
        AdoptionListing listing = new AdoptionListing(id, owner);
        listing.setPetName("Milo " + id);
        listing.setSpecies(species);
        listing.setGender(PetGender.MALE);
        listing.setDescription("Friendly pet.");
        listing.setVaccinated(true);
        listing.setSterilized(false);
        listing.setLocation("Ariana");
        listing.setStatus(status);
        entityManager.persist(listing);
    }
}
