package tn.lammapets.backend.store.product;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface ProductOptionRepository extends JpaRepository<ProductOption, Long> {

	/** Retire le stock en une seule requête : deux commandes simultanées ne peuvent pas vendre le même article. */
	@Query("select o from ProductOption o join fetch o.product p where o.active = true and p.active = true and o.stock <= :max order by o.stock, p.name")
	List<ProductOption> findLowStock(int max);

	@Modifying
	@Query("update ProductOption o set o.stock = o.stock - :qty where o.id = :id and o.stock >= :qty")
	int decrementStock(Long id, int qty);

	@Modifying
	@Query("update ProductOption o set o.stock = o.stock + :qty where o.id = :id")
	int incrementStock(Long id, int qty);

}
