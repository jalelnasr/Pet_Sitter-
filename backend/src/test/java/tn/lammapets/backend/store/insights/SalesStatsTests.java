package tn.lammapets.backend.store.insights;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.Test;

import tn.lammapets.backend.store.insights.SalesCommentator.Commentary;
import tn.lammapets.backend.store.insights.SalesDtos.LowStock;
import tn.lammapets.backend.store.insights.SalesDtos.SalesStats;

class SalesStatsTests {

	@Test
	void changeIsRoundedAndUnknownWithoutPreviousSales() {
		assertThat(SalesStatsService.changePercent(120, 100)).isEqualTo(20);
		assertThat(SalesStatsService.changePercent(50, 100)).isEqualTo(-50);
		assertThat(SalesStatsService.changePercent(80, 0)).isNull();
	}

	@Test
	void demoCommentaryUsesOnlyTheGivenNumbers() {
		SalesStats s = new SalesStats(7, Instant.now(), Instant.now(), 3, 210, 100, 110, 70, 1, 5, List.of(),
				List.of(new LowStock("p", "Croquettes", "2 kg", 2)));
		Commentary c = new DemoSalesCommentator().comment(s);
		assertThat(c.summary()).contains("3 commandes").contains("210 DT").contains("+110 %");
		assertThat(c.points()).hasSize(2);
		assertThat(c.points().get(0)).contains("Croquettes · 2 kg").contains("2 restants");
	}

	@Test
	void theTextSentToTheProviderHasNoCustomerData() {
		SalesStats s = new SalesStats(30, Instant.now(), Instant.now(), 0, 0, 0, null, 0, 0, 0, List.of(), List.of());
		assertThat(SalesCommentator.describe(s)).contains("non calculable").doesNotContain("@");
	}

}
