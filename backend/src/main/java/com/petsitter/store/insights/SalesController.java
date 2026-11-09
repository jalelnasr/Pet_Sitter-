package com.petsitter.store.insights;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.store.insights.SalesDtos.SalesSummaryResponse;
import com.petsitter.user.enums.UserRole;

import jakarta.servlet.http.HttpServletRequest;

@RestController
public class SalesController {

	private final SalesSummaryService service;

	private final CurrentUserResolver users;

	public SalesController(SalesSummaryService service, CurrentUserResolver users) {
		this.service = service;
		this.users = users;
	}

	@GetMapping("/api/admin/sales-summary")
	SalesSummaryResponse summary(HttpServletRequest request, @RequestParam(defaultValue = "7") int days) {
		users.requireRole(request, UserRole.ADMIN);
		return service.summary(days);
	}

}
