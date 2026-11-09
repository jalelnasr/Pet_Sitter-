package com.petsitter.store.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import com.petsitter.store.product.ProductOption;

@Entity
@Table(name = "order_items")
public class OrderItem {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "order_id")
	private Order order;

	@Column(name = "option_id")
	private Long optionId;

	@Column(name = "product_id", length = 60)
	private String productId;

	@Column(name = "product_name")
	private String productName;

	@Column(name = "option_label")
	private String optionLabel;

	@Column(name = "unit_price")
	private int unitPrice;

	private int quantity;

	protected OrderItem() {
	}

	OrderItem(Order order, ProductOption option, int quantity) {
		this.order = order;
		this.optionId = option.getId();
		this.productId = option.getProduct().getId();
		this.productName = option.getProduct().getName();
		this.optionLabel = option.getLabel();
		this.unitPrice = option.getPrice();
		this.quantity = quantity;
	}

	public Long getOptionId() {
		return optionId;
	}

	public String getProductId() {
		return productId;
	}

	public String getProductName() {
		return productName;
	}

	public String getOptionLabel() {
		return optionLabel;
	}

	public int getUnitPrice() {
		return unitPrice;
	}

	public int getQuantity() {
		return quantity;
	}

	public int getLineTotal() {
		return unitPrice * quantity;
	}

}
