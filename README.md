# 🦅 BirdLens

> **AI-powered bird identification** — photograph a bird, get the species, conservation status, habitat, and a curated image. Instantly.

```
Accuracy: 91.02%  ·  50 species  ·  MobileNetV2  ·  Flutter + Node.js + FastAPI + PostgreSQL + AWS S3
```

---

## What Is BirdLens?

BirdLens turns a bird photograph into an educational species record. It does not stop at a classification label — it combines the ML prediction with curated metadata (scientific name, habitat, conservation status) and delivers a representative image from a private AWS S3 bucket through a temporary signed URL.

Authenticated users maintain a personal favorites collection and a full prediction history. Uploaded photographs are processed in memory for inference and are **not persisted** anywhere.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  Flutter Mobile App                                                  │
│  Riverpod · Dio · GoRouter · flutter_secure_storage                 │
└──────────────────────────┬──────────────────────────────────────────┘
                           │  HTTPS REST · Bearer JWT · multipart/form-data
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Node.js / Express  —  Orchestration API                            │
│                                                                     │
│   Auth     Birds    Favorites   History    Health                   │
│    │         │          │          │         │                      │
│    └────┬────┘──────────┘──────────┘         │                     │
│         │                                                           │
│    ┌────▼──────────┐        ┌────────────────────────┐             │
│    │  Drizzle ORM  │        │  birdResponse utility  │             │
│    │  Neon PgSQL   │        │  (enrichment + signing) │            │
│    └───────────────┘        └────────────┬───────────┘             │
│                                          │                          │
│                             ┌────────────▼───────────┐             │
│                             │  AWS S3 (private)      │             │
│                             │  Signed URLs (1 hour)  │             │
│                             └────────────────────────┘             │
└──────────────────────────┬──────────────────────────────────────────┘
                           │  multipart/form-data (image bytes)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  FastAPI  —  ML Inference Microservice                              │
│                                                                     │
│   POST /api/predict/                                                │
│        │                                                            │
│        ▼                                                            │
│   PyTorch MobileNetV2  (50-class transfer learning)                 │
│        │                                                            │
│        ▼                                                            │
│   { "bird": "Baird_Sparrow", "confidence": 99.25 }                 │
└─────────────────────────────────────────────────────────────────────┘
```

The architecture deliberately separates the mobile experience, public API, inference runtime, relational persistence, and object storage so each component can evolve independently.

---

## Feature Set

| Area | What users can do |
|---|---|
| Onboarding | Intro to AI identification, history, and favorites |
| Authentication | Register, sign in, persist session securely, sign out |
| Scan / Identify | Capture or select an image and submit for prediction |
| Prediction result | Species name, confidence score, confidence indicator |
| Bird details | Representative image, scientific name, habitat, description, conservation status |
| Favorites | Save and manage a personal collection of birds |
| History | Review all past identifications, newest first; bulk-delete |

---

## Technology Stack

### Flutter Frontend

| Concern | Package |
|---|---|
| State management | `riverpod` |
| HTTP + multipart uploads | `dio` |
| Navigation | `go_router` |
| Secure token storage | `flutter_secure_storage` |
| Target | iOS + Android (cross-platform) |

### Node.js Backend

| Concern | Package |
|---|---|
| Web framework | `express` |
| ORM + migrations | `drizzle-orm`, `drizzle-kit` |
| Database | Neon PostgreSQL (serverless) |
| Auth | `jsonwebtoken`, `bcrypt` |
| File upload | `multer` (memory storage) |
| AWS | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` |

### FastAPI ML Service

| Concern | Tool |
|---|---|
| Web framework | FastAPI + Uvicorn |
| Inference | PyTorch, torchvision |
| Model | MobileNetV2 (transfer learning) |
| Image processing | Pillow |
| Class mapping | `class_names.json` |

### Infrastructure

| Component | Service |
|---|---|
| Relational DB | Neon PostgreSQL |
| Object storage | AWS S3 (private bucket) |
| Image signing | AWS SDK v3 GetObject presigned URLs |

---

## Machine Learning

### Model

- **Architecture:** MobileNetV2 pretrained on ImageNet, final classifier replaced for 50-class bird identification
- **Training dataset:** CUB-200 (or equivalent) subset — 50 species, ~6,000+ images
- **Best reported accuracy:** 91.02%
- **Augmentations:** Random horizontal flip, random crop, color jitter, normalization (ImageNet stats)
- **Loss:** CrossEntropyLoss
- **Optimizer:** Adam with learning rate scheduling

### Training workflow

```bash
# In the ml/ directory
python train.py        # Full training run — saves best checkpoint
python evaluate.py     # Validation metrics
python export.py       # Exports model.pt + class_names.json
```

