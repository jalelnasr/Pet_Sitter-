package com.petsitter.store.order;

import java.time.Instant;
import java.util.List;

import com.petsitter.store.order.OrderEnums.OrderStatus;
import com.petsitter.store.order.OrderEnums.PaymentMethod;
import com.petsitter.store.order.OrderEnums.PaymentStatus;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class OrderDtos {

	private OrderDtos() {
	}

	public record ItemRequest(@NotNull Long optionId, @Min(1) @Max(99) int quantity) {
	}

	/** Le client n'envoie jamais de prix : le serveur les relit dans le catalogue. */
	public record CreateOrderRequest(
			@NotEmpty(message = "Le panier est vide.") @Size(max = 50) List<@Valid ItemRequest> items,
			@NotNull PaymentMethod payment,
			@NotBlank(message = "Indiquez le destinataire.") @Size(max = 100) String recipient,
			@NotBlank @Pattern(regexp = "\\+?[0-9 ]{8,19}", message = "Numéro de téléphone invalide.") String phone,
			@NotBlank(message = "Indiquez l'adresse de livraison.") @Size(max = 255) String address,
			@NotBlank(message = "Indiquez la ville.") @Size(max = 100) String city) {
	}

	public record StatusRequest(@NotNull OrderStatus status) {
	}

	public record ItemResponse(String productId, String productName, Long optionId, String optionLabel, int unitPrice,
			int quantity, int lineTotal) {
	}

	public record EventResponse(OrderStatus status, Instant changedAt) {
	}

	public record OrderResponse(Long id, String number, String userId, OrderStatus status, PaymentMethod paymentMethod,
			PaymentStatus paymentStatus, int subtotal, int shipping, int total, int itemCount, String recipient,
			String phone, String address, String city, Instant createdAt, List<ItemResponse> items,
			List<EventResponse> history) {

		public static OrderResponse of(Order o) {
			return new OrderResponse(o.getId(), o.getNumber(), o.getUser().getId(), o.getStatus(), o.getPaymentMethod(),
					o.getPaymentStatus(), o.getSubtotal(), o.getShipping(), o.getTotal(),
					o.getItems().stream().mapToInt(OrderItem::getQuantity).sum(), o.getRecipient(), o.getPhone(),
					o.getAddress(), o.getCity(), o.getCreatedAt(),
					o.getItems().stream()
						.map(i -> new ItemResponse(i.getProductId(), i.getProductName(), i.getOptionId(), i.getOptionLabel(),
								i.getUnitPrice(), i.getQuantity(), i.getLineTotal()))
						.toList(),
					o.getHistory().stream().map(e -> new EventResponse(e.getStatus(), e.getChangedAt())).toList());
		}
	}

}
