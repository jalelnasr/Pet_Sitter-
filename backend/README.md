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
| `GET /api/products?category&species&q&page&size` | public | catalogue |
| `GET /api/products/{id}` | public | fiche produit |
| `POST /api/orders` | connecté | passer commande |
| `GET /api/orders/me`, `/api/orders/{id}` | propriétaire ou admin | suivi |
| `POST /api/orders/{id}/cancel` | propriétaire ou admin | annuler avant préparation |
| `GET, POST /api/admin/products` | admin | gérer le catalogue |
| `PUT, DELETE /api/admin/products/{id}` | admin | modifier, retirer de la vente |
| `GET /api/admin/orders?status` | admin | toutes les commandes |
| `PATCH /api/admin/orders/{id}/status` | admin | faire avancer une commande |

Parcours d'une commande : `CONFIRMED → PREPARING → SHIPPED → DELIVERED` ; annulation possible avant l'expédition.

## Règles

- Le serveur calcule les prix et les totaux. Livraison : 7 DT, offerte dès 80 DT.
- Le stock est porté par chaque format et retiré de façon atomique ; une annulation le rend.
- Prix en dinars entiers, comme dans l'application.
- Le paiement par carte est refusé tant qu'aucun prestataire de paiement n'est branché.
