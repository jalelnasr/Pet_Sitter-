-- Le mot de passe passe dans la table users. La colonne accepte le vide : les comptes sans mot de passe
-- et les insertions des autres modules continuent de fonctionner.
ALTER TABLE users ADD COLUMN password_hash VARCHAR(100) NULL;

UPDATE users SET password_hash = (SELECT c.password_hash FROM user_credentials c WHERE c.user_id = users.id);

DROP TABLE user_credentials;
