package tn.lammapets.backend.store.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import tn.lammapets.backend.store.order.OrderEnums.OrderStatus;

public interface OrderRepository extends JpaRepository<Order, Long> {

	Page<Order> findByUserId(String userId, Pageable pageable);

	@Query("select o from Order o where :status is null or o.status = :status")
	Page<Order> search(OrderStatus status, Pageable pageable);

}
