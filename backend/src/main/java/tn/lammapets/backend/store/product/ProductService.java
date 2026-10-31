package tn.lammapets.backend.store.product;

import java.util.Locale;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.lammapets.backend.common.ApiException;
import tn.lammapets.backend.store.product.ProductDtos.CreateProductRequest;
import tn.lammapets.backend.store.product.ProductDtos.PageResponse;
import tn.lammapets.backend.store.product.ProductDtos.ProductRequest;
import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;

@Service
public class ProductService {

	private static final int MAX_PAGE_SIZE = 100;

	private final ProductRepository products;

	public ProductService(ProductRepository products) {
		this.products = products;
	}

	@Transactional(readOnly = true)
	public PageResponse<ProductResponse> search(ShopCategory category, Species species, String q, boolean includeInactive,
			int page, int size) {
		String pattern = (q == null || q.isBlank()) ? null : "%" + escapeLike(q.trim().toLowerCase(Locale.ROOT)) + "%";
		PageRequest pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE), Sort.by("name"));
		return PageResponse.of(products.search(category, species, pattern, includeInactive, pageable).map(ProductResponse::of));
	}

	@Transactional(readOnly = true)
	public ProductResponse getPublic(String id) {
		Product p = find(id);
		if (!p.isActive()) {
			throw notFound();
		}
		return ProductResponse.of(p);
	}

	@Transactional
	public ProductResponse create(CreateProductRequest req) {
		if (products.existsById(req.id())) {
			throw new ApiException(HttpStatus.CONFLICT, "Un produit existe déjà avec cet identifiant.");
		}
		checkLabels(req.product());
		Product p = new Product(req.id());
		p.update(req.product());
		return ProductResponse.of(products.saveAndFlush(p));
	}

	@Transactional
	public ProductResponse update(String id, ProductRequest req) {
		checkLabels(req);
		Product p = find(id);
		p.update(req);
		products.flush();
		return ProductResponse.of(p);
	}

	/** Retrait de la vente : le produit reste en base pour l'historique des commandes. */
	@Transactional
	public void deactivate(String id) {
		find(id).deactivate();
	}

	private void checkLabels(ProductRequest req) {
		long distinct = req.options().stream().map(ProductDtos.OptionRequest::label).distinct().count();
		if (distinct != req.options().size()) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Deux formats portent le même nom.");
		}
	}

	private Product find(String id) {
		return products.findById(id).orElseThrow(ProductService::notFound);
	}

	private static ApiException notFound() {
		return new ApiException(HttpStatus.NOT_FOUND, "Produit introuvable.");
	}

	private static String escapeLike(String s) {
		return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
	}

}
