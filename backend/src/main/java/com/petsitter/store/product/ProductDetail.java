package com.petsitter.store.product;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class ProductDetail {

	@Column(name = "detail_label")
	private String label;

	@Column(name = "detail_value")
	private String value;

	protected ProductDetail() {
	}

	public ProductDetail(String label, String value) {
		this.label = label;
		this.value = value;
	}

	public String getLabel() {
		return label;
	}

	public String getValue() {
		return value;
	}

}
