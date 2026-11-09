package com.petsitter.store.product;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/** Format vendable (2 kg, taille M…) : c'est lui qui porte le prix et le stock. */
@Entity
@Table(name = "product_options")
public class ProductOption {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "product_id")
	private Product product;

	private String label;

	private int price;

	private int stock;

	@Column(name = "sort_order")
	private int sortOrder;

	private boolean active = true;

	protected ProductOption() {
	}

	ProductOption(Product product, String label) {
		this.product = product;
		this.label = label;
	}

	void update(int price, int stock, int sortOrder) {
		this.price = price;
		this.stock = stock;
		this.sortOrder = sortOrder;
		this.active = true;
	}

	void deactivate() {
		this.active = false;
	}

	public Long getId() {
		return id;
	}

	public Product getProduct() {
		return product;
	}

	public String getLabel() {
		return label;
	}

	public int getPrice() {
		return price;
	}

	public int getStock() {
		return stock;
	}

	public boolean isActive() {
		return active;
	}

}
