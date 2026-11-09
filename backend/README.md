# PetSitter — backend (Spring Boot + MySQL)

REST API for the Adoption module only. It powers the existing Flutter Adoption UI
(listings, adoption requests, owner decisions, minimal Admin moderation). It does
**not** provide any backend for Events, Pet Sitting, Store, Messaging or the other
modules.

The Events module was deliberately left untouched (no file, route, model, mock or
widget changes).

---

## 1. Stack and architecture

| Layer | Technology |
| --- | --- |
| Language / runtime | Java 17 |
| Framework | Spring Boot 3.3.5 (Spring Web MVC, Spring Data JPA, Hibernate, Bean Validation) |
| Database | MySQL / MariaDB via XAMPP |
| API docs | springdoc-openapi 2.6.0 (Swagger UI) |
| Tests | JUnit 5, Mockito, AssertJ, H2 (test scope only) |
| Build | Maven |

```
Flutter screens
   ↓
ViewModels (ChangeNotifier)
   ↓
ApiAdoptionRepository
   ↓
AdoptionApiService  →  ApiClient (single place for base URL + headers)
   ↓  HTTP/JSON
Spring controllers
   ↓
Services (authorization + business rules)
   ↓
Spring Data repositories
   ↓
MySQL: users, adoption_listings, adoption_images, adoption_requests
```

Package root: `com.petsitter`.

| Package | Responsibility |
| --- | --- |
| `config` | CORS, OpenAPI metadata, idempotent demo-user seeding |
| `common.exception` | Typed exceptions + one global error handler |
| `common.response` | `ErrorResponse` (single JSON error shape) |
| `user` | `UserEntity`, role enum, repository, `DemoUserResolver` (temporary header auth) |
| `adoption.entity` | `AdoptionListing`, `AdoptionImage`, `AdoptionRequest` |
| `adoption.enums` | Listing status, species, gender, housing type, request status |
| `adoption.dto` | Request/response records + validation |
| `adoption.repository` | Spring Data queries (public feed, ownership, requests) |
| `adoption.mapper` | Entity → DTO mapping |
| `adoption.service` | All business rules and transactions |
| `adoption.controller` | Public, authenticated and Admin endpoints |

---

## 2. Prerequisites

- Java 17 (`java -version`).
- Maven 3.9+. It is not always on `PATH`; IntelliJ bundles one at
  `C:\Program Files\JetBrains\IntelliJ IDEA <version>\plugins\maven-plugin\lib\maven3\bin\mvn.cmd`.
- XAMPP with MySQL/MariaDB running.
- Port **8081** free. Port 8080 is never used.

---

## 3. Database setup (XAMPP)

1. Start **XAMPP → MySQL** (the backend cannot start without it: `Communications link failure`
   / `Connection refused` in the logs means MySQL is not running).
2. Nothing else to do: the database **`petsitter_db`** is created automatically on first startup
   (`createDatabaseIfNotExist=true`, server charset — `utf8mb4` with XAMPP). You can still create
   it yourself in phpMyAdmin with `utf8mb4_unicode_ci`.
3. Do **not** create tables manually. Hibernate uses
   `spring.jpa.hibernate.ddl-auto=update` and creates:

| Table | Purpose |
| --- | --- |
| `users` | Accounts (demo users `OWNER_DEMO`, `PETSITTER_DEMO`, `ADMIN_DEMO`, `sami`, `samira`, `admin` + sign-ups) |
| `password_reset_codes` | Hashed 6-digit password reset codes |
| `conversations`, `messages` | Messaging |
| `adoption_listings` | Animal listings, status, publisher, location |
| `adoption_images` | Ordered image URLs (max 6 per listing) |
| `adoption_requests` | Adoption requests, applicant, decision, AI score |

No Flyway, Liquibase, `schema.sql` or `data.sql` is used.

Default connection (XAMPP): MySQL on `localhost:3306`, user `root`, empty password.
Override with environment variables:

