-- Avis sur les produits de la boutique (les avis sur les pet sitters relèvent d'un autre module).
CREATE TABLE product_reviews (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id VARCHAR(60)   NOT NULL,
  user_id    VARCHAR(64)   NOT NULL,
  rating     INT           NOT NULL,
  comment    VARCHAR(1000) NULL,
  created_at DATETIME(6)   NOT NULL,
  updated_at DATETIME(6)   NOT NULL,
  CONSTRAINT uk_reviews_product_user UNIQUE (product_id, user_id),
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Les notes du catalogue de démonstration étaient inventées : seuls les vrais avis comptent désormais.
UPDATE products SET rating = 0, reviews = 0;
