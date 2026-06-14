# 🦅 BirdLens — Backend Service

> **Mobile-facing orchestration API** — authenticates users, routes predictions, enriches bird metadata, and delivers private images through temporary signed URLs.

---

## What This Service Does

```
Mobile App  ──▶  Express API  ──▶  FastAPI ML Service
                     │
                     ├──▶  Neon PostgreSQL   (users, birds, favorites, history)
                     └──▶  Private AWS S3    (representative bird images)
```

The backend is the system's connective tissue. It does not run the ML model — it orchestrates the complete prediction workflow, owns all relational data, and keeps storage implementation details invisible to clients.

---

## Contents

- [Responsibilities](#responsibilities)
- [Architecture & Request Flow](#architecture--request-flow)
- [Project Structure](#project-structure)
- [API Reference](#api-reference)
- [Authentication](#authentication)
- [Database Schema](#database-schema)
- [Prediction Orchestration](#prediction-orchestration)
- [S3 & Response Enrichment](#s3--response-enrichment)
- [Configuration](#configuration)
- [Development & Operations](#development--operations)
- [Security & Improvement Priorities](#security--improvement-priorities)

---

## Responsibilities

**Owns:**

| Domain | Details |
|---|---|
| Identity | Registration, login, `/me` lookup, JWT creation & verification |
| Public API | REST endpoints consumed by the Flutter mobile app |
| Persistence | Database access through Drizzle ORM |
| Prediction routing | Bridges client uploads to the FastAPI ML service |
| Bird metadata | Resolves ML class strings to canonical species records |
| History | Append-only prediction event log per user |
| Favorites | Create, list, and delete user-to-bird relationships |
| Image delivery | Signs private S3 object keys into temporary URLs |

**Does not own:** model training, inference internals, or user-uploaded image storage.

---

## Architecture & Request Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    REQUEST LIFECYCLE                         │
│                                                             │
│   Express Route                                             │
│       │                                                     │
│       ▼                                                     │
│   Middleware ──── protectRoute (JWT verify)                 │
│       │      └─── Multer (memory storage, no disk)         │
│       │                                                     │
│       ▼                                                     │
│   Controller                                                │
│       ├──▶  Drizzle / Neon PostgreSQL                       │
│       ├──▶  ML Service Client  ──▶  FastAPI /api/predict/   │
│       └──▶  Bird Enrichment Utility                         │
│                  └──▶  S3 Signing Service (1-hour URLs)     │
│       │                                                     │
│       ▼                                                     │
│   JSON Response                                             │
└─────────────────────────────────────────────────────────────┘
```

### Prediction request — step by step

```
POST /api/birds/predict
  ① protectRoute verifies Bearer JWT
  ② Multer stores image bytes in memory (never on disk)
  ③ birds.controller forwards buffer to FastAPI as multipart
  ④ FastAPI returns { bird: "Baird_Sparrow", confidence: 99.25 }
  ⑤ Controller looks up matching row in birds table
  ⑥ birdResponse signs aws_image_key → image_url (1 hour)
  ⑦ Controller inserts history event for authenticated user
  ⑧ Enriched response returned to client
```

---

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── cron.js          ← Production keep-alive (every 14 min)
│   │   ├── db.js            ← Neon HTTP client + Drizzle instance
│   │   └── env.js           ← Single ENV object from process.env
│   │
│   ├── controllers/
│   │   ├── auth.controller.js       ← Signup, login, /me
│   │   ├── birds.controller.js      ← Bird details + prediction
│   │   ├── favorites.controller.js  ← Add / list / remove
│   │   └── history.controller.js    ← List + bulk delete
│   │
│   ├── db/
│   │   ├── migrations/      ← Versioned PostgreSQL SQL files
│   │   └── schema.js        ← Current Drizzle schema (source of truth)
│   │
│   ├── middleware/
│   │   ├── auth.middleware.js    ← Bearer token → req.user
│   │   └── upload.middleware.js  ← Multer memory storage
│   │
│   ├── routes/              ← Express route definitions
│   │
│   ├── scripts/
│   │   └── seed.js          ← Updates existing bird rows by name
│   │
│   ├── seed/
│   │   └── birds.js         ← Curated metadata for 50 species
│   │
│   ├── services/
│   │   ├── ml.service.js    ← Multipart FormData → FastAPI client
│   │   └── s3.service.js    ← GetObject signed URL (3600s)
│   │
│   ├── utils/
│   │   ├── birdResponse.js      ← Hides aws_image_key, emits image_url
│   │   └── generateTokens.js    ← 7-day JWT generator
│   │
│   └── server.js            ← Express composition root
│
├── drizzle.config.js        ← Drizzle Kit config
├── package.json
└── package-lock.json
```

### Key file guide

| File | Behaviour that matters |
|---|---|
| `src/server.js` | Enables CORS/JSON, starts cron in production, mounts route groups, exposes `/api/health` |
| `src/config/env.js` | Reads all env vars into one `ENV` object — no `process.env` scattered through the codebase |
| `src/config/db.js` | Neon HTTP client + Drizzle with full schema |
| `src/config/cron.js` | Pings `API_URL` and `ML_SERVICE` every 14 minutes in production to prevent cold starts |
| `src/db/schema.js` | Defines users, birds, favorites, history — all constraints and the history user index |
| `src/services/ml.service.js` | Converts Multer buffer + filename to `FormData` and posts to `${ML_SERVICE}/api/predict/` |
| `src/services/s3.service.js` | `GetObjectCommand` + `getSignedUrl(..., { expiresIn: 3600 })` |
| `src/utils/birdResponse.js` | Strips `aws_image_key`, injects `image_url`; signs lists concurrently with `Promise.all` |
| `src/scripts/seed.js` | Updates bird metadata by exact `name` match — run only after rows exist |

---

## API Reference

Base path: `/api`

### Authentication

#### `POST /auth/signup` — Public

Normalizes email to lowercase, trims username, validates input, hashes password with bcrypt, creates user, returns JWT.

**Request body:**
```json
{
  "email": "person@example.com",
  "username": "birder",
  "password": "Secret1"
}
```

**Validation rules:**
- Username: 3–20 characters
- Password: 6–25 characters, must contain uppercase + lowercase + number; allowed chars are letters, digits, `@`, `-`

**Success `201`:**
```json
{
  "message": "User created successfully",
  "token": "<jwt>",
  "user": {
    "id": "<uuid>",
    "email": "person@example.com",
    "username": "birder"
  }
}
```

---

#### `POST /auth/login` — Public

Verifies email and password. Returns the same safe user summary + fresh JWT. Unknown email and wrong password both return the generic `Invalid Credentials` response (no user enumeration).

---

#### `GET /auth/me` — Protected

Returns `{ id, username, email }` for the JWT subject. No password hash, no internal IDs beyond `id`.

---

### Birds & Prediction

#### `GET /birds/:bird_id` — Public

Fetches one species by UUID. The stored `aws_image_key` is replaced with a 1-hour `image_url`. Raw S3 key is never exposed.

---

#### `POST /birds/predict` — Protected

Accepts `multipart/form-data`. The file field must be named `image`.

```
Authorization: Bearer <jwt>
Content-Type: multipart/form-data
image: <binary>
```

**Response:**
```json
{
  "bird": {
    "id": "<uuid>",
    "name": "Baird_Sparrow",
    "description": "...",
    "scientific_name": "Centronyx bairdii",
    "habitat": "...",
    "conservation_status": "...",
    "image_url": "<signed-s3-url-valid-1h>"
  },
  "confidence": 99.25,
  "is_confident": true
}
```

A history row is inserted for the authenticated user on every successful prediction.

---

### Favorites

All routes are protected. User identity comes from the JWT — never from a request body field.

| Method | Path | Body | Description |
|---|---|---|---|
| `POST` | `/favorites` | `{ "bird_id": "<uuid>" }` | Creates favorite; duplicate pair violates composite PK |
| `GET` | `/favorites` | — | Returns enriched list with signed `image_url` per bird, or `[]` |
| `DELETE` | `/favorites` | `{ "bird_id": "<uuid>" }` | Removes the matching favorite for the authenticated user |

The list response includes: bird ID, name, favorite timestamp, and `image_url`.

---

### History

| Method | Path | Description |
|---|---|---|
| `GET` | `/history` | Enriched prediction records, newest first |
| `DELETE` | `/history` | Deletes every history row owned by the authenticated user |

Each history record contains: `history_id`, `bird_id`, `name`, `confidence`, `predicted_at`, `image_url`.

---

### Health

`GET /api/health` → `200 OK` when the Express process is alive.

> ⚠️ Does not verify database, S3, or ML service health. Suitable for process-alive checks only.

---

## Authentication

### Password handling

- Email is trimmed and lowercased on ingestion.
- Passwords are never returned in any response.
- bcrypt with `SALT_ROUNDS = 10`.
- Login errors return a single generic message for both unknown email and wrong password — no user enumeration.

### JWT handling

`generateToken(id)` signs `{ id }` with `JWT_SECRET`, 7-day expiry.

`protectRoute` middleware:
1. Reads `Authorization: Bearer <token>`
2. Verifies signature and expiry
3. Sets `req.user` to the decoded payload

Because controllers use `req.user.id` for all database queries, it is impossible for a caller to access another user's data by crafting a different request body.

### Recommended hardening

- Validate `JWT_SECRET` presence and minimum entropy at startup
- Add `iss` / `aud` claims and key rotation strategy
- Implement login throttling and account lockout
- Define refresh-token or session revocation behaviour
- Evaluate Argon2id if requirements evolve beyond bcrypt

---

## Database Schema

```
users ──────────────────────────────────────────
  id           UUID   PK, random default
  username     text   not null
  email        text   not null, unique
  password_hash text  not null
  created_at   ts     not null, defaults now
  updated_at   ts     not null, defaults now

birds ──────────────────────────────────────────
  id                UUID   PK
  name              text   not null, unique ← must match ML class string exactly
  description       text   nullable
  aws_image_key     text   nullable private S3 key
  scientific_name   text   nullable
  habitat           text   nullable
  conservation_status text nullable

favorites ──────────────────────────────────────
  user_id    UUID   PK part, FK → users
  bird_id    UUID   PK part, FK → birds
  created_at ts     not null, defaults now
  ↑ composite PK enforces uniqueness at the database level

history ────────────────────────────────────────
  id           serial  PK
  user_id      UUID    not null, FK → users, indexed
  bird_id      UUID    not null, FK → birds
  confidence   real    not null
  predicted_at ts      not null, defaults now
```

### Migration history

| Migration | What changed |
|---|---|
| `0000_simple_dexter_bennett.sql` | Created users, birds, favorites, history |
| `0001_amused_the_fury.sql` | Renamed history timestamp, added confidence and temporary uploaded-image URL column |
| `0002_premium_ikaris.sql` | Renamed bird image URL to S3 key, renamed user image field, indexed history by user |
| `0003_unknown_guardian.sql` | Removed user image key — decision not to persist uploads |

### Normalization rationale

History stores a foreign key to the canonical bird rather than repeating metadata or S3 keys. Favorites do the same. This avoids update anomalies and keeps a single authoritative row per supported species. If a bird's description or image changes, every history and favorite record reflects the update automatically.

### Seeding

`src/seed/birds.js` contains curated metadata for all 50 supported species. `src/scripts/seed.js` performs updates by exact `name` match. Run only after bird rows exist. Note: the script logs "Inserted" but its actual database operation is update-only.

---

## Prediction Orchestration

```
Client image bytes
    │
    ▼
Multer (memory storage — no disk write)
    │
    ▼
ml.service.js — builds FormData with buffer + filename
    │  POST multipart to ${ML_SERVICE}/api/predict/
    ▼
FastAPI response: { bird: "Baird_Sparrow", confidence: 99.25 }
    │
    ▼
Controller looks up birds table by name
    │   ← class mapping is a cross-service contract:
    │     class_names.json[index] == prediction.bird == birds.name
    ▼
birdResponse.js signs aws_image_key → image_url
    │
    ▼
history insert for req.user.id
    │
    ▼
Enriched JSON response to client
```

> ⚠️ If enrichment or history insertion fails, the entire request returns `500` even if inference succeeded. This is a known gap — see improvement priorities.

---

## S3 & Response Enrichment

The S3 service creates `GetObject` signed URLs using configured credentials and region. URLs expire after **3,600 seconds**.

`enrichBird()` and `enrichBirds()` (used throughout controllers):

1. Read `aws_image_key` from the database row
2. Call S3 service to generate a signed URL when a key exists
3. Delete `aws_image_key` from the response object
4. Inject `image_url` in its place

This keeps the private S3 bucket invisible to clients. Signed URLs contain AWS signing metadata — that is by design and is distinct from exposing the secret access key.

For list responses, `enrichBirds()` fires all signing operations concurrently via `Promise.all`.

---

## Configuration

Create a `.env` file in `backend/` — it is gitignored. Never commit real values.

| Variable | Purpose |
|---|---|
| `DB_URL` | Neon/PostgreSQL connection string |
| `PORT` | Express listener port (default: `5001`) |
| `NODE_ENV` | Set to `production` to activate the keep-alive cron |
| `API_URL` | Backend URL pinged by production cron |
| `JWT_SECRET` | JWT signing and verification secret |
| `ML_SERVICE` | FastAPI base URL (`http://...` without trailing slash) |
| `AWS_BUCKET_NAME` | Private S3 bucket name |
| `AWS_REGION` | S3 region (e.g. `us-east-1`) |
| `AWS_ACCESS_KEY_ID` | S3 identity for local/key-based setups |
| `AWS_SECRET_ACCESS_KEY` | S3 credential for local/key-based setups |

---

## Development & Operations

### Install and run

```bash
# Install dependencies
npm install

# Development (nodemon watch)
npm run dev

# Production
npm start
```

### Database migrations

```bash
# Generate migration SQL from schema changes
npx drizzle-kit generate

# Apply pending migrations
npx drizzle-kit migrate
```

Always review generated SQL before applying to shared or production environments.

### Smoke test order

Run these in sequence after any deployment to verify the full stack:

```
1. GET  /api/health              → 200 OK
2. POST /auth/signup             → 201, token returned
3. POST /auth/login              → 200, token returned
4. GET  /auth/me                 → 200, user object (no password)
5. GET  /birds/:known_uuid       → 200, image_url present
6. POST /birds/predict (+ image) → 200, enriched bird + confidence
7. GET  /history                 → 200, contains the prediction above
8. POST /favorites               → 200, favorite created
9. GET  /favorites               → 200, list with image_url
10. DELETE /favorites            → 200, removed
11. DELETE /history              → 200, all history cleared
```

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| Prediction returns `Bird not found` | ML class string does not exactly match `birds.name`, or row is missing |
| `image_url` is null | Bird row has no `aws_image_key` |
| Signed URL returns 403 | Expired URL, wrong key, wrong region/bucket, or missing S3 permission |
| Prediction returns `500` | ML service unavailable, DB error, signing error, or history insert failure |
| Protected route returns `401` | Missing, malformed, expired, or incorrectly signed JWT |
| Duplicate favorite returns `500` | Composite PK violation not yet mapped to `409 Conflict` |

---

## Security & Improvement Priorities

### Current strengths

- User identity comes from verified JWTs — request body user IDs are ignored
- Password hashes and all credentials are excluded from every response
- All SQL goes through Drizzle — no string concatenation
- S3 stays private; object keys are stripped from API responses
- User-uploaded images are not intentionally persisted anywhere

### Highest-priority gaps

1. **Schema validation** — add validation for request params, bodies, and file metadata (e.g. Zod)
2. **File limits** — add Multer file-size cap and MIME-type allowlist before forwarding to ML service
3. **Rate limiting + CORS** — restrict origins, add express-rate-limit, add ML service boundary auth
4. **Centralized error handling** — never return raw `error.message`; use opaque error codes
5. **Duplicate favorite → 409** — map composite PK violation to a proper conflict response
6. **ML call reliability** — add timeouts, retries, and circuit-breaking for FastAPI calls
7. **Testing** — unit tests for controllers and utils; integration tests for prediction flow
8. **OpenAPI docs** — generate from schema for client contract clarity
9. **Structured logging + metrics** — replace console.log with structured output; add latency tracking
10. **Managed identity** — use IAM roles / workload identity in deployment; rotate secrets
11. **Pagination** — add cursor/offset pagination for history and favorites lists
12. **Account deletion** — define FK cascade behaviour and a formal account deletion flow

---

> The backend is a well-separated portfolio-scale orchestration service. Its next engineering phase is reliability and operational maturity — not more controller features.