package tn.lammapets.backend.store.product;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import tn.lammapets.backend.store.product.ProductDtos.CreateProductRequest;
import tn.lammapets.backend.store.product.ProductDtos.PageResponse;
import tn.lammapets.backend.store.product.ProductDtos.ProductRequest;
import tn.lammapets.backend.store.product.ProductDtos.ProductResponse;

import jakarta.validation.Valid;

@RestController
public class ProductController {

	private final ProductService service;

	private final ProductImageService images;

	public ProductController(ProductService service, ProductImageService images) {
		this.service = service;
		this.images = images;
	}

	@PostMapping("/api/admin/product-images")
	@ResponseStatus(HttpStatus.CREATED)
	ProductDtos.ImageResponse uploadImage(@RequestParam MultipartFile file) {
		return new ProductDtos.ImageResponse(images.store(file));
	}

	@GetMapping("/api/products")
	PageResponse<ProductResponse> list(@RequestParam(required = false) ShopCategory category,
			@RequestParam(required = false) Species species, @RequestParam(required = false) String q,
			@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
		return service.search(category, species, q, false, page, size);
	}

	@GetMapping("/api/products/{id}")
	ProductResponse get(@PathVariable String id) {
		return service.getPublic(id);
	}

	@GetMapping("/api/admin/products")
	PageResponse<ProductResponse> adminList(@RequestParam(required = false) ShopCategory category,
			@RequestParam(required = false) Species species, @RequestParam(required = false) String q,
			@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
		return service.search(category, species, q, true, page, size);
	}

	@PostMapping("/api/admin/products")
	@ResponseStatus(HttpStatus.CREATED)
	ProductResponse create(@Valid @RequestBody CreateProductRequest req) {
		return service.create(req);
	}

	@PutMapping("/api/admin/products/{id}")
	ProductResponse update(@PathVariable String id, @Valid @RequestBody ProductRequest req) {
		return service.update(id, req);
	}

	@DeleteMapping("/api/admin/products/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void delete(@PathVariable String id) {
		service.deactivate(id);
	}

}
