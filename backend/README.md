# 🖥️ BirdLens — Backend API

> **Node.js / Express orchestration layer that owns authentication, prediction coordination, PostgreSQL persistence, favorites, history, and private AWS S3 image delivery. The single public-facing entry point between the Flutter app and all backend systems.**

---

## 📑 Table of Contents

- [Role in the System](#-role-in-the-system)
- [Quick Start](#-quick-start)
- [Architecture](#️-architecture)
- [Project Structure](#-project-structure)
- [Request Lifecycle Pattern](#-request-lifecycle-pattern)
- [Authentication System](#-authentication-system)
- [Database Design](#️-database-design)
- [API Reference](#-api-reference)
- [Prediction Pipeline](#-prediction-pipeline)
- [Favorites System](#-favorites-system)
- [History System](#-history-system)
- [AWS S3 & Signed URLs](#-aws-s3--signed-urls)
- [Bird Metadata Enrichment](#-bird-metadata-enrichment)
- [Environment Variables](#-environment-variables)
- [Docker](#-docker)
- [Deployment on Render](#-deployment-on-render)
- [Security Review](#-security-review)
- [Scalability Notes](#-scalability-notes)
- [Known Limitations & Roadmap](#-known-limitations--roadmap)
- [Troubleshooting](#-troubleshooting)

---

## 🔍 Role in the System

The Express backend is the **central orchestration layer**. It presents one stable API to Flutter and hides all internal complexity:

```
Flutter App (only talks to this service)
       │
       │  HTTPS + Bearer JWT
       ▼
┌────────────────────────────────────────────┐
│        Node.js / Express API               │
│                                            │
│  ✅  JWT authentication & authorization    │
│  ✅  Drizzle ORM → Neon PostgreSQL         │
│  ✅  Multipart → FastAPI ML service        │
│  ✅  AWS S3 signed URL generation          │
│  ✅  History & favorites persistence       │
│  ✅  Bird metadata enrichment              │
│  ✅  Response contract enforcement         │
└────────────────────────────────────────────┘
       │                   │                  │
       ▼                   ▼                  ▼
  FastAPI ML          Neon PostgreSQL    Private AWS S3
  Inference           (Drizzle ORM)     (Signed URLs)
```

> The Express API is the **only** intended public entry point. FastAPI, PostgreSQL, and S3 are private to it.

---

## ⚡ Quick Start

```bash
# 1. Navigate to backend
cd backend

# 2. Install dependencies
npm install

# 3. Set up environment (copy and fill in your values)
cp .env.example .env

# 4. Run database migrations
npx drizzle-kit migrate

# 5. Seed bird metadata
node src/scripts/seed.js

# 6. Start development server
npm run dev
```

Health check:

```bash
curl http://localhost:5001/api/health
# → { "message": "Server is running successfully" }
```

> The FastAPI ML service must be running separately (default: `http://localhost:8000`) for predictions to work.

---

## 🏗️ Architecture

### Layered Request Pattern

Every request flows through the same consistent pipeline:

```
HTTP Request
     │
     ▼
┌─────────────┐
│   Routes    │  auth.routes.js / birds.routes.js / favorites.routes.js / history.routes.js
│             │  Defines method + path + middleware composition
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Middleware │  auth.middleware.js  →  verifies JWT, sets req.user
│             │  upload.middleware.js →  Multer memory storage, sets req.file
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Controllers │  auth / birds / favorites / history controllers
│             │  Orchestrates: validate → query → call services → enrich → respond
└──────┬──────┘
       │
       ├───────────────────────────────┐
       ▼                               ▼
┌─────────────┐                ┌──────────────┐
│  Services   │                │  Drizzle ORM │
│             │                │              │
│ ml.service  │                │  Neon        │
│ s3.service  │                │  PostgreSQL  │
└──────┬──────┘                └──────────────┘
       │
       ▼
   FastAPI / AWS S3

       │
       ▼
┌─────────────┐
│   Utils     │  generateTokens.js  →  JWT signing
│             │  birdResponse.js    →  enrichBird() / enrichBirds()
└─────────────┘
```

### Component Responsibilities

| File/Folder | Who calls it | What it does |
|------------|-------------|--------------|
| `server.js` | Uvicorn/Render | App factory, CORS, JSON parsing, route mounting, health endpoint, cron |
| `config/env.js` | All | Typed environment variable access |
| `config/db.js` | ORM | Drizzle + Neon serverless client setup |
| `config/cron.js` | server.js (production) | 14-min keep-alive ping |
| `routes/*.js` | server.js | HTTP method/path/middleware declarations |
| `controllers/*.js` | Routes | Use-case orchestration + response |
| `middleware/auth.middleware.js` | Protected routes | JWT verification, `req.user` injection |
| `middleware/upload.middleware.js` | Prediction route | Multer memory-mode file parsing |
| `services/ml.service.js` | Birds controller | Multipart → FastAPI → prediction JSON |
| `services/s3.service.js` | enrichBird() | GetObject → signed URL |
| `utils/generateTokens.js` | Auth controller | Signs JWT with 7-day expiry |
| `utils/birdResponse.js` | All controllers returning birds | Strips `aws_image_key`, injects `image_url` |
| `db/schema.js` | Drizzle | Table + column + constraint definitions |
| `db/migrations/` | Drizzle Kit | Applied SQL migrations |
| `seed/birds.js` | seed.js script | 50-species metadata payloads |
| `scripts/seed.js` | Manual/CI | Updates existing bird records with metadata |

---

## 📁 Project Structure

```
backend/
│
├── Dockerfile                    # Container image (Node.js runtime)
├── package.json
├── drizzle.config.js             # Drizzle Kit migration config
│
└── src/
    ├── server.js                 # App factory, CORS, routes, cron, health
    │
    ├── config/
    │   ├── env.js                # Runtime environment variables
    │   ├── db.js                 # Drizzle + Neon connection
    │   └── cron.js               # Production keep-alive scheduler
    │
    ├── routes/
    │   ├── auth.routes.js        # /api/auth/*
    │   ├── birds.routes.js       # /api/birds/*
    │   ├── favorites.routes.js   # /api/favorites
    │   └── history.routes.js     # /api/history
    │
    ├── controllers/
    │   ├── auth.controller.js    # signup, login, me
    │   ├── birds.controller.js   # predict, getById
    │   ├── favorites.controller.js # add, list, remove
    │   └── history.controller.js # list, delete
    │
    ├── middleware/
    │   ├── auth.middleware.js    # verifyJWT → req.user
    │   └── upload.middleware.js  # Multer memory → req.file
    │
    ├── services/
    │   ├── ml.service.js         # Posts image buffer to FastAPI
    │   └── s3.service.js         # Generates signed GetObject URLs
    │
    ├── utils/
    │   ├── generateTokens.js     # JWT signing (7-day expiry)
    │   └── birdResponse.js       # enrichBird() / enrichBirds()
    │
    ├── db/
    │   ├── schema.js             # Drizzle table definitions
    │   └── migrations/           # SQL migration files
    │
    ├── seed/
    │   └── birds.js              # 50-species metadata payloads
    │
    └── scripts/
        └── seed.js               # Metadata update runner
```

---

## 🔄 Request Lifecycle Pattern

All four resource domains follow the same controller pattern:

```
1. Extract input from req.body / req.params / req.file / req.user
        │
2. Validate required fields (manual or schema-based)
        │
3. Query PostgreSQL via Drizzle ORM
        │
4. Call external services if needed (ML / S3)
        │
5. Transform result through enrichment utility
        │
6. Return JSON response with appropriate status
```

---

## 🔐 Authentication System

### Registration Flow

```
POST /api/auth/signup
       │
       ├─ Trim username, normalize email to lowercase
       ├─ Validate: username (3-20 chars), email format (≤254 chars), password (6-25 chars)
       │   password requires uppercase + lowercase + digit
       │   allowed chars: letters, digits, @, -
       │
       ├─ Check email uniqueness in users table
       │
       ├─ bcrypt.hash(password, saltRounds=10)
       │
       ├─ INSERT into users
       │
       ├─ generateToken(user.id) → 7-day JWT
       │
       └─ Return { message, token, user: { id, email, username } }
```

### Login Flow

```
POST /api/auth/login
       │
       ├─ Normalize email
       ├─ Query user by email
       ├─ bcrypt.compare(password, hash)
       │   ← Same error message for "user not found" and "wrong password"
       │     prevents account enumeration
       │
       └─ Return { token, user: { id, email, username } }
```

### JWT Design

```json
{
  "id": "<user-uuid>",
  "iat": "<issued-at-unix>",
  "exp": "<7-days-later-unix>"
}
```

### Auth Middleware

```
Authorization: Bearer <token>
       │
       ├─ Requires "Bearer " prefix
       ├─ jsonwebtoken.verify(token, JWT_SECRET)
       ├─ Places decoded payload on req.user
       └─ Returns 401 for missing / expired / invalid tokens
```

> **Key security property:** All protected controllers derive `user_id` from `req.user` (the verified JWT) — never from the request body. A user cannot access another user's resources by changing an ID.

### Session Boot (Flutter side)

```
App starts
    │
    ├─ Read token from flutter_secure_storage
    │
    ├─ If token exists: GET /api/auth/me
    │     ├─ Valid  → enter /main
    │     └─ Invalid → delete token → go to sign-in
    │
    └─ No token → go to welcome
```

---

## 🗄️ Database Design

### Entity Relationship Diagram

```
USERS ──────────────────────────────────────────────────────────
  id (UUID, PK)             ──┐
  username (text, not null)   │
  email (text, unique)        │  1:N
  password_hash (text)        │
  created_at (timestamp)      ├──── FAVORITES
  updated_at (timestamp)      │      user_id (UUID, FK, composite PK) ──┐
                              │      bird_id (UUID, FK, composite PK) ──┤
                              │      created_at                          │
                              │                                          │
                              ├──── HISTORY                             │
                              │      id (serial, PK)                    │
                              │      user_id (UUID, FK, indexed)        │
                              │      bird_id (UUID, FK)  ───────────────┤
                              │      confidence (real)                   │
                              │      predicted_at (timestamp)           │
                              │                                          │
BIRDS ──────────────────────────────────────────────────────────         │
  id (UUID, PK) ─────────────────────────────────────────────────────────┘
  name (text, unique)         ← Must exactly match ML class_names.json
  description (text, null)
  scientific_name (text, null)
  habitat (text, null)
  conservation_status (text, null)
  aws_image_key (text, null)  ← Never returned to client; replaced by image_url
```

### Table Decisions

| Decision | Detail |
|---------|--------|
| UUIDs for user/bird IDs | Non-sequential, safe to expose in APIs |
| Composite PK on favorites `(user_id, bird_id)` | Duplicate prevention is atomic — no race condition |
| `birds.name` must match ML class exactly | Cross-system invariant — any mismatch silently breaks enrichment |
| No `aws_image_key` on history | User photos not stored; history references canonical `birds` record |
| `history_user_idx` on `history.user_id` | Fast per-user history queries |

### Migration History

| Migration | Change |
|-----------|--------|
| `0000` | Created `users`, `birds`, `favorites`, `history` with FK constraints |
| `0001` | Added `confidence`, `user_image_key` to history, renamed timestamp |
| `0002` | Renamed `image_key` → `aws_image_key`, added `history_user_idx` |
| `0003` | **Dropped `user_image_key`** — finalized privacy decision |

### Drizzle ORM Pattern

```javascript
// Prediction history insert
await db.insert(history).values({
  user_id: req.user.id,
  bird_id: foundBird.id,
  confidence: prediction.confidence,
});

// History retrieval with join
const rows = await db
  .select()
  .from(history)
  .innerJoin(birds, eq(history.bird_id, birds.id))
  .where(eq(history.user_id, req.user.id))
  .orderBy(desc(history.predicted_at));
```

---

## 📡 API Reference

All routes are under `/api`.

### Health

| Method | Path | Auth | Response |
|--------|------|------|----------|
| `GET` | `/api/health` | None | `{ "message": "Server is running successfully" }` |

### Authentication

| Method | Path | Auth | Body |
|--------|------|------|------|
| `POST` | `/api/auth/signup` | None | `{ username, email, password }` |
| `POST` | `/api/auth/login` | None | `{ email, password }` |
| `GET` | `/api/auth/me` | Bearer JWT | None |

**Signup success `201`:**
```json
{
  "message": "User created successfully",
  "token": "<jwt>",
  "user": { "id": "<uuid>", "email": "...", "username": "..." }
}
```

**Password validation rules:**
```
Length:       6–25 characters
Requirements: ≥1 uppercase + ≥1 lowercase + ≥1 digit
Allowed:      letters, digits, @, -
```

### Birds

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/api/birds/:bird_id` | None | Fetch one enriched bird record |
| `POST` | `/api/birds/predict` | Bearer JWT | Predict + enrich + record history |

**`POST /api/birds/predict`** — Content-Type: `multipart/form-data`, field: `image`

**Success `200`:**
```json
{
  "bird": {
    "id": "<uuid>",
    "name": "Baird_Sparrow",
    "description": "...",
    "scientific_name": "Centronyx bairdii",
    "habitat": "...",
    "conservation_status": "...",
    "image_url": "<temporary-s3-signed-url>"
  },
  "confidence": 99.25,
  "is_confident": true
}
```

### Favorites

| Method | Path | Auth | Body |
|--------|------|------|------|
| `POST` | `/api/favorites` | Bearer JWT | `{ "bird_id": "<uuid>" }` |
| `GET` | `/api/favorites` | Bearer JWT | None |
| `DELETE` | `/api/favorites` | Bearer JWT | `{ "bird_id": "<uuid>" }` |

**List `200`:** Array of enriched bird records with `created_at`.

### History

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/api/history` | Bearer JWT | Newest-first enriched prediction list |
| `DELETE` | `/api/history` | Bearer JWT | Delete all history for current user |

**List `200`:** Array of `{ bird, confidence, predicted_at }`.

### Status Code Reference

| Code | Meaning |
|------|---------|
| `200` | OK — read, login, prediction, deletion |
| `201` | Created — user or favorite created |
| `400` | Bad request — missing / invalid input |
| `401` | Unauthorized — missing/expired/invalid JWT or wrong credentials |
| `404` | Not found — user or bird does not exist |
| `413` | Payload too large — image exceeds 3 MB (FastAPI) |
| `500` | Internal server error — unexpected failure |

---

## 🔮 Prediction Pipeline

The full end-to-end prediction flow across all services:

```
Flutter: User selects/captures image
       │
       │  POST /api/birds/predict
       │  multipart/form-data  +  Authorization: Bearer <jwt>
       ▼
Express: auth.middleware.js
       │  Verifies JWT → req.user.id
       ▼
Express: upload.middleware.js (Multer)
       │  Parses image into memory → req.file.buffer
       ▼
Express: birds.controller.js
       │
       ├─ ml.service.js:
       │    FormData with image buffer
       │    POST http://<ML_SERVICE>/api/predict/
       │    ← { bird: "Baird_Sparrow", confidence: 99.25, is_confident: true }
       │
       ├─ Drizzle: SELECT * FROM birds WHERE name = "Baird_Sparrow"
       │    ← canonical bird record with aws_image_key
       │
       ├─ s3.service.js:
       │    GetObjectCommand(bucket, "birds/Baird_Sparrow.jpg")
       │    ← temporary signed URL (1 hour TTL)
       │
       ├─ Drizzle: INSERT INTO history (user_id, bird_id, confidence)
       │
       └─ enrichBird(): remove aws_image_key, add image_url
       │
       ▼
Flutter: Renders enriched result screen
```

### Prediction Failure Points

| Stage | Failure | Status |
|-------|---------|--------|
| Auth | Missing / expired JWT | 401 |
| Upload | No file in request | 400 |
| FastAPI call | Service unavailable / timeout | 502 |
| FastAPI validation | Bad MIME / too large / corrupt | 400/413 |
| Bird lookup | Class name not in DB | 404 |
| S3 signing | Wrong key / bucket / perms | 500 |
| History insert | DB failure | 500 |

> User uploads are **never written** to PostgreSQL, S3, or disk — they exist in Express memory only during the request.

---

## ⭐ Favorites System

```
Add favorite:
  POST /api/favorites { bird_id }
       │
       ├─ user_id from req.user (JWT)
       ├─ INSERT (user_id, bird_id) into favorites
       └─ DB composite PK prevents duplicates atomically

List favorites:
  GET /api/favorites
       │
       ├─ SELECT favorites JOIN birds WHERE user_id = req.user.id
       ├─ enrichBirds() — concurrent signed URL generation via Promise.all
       └─ Return enriched list

Remove favorite:
  DELETE /api/favorites { bird_id }
       │
       ├─ WHERE user_id = req.user.id AND bird_id = ?
       └─ A user cannot remove another user's favorites (JWT enforces this)
```

**Why composite primary key over generated row ID?**

```
PRIMARY KEY (user_id, bird_id)

Benefits:
✅ Duplicate prevention is atomic — no TOCTOU race condition
✅ No redundant generated ID needed
✅ Relationship identity matches domain semantics
✅ Concurrent requests cannot create duplicate pairs

Note: Map duplicate-key DB errors to 409 Conflict (not 500) — improvement needed.
```

---

## 📜 History System

```
Record (after every successful authenticated prediction):
  INSERT INTO history (user_id, bird_id, confidence, predicted_at)

List:
  SELECT history JOIN birds
  WHERE history.user_id = req.user.id
  ORDER BY predicted_at DESC
  → enrichBirds() for signed URLs

Delete all:
  DELETE FROM history WHERE user_id = req.user.id
```

**What history stores vs. doesn't:**

| Data | Stored? | Reason |
|------|---------|--------|
| Authenticated user ID | ✅ | Ownership |
| Canonical bird ID | ✅ | Links to metadata |
| Confidence score | ✅ | Product feature |
| Prediction timestamp | ✅ | Ordering |
| User-uploaded photograph | ❌ | Privacy decision |
| Bird metadata (redundant copy) | ❌ | Normalized — join to birds |

---

## ☁️ AWS S3 & Signed URLs

### Bucket Structure

```
s3://birdlens-bucket/
└── birds/
    ├── American_Crow.jpg
    ├── Anna_Hummingbird.jpg
    ├── Baird_Sparrow.jpg
    └── ... (one per supported species)
```

### Why Signed URLs (not public bucket)?

```
Option A: Public bucket URLs
  ❌ Bucket must be public — not safe
  ❌ Permanent access — can't revoke
  ✅ Simple to implement

Option B: Proxy through Express
  ❌ Every image byte goes through Node — high bandwidth cost
  ❌ Adds latency for every image load
  ✅ Full access control

Option C: Signed URLs ← BirdLens choice
  ✅ Bucket stays private
  ✅ Time-limited access (1 hour TTL)
  ✅ Client fetches directly from S3 — no proxy bandwidth
  ✅ No AWS credentials in client
  ✅ Industry standard for private object delivery
```

### Signed URL Flow

```
Express: s3.service.js
       │
       ├─ S3Client({ region, credentials })
       ├─ GetObjectCommand({ Bucket, Key: "birds/Baird_Sparrow.jpg" })
       └─ getSignedUrl(client, command, { expiresIn: 3600 })
              │
              └─ Temporary URL with auth params embedded
                     │
                     └─ Client GETs image directly from S3
```

> Signed URLs include auth metadata (credential scope, expiry, signature) — this is **expected and safe**. The AWS secret access key is never included.

### Response Enrichment

```javascript
// Internal bird record:
{ id, name, description, aws_image_key, scientific_name, habitat, conservation_status }

// After enrichBird():
{ id, name, description, image_url, scientific_name, habitat, conservation_status }
//  aws_image_key is removed before client response
```

`enrichBirds()` uses `Promise.all` to sign all images in a list concurrently.

---

## 🐦 Bird Metadata Enrichment

### Cross-System Class Name Invariant

```
ML class_names.json[index]
        ==
FastAPI response: prediction.bird
        ==
PostgreSQL birds.name
        ==
S3 key: birds/<name>.jpg
```

> A single character difference (case, underscore, space) causes inference to succeed but metadata enrichment to silently fail — the most dangerous bug category in this system.

### Seeding Metadata

```bash
# Update all 50 bird records with metadata
node src/scripts/seed.js
```

`seed.js` iterates `seed/birds.js`, matches each entry by exact `birds.name`, and updates `scientific_name`, `description`, `habitat`, and `conservation_status`. Does not insert missing birds — only updates existing rows.

---

## ⚙️ Environment Variables

```env
# Database
DB_URL=postgresql://<user>:<pass>@<neon-host>/<db>?sslmode=require

# Server
PORT=5001
NODE_ENV=production

# Auth
JWT_SECRET=<minimum-32-char-random-secret>

# ML Service
ML_SERVICE=http://localhost:8000        # local
# ML_SERVICE=https://your-ml.onrender.com  # deployed

# AWS S3
AWS_BUCKET_NAME=birdlens-images
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=<key-id>
AWS_SECRET_ACCESS_KEY=<secret>

# Keep-alive (Render free tier)
API_URL=https://your-api.onrender.com/api/health
```

> Never commit real secrets. Use Render's environment variable panel in production.

---

## 🐳 Docker

### Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY src/ ./src/

EXPOSE 5001

CMD ["node", "src/server.js"]
```

### Docker Compose (Local Multi-Service)

```yaml
# docker-compose.yml (repo root)
version: "3.9"
services:

  backend:
    build: ./backend
    ports:
      - "5001:5001"
    environment:
      - DB_URL=${DB_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ML_SERVICE=http://ml:8000
      - AWS_BUCKET_NAME=${AWS_BUCKET_NAME}
      - AWS_REGION=${AWS_REGION}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - NODE_ENV=development
    depends_on:
      - ml

  ml:
    build: ./ML_service
    ports:
      - "8000:8000"
    volumes:
      - ./ML_service/app/models:/app/app/models
```

**Run everything locally:**

```bash
# From repo root
docker compose up --build
```

**Individual commands:**

```bash
# Build only backend
docker build -t birdlens-backend ./backend

# Run backend container
docker run -p 5001:5001 --env-file ./backend/.env birdlens-backend

# Shell into running container
docker exec -it <container-id> sh
```

---

## 🚀 Deployment on Render

Both services are deployed on Render as Web Services.

### Backend Render Configuration

| Field | Value |
|-------|-------|
| Runtime | Docker |
| Dockerfile path | `./backend/Dockerfile` |
| Port | `5001` |
| Health check | `/api/health` |

**Environment variables:** Set all from `.env` in Render dashboard.

### Deployment Order

```
1. Deploy Neon PostgreSQL (already managed/hosted)
2. Run migrations: npx drizzle-kit migrate
3. Seed bird records: node src/scripts/seed.js
4. Upload representative images to S3 bucket
5. Deploy FastAPI ML service on Render (get its URL)
6. Deploy Express backend on Render (set ML_SERVICE to FastAPI URL)
7. Smoke test all endpoints
8. Set API_BASE_URL in Flutter .env → build APK
```

### Keep-Alive Cron

Render free tier services sleep after inactivity. The backend starts a production-only cron job:

```javascript
// config/cron.js
// Pings API_URL and ML_SERVICE/health every 14 minutes
// Prevents hobby-tier cold starts during active usage
```

> This is a **hosting workaround**, not a production monitoring strategy.

---

## 🔒 Security Review

### Strengths

```
✅ Passwords hashed with bcrypt (cost 10)
✅ Raw passwords never returned or logged
✅ JWTs expire after 7 days
✅ Protected resources derive user from verified JWT (not request body)
✅ Drizzle ORM — no string-built SQL
✅ S3 bucket is private by design
✅ Signed URLs replace public object access
✅ aws_image_key stripped from all client responses
✅ User uploads never intentionally persisted
✅ Same error for "user not found" and "wrong password" — no enumeration
✅ Environment files in .gitignore
```

### Known Weaknesses

```
⚠️  CORS is currently permissive (allow all origins)
⚠️  No rate limiting on auth or prediction endpoints
⚠️  No Express-level upload size limit (only FastAPI enforces 3 MB)
⚠️  Some error responses leak internal error.message
⚠️  No service-to-service auth between Express and FastAPI
⚠️  AWS uses long-lived access keys (not IAM roles/workload identity)
⚠️  No JWT refresh or revocation mechanism
⚠️  No request body schema validation
⚠️  Duplicate favorites return 500 instead of 409
```

---

## 📈 Scalability Notes

| Scale | Current fit | What's needed |
|-------|-------------|---------------|
| 10–100 users | ✅ Sufficient | Focus on correctness |
| 1,000 users | ⚠️ Needs work | Rate limiting, pagination, multiple ML workers, metrics |
| 10,000 users | ❌ Not ready | Horizontal scale, caching, load balancer, Redis, queues, CDN |

Express is **largely stateless** — JWT carries identity, PostgreSQL owns state. Horizontal scaling is straightforward once observability and external dependency handling is solid.

---

## 🗺️ Known Limitations & Roadmap

### Immediate (before any production traffic)

```
□ Strict CORS allowlist (not allow-all)
□ Rate limiting on /signup, /login, /predict
□ Express-level multipart size limit (before buffer fills memory)
□ Request schema validation (zod or joi)
□ Map duplicate-key DB errors → 409 Conflict
□ Centralized error middleware (not per-controller try/catch)
□ Safe error messages (no internal error.message to client)
□ Explicit ML service timeout + retry budget
□ Service-to-service auth between Express and FastAPI
□ Automated tests (unit + integration)
```

### Medium Term

```
□ Pagination for /history and /favorites
□ Individual history event deletion
□ JWT refresh + shorter-lived access tokens
□ Password reset + email verification
□ Model version in prediction response and history row
□ Bird metadata admin endpoint
□ OpenAPI spec generation
□ Structured logging (correlation IDs)
□ Metrics and tracing
```

---

## 🛠️ Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Cannot connect to database` | Bad `DB_URL` or missing SSL params | Check `.env`, ensure `?sslmode=require` for Neon |
| `JWT_SECRET is not defined` | Missing env var | Set `JWT_SECRET` in `.env` |
| `ML service unavailable` | FastAPI not running | Start FastAPI on port 8000 or check `ML_SERVICE` env |
| `Bird not found after prediction` | Class name mismatch | Verify `birds.name` matches `class_names.json` exactly |
| `S3 signed URL fails` | Wrong key/bucket/region/permission | Check `AWS_*` vars; verify `birds/<name>.jpg` exists in bucket |
| `Duplicate favorite returns 500` | DB unique constraint not mapped | Known issue — map to 409 |
| `History empty after prediction` | History insert failing silently | Check controller error handling and DB connection |
| `Service sleeps on Render` | Hobby tier cold start | Check cron keep-alive config; upgrade to paid tier for prod |

---

<div align="center">

**The backend is the system's trust boundary.**
Everything authenticated, enriched, and secured happens here.

*BirdLens Backend — Part of the BirdLens full-stack AI bird identification system*

</div>
