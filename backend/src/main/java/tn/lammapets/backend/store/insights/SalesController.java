package tn.lammapets.backend.store.insights;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import tn.lammapets.backend.store.insights.SalesDtos.SalesSummaryResponse;

@RestController
public class SalesController {

	private final SalesSummaryService service;

	public SalesController(SalesSummaryService service) {
		this.service = service;
	}

	@GetMapping("/api/admin/sales-summary")
	SalesSummaryResponse summary(@RequestParam(defaultValue = "7") int days) {
		return service.summary(days);
	}

}
