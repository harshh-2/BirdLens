# 🦅 BirdLens

> **AI-powered cross-platform bird identification app. Point your camera at a bird, get the species name, scientific info, habitat, conservation status, and a high-quality image — instantly.**

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?style=flat&logo=node.js)](https://nodejs.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.11x-009688?style=flat&logo=fastapi)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.x-EE4C2C?style=flat&logo=pytorch)](https://pytorch.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon-4169E1?style=flat&logo=postgresql)](https://neon.tech)
[![AWS S3](https://img.shields.io/badge/AWS-S3-FF9900?style=flat&logo=amazons3)](https://aws.amazon.com/s3)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker)](https://docker.com)
[![Render](https://img.shields.io/badge/Deployed-Render-46E3B7?style=flat&logo=render)](https://render.com)

</div>

---

## 📸 Screenshots

<table>
  <tr>
    <th>Onboarding</th>
    <th>Sign In</th>
    <th>Home</th>
    <th>Scan</th>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/e37f6af2-28b3-4c0e-a1b3-2b7816dbe6d7" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/649df861-5aee-4159-914e-75fa01b85513" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/ad13c9cd-061f-4766-978c-8f0942da5df4" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/b0011cf4-f505-4235-8bb0-efbdc809c548" width="220"></td>
  </tr>

  <tr>
    <th>Prediction Result</th>
    <th>Bird Details</th>
    <th>Favorites</th>
    <th>History</th>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/0cd71ec6-53d7-42cc-8a7b-658a6b3cde40" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/7d710a99-0bcf-40c6-a6e3-243a1ab47aaf" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/015d0406-e610-4aba-84e6-cdf169912197" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/cfe93a4d-ec4b-4105-94b9-94822bed1c34" width="220"></td>
  </tr>

  <tr>
    <th colspan="4">Profile</th>
  </tr>
  <tr>
    <td colspan="4" align="center">
      <img src="https://github.com/user-attachments/assets/89741b2a-d987-46e2-9064-ea452caeb759" width="220">
    </td>
  </tr>
</table>

---




## ⬇️ Download

<div align="center">

| Platform | Link |
|----------|------|
| 🤖 Android APK | [**Download Latest APK**](https://github.com/harshh-2/BirdLens/releases/tag/Birdlens-v1.1) |

</div>

> Android: Enable "Install from unknown sources" in Settings → Security before installing.

---

## 📑 Table of Contents

- [What Is BirdLens?](#-what-is-birdlens)
- [System Architecture](#️-system-architecture)
- [Technology Stack](#-technology-stack)
- [Repository Structure](#-repository-structure)
- [Full Data Flow](#-full-data-flow)
- [Key Engineering Decisions](#-key-engineering-decisions)
- [Database Design](#️-database-design)
- [API Overview](#-api-overview)
- [Docker & Local Development](#-docker--local-development)
- [Deployment](#-deployment)
- [Security & Privacy](#-security--privacy)
- [Model Performance](#-model-performance)
- [Scalability](#-scalability)
- [Component READMEs](#-component-readmes)
- [Roadmap](#-roadmap)
- [Interview Discussion Topics](#-interview-discussion-topics)

---

## 🔍 What Is BirdLens?

BirdLens transforms a bird photograph into a complete identification result. It does not stop at a raw ML label.

```
User photographs a bird
        │
        ▼
BirdLens returns:
  ├─ Species name           (e.g. "Baird's Sparrow")
  ├─ Scientific name        (e.g. "Centronyx bairdii")
  ├─ Habitat description
  ├─ Conservation status
  ├─ Representative image   (from private AWS S3 via signed URL)
  ├─ Confidence percentage  (e.g. 99.25%)
  ├─ Confidence indicator   (is_confident: true/false)
  └─ Auto-saved to history
```

Authenticated users also get:
- **Favorites** — save birds to a personal collection
- **History** — chronological prediction log (newest first)
- **Privacy** — uploaded photos are used for inference only, never stored

---

## 🏗️ System Architecture

### High-Level Overview

```
┌────────────────────────────────────────────────────────────────┐
│                        USER DEVICE                             │
│                                                                │
│   Flutter App (iOS / Android)                                  │
│   Riverpod · Dio · flutter_secure_storage · GoRouter           │
└────────────────────────┬───────────────────────────────────────┘
                         │  HTTPS + Bearer JWT
                         │  multipart/form-data (image)
                         ▼
┌────────────────────────────────────────────────────────────────┐
│                   PUBLIC API BOUNDARY                          │
│                                                                │
│   Node.js / Express Orchestration API                          │
│   JWT auth · Drizzle ORM · Multer · Axios · CORS · cron        │
└──────┬──────────────────┬────────────────────┬─────────────────┘
       │                  │                    │
       │ multipart        │ SQL queries        │ GetObject
       ▼                  ▼                    ▼
┌──────────────┐  ┌───────────────┐  ┌────────────────────┐
│   FastAPI    │  │     Neon      │  │    Private AWS S3  │
│   ML Service │  │  PostgreSQL   │  │                    │
│              │  │               │  │  birds/            │
│  MobileNetV2 │  │  users        │  │  ├── Crow.jpg      │
│  50 species  │  │  birds        │  │  ├── Sparrow.jpg   │
│  91.02% acc  │  │  favorites    │  │  └── ...           │
│              │  │  history      │  │                    │
│  PyTorch     │  │  Drizzle ORM  │  │  Signed URLs only  │
└──────────────┘  └───────────────┘  └────────────────────┘
```

### Network Trust Boundaries

```
🌐 Public        →  Flutter App
🔒 Public API    →  Express (only public entry point)
🔐 Internal      →  FastAPI ML (private, Express-only access)
🔐 Private Data  →  PostgreSQL (private, ORM access only)
🔐 Private Store →  S3 (private bucket, signed URLs only)
```

### Component Ownership

| Component | Owns | Does NOT own |
|-----------|------|-------------|
| Flutter | Presentation, navigation, token persistence, API consumption | Credentials, DB access, ML |
| Express | Auth, orchestration, persistence, S3 signing, enrichment | Model internals, training |
| FastAPI | Image validation, preprocessing, inference | User identity, favorites, history, S3 |
| PostgreSQL | Relational source of truth | Image bytes, model files |
| S3 | Representative bird images | User prediction uploads |

---

## 🛠️ Technology Stack

### Frontend

| Technology | Version | Role |
|-----------|---------|------|
| Flutter | 3.x | Cross-platform UI framework |
| Dart | 3.x | Frontend language |
| Riverpod | 2.x | State management |
| Dio | 5.x | HTTP client, interceptors, multipart |
| flutter_secure_storage | 9.x | Platform-native JWT persistence |
| flutter_dotenv | 5.x | Non-secret client configuration |
| flutter_screenutil | 5.x | Responsive dimensions |
| go_router | 13.x | Declarative navigation (migration target) |
| cached_network_image | 3.x | S3 image caching |

### Backend

| Technology | Version | Role |
|-----------|---------|------|
| Node.js | 20 | Backend runtime |
| Express | 5 | REST API and middleware |
| bcryptjs | 2.x | Password hashing (cost 10) |
| jsonwebtoken | 9.x | JWT signing and verification |
| Multer | 1.x | Multipart memory storage |
| Drizzle ORM | 0.3x | Relational queries + schema |
| Drizzle Kit | 0.2x | Migration generation |
| Neon serverless | 0.9x | PostgreSQL connectivity |
| AWS SDK v3 | 3.x | S3 + signed URL generation |
| Axios | 1.x | FastAPI service calls |

### Machine Learning

| Technology | Version | Role |
|-----------|---------|------|
| Python | 3.10+ | ML service + training language |
| FastAPI | 0.11x | Inference HTTP API |
| PyTorch | 2.x | Training and inference |
| torchvision | 0.17x | MobileNetV2 + transforms |
| Pillow | 10.x | Image decode + validation |
| Pydantic | 2.x | Response schema validation |
| Uvicorn | 0.29x | ASGI server |

### Infrastructure

| Technology | Role |
|-----------|------|
| Neon PostgreSQL | Managed serverless PostgreSQL |
| AWS S3 (private) | Representative bird image storage |
| Docker | Container images (backend + ML) |
| Docker Compose | Local multi-service orchestration |
| Render | Deployed hosting for backend + ML service |

---

## 📂 Repository Structure

```
BirdLens/
│
├── README.md                    ← This file
├── TECHNICAL_REPORT.md          ← Complete engineering reference
├── .gitignore                   ← Excludes .env, venv, __pycache__, node_modules
├── docker-compose.yml           ← Local multi-service orchestration
│
├── backend/                     ← Node.js / Express orchestration API
│   ├── README.md
│   ├── Dockerfile
│   ├── package.json
│   ├── drizzle.config.js
│   └── src/
│       ├── server.js
│       ├── config/              (env, db, cron)
│       ├── routes/              (auth, birds, favorites, history)
│       ├── controllers/         (auth, birds, favorites, history)
│       ├── middleware/          (auth, upload)
│       ├── services/            (ml, s3)
│       ├── utils/               (token, bird enrichment)
│       ├── db/                  (schema, migrations/)
│       ├── seed/                (birds.js — 50 species metadata)
│       └── scripts/             (seed.js runner)
│
├── ML_service/                  ← FastAPI inference microservice
│   ├── README.md
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py
│       ├── routes/prediction.py
│       ├── services/prediction.py
│       ├── schemas/prediction_schema.py
│       ├── utils/image_processor.py
│       └── models/
│           ├── bird_classifier.py
│           ├── birds50_best.pth
│           ├── class_names.json
│           ├── selected_classes.json
│           └── model_config.json
│
├── notebooks/                   ← MobileNetV2 training workflow
│   ├── README.md
│   ├── requirements.txt
│   └── training.ipynb
│
└── mobile/                      ← Flutter cross-platform client
    ├── README.md
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── constants/           (api_constants)
        ├── providers/           (auth, favorites, history, navigation, profile)
        ├── services/            (dio, storage, auth, bird, favorite, history, image, profile)
        ├── themes/              (app_colors — 8 palettes)
        ├── widgets/             (card, image, text, shadows, auth widgets)
        └── screens/             (splash, welcome, auth, nav, home, birds, favorites, history, profile)
```

---

## 🔄 Full Data Flow

A complete prediction request, end-to-end:

```
Step 1  — User taps "Scan" in Flutter app
Step 2  — ImagePickerService opens camera / gallery
Step 3  — Image compressed on-device (reduces upload size)
Step 4  — Dio POST /api/birds/predict + Bearer JWT + multipart image
Step 5  — Express auth middleware: verifies JWT → req.user.id
Step 6  — Multer: image bytes → req.file.buffer (memory only, no disk)
Step 7  — ml.service.js: FormData → POST to FastAPI /api/predict/
Step 8  — FastAPI: validates MIME type, checks ≤3MB, Pillow decode to RGB
Step 9  — image_processor.py: Resize(224×224) → ToTensor → Normalize(ImageNet)
Step 10 — MobileNetV2: forward pass (no_grad) → softmax → argmax → class name
Step 11 — FastAPI returns: { bird: "Baird_Sparrow", confidence: 99.25, is_confident: true }
Step 12 — Express: SELECT * FROM birds WHERE name = "Baird_Sparrow"
Step 13 — s3.service.js: GetObjectCommand → signed URL (1hr TTL)
Step 14 — Express: INSERT INTO history (user_id, bird_id, confidence)
Step 15 — enrichBird(): strip aws_image_key, inject image_url
Step 16 — Express returns enriched JSON to Flutter
Step 17 — Flutter navigates to /birdDetails with result
Step 18 — User sees species, metadata, image, and confidence

User image exits the pipeline at Step 11 — never written to DB, S3, or disk.
```

---

## 🧠 Key Engineering Decisions

### 1. Dedicated Python ML Microservice

```
Problem:  PyTorch/torchvision are Python-native. Embedding in Node.js is painful.
Solution: FastAPI as a dedicated inference service.
Benefits: Native Python ML ecosystem, independent scaling, stable public API
          even if model architecture changes.
Tradeoff: Extra network hop, second failure domain, contract coordination needed.
```

### 2. User Photos Never Stored

```
Problem:  Image storage creates privacy, cost, and lifecycle obligations.
Solution: Handle uploads in-memory only. Discard after inference.
Benefits: No user data retained, no storage cost, no GDPR/privacy exposure,
          no orphaned objects.
Tradeoff: No original photo archive (but history doesn't need it).
```

### 3. Private S3 + Signed URLs

```
Problem:  Representative bird images need to reach the client, but public
          S3 buckets are not safe.
Solution: Private bucket + time-limited signed GetObject URLs (1hr TTL).
Benefits: Bucket stays private, client fetches direct (no proxy bandwidth),
          no credentials in client, industry standard.
Tradeoff: More complex than public URLs; signed URLs expire.
```

### 4. Composite Primary Key on Favorites

```
Problem:  Concurrent or repeated requests can create duplicate favorites.
Solution: PRIMARY KEY (user_id, bird_id) — duplicate prevention is atomic.
Benefits: No TOCTOU race condition, no app-level pre-insert check needed,
          concurrent safe.
Tradeoff: Needs proper 409 error mapping (currently returns 500).
```

### 5. Cross-System Class Name Invariant

```
ML class_names.json[index]  ==  FastAPI response.bird  ==  PostgreSQL birds.name

This is the most important cross-service contract in the system.
Any character difference causes inference to succeed but enrichment to fail silently.
```

### 6. JWT Identity Derived from Token, Not Request Body

```
// WRONG pattern:
const userId = req.body.user_id;  // Client can forge this

// BirdLens pattern:
const userId = req.user.id;  // From verified JWT only
```

---

## 🗄️ Database Design

```
USERS
  id (UUID PK) · username · email (unique) · password_hash · created_at · updated_at

BIRDS
  id (UUID PK) · name (unique) ← matches ML class exactly
  description · scientific_name · habitat · conservation_status
  aws_image_key ← NEVER sent to client; replaced by signed image_url

FAVORITES
  user_id (FK) + bird_id (FK)  ← composite primary key (unique enforcement)
  created_at

HISTORY
  id (serial PK) · user_id (FK, indexed) · bird_id (FK)
  confidence · predicted_at

Relationships:
  USERS 1──N FAVORITES N──1 BIRDS
  USERS 1──N HISTORY   N──1 BIRDS
```

**Migration history:** 4 migrations documenting architecture evolution, including the deliberate removal of `user_image_key` from history (privacy decision).

---

## 📡 API Overview

All routes under `/api`. Full reference in `backend/README.md`.

| Domain | Endpoints | Auth |
|--------|-----------|------|
| Health | `GET /api/health` | None |
| Auth | `POST /signup` · `POST /login` · `GET /me` | None / JWT |
| Birds | `GET /birds/:id` · `POST /birds/predict` | None / JWT |
| Favorites | `POST` · `GET` · `DELETE /favorites` | JWT |
| History | `GET` · `DELETE /history` | JWT |

**Prediction response:**
```json
{
  "bird": {
    "id": "uuid",
    "name": "Baird_Sparrow",
    "scientific_name": "Centronyx bairdii",
    "description": "...",
    "habitat": "...",
    "conservation_status": "...",
    "image_url": "https://s3.amazonaws.com/...?X-Amz-Expires=3600&..."
  },
  "confidence": 99.25,
  "is_confident": true
}
```

---

## 🐳 Docker & Local Development

### Docker Compose (Recommended)

```bash
# Start backend + ML service together
docker compose up --build

# Backend available at: http://localhost:5001
# FastAPI available at: http://localhost:8000
```

```yaml
# docker-compose.yml
services:
  backend:
    build: ./backend
    ports: ["5001:5001"]
    environment:
      ML_SERVICE: http://ml:8000
      # ... other env vars

  ml:
    build: ./ML_service
    ports: ["8000:8000"]
    volumes:
      - ./ML_service/app/models:/app/app/models
```

### Manual Local Dev

```bash
# Terminal 1: ML service
cd ML_service
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Terminal 2: Backend
cd backend
npm install
npx drizzle-kit migrate
npm run dev

# Terminal 3: Flutter
cd mobile
flutter pub get
flutter run
```

### Environment Setup

```bash
# backend/.env
DB_URL=postgresql://...
JWT_SECRET=your-32-char-minimum-secret
ML_SERVICE=http://localhost:8000
AWS_BUCKET_NAME=birdlens-images
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
PORT=5001
NODE_ENV=development

# mobile/.env (or lib/constants/api_constants.dart)
API_BASE_URL=http://10.0.2.2:5001  # Android emulator
```

---

## 🚀 Deployment

### Architecture on Render

```
Render Web Service: birdlens-backend
  Docker image from ./backend/Dockerfile
  Port: 5001
  Health: /api/health

Render Web Service: birdlens-ml
  Docker image from ./ML_service/Dockerfile
  Port: 8000
  Health: /health

Neon PostgreSQL: Managed (external)
AWS S3: Private bucket (external)
Flutter: APK / App Store release
```

### Deployment Order

```
1.  Provision Neon PostgreSQL
2.  npx drizzle-kit migrate   (create tables)
3.  node src/scripts/seed.js  (populate bird metadata)
4.  Create private S3 bucket
5.  Upload birds/<name>.jpg for all 50 species
6.  Deploy FastAPI on Render → get ML service URL
7.  Verify: curl https://ml.onrender.com/health
8.  Deploy Express on Render → set ML_SERVICE to FastAPI URL
9.  Verify: curl https://api.onrender.com/api/health
10. Set API_BASE_URL in mobile/.env → flutter build apk --release
11. Run smoke tests (signup → predict → favorite → history)
```

---

## 🔒 Security & Privacy

### Security Strengths

```
✅ bcrypt password hashing (cost 10) — never stores raw passwords
✅ 7-day JWT — resource identity from verified token, not request body
✅ Express-rate-limiting on auth and predict routes
✅ Drizzle ORM — no string-built SQL, parameterized queries
✅ Private S3 bucket — public access blocked by bucket policy
✅ Signed URLs — time-limited, no AWS credentials in client
✅ aws_image_key stripped from all client responses
✅ flutter_secure_storage — platform keystore for JWT
✅ Same error for "not found" and "wrong password" — no enumeration
✅ .env and secrets in .gitignore
```

### Privacy Strengths

| Data | Stored? | Where |
|------|---------|-------|
| Email / username | ✅ | PostgreSQL (auth) |
| Password | ❌ | Hash only |
| Prediction species + confidence | ✅ | History table |
| **User-uploaded photograph** | **❌** | **Inference only, then discarded** |
| Representative bird images | ✅ | Private S3 (non-user content) |

### Known Gaps (Pre-Production)

```
⚠️  CORS is currently permissive (allow all origins)
⚠️  FastAPI has no service-to-service authentication
⚠️  AWS uses long-lived keys (not IAM roles)
```

---

## 🤖 Model Performance

| Attribute | Value |
|-----------|-------|
| Architecture | MobileNetV2 (ImageNet pretrained) |
| Classes | 50 bird species (from 220 available) |
| Input | RGB image, 224×224 |
| Best accuracy | **91.02%** |
| Confidence threshold | `0.65` raw softmax probability |
| Runtime | CPU (Render free tier) |
| Training | 10 epochs, AdamW, CosineAnnealingLR |

**Known limitations:**
- Only 50 of 220 species supported — unsupported birds are mapped to closest class
- Softmax confidence is uncalibrated — may be overconfident
- Top-1 only — no fallback for visually ambiguous images
- Test split used for checkpoint selection — accuracy estimate is optimistic

---

## 📈 Scalability

| Scale | Status |
|-------|--------|
| 10–100 users | ✅ Current architecture is sufficient |
| 1,000 users | ⚠️ Add rate limiting, pagination, multiple ML workers, metrics |
| 10,000 users | ❌ Need horizontal Express scaling, Redis caching, CDN, autoscaling inference, queues |

Express is stateless (JWT carries identity, PostgreSQL owns state) — horizontal scaling is straightforward once observability is added.

---

## 📚 Component READMEs

| Component | README | Covers |
|-----------|--------|--------|
| Backend API | [`backend/README.md`](backend/README.md) | Architecture, Auth, DB, API Reference, Docker, S3, Deployment |
| ML Inference | [`ML_service/README.md`](ML_service/README.md) | FastAPI, preprocessing, model, validation, operations |
| Model Training | [`notebooks/README.md`](notebooks/README.md) | Training pipeline, dataset, artifacts, evaluation |
| Flutter App | [`mobile/README.md`](mobile/README.md) | Architecture, Riverpod, Dio, screens, navigation, build |
| Full Engineering | [`TECHNICAL_REPORT.md`](TECHNICAL_REPORT.md) | Complete 34-section engineering reference |

---

## 🗺️ Roadmap

### Short Term
```
□ Automated tests (backend unit + integration, ML contract, Flutter widget)
□ CORS allowlist,  request validation
□ Dockerfiles tested, Compose verified end-to-end
□ CI pipeline (lint + test + build + secret scan)
□ Structured logging + basic metrics
□ GoRouter declarative auth guards
```

### Medium Term
```
□ Top-K prediction results
□ Confidence calibration (temperature scaling)
□ Unknown-species rejection
□ Model version in responses + history
□ Pagination for favorites + history
□ Individual history deletion
□ CDN / private image distribution
□ Bird metadata admin tooling
```

### Long Term
```
□ Expand to curated 220-species catalog
□ Geographic + seasonal prediction context
□ On-device inference option (TFLite)
□ Community sightings
□ Multi-region deployment
□ Model drift monitoring + registry
```

---

## 💬 Interview Discussion Topics

These are the highest-value architecture decisions to discuss in placement interviews:

| Topic | Why It's Interesting |
|-------|---------------------|
| Why FastAPI is separate from Express | ML dependency isolation, independent scaling, stable client contract |
| Why user photos are never stored | Privacy-by-design, cost, GDPR implications, lifecycle complexity |
| Why favorites use a composite PK | Atomic duplicate prevention vs. app-layer checks, race condition avoidance |
| The class-name invariant | Cross-service contracts, silent failure modes, the hardest bug to debug |
| Private S3 + signed URLs | Security vs. simplicity tradeoff, temporary access patterns |
| Stateless JWT vs. server sessions | Horizontal scaling, revocation complexity, token expiry |
| How to scale CPU inference | TorchScript/ONNX, GPU serving, request batching, worker pools |
| What production readiness actually requires | Tests, rate limiting, observability, secrets management, CI/CD |
| Why history doesn't store user images | Privacy, normalization, what "history" actually means as a product feature |

---
## 👤 About

Built by **Harsh** — 2nd year CSE (Software Engineering), SRMIST.

---

<div align="center">

**BirdLens: From notebook experiment to full-stack AI product.**

*Flutter · Node.js · FastAPI · PyTorch · PostgreSQL · AWS S3 · Docker · Render*

</div>