The model artifact and class mapping are the deployment contract between the ML service and the backend. The class string in `class_names.json[index]` must exactly match the `name` column in the `birds` database table.

### Prediction confidence

The model returns the maximum softmax probability as `confidence` (0–100). The backend includes `is_confident: true` when the score crosses a defined threshold, enabling the mobile app to surface appropriate uncertainty messaging.

---

## Database Schema

```
users
  id             UUID    PK
  username       text    not null
  email          text    not null, unique
  password_hash  text    not null
  created_at     ts
  updated_at     ts

birds
  id                  UUID    PK
  name                text    not null, unique  ← ML class string
  description         text
  aws_image_key       text    ← private S3 object key (hidden from API)
  scientific_name     text
  habitat             text
  conservation_status text

favorites
  user_id    UUID    PK, FK → users
  bird_id    UUID    PK, FK → birds    ← composite PK = no duplicates
  created_at ts

history
  id           serial  PK
  user_id      UUID    not null, FK → users, indexed
  bird_id      UUID    not null, FK → birds
  confidence   real    not null
  predicted_at ts
```

History and favorites store foreign keys to the canonical bird record — never duplicated metadata. Changing a bird's description or image propagates to all history and favorites automatically.

---

## API Reference (Summary)

Base: `https://<your-api>/api`

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/signup` | Public | Register; returns JWT |
| `POST` | `/auth/login` | Public | Login; returns JWT |
| `GET` | `/auth/me` | Bearer | Current user (`id`, `username`, `email`) |

### Birds

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/birds/:id` | Public | Species detail with signed `image_url` |
| `POST` | `/birds/predict` | Bearer | Multipart image upload → enriched prediction |

### Favorites

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/favorites` | Bearer | `{ bird_id }` → save bird |
| `GET` | `/favorites` | Bearer | List with signed image URLs |
| `DELETE` | `/favorites` | Bearer | `{ bird_id }` → remove bird |

### History

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/history` | Bearer | All predictions, newest first |
| `DELETE` | `/history` | Bearer | Clear all history for user |

### Health

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/health` | `200` when Express is alive |

---

## End-to-End Prediction Flow

```
User selects photo in Flutter
        │
        │  POST /api/birds/predict
        │  Authorization: Bearer <jwt>
        │  Content-Type: multipart/form-data
        │  image: <bytes>
        ▼
Express protectRoute (JWT verify) → sets req.user
        │
        ▼
Multer → image buffer in req.file.buffer (no disk write)
        │
        ▼
ml.service.js → FormData → FastAPI /api/predict/
        │
        ▼
PyTorch MobileNetV2 → { bird: "Baird_Sparrow", confidence: 99.25 }
        │
        ▼
birds.controller → SELECT * FROM birds WHERE name = 'Baird_Sparrow'
        │
        ▼
birdResponse.js → GetObject signed URL (1 hour) → replaces aws_image_key
        │
        ▼
INSERT INTO history (user_id, bird_id, confidence)
        │
        ▼
{
  bird: {
    id, name, description, scientific_name,
    habitat, conservation_status, image_url
  },
  confidence: 99.25,
  is_confident: true
}
        │
        ▼
Flutter renders result screen
```

---

## Privacy Design

BirdLens was designed with explicit privacy decisions:

| Decision | Rationale |
|---|---|
| User photos never stored | Images are forwarded in memory and discarded after inference — reduces privacy risk, storage cost, and regulatory surface |
| Representative images in private S3 | Bucket is not public; all image access goes through 1-hour signed URLs |
| `aws_image_key` never returned | Raw S3 keys are stripped by `birdResponse.js` before any response leaves the server |
| JWT ownership model | Controllers use `req.user.id` from the verified token — callers cannot access other users' data |
| Password hashes never returned | `password_hash` is excluded from every response |

---

## Repository Structure

```
birdlens/
├── backend/          ← Node.js / Express API
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── db/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── scripts/
│   │   ├── seed/
│   │   ├── services/
│   │   └── utils/
│   ├── drizzle.config.js
│   └── package.json
│
├── ml/               ← FastAPI inference microservice
│   ├── main.py           ← FastAPI app + /api/predict/ endpoint
│   ├── model.pt          ← Trained MobileNetV2 weights
│   ├── class_names.json  ← Ordered class index → species name
│   └── requirements.txt
│
├── training/         ← PyTorch training pipeline
│   ├── train.py
│   ├── evaluate.py
│   ├── dataset.py
│   └── config.py
│
└── mobile/           ← Flutter application
    ├── lib/
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── birds/
    │   │   ├── favorites/
    │   │   ├── history/
    │   │   └── scan/
    │   ├── core/
    │   │   ├── providers/
    │   │   ├── router/
    │   │   └── network/
    │   └── main.dart
    └── pubspec.yaml
