package com.petsitter.store.product;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public final class ProductDtos {

	private ProductDtos() {
	}

	public record OptionRequest(@NotBlank @Size(max = 60) String label, @Positive @Max(1000000) int price,
			@PositiveOrZero @Max(1000000) int stock) {
	}

	public record DetailDto(@NotBlank @Size(max = 60) String label, @NotBlank @Size(max = 255) String value) {
	}

	public record ProductRequest(
			@NotBlank @Size(max = 150) String name,
			@NotBlank @Size(max = 100) String brand,
			@NotNull ShopCategory category,
			@NotEmpty Set<Species> species,
			@NotBlank @Size(max = 2000) String description,
			@NotEmpty List<@Valid OptionRequest> options,
			List<@Valid DetailDto> details,
			@Positive Integer oldPrice,
			@Size(max = 40) String badge,
			@NotNull PackKind packKind,
			@NotNull @Pattern(regexp = "#[0-9A-Fa-f]{6}") String color,
			@NotNull @Pattern(regexp = "#[0-9A-Fa-f]{6}") String tint,
			@NotBlank @Size(max = 40) String icon,
			@Size(max = 500) String imageUrl) {
	}

	public record CreateProductRequest(
			@NotNull @Pattern(regexp = "[a-z0-9-]{2,60}", message = "Identifiant : minuscules, chiffres et tirets.") String id,
			@NotNull @Valid ProductRequest product) {
	}

	public record ImageResponse(String url) {
	}

	public record OptionResponse(Long id, String label, int price, int stock) {
	}

	public record ProductResponse(String id, String name, String brand, ShopCategory category, Set<Species> species,
			List<OptionResponse> options, BigDecimal rating, int reviews, PackKind packKind, String color, String tint,
			String icon, String imageUrl, String description, List<DetailDto> details, Integer oldPrice, String badge,
			boolean active) {

		public static ProductResponse of(Product p) {
			return new ProductResponse(p.getId(), p.getName(), p.getBrand(), p.getCategory(), new TreeSet<>(p.getSpecies()),
					p.getOptions().stream().filter(ProductOption::isActive)
						.map(o -> new OptionResponse(o.getId(), o.getLabel(), o.getPrice(), o.getStock())).toList(),
					p.getRating(), p.getReviews(), p.getPackKind(), p.getColor(), p.getTint(), p.getIcon(), p.getImageUrl(),
					p.getDescription(), p.getDetails().stream().map(d -> new DetailDto(d.getLabel(), d.getValue())).toList(),
					p.getOldPrice(), p.getBadge(), p.isActive());
		}
	}

	public record PageResponse<T>(List<T> items, int page, int size, long totalItems, int totalPages) {
		public static <T> PageResponse<T> of(org.springframework.data.domain.Page<T> p) {
			return new PageResponse<>(p.getContent(), p.getNumber(), p.getSize(), p.getTotalElements(), p.getTotalPages());
		}
	}

}
