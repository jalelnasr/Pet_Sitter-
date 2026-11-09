package com.petsitter.store.order;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.CascadeType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import com.petsitter.store.order.OrderDtos.CreateOrderRequest;
import com.petsitter.store.order.OrderEnums.OrderStatus;
import com.petsitter.store.order.OrderEnums.PaymentMethod;
import com.petsitter.store.order.OrderEnums.PaymentStatus;
import com.petsitter.store.product.ProductOption;
import com.petsitter.user.entity.UserEntity;

@Entity
@Table(name = "orders")
public class Order {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "order_number")
	private String number;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id")
	private UserEntity user;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private OrderStatus status = OrderStatus.CONFIRMED;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	@Column(name = "payment_method")
	private PaymentMethod paymentMethod;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	@Column(name = "payment_status")
	private PaymentStatus paymentStatus = PaymentStatus.PENDING;

	private int subtotal;

	private int shipping;

	private int total;

	private String recipient;

	private String phone;

	private String address;

	private String city;

	@Version
	private long version;

	@Column(name = "created_at")
	private Instant createdAt = Instant.now();

	@OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
	private List<OrderItem> items = new ArrayList<>();

	@ElementCollection
	@CollectionTable(name = "order_status_history", joinColumns = @JoinColumn(name = "order_id"))
	@OrderColumn(name = "sort_order")
	private List<StatusEvent> history = new ArrayList<>(List.of(new StatusEvent(OrderStatus.CONFIRMED)));

	protected Order() {
	}

	Order(UserEntity user, CreateOrderRequest req) {
		this.user = user;
		this.paymentMethod = req.payment();
		this.recipient = req.recipient().trim();
		this.phone = req.phone().trim();
		this.address = req.address().trim();
		this.city = req.city().trim();
	}

	void addItem(ProductOption option, int quantity) {
		OrderItem item = new OrderItem(this, option, quantity);
		items.add(item);
		subtotal += item.getLineTotal();
	}

	void applyShipping(int shipping) {
		this.shipping = shipping;
		this.total = subtotal + shipping;
	}

	void assignNumber() {
		this.number = "PS-" + (10000 + id);
	}

	void moveTo(OrderStatus next) {
		status = next;
		history.add(new StatusEvent(next));
		if (next == OrderStatus.DELIVERED) {
			paymentStatus = PaymentStatus.PAID; // paiement en espèces encaissé par le livreur
		}
		else if (next == OrderStatus.CANCELLED) {
			paymentStatus = PaymentStatus.CANCELLED;
		}
	}

	public Long getId() {
		return id;
	}

	public String getNumber() {
		return number;
	}

	public UserEntity getUser() {
		return user;
	}

	public OrderStatus getStatus() {
		return status;
	}

	public PaymentMethod getPaymentMethod() {
		return paymentMethod;
	}

	public PaymentStatus getPaymentStatus() {
		return paymentStatus;
	}

	public int getSubtotal() {
		return subtotal;
	}

	public int getShipping() {
		return shipping;
	}

	public int getTotal() {
		return total;
	}

	public String getRecipient() {
		return recipient;
	}

	public String getPhone() {
		return phone;
	}

	public String getAddress() {
		return address;
	}

	public String getCity() {
		return city;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public List<OrderItem> getItems() {
		return items;
	}

	public int getItemCount() {
		return items.stream().mapToInt(OrderItem::getQuantity).sum();
	}

	public List<StatusEvent> getHistory() {
		return history;
	}

}