| Variable | Default |
| --- | --- |
| `DB_URL` | `jdbc:mysql://localhost:3306/petsitter_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| `DB_USERNAME` | `root` |
| `DB_PASSWORD` | *(empty)* |

Example:

```powershell
$env:DB_PASSWORD = "myPassword"
```

---

## 4. Run the backend

```powershell
cd backend
mvn spring-boot:run
```

or build and run the executable jar:

```powershell
mvn -DskipTests package
java -jar target/petsitter-backend-1.0.0.jar
```

Startup verifies the schema and seeds the three demo users idempotently. Restarting
does not duplicate them.

- API base: <http://localhost:8081/api>
- Swagger UI: <http://localhost:8081/swagger-ui/index.html>
- OpenAPI JSON: <http://localhost:8081/v3/api-docs>

---

## 5. Authentication (User module) and messaging

### Accounts and sessions

Passwords are hashed with BCrypt (`spring-security-crypto`, no Spring Security filter
chain). A successful sign-up, login, password reset or password change returns a
signed JWT (HS256) valid 72 h:

```json
{ "token": "eyJ…", "tokenType": "Bearer", "expiresAt": "…", "user": { "id": "…", "fullName": "…", "role": "OWNER", … } }
```

Send it on every request: `Authorization: Bearer <token>`.

- `JwtAuthenticationFilter` checks the token on `/api/**`. When it is valid, the legacy
  `X-Demo-User-Id` / `X-User-Id` headers are **replaced** by the authenticated user id, so the
  Adoption, Events and Pet Sitting modules work with real accounts unchanged, and these headers
  can no longer be spoofed.
- The token embeds a fingerprint of the password: changing or resetting the password closes
  every other session.
- 5 wrong passwords lock the account for 15 minutes.
- Without a token, `X-Demo-User-Id` is still accepted while `ALLOW_DEMO_HEADER=true` (default,
  for Swagger and the demo-user selectors). Set it to `false` to require real logins everywhere.
- The demo accounts (`OWNER_DEMO`, `PETSITTER_DEMO`, `ADMIN_DEMO`, `sami`, `samira`, `admin`)
  receive the password `Demo1234` at startup if they have none (`DEMO_PASSWORD`, empty = off).

| Variable | Default | Purpose |
| --- | --- | --- |
| `JWT_SECRET` | dev secret (warning logged) | HMAC key, 32 bytes minimum |
| `JWT_VALIDITY_HOURS` | `72` | Session length |
| `ALLOW_DEMO_HEADER` | `true` | Accept `X-Demo-User-Id` without a token |
| `DEMO_PASSWORD` | `Demo1234` | Password given to demo accounts |
| `LOG_RESET_CODES` | `true` | Print reset codes in the console when no e-mail is sent |
| `backend/mail.properties` (or `SPRING_MAIL_*` variables) | — | SMTP account for reset e-mails, see below |

### Forgot password

1. `POST /api/auth/forgot-password {email}` → a 6-digit code is e-mailed (same answer whether
   the address exists or not; one request per 60 s). **Without SMTP, the code is printed in the
   backend console**: `[DEV] Code de réinitialisation pour … : 123456`.

#### Sending the codes by real e-mail (Gmail)

1. Enable 2-Step Verification on the Google account, then create an **app password** at
   <https://myaccount.google.com/apppasswords> (16 letters). The normal account password is refused.
2. Copy `backend/mail.properties.example` to `backend/mail.properties` (ignored by git) and set
   `spring.mail.username` (the Gmail address) and `spring.mail.password` (the app password).
3. Restart the backend. The startup log says `E-mail configuré : codes de réinitialisation envoyés via
   smtp.gmail.com…`; without the file it says `E-mail non configuré`.

The e-mail (text + HTML, UTF-8) is sent from the SMTP account itself. If Gmail refuses the
credentials, the console explains it and still prints the code, so testing is never blocked.
2. `POST /api/auth/verify-reset-code {email, code}` (optional check).
3. `POST /api/auth/reset-password {email, code, newPassword}` → new session.

Codes are stored hashed, expire after 15 minutes, allow 5 attempts and work once.

### Endpoints

| Method and path | Access | Purpose |
| --- | --- | --- |
| `POST /api/auth/register` | public | Sign up (`OWNER` by default, or `PETSITTER`) |
| `POST /api/auth/login` | public | Log in |
| `POST /api/auth/forgot-password`, `/verify-reset-code`, `/reset-password` | public | Password recovery |
| `GET, PUT /api/auth/me` | signed in | Read / update my profile |
| `PUT /api/auth/me/password` | signed in | Change password (returns a new token) |
| `PUT /api/auth/me/role` | signed in | Switch OWNER ↔ PETSITTER |
| `GET /api/users?q&role`, `GET /api/users/{id}` | signed in | Member directory (no e-mail or phone) |
| `GET /api/admin/users`, `PUT /api/admin/users/{id}/status` | ADMIN | List, suspend or reactivate accounts |
| `GET /api/conversations` | signed in | My conversations with unread counts |
| `POST /api/conversations {participantId, subject?, message?}` | signed in | Open (or find) the conversation with a member |
| `GET /api/conversations/unread-count` | signed in | Total unread messages |
| `GET /api/conversations/{id}` | participant | Conversation details |
| `GET /api/conversations/{id}/messages?afterId&beforeId&limit` | participant | Messages, oldest first (`afterId` = new ones) |
| `POST /api/conversations/{id}/messages {content}` | participant | Send a message (2000 characters max) |
| `DELETE /api/conversations/{id}/messages/{messageId}` | sender only | Delete a message for everyone (text hidden, kept for moderation) |
| `POST /api/conversations/{id}/read` | participant | Mark received messages as read |
| `GET /api/conversations/{id}/ai/replies` | participant | AI assistant: 3 suggested replies |

**AI messaging assistant** (`messaging_ai/`, FastAPI on port 8002, see its README): every sent message
is analysed. Scam or insult → `409 RISKY_MESSAGE` with the explanation and nothing is stored; the app
asks the sender, who can resend with `confirmRisk: true`. The message is then stored with
`risk: HIGH` and `riskReason`, shown to the recipient as a warning. If `messaging_ai` is down,
`MessagingAiFallback` applies the same rules in Java (`MESSAGING_AI_URL`, default `http://localhost:8002`).

Messaging rules: one conversation per pair of members, only the two participants can read or
write, no message to yourself or to a suspended account. New tables: `password_reset_codes`,
`conversations`, `messages`; new nullable columns on `users` (created by `ddl-auto=update`).

--- | --- | --- | --- |
| `OWNER_DEMO` | Amira | amira@petsitter.test | `OWNER` |
| `PETSITTER_DEMO` | Sami | sami@petsitter.test | `PETSITTER` |
| `ADMIN_DEMO` | Admin | admin@petsitter.test | `ADMIN` |

In Swagger UI, click **Authorize** only if an API-key scheme is added later;
for now, pass the header on each operation. The Flutter client attaches it
automatically from its demo-user selector.

---

## 6. Endpoints

### Listings

| Method | Path | Allowed | Success |
| --- | --- | --- | --- |
| `POST` | `/api/adoption-listings` | `OWNER`, `PETSITTER` | `201` |
| `GET` | `/api/adoption-listings?species=&location=&page=&size=` | public | `200` |
| `GET` | `/api/adoption-listings/mine` | any valid demo user | `200` |
| `GET` | `/api/adoption-listings/{id}` | public (optional header) | `200` |
| `PUT` | `/api/adoption-listings/{id}` | publisher | `200` |
| `PATCH` | `/api/adoption-listings/{id}/publish` | publisher | `200` |
| `PATCH` | `/api/adoption-listings/{id}/pause` | publisher | `200` |
| `PATCH` | `/api/adoption-listings/{id}/archive` | publisher | `200` |

`GET /api/adoption-listings` returns a Spring `Page` with `content`, `totalElements`,
`number`, `size`, etc. Page size is clamped to 1–50. Results are newest first and
never include `DRAFT`, `PAUSED`, `ADOPTED`, `HIDDEN` or `ARCHIVED` listings.

### Requests

| Method | Path | Allowed | Success |
| --- | --- | --- | --- |
| `POST` | `/api/adoption-requests` | `OWNER`, `PETSITTER` | `201` |
| `GET` | `/api/adoption-requests/sent` | any valid demo user | `200` |
| `GET` | `/api/adoption-requests/received` | any valid demo user | `200` |
| `GET` | `/api/adoption-requests/{id}` | applicant, publisher, `ADMIN` | `200` |
| `PATCH` | `/api/adoption-requests/{id}/accept` | publisher | `200` |
| `PATCH` | `/api/adoption-requests/{id}/reject` | publisher | `200` |
| `PATCH` | `/api/adoption-requests/{id}/cancel` | applicant | `200` |

`accept` / `reject` / `cancel` accept an optional body:

```json
{ "responseMessage": "Merci, nous vous rappelons demain." }
```

### Admin moderation

| Method | Path | Allowed | Success |
| --- | --- | --- | --- |
| `GET` | `/api/admin/adoption-listings` | `ADMIN` | `200` |
| `PATCH` | `/api/admin/adoption-listings/{id}/hide` | `ADMIN` | `200` |
| `PATCH` | `/api/admin/adoption-listings/{id}/archive` | `ADMIN` | `200` |

There is no full Admin console: only hiding/archiving is supported.

---

## 7. Request examples

### Create a listing (`OWNER_DEMO`)

```http
POST /api/adoption-listings
X-Demo-User-Id: OWNER_DEMO
Content-Type: application/json
```

```json
{
  "petName": "Milo",
  "species": "CAT",
  "breed": "Siamese",
  "age": 2,
  "gender": "MALE",
  "description": "Friendly cat looking for a responsible and caring family.",
  "healthInformation": "Vaccinated and in good health.",
  "vaccinated": true,
  "sterilized": false,
  "location": "Ariana",
  "imageUrls": ["https://example.com/milo.jpg"]
}
```

`status` is optional. Omit it (or send `PUBLISHED`) to publish immediately; send
`"status": "DRAFT"` to save a draft. If `imageUrls` is empty, the backend uses one
default Unsplash URL.

### Send a request (`PETSITTER_DEMO`)

```json
{
  "listingId": "2d49e934-00d0-4ae7-8323-c9f995706bb4",
  "fullName": "Sami",
  "phone": "+216 20 000 000",
  "address": "12 rue des Jasmins, Tunis",
  "message": "I would like to adopt Milo and provide a stable home.",
  "housingType": "APARTMENT",
  "hasGarden": false,
  "hasOtherPets": false,
  "otherPetsDetails": null,
  "experience": "I have previous experience caring for cats.",
  "aiScore": 85
}
```

Enumerations:

- `species`: `DOG`, `CAT`, `BIRD`, `RABBIT`, `OTHER`
- `gender`: `MALE`, `FEMALE`, `UNKNOWN`
- `housingType`: `APARTMENT`, `HOUSE`, `FARM`, `OTHER`
- listing status: `DRAFT`, `PUBLISHED`, `PAUSED`, `ADOPTED`, `ARCHIVED`, `HIDDEN`
- request status: `PENDING`, `ACCEPTED`, `REJECTED`, `CANCELLED`

---

## 8. Business rules enforced server-side

The Flutter client hides impossible buttons, but the backend is the source of truth.

1. `OWNER` can create a listing.
2. `PETSITTER` can create a listing.
3. `ADMIN` cannot create a listing (`403`).
4. The publisher can edit their own listing.
5. Another user cannot edit it (`403`).
6. The publisher can publish a `DRAFT` or `PAUSED` listing.
7. Publishing any other status returns `409 INVALID_STATUS_TRANSITION`.
8. Only the publisher can publish.
9. The publisher can pause a `PUBLISHED` listing.
10. Pausing any other status returns `409`.
11. Only the publisher can pause.
12. The publisher can archive a listing that is not already archived.
13. Archiving an archived listing returns `409`.
14. Only the publisher can archive.
15. The public feed contains only `PUBLISHED` listings.
16. The public feed supports `species` and case-insensitive `location` filters.
17. Anonymous visitors can read a published listing by id.
18. `HIDDEN`/`ARCHIVED` details are visible only to the publisher or `ADMIN`;
    everyone else receives `404` so the listing's existence is not leaked.
19. `OWNER` can send an adoption request.
20. `PETSITTER` can send an adoption request.
21. `ADMIN` cannot send a request (`403`).
22. Requests are accepted only for `PUBLISHED` listings (`409`).
23. A publisher cannot request their own listing (`409 OWN_LISTING_NOT_ALLOWED`).
24. Only one `PENDING` request per applicant and listing is allowed
    (`409 ACTIVE_REQUEST_ALREADY_EXISTS`).
25. An applicant may send a new request after a previous one is `REJECTED` or
    `CANCELLED`, because those are no longer pending.
26. The applicant can read their request.
27. The publisher can read requests received on their listings.
28. `ADMIN` can read any request.
29. Any other user receives `403`.
30. Only the applicant can cancel their request, and only while `PENDING`.
31. Only the listing publisher can accept or reject a request.
32. Only `PENDING` requests can be accepted, rejected or cancelled (`409`).
33. Accepting a request (one transaction) sets it to `ACCEPTED` + `processedAt`,
    sets the listing to `ADOPTED`, and sets every other `PENDING` request of that
    listing to `REJECTED` + `processedAt`.
34. Only `ADMIN` can list all listings or hide/archive them; other roles receive
    `403`.

Additional constraints: Bean Validation on all payloads (required fields, lengths,
age ≥ 0, AI score 0–100, max 6 images), and `X-Demo-User-Id` must exist.

---

## 9. HTTP errors

One JSON shape everywhere:

```json
{
  "status": 409,
  "code": "ACTIVE_REQUEST_ALREADY_EXISTS",
  "message": "You already have a pending adoption request for this listing.",
  "timestamp": "2026-10-30T10:15:30Z"
}
```

Validation errors also include `fieldErrors`:

```json
{
  "status": 400,
  "code": "VALIDATION_ERROR",
  "message": "Invalid request payload.",
  "timestamp": "2026-10-30T10:15:30Z",
  "fieldErrors": { "description": "must not be blank" }
}
```

| Status | When |
| --- | --- |
| `200` | Read/update/transition succeeded |
| `201` | Listing or request created |
| `204` | Reserved; not currently returned |
| `400` | Validation, missing header, malformed JSON |
| `403` | Authenticated demo user lacks the role/ownership |
| `404` | User, listing or request not found (also hides private listings) |
| `409` | Business conflict / invalid status transition |
| `500` | Unexpected error (no stack trace or SQL exposed) |

Codes include `VALIDATION_ERROR`, `BAD_REQUEST`, `NOT_FOUND`, `FORBIDDEN`,
`INVALID_STATUS_TRANSITION`, `OWN_LISTING_NOT_ALLOWED`, `LISTING_NOT_AVAILABLE`,
`ACTIVE_REQUEST_ALREADY_EXISTS`, `REQUEST_NOT_PENDING`, `DATA_CONFLICT`,
`INTERNAL_ERROR`.

---

## 10. Automated tests

### Backend

```powershell
cd backend
mvn test
```

Test classes:

- `AdoptionServiceTest` — Mockito unit tests for listing ownership, roles,
  duplicate requests, own-listing refusal, cancellation and the transactional
  acceptance (request accepted, listing adopted, other pending requests rejected).
- `AdoptionListingRepositoryTest` — `@DataJpaTest` on H2 (test scope) proving the
  public query excludes `HIDDEN`, `ARCHIVED` and `DRAFT`, and supports species
  filtering.

MySQL is not needed for `mvn test`; H2 is test-scope only and never used at runtime.

### Flutter

```powershell
flutter test
flutter analyze
```

`test/adoption_flow_test.dart` uses an in-memory fake repository (no network) to
check loading, empty and error states, demo-user switching, publisher/requester/Admin
actions, acceptance and cancellation, validation and the 320 px layout.

---

## 11. Manual Swagger UI scenario

Use <http://localhost:8081/swagger-ui/index.html>. For each protected call, add the
`X-Demo-User-Id` header.

1. `GET /api/adoption-listings` → `200`, possibly empty.
2. `POST /api/adoption-listings` with `OWNER_DEMO` and the sample body → `201`,
   `publisher.id = OWNER_DEMO`, `status = PUBLISHED`; copy the `id`.
3. `GET /api/adoption-listings` → `200`, the new listing appears once.
4. `GET /api/adoption-listings/{id}` → `200`, correct details.
5. `POST /api/adoption-requests` with `PETSITTER_DEMO`, that `listingId` and the
   sample body → `201`, `status = PENDING`; copy the request `id`.
6. Repeat step 5 → `409 ACTIVE_REQUEST_ALREADY_EXISTS`.
7. Repeat step 5 with `OWNER_DEMO` (the publisher) → `409 OWN_LISTING_NOT_ALLOWED`.
8. `GET /api/adoption-requests/received` with `OWNER_DEMO` → `200`, one request
   from `PETSITTER_DEMO`.
9. `PATCH /api/adoption-requests/{id}/accept` with `OWNER_DEMO` and
   `{"responseMessage":"Accepted"}` → `200`, `status = ACCEPTED`, `processedAt` set.
10. `GET /api/adoption-listings/{id}` → `200`, `status = ADOPTED`.
11. `PUT /api/adoption-listings/{id}` with `PETSITTER_DEMO` → `403 FORBIDDEN`.
12. Create a second listing with `PETSITTER_DEMO`; `PATCH
    /api/admin/adoption-listings/{secondId}/hide` with `ADMIN_DEMO` → `200`,
    `status = HIDDEN`; repeat with `OWNER_DEMO` → `403`.
13. `GET /api/admin/adoption-listings` with `ADMIN_DEMO` → `200`;
    repeat with `PETSITTER_DEMO` → `403`, and verify the hidden listing is absent
    from the public feed.

Verify persistence in phpMyAdmin (`petsitter_db`):

```sql
SELECT id, first_name, role FROM users;
SELECT id, pet_name, status, publisher_id FROM adoption_listings;
SELECT id, status, listing_id, applicant_id FROM adoption_requests;
SELECT listing_id, display_order, image_url FROM adoption_images;
```

---

## 12. Flutter integration

### Base URL

Never use `localhost` from the Android emulator.

| Target | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8081/api` (default) |
| Physical phone | `http://<COMPUTER_LAN_IP>:8081/api` |
| iOS simulator / desktop | `http://127.0.0.1:8081/api` |

For a physical device:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8081/api
```

The phone and the computer must be on the same Wi-Fi network, and Windows Firewall
must allow inbound TCP 8081.

`android/app/src/main/AndroidManifest.xml` now includes `INTERNET` and
`android:usesCleartextTraffic="true"` for local HTTP development. Replace this with
an HTTPS/network-security configuration before production.

### Flutter files

| File | Role |
| --- | --- |
| `lib/adoption/api/api_client.dart` | `ApiConstants`, `ApiException`, single HTTP client; adds `X-Demo-User-Id` |
| `lib/adoption/api/demo_session.dart` | `UserRole`, `DemoUser`, `DemoUsers`, `DemoSessionProvider` (`ChangeNotifier`) |
| `lib/adoption/adoption_api_service.dart` | JSON ↔ Dart mapping for every endpoint |
| `lib/adoption/adoption_repository.dart` | `AdoptionRepository` interface + `ApiAdoptionRepository` |
| `lib/adoption/adoption_models.dart` | `AdoptionPet`, `AdoptionDraft`, `AdoptionRequest`, statuses |
| `lib/adoption/adoption_view_models.dart` | Async ViewModels + local AI advisor |
| `lib/adoption/adoption_screens.dart` | List, details, request form, sent/received, request details, my listings, create/edit, Admin |
| `lib/adoption/adoption_widgets.dart` | Existing cards/pills + demo selector, status pill, management card, error note |
| `lib/adoption/adoption_routes.dart` | Named routes, including the new screens |

The demo-user selector is in the Adoption list header. Switching user reloads every
screen and changes the available actions. No `Deps`, shell, shared navigation or
Events file was modified. Only `pubspec.yaml` (`http`) and the Android manifest were
changed outside `lib/adoption/`.

### Flutter limitations

- No secure authentication: the demo header is temporary and must be replaced by
  JWT before any real deployment.
- No file upload: create/edit accepts an image URL only. `multipart` limits are
  configured but no upload endpoint exists yet.
- The AI score is a local heuristic sent with the request; it is not a trained model.
- Listings are limited to 50 per public page; infinite scroll/pagination UI is not
  implemented.
- Events, Pet Sitting, Store and Messaging remain mock-only and have no backend.

---

## 13. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Communications link failure` | Start XAMPP MySQL; check `DB_URL`/credentials. |
| `Unknown database 'petsitter_db'` | Create it in phpMyAdmin. |
| `Port 8081 was already in use` | `netstat -ano \| findstr :8081`, stop the other process or change `server.port` (but the client expects 8081). |
| Flutter shows `Impossible de joindre le serveur` | Backend not running, wrong base URL, firewall, or phone not on the LAN. |
| `404` for a valid demo header | Re-run the backend so `DemoDataInitializer` seeds users, or check the header spelling. |
| Swagger UI loads but calls fail | Add `X-Demo-User-Id`; open <http://localhost:8081/v3/api-docs> to confirm the API is up. |
| Reset demo data | Drop/recreate `petsitter_db`; Hibernate recreates tables and demo users on restart. |

---

## 14. Project structure

```
backend/
  pom.xml
  README.md
  src/main/java/com/petsitter/
    PetSitterApplication.java
    config/{CorsConfig,OpenApiConfig,DemoDataInitializer}.java
    common/exception/{...}.java
    common/response/ErrorResponse.java
    user/{entity,enums,repository,service}/...
    adoption/{controller,dto,entity,enums,mapper,repository,service}/...
  src/main/resources/application.properties
  src/test/java/com/petsitter/adoption/
    AdoptionServiceTest.java
    AdoptionListingRepositoryTest.java
```

---

## 15. Scope checklist

- Adoption backend only; no Events module changes, no Events backend.
- Port 8081 only; port 8080 unused.
- MySQL/XAMPP only; no PostgreSQL, Firebase, Supabase or MongoDB.
- Tables auto-generated by Hibernate; no migration tool.
- No Spring Security/JWT yet; demo header instead.
- No Postman collection; Swagger UI is the manual test tool.
- No secrets committed; database credentials are environment-overridable.
