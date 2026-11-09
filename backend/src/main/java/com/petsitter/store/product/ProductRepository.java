package com.petsitter.store.product;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ProductRepository extends JpaRepository<Product, String> {

	@Query("""
			select p from Product p
			where (:includeInactive = true or p.active = true)
			  and (:category is null or p.category = :category)
			  and (:species is null or :species member of p.species)
			  and (:q is null or lower(p.name) like :q or lower(p.brand) like :q)
			""")
	Page<Product> search(ShopCategory category, Species species, String q, boolean includeInactive, Pageable pageable);

}
