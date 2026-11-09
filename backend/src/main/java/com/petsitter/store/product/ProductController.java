package com.petsitter.store.product;

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

import com.petsitter.auth.security.CurrentUserResolver;
import com.petsitter.store.product.ProductDtos.CreateProductRequest;
import com.petsitter.store.product.ProductDtos.ImageResponse;
import com.petsitter.store.product.ProductDtos.PageResponse;
import com.petsitter.store.product.ProductDtos.ProductRequest;
import com.petsitter.store.product.ProductDtos.ProductResponse;
import com.petsitter.user.enums.UserRole;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;

/** Catalogue public, et sa gestion réservée aux administrateurs. */
@RestController
public class ProductController {

	private final ProductService service;

	private final ProductImageService images;

	private final CurrentUserResolver users;

	public ProductController(ProductService service, ProductImageService images, CurrentUserResolver users) {
		this.service = service;
		this.images = images;
		this.users = users;
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
	PageResponse<ProductResponse> adminList(HttpServletRequest request,
			@RequestParam(required = false) ShopCategory category, @RequestParam(required = false) Species species,
			@RequestParam(required = false) String q, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		users.requireRole(request, UserRole.ADMIN);
		return service.search(category, species, q, true, page, size);
	}

	@PostMapping("/api/admin/product-images")
	@ResponseStatus(HttpStatus.CREATED)
	ImageResponse uploadImage(HttpServletRequest request, @RequestParam MultipartFile file) {
		users.requireRole(request, UserRole.ADMIN);
		return new ImageResponse(images.store(file));
	}

	@PostMapping("/api/admin/products")
	@ResponseStatus(HttpStatus.CREATED)
	ProductResponse create(HttpServletRequest request, @Valid @RequestBody CreateProductRequest req) {
		users.requireRole(request, UserRole.ADMIN);
		return service.create(req);
	}

	@PutMapping("/api/admin/products/{id}")
	ProductResponse update(HttpServletRequest request, @PathVariable String id, @Valid @RequestBody ProductRequest req) {
		users.requireRole(request, UserRole.ADMIN);
		return service.update(id, req);
	}

	@DeleteMapping("/api/admin/products/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	void delete(HttpServletRequest request, @PathVariable String id) {
		users.requireRole(request, UserRole.ADMIN);
		service.deactivate(id);
	}

}
