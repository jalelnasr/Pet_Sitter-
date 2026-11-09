package com.petsitter.store.order;

import java.time.Instant;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

import com.petsitter.store.order.OrderEnums.OrderStatus;

@Embeddable
public class StatusEvent {

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private OrderStatus status;

	@Column(name = "changed_at")
	private Instant changedAt;

	protected StatusEvent() {
	}

	StatusEvent(OrderStatus status) {
		this.status = status;
		this.changedAt = Instant.now();
	}

	public OrderStatus getStatus() {
		return status;
	}

	public Instant getChangedAt() {
		return changedAt;
	}

}