```

---

## Getting Started

### Prerequisites

- Node.js 18+
- Python 3.10+
- Flutter 3.x
- PostgreSQL (or Neon account)
- AWS S3 bucket (private)

### Backend

```bash
cd backend
npm install

# Create .env (see Configuration section)
cp .env.example .env

# Run migrations
npx drizzle-kit migrate

# Seed bird metadata (after migrations)
node src/scripts/seed.js

# Start development server
npm run dev
```

### ML Service

```bash
cd ml
pip install -r requirements.txt

# Place model.pt and class_names.json in ml/
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

---

## Configuration

### Backend environment variables

| Variable | Description |
|---|---|
| `DB_URL` | Neon/PostgreSQL connection string |
| `PORT` | Express port (default: `5001`) |
| `NODE_ENV` | `production` activates keep-alive cron |
| `API_URL` | Backend URL for cron ping |
| `JWT_SECRET` | Signing secret — keep strong and secret |
| `ML_SERVICE` | FastAPI base URL |
| `AWS_BUCKET_NAME` | S3 bucket name |
| `AWS_REGION` | S3 region |
| `AWS_ACCESS_KEY_ID` | S3 identity |
| `AWS_SECRET_ACCESS_KEY` | S3 credential |

**Never commit `.env` files.** All environment files are gitignored.

---

## Security Overview

### Strengths

- JWT ownership — all protected resources are scoped to `req.user.id`
- bcrypt password hashing (10 rounds)
- No raw SQL — all queries through Drizzle ORM
- Private S3 with 1-hour signed URLs
- User images never persisted

### Known gaps (next priorities)

1. Request schema validation (bodies, params, file metadata)
2. Multer file-size and MIME-type limits
3. Rate limiting and strict CORS
4. Centralized error handler (no `error.message` leakage)
5. Duplicate favorite → `409 Conflict` (currently `500`)
6. ML service boundary authentication
7. Service timeouts and circuit-breaking
8. IAM roles / managed identity in production

---

## Engineering Assessment

| Area | Score |
|---|---|
| Backend engineering | 8.0 / 10 |
| Machine learning | 7.5 / 10 |
| Cloud engineering | 7.5 / 10 |
| Frontend architecture | 8.0 / 10 |
| Database design | 8.5 / 10 |
| Security & privacy | 7.5 / 10 |
| System design | 8.5 / 10 |
| Production readiness | 6.5 / 10 |
| Portfolio impact | 9.0 / 10 |

BirdLens is best understood as a production-oriented engineering case study built around an applied ML feature. Its strongest contribution is not the 91.02% model accuracy — it is the complete, defensible system around that model: cross-platform client, secure identity, dedicated inference microservice, normalized relational schema, private cloud storage, temporary signed image delivery, and privacy-by-design non-persistence of uploads.

---

## Roadmap

**Reliability phase (next)**
- Automated tests (unit + integration)
- Request validation (Zod on all routes)
- Centralized error handling
- Service-to-service authentication for ML boundary
- CI/CD pipeline

**Operational maturity**
- Structured logging and distributed tracing
- Health checks for DB, S3, and ML service
- Pagination for history and favorites
- OpenAPI specification

**ML improvements**
- Per-class metrics and confusion matrix
- Confidence calibration (temperature scaling)
- Top-K species output
- Unknown/out-of-distribution rejection
- Model versioning and A/B deployment

**Feature expansion**
- Push notifications for rare bird sightings
- Map view of prediction history
- Community-contributed species data
- Offline-capable on-device model

---

## Why This Architecture

**Why is FastAPI separate from Node.js?**
Python's ML ecosystem (PyTorch, torchvision, Pillow) lives in Python. Running inference in a Node.js child process or via a native addon couples the systems unnecessarily, makes GPU access harder, and complicates deployment. A dedicated FastAPI service has an independent resource footprint and can be scaled, updated, or replaced without touching the backend.

**Why are user uploads not stored?**
Privacy-by-design. The system has no legitimate reason to retain user photographs after inference completes. Not storing them eliminates a class of privacy risk and reduces S3 cost and regulatory surface with no loss of functionality.

**Why does the composite primary key matter for favorites?**
A unique constraint on `(user_id, bird_id)` is enforced at the database level. No application code, no race condition, no additional query can produce a duplicate favorite — the schema makes it structurally impossible.

**Why private S3 + signed URLs instead of public images?**
Public buckets expose all content permanently to anyone with the URL. Signed URLs give time-bounded access that can be audited, are scoped to specific objects, and can be invalidated by rotating credentials. The access pattern is identical to the client — they just can't keep the URL past its expiry.

---

> BirdLens demonstrates the complete path from model training to a secure, user-facing product. With automated tests, observability, CI/CD, and service security hardening, it progresses from a strong portfolio-scale system into a credible production deployment.