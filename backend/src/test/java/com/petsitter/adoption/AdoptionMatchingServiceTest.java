package com.petsitter.adoption;

import com.petsitter.adoption.ai.AdoptionAiClient;
import com.petsitter.adoption.ai.PythonMatchPayload;
import com.petsitter.adoption.dto.matching.MatchingAdviceRequest;
import com.petsitter.adoption.dto.matching.MatchingAdviceResponse;
import com.petsitter.adoption.entity.AdoptionListing;
import com.petsitter.adoption.enums.HousingType;
import com.petsitter.adoption.enums.ListingStatus;
import com.petsitter.adoption.enums.PetGender;
import com.petsitter.adoption.enums.PetSpecies;
import com.petsitter.adoption.service.AdoptionListingService;
import com.petsitter.adoption.service.AdoptionMatchingService;
import com.petsitter.common.exception.ServiceUnavailableException;
import com.petsitter.user.entity.UserEntity;
import com.petsitter.user.enums.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdoptionMatchingServiceTest {

    @Mock
    private AdoptionListingService listings;

    @Mock
    private AdoptionAiClient aiClient;

    private AdoptionMatchingService matching;

    @BeforeEach
    void setUp() {
        matching = new AdoptionMatchingService(listings, aiClient);
    }

    @Test
    void adviseReturnsPythonResult() {
        when(listings.find("LISTING_1")).thenReturn(listing());
        when(aiClient.match(any())).thenReturn(Optional.of(
                new MatchingAdviceResponse(81, "Bon match", List.of("Tip 1"), "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")));

        MatchingAdviceResponse response = matching.advise(new MatchingAdviceRequest(
                "LISTING_1", HousingType.APARTMENT, false, false, null,
                "Experience with cats", "Quiet home"));

        assertThat(response.score()).isEqualTo(81);
        ArgumentCaptor<PythonMatchPayload> captor = ArgumentCaptor.forClass(PythonMatchPayload.class);
        verify(aiClient).match(captor.capture());
        assertThat(captor.getValue().listing().species()).isEqualTo("CAT");
        assertThat(captor.getValue().candidate().experience()).contains("cats");
    }

    @Test
    void adviseFailsWhenPythonIsDown() {
        when(listings.find("LISTING_1")).thenReturn(listing());
        when(aiClient.match(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> matching.advise(new MatchingAdviceRequest(
                "LISTING_1", HousingType.HOUSE, true, false, null, "exp", "mot")))
                .isInstanceOf(ServiceUnavailableException.class);
    }

    private AdoptionListing listing() {
        UserEntity owner = new UserEntity("OWNER_DEMO", "Amira", "amira@petsitter.test", UserRole.OWNER);
        AdoptionListing listing = new AdoptionListing("LISTING_1", owner);
        listing.setPetName("Milo");
        listing.setSpecies(PetSpecies.CAT);
        listing.setBreed("Siamese");
        listing.setAge(2);
        listing.setGender(PetGender.MALE);
        listing.setDescription("Friendly cat.");
        listing.setVaccinated(true);
        listing.setSterilized(false);
        listing.setLocation("Ariana");
        listing.setStatus(ListingStatus.PUBLISHED);
        return listing;
    }
}
