package tn.lammapets.backend.store.product;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.CascadeType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;

@Entity
@Table(name = "products")
public class Product {

	@Id
	private String id;

	private String name;

	private String brand;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private ShopCategory category;

	private String description;

	@Column(precision = 2, scale = 1)
	private BigDecimal rating = BigDecimal.ZERO;

	private int reviews;

	@Column(name = "old_price")
	private Integer oldPrice;

	private String badge;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	@Column(name = "pack_kind")
	private PackKind packKind;

	private String color;

	private String tint;

	private String icon;

	@Column(name = "image_url")
	private String imageUrl;

	private boolean active = true;

	@Column(name = "created_at")
	private Instant createdAt = Instant.now();

	@Column(name = "updated_at")
	private Instant updatedAt = Instant.now();

	@ElementCollection
	@CollectionTable(name = "product_species", joinColumns = @JoinColumn(name = "product_id"))
	@Column(name = "species")
	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	private Set<Species> species = new HashSet<>();

	@ElementCollection
	@CollectionTable(name = "product_details", joinColumns = @JoinColumn(name = "product_id"))
	@OrderColumn(name = "sort_order")
	private List<ProductDetail> details = new ArrayList<>();

	@OneToMany(mappedBy = "product", cascade = CascadeType.ALL)
	@OrderBy("sortOrder")
	private List<ProductOption> options = new ArrayList<>();

	protected Product() {
	}

	public Product(String id) {
		this.id = id;
	}

	public void update(ProductDtos.ProductRequest r) {
		name = r.name();
		brand = r.brand();
		category = r.category();
		description = r.description();
		oldPrice = r.oldPrice();
		badge = r.badge();
		packKind = r.packKind();
		color = r.color();
		tint = r.tint();
		icon = r.icon();
		imageUrl = r.imageUrl();
		active = true;
		updatedAt = Instant.now();
		species.clear();
		species.addAll(r.species());
		details.clear();
		if (r.details() != null) {
			r.details().forEach(d -> details.add(new ProductDetail(d.label(), d.value())));
		}
		// Un format déjà commandé doit rester en base : on le retire de la vente sans le supprimer.
		options.forEach(ProductOption::deactivate);
		for (int i = 0; i < r.options().size(); i++) {
			ProductDtos.OptionRequest o = r.options().get(i);
			ProductOption option = options.stream().filter(x -> x.getLabel().equals(o.label())).findFirst().orElseGet(() -> {
				ProductOption created = new ProductOption(this, o.label());
				options.add(created);
				return created;
			});
			option.update(o.price(), o.stock(), i);
		}
	}

	public void setReviewStats(BigDecimal rating, int reviews) {
		this.rating = rating;
		this.reviews = reviews;
	}

	public void deactivate() {
		active = false;
		updatedAt = Instant.now();
	}

	public String getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getBrand() {
		return brand;
	}

	public ShopCategory getCategory() {
		return category;
	}

	public String getDescription() {
		return description;
	}

	public BigDecimal getRating() {
		return rating;
	}

	public int getReviews() {
		return reviews;
	}

	public Integer getOldPrice() {
		return oldPrice;
	}

	public String getBadge() {
		return badge;
	}

	public PackKind getPackKind() {
		return packKind;
	}

	public String getColor() {
		return color;
	}

	public String getTint() {
		return tint;
	}

	public String getIcon() {
		return icon;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public boolean isActive() {
		return active;
	}

	public Set<Species> getSpecies() {
		return species;
	}

	public List<ProductDetail> getDetails() {
		return details;
	}

	public List<ProductOption> getOptions() {
		return options;
	}

}
