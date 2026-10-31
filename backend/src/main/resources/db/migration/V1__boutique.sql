-- La table users appartient au schéma commun de petsitter_db : on s'y réfère sans la modifier.
-- Elle n'a pas de colonne de mot de passe, d'où user_credentials.
CREATE TABLE user_credentials (
  user_id       VARCHAR(64)  PRIMARY KEY,
  password_hash VARCHAR(100) NOT NULL,
  created_at    DATETIME(6)  NOT NULL,
  CONSTRAINT fk_credentials_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE products (
  id          VARCHAR(60)   PRIMARY KEY,
  name        VARCHAR(150)  NOT NULL,
  brand       VARCHAR(100)  NOT NULL,
  category    VARCHAR(20)   NOT NULL,
  description VARCHAR(2000) NOT NULL,
  rating      DECIMAL(2,1)  NOT NULL DEFAULT 0,
  reviews     INT           NOT NULL DEFAULT 0,
  old_price   INT           NULL,
  badge       VARCHAR(40)   NULL,
  pack_kind   VARCHAR(20)   NOT NULL,
  color       VARCHAR(7)    NOT NULL,
  tint        VARCHAR(7)    NOT NULL,
  icon        VARCHAR(40)   NOT NULL,
  image_url   VARCHAR(500)  NULL,
  active      BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at  DATETIME(6)   NOT NULL,
  updated_at  DATETIME(6)   NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE INDEX idx_products_category ON products (category);

CREATE TABLE product_species (
  product_id VARCHAR(60) NOT NULL,
  species    VARCHAR(20) NOT NULL,
  PRIMARY KEY (product_id, species),
  CONSTRAINT fk_species_product FOREIGN KEY (product_id) REFERENCES products (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE product_details (
  product_id   VARCHAR(60)  NOT NULL,
  sort_order   INT          NOT NULL,
  detail_label VARCHAR(60)  NOT NULL,
  detail_value VARCHAR(255) NOT NULL,
  PRIMARY KEY (product_id, sort_order),
  CONSTRAINT fk_details_product FOREIGN KEY (product_id) REFERENCES products (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE product_options (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id VARCHAR(60) NOT NULL,
  label      VARCHAR(60) NOT NULL,
  price      INT         NOT NULL,
  stock      INT         NOT NULL,
  sort_order INT         NOT NULL,
  active     BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_options_product FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT uk_options_label UNIQUE (product_id, label),
  CONSTRAINT ck_options_stock CHECK (stock >= 0),
  CONSTRAINT ck_options_price CHECK (price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE orders (
  id               BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_number     VARCHAR(20)  NULL,
  user_id          VARCHAR(64)  NOT NULL,
  status           VARCHAR(20)  NOT NULL,
  payment_method   VARCHAR(20)  NOT NULL,
  payment_status   VARCHAR(20)  NOT NULL,
  subtotal         INT          NOT NULL,
  shipping         INT          NOT NULL,
  total            INT          NOT NULL,
  recipient        VARCHAR(100) NOT NULL,
  phone            VARCHAR(20)  NOT NULL,
  address          VARCHAR(255) NOT NULL,
  city             VARCHAR(100) NOT NULL,
  version          BIGINT       NOT NULL,
  created_at       DATETIME(6)  NOT NULL,
  CONSTRAINT uk_orders_number UNIQUE (order_number),
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE INDEX idx_orders_user ON orders (user_id, created_at);
CREATE INDEX idx_orders_status ON orders (status, created_at);

-- Nom, format et prix sont copiés : une commande ne change pas si le catalogue change.
CREATE TABLE order_items (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id     BIGINT       NOT NULL,
  option_id    BIGINT       NOT NULL,
  product_id   VARCHAR(60)  NOT NULL,
  product_name VARCHAR(150) NOT NULL,
  option_label VARCHAR(60)  NOT NULL,
  unit_price   INT          NOT NULL,
  quantity     INT          NOT NULL,
  CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders (id),
  CONSTRAINT fk_items_option FOREIGN KEY (option_id) REFERENCES product_options (id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE order_status_history (
  order_id   BIGINT      NOT NULL,
  sort_order INT         NOT NULL,
  status     VARCHAR(20) NOT NULL,
  changed_at DATETIME(6) NOT NULL,
  PRIMARY KEY (order_id, sort_order),
  CONSTRAINT fk_history_order FOREIGN KEY (order_id) REFERENCES orders (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
