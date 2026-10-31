# Backend Lamma Pets : boutique et commandes

Spring Boot 4, MySQL 8, Flyway, JWT. Rôles : `OWNER`, `PETSITTER`, `ADMIN`.

## Lancer en local

```powershell
.\mvnw.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

- Base : `petsitter_db` de XAMPP (`localhost:3306`, utilisateur `root` sans mot de passe par défaut), à changer avec `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`.
- Ce module ajoute ses tables (`products`, `product_*`, `orders`, `order_*`, `user_credentials`) et ne modifie ni `users` ni `adoption_*`.
- Swagger : http://localhost:8080/swagger-ui.html
- Admin de développement : `admin@petsitter.test` / `admin12345`
- Le profil `dev` charge aussi le catalogue fictif de l'application (`db/dev`).
- Tests (base H2 en mémoire) : `.\mvnw.cmd test`

Sans le profil `dev`, il faut fournir `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET` (32 octets minimum),
et au besoin `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `CORS_ORIGINS`.

## API

| Méthode et route | Accès | Rôle |
|---|---|---|
| `POST /api/auth/register`, `/login` | public | inscription (`OWNER` ou `PETSITTER`), connexion |
| `GET /api/auth/me` | connecté | compte courant |
| `PUT /api/auth/me/role` | connecté | passer de `OWNER` à `PETSITTER`, ou l'inverse |
| `GET /api/products?category&species&q&page&size` | public | catalogue |
| `GET /api/products/{id}` | public | fiche produit |
| `GET /api/products/{id}/reviews` | public | avis d'un produit |
| `GET, PUT, DELETE /api/products/{id}/reviews/me` | connecté | mon avis (après réception du produit) |
| `POST /api/orders` | connecté | passer commande |
| `GET /api/orders/me`, `/api/orders/{id}` | propriétaire ou admin | suivi |
| `POST /api/orders/{id}/cancel` | propriétaire ou admin | annuler avant préparation |
| `GET, POST /api/admin/products` | admin | gérer le catalogue |
| `PUT, DELETE /api/admin/products/{id}` | admin | modifier, retirer de la vente |
| `POST /api/admin/product-images` | admin | envoyer une photo (`file` : JPG, PNG ou WebP, 5 Mo maximum) |
| `GET /api/images/{nom}` | public | afficher une photo |
| `DELETE /api/admin/reviews/{id}` | admin | supprimer un avis |
| `GET /api/admin/orders?status` | admin | toutes les commandes |
| `PATCH /api/admin/orders/{id}/status` | admin | faire avancer une commande |

Parcours d'une commande : `CONFIRMED → PREPARING → SHIPPED → DELIVERED` ; annulation possible avant l'expédition.

## Connexion provisoire

`/api/auth/*` et la table `user_credentials` servent seulement à tester la boutique : les utilisateurs sont le module
d'un autre membre de l'équipe. Pour les remplacer, il suffit que son module fournisse un jeton JWT signé avec
`sub` = `users.id` et `role` = `OWNER`, `PETSITTER` ou `ADMIN`. La boutique ne lit rien d'autre (et `users` pour le nom).

## Règles

- Le serveur calcule les prix et les totaux. Livraison : 7 DT, offerte dès 80 DT.
- Le stock est porté par chaque format et retiré de façon atomique ; une annulation le rend.
- Prix en dinars entiers, comme dans l'application.
- Un client donne un seul avis par produit, après l'avoir reçu. La note du produit est recalculée à partir des vrais avis.
- Les photos sont rangées dans `uploads/` (ou `UPLOADS_DIR`), sur la machine du serveur, hors du dépôt Git.
- Le paiement par carte est refusé tant qu'aucun prestataire de paiement n'est branché.
