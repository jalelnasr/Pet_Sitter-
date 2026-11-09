package tn.lammapets.backend.store.order;

import java.time.Instant;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import tn.lammapets.backend.store.order.OrderEnums.OrderStatus;

public interface OrderRepository extends JpaRepository<Order, Long> {

	Page<Order> findByUserId(String userId, Pageable pageable);

	List<Order> findByCreatedAtGreaterThanEqual(Instant from);

	@Query("select count(i) > 0 from OrderItem i where i.productId = :productId and i.order.user.id = :userId and i.order.status = :status")
	boolean hasProductWithStatus(String userId, String productId, OrderStatus status);

	@Query("select o from Order o where :status is null or o.status = :status")
	Page<Order> search(OrderStatus status, Pageable pageable);

}
