package tn.lammapets.backend.store.product;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface ProductOptionRepository extends JpaRepository<ProductOption, Long> {

	/** Retire le stock en une seule requête : deux commandes simultanées ne peuvent pas vendre le même article. */
	@Modifying
	@Query("update ProductOption o set o.stock = o.stock - :qty where o.id = :id and o.stock >= :qty")
	int decrementStock(Long id, int qty);

	@Modifying
	@Query("update ProductOption o set o.stock = o.stock + :qty where o.id = :id")
	int incrementStock(Long id, int qty);

}
