-- Copie de la table users de petsitter_db, pour les tests sur H2.
CREATE TABLE users (
  id         VARCHAR(64)  NOT NULL PRIMARY KEY,
  email      VARCHAR(160) NOT NULL UNIQUE,
  first_name VARCHAR(80)  NOT NULL,
  role       VARCHAR(20)  NOT NULL
);
INSERT INTO users VALUES ('ADMIN_DEMO', 'admin@test.tn', 'Admin', 'ADMIN');
