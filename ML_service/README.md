# 🦅 BirdLens — ML Inference Service

> **FastAPI microservice that validates, preprocesses, and classifies bird images using a fine-tuned MobileNetV2 model. Returns species name and calibrated confidence in under a second.**

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Quick Start](#-quick-start)
- [Service Contract](#-service-contract)
- [Architecture](#️-architecture)
- [Request Lifecycle](#-request-lifecycle)
- [Model Details](#-model-details)
- [Preprocessing Pipeline](#️-preprocessing-pipeline)
- [Validation & Error Handling](#-validation--error-handling)
- [Project Structure](#-project-structure)
- [Artifact Contract](#-artifact-contract)
- [Deployment & Operations](#-deployment--operations)
- [Why a Dedicated Microservice?](#-why-a-dedicated-microservice)
- [Known Limitations & Roadmap](#-known-limitations--roadmap)
- [Troubleshooting](#-troubleshooting)

---

## 🔍 Overview

The BirdLens ML Service is a focused, single-responsibility FastAPI application. It does **one thing well**: accept a bird photograph, run it through a 50-class PyTorch classifier, and return a structured prediction.

It is **deliberately decoupled** from the Node.js API — inference stays in Python's native ML ecosystem, and each service can scale and deploy independently.

```
┌──────────────────────────────────────────────────────────────┐
│                        ML SERVICE SCOPE                      │
│                                                              │
│   ✅  Image validation (MIME, size, decodability)            │
│   ✅  Pillow-based preprocessing                             │
│   ✅  MobileNetV2 inference                                  │
│   ✅  Structured JSON prediction response                    │
│                                                              │
│   ❌  User identity / authentication                         │
│   ❌  History or favorites persistence                       │
│   ❌  S3 / database access                                   │
│   ❌  Business logic or metadata enrichment                  │
└──────────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start

```bash
# 1. Clone and navigate
cd ML_service

# 2. Create virtual environment
python -m venv .venv

# 3. Activate (Linux/macOS)
source .venv/bin/activate
# Windows: .venv\Scripts\activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Start the service
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

> ⚠️ **Important:** Always run from the `ML_service/` directory — model artifact paths are relative to it.

**Verify it's running:**

```bash
curl http://localhost:8000/health
# → {"status": "ok"}
```

**Run a prediction:**

```bash
curl -X POST http://localhost:8000/api/predict/ \
     -F "file=@/path/to/bird.jpg"
```

Interactive API docs available at:
- **Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`

---

## 📡 Service Contract

### Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/` | None | Basic service liveness |
| `GET` | `/health` | None | Process health check |
| `POST` | `/api/predict/` | None (internal) | Single-image bird classification |

---

### `POST /api/predict/`

**Request** — `multipart/form-data` with field `file`:

```bash
curl -X POST http://localhost:8000/api/predict/ \
     -F "file=@sparrow.jpg"
```

**Success Response** — `200 OK`:

```json
{
  "bird": "Baird_Sparrow",
  "confidence": 99.25,
  "is_confident": true
}
```

**Field Semantics:**

| Field | Type | Description |
|-------|------|-------------|
| `bird` | `string` | Exact class string from `class_names.json` — must match `birds.name` in PostgreSQL exactly |
| `confidence` | `float` | `max(softmax) × 100`, rounded to 2 decimal places |
| `is_confident` | `bool` | `true` when raw probability ≥ `0.65` |

> 🔗 The `bird` field is the cross-service contract key. If it doesn't exactly match `birds.name` in the backend DB, metadata enrichment silently fails.

---

## 🏗️ Architecture

### Service Position in BirdLens

```
Flutter App
    │
    │  HTTPS + JWT
    ▼
Node.js / Express API  ────────────────────────────┐
    │                                               │
    │  multipart/form-data (image buffer)           │  Drizzle ORM
    ▼                                               ▼
FastAPI ML Service                          Neon PostgreSQL
    │
    ▼
PyTorch MobileNetV2
    │
    └──► { bird, confidence, is_confident }
         returned to Express → enriched → Flutter
```

### Internal Component Flow

```
POST /api/predict/
       │
       ▼
┌─────────────────┐
│  Route Layer    │  routes/prediction.py
│  (Transport)    │  receives UploadFile, delegates
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Service Layer  │  services/prediction.py
│  (Use Case)     │  validates MIME, size, decodability
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Image Util     │  utils/image_processor.py
│  (Transform)    │  resize → tensor → normalize → batch
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Classifier     │  models/bird_classifier.py
│  (Inference)    │  BirdClassifier.predict()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Schema Layer   │  schemas/prediction_schema.py
│  (Validation)   │  Pydantic validates response shape
└────────┬────────┘
         │
         ▼
    JSON Response
```

---

## 🔄 Request Lifecycle

A single prediction request traverses 7 stages:

```
Stage 1  ──  HTTP Transport
             routes/prediction.py receives UploadFile

Stage 2  ──  MIME Validation
             services/prediction.py checks content_type
             ✅ image/jpeg  ✅ image/png  ✅ image/webp
             ❌ anything else → HTTP 400

Stage 3  ──  Size Check
             Read bytes into memory
             ❌ > 3 MB → HTTP 413

Stage 4  ──  Image Decodability
             Pillow.Image.open() verifies the bytes
             .convert("RGB") normalizes channel count
             ❌ Invalid/corrupt image → HTTP 400

Stage 5  ──  Preprocessing
             utils/image_processor.py
             Resize(224×224) → ToTensor() → Normalize(ImageNet)
             Add batch dimension → shape [1, 3, 224, 224]

Stage 6  ──  Inference
             BirdClassifier.predict()
             torch.no_grad() → logits → softmax
             argmax → class index → class name lookup

Stage 7  ──  Response
             Pydantic validates PredictionResponse
             Returns { bird, confidence, is_confident }
```

> 🧠 User images are **processed in memory only** — never written to disk, database, or object storage.

---

## 🤖 Model Details

| Attribute | Value |
|-----------|-------|
| Architecture | MobileNetV2 |
| Framework | PyTorch + torchvision |
| Pretrained weights | ImageNet (default) |
| Classifier head | `Linear(1280, 50)` |
| Input shape | `[1, 3, 224, 224]` |
| Classes | 50 bird species |
| Best reported accuracy | **91.02%** |
| Confidence threshold | `0.65` (raw softmax probability) |
| Runtime device | CPU |
| Gradient computation | Disabled (`torch.no_grad()`) |

### Startup Initialization Sequence

The `BirdClassifier` singleton initializes **once at application import** — not per request:

```
Application Start
       │
       ├─ 1. Load class_names.json (index → species name map)
       │
       ├─ 2. Instantiate MobileNetV2 with ImageNet weights
       │
       ├─ 3. Replace classifier[1]: Linear(1280, 50)
       │
       ├─ 4. Load birds50_best.pth  (map_location="cpu")
       │
       ├─ 5. model.eval()  — switch to evaluation mode
       │
       └─ 6. torch.no_grad()  — disable gradient tracking
```

> ⚡ Loading at startup avoids cold-inference latency per request. The tradeoff: if any artifact is missing or shape-mismatched, **the service fails to start** — which is the right failure mode.

---

## 🖼️ Preprocessing Pipeline

Inference preprocessing **must exactly match training** — any mismatch degrades accuracy:

```
Input Image (any size, any valid format)
       │
       ▼
┌─────────────────────────────────┐
│  Resize(224 × 224)              │  ← Direct square resize
│  Note: aspect ratio not         │     preserved (future: center crop)
│  preserved                      │
└─────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│  ToTensor()                     │  ← [H, W, C] uint8 → [C, H, W] float
│  Scales pixel values to [0, 1]  │
└─────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│  Normalize(ImageNet stats)      │
│  mean = [0.485, 0.456, 0.406]   │
│  std  = [0.229, 0.224, 0.225]   │
└─────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│  unsqueeze(0)                   │  ← Add batch dimension
│  Shape: [3, 224, 224]           │
│       → [1, 3, 224, 224]        │
└─────────────────────────────────┘
       │
       ▼
  MobileNetV2 Inference
```

> ℹ️ The current direct-resize approach is simple and model-compatible, but can distort unusually shaped images. A future improvement would use `Resize + CenterCrop` consistently in both training and inference.

---

## ❗ Validation & Error Handling

| Condition | HTTP Status | Response |
|-----------|-------------|----------|
| Unsupported MIME type | `400` | Only JPG/PNG/WebP allowed |
| Payload over 3 MB | `413` | Payload too large |
| Invalid or corrupt image | `400` | Could not decode image |
| Valid image, successful inference | `200` | Prediction JSON |

**Validation is dual-layered:**
1. Declared MIME type check (what the client claims)
2. Actual Pillow decodability check (what the bytes actually are)

> 🔒 For production: also place body-size limits at the **reverse proxy** and **Node API** so oversized uploads are rejected before crossing service boundaries.

---

## 📁 Project Structure

```
ML_service/
│
├── app/
│   ├── main.py                    # FastAPI app instance, health routes
│   │
│   ├── models/
│   │   ├── bird_classifier.py     # Singleton model loader + predict()
│   │   ├── birds50_best.pth       # ← Trained state dictionary (not committed)
│   │   ├── class_names.json       # Index → species string mapping
│   │   ├── selected_classes.json  # Original 50 sampled classes
│   │   └── model_config.json      # Architecture metadata + best accuracy
│   │
│   ├── routes/
│   │   └── prediction.py          # /api/predict/ transport endpoint
│   │
│   ├── schemas/
│   │   └── prediction_schema.py   # Pydantic: PredictionResponse model
│   │
│   ├── services/
│   │   └── prediction.py          # Validation + prediction use case
│   │
│   └── utils/
│       └── image_processor.py     # Deterministic inference preprocessing
│
├── requirements.txt               # Pinned Python dependencies
└── README.md                      # This document
```

### File Responsibilities at a Glance

| File | Who calls it | What it does |
|------|-------------|--------------|
| `main.py` | Uvicorn | Creates app, mounts routes, health endpoint |
| `routes/prediction.py` | Express (internal) | HTTP transport, hands UploadFile to service |
| `services/prediction.py` | Route | Validation logic + orchestrates preprocessing + inference |
| `utils/image_processor.py` | Service | Deterministic tensor preprocessing |
| `models/bird_classifier.py` | Service | Loads weights, runs torch inference |
| `schemas/prediction_schema.py` | Route | Pydantic response contract enforcement |

---

## 📦 Artifact Contract

The service requires **four coordinated artifacts** — all must be from the same training run:

| Artifact | Role | If Missing/Wrong |
|----------|------|-----------------|
| `birds50_best.pth` | Trained model state dictionary | Service fails to start |
| `class_names.json` | Output-index → species string map | Wrong/missing predictions |
| `selected_classes.json` | Records sampled source classes | Loss of training provenance |
| `model_config.json` | Architecture + accuracy metadata | Broken deployment validation |

### Release Checklist

Before deploying a new model version:

```
□ Train and select best checkpoint
□ Export class_names.json in same index order used during training
□ Verify: len(class_names.json) == final Linear layer output size (50)
□ Verify: every class name exists exactly once in PostgreSQL birds.name
□ Run known-image smoke suite (≥ 1 test image per class ideally)
□ Measure accuracy and P95 inference latency
□ Update model_config.json with verified metadata
□ Deploy ML service BEFORE depending on new classes from backend/mobile
□ Record model version (not yet in response — add to roadmap)
```

### Cross-System Class Name Invariant

```
class_names.json[index]
        ==
FastAPI response: "bird"
        ==
PostgreSQL birds.name
```

> 🚨 A single character difference (case, underscore, space) causes inference to succeed but metadata enrichment to silently fail — the most dangerous bug category in this system.

---

## 🚀 Deployment & Operations

### Container / Runtime Expectations

```
• Run one or more Uvicorn workers (benchmark memory × worker count first)
• Include all model artifacts in the immutable deployment image
• Keep the service PRIVATE — only the Node.js backend should reach it
• Use /health for process liveness
• Add a READINESS check that confirms BirdClassifier loaded successfully
• Set request-size and timeout limits at the edge (reverse proxy)
```

### Environment

No environment variables are required for basic operation — the service is stateless and self-contained. For production, consider:

- `ML_CONFIDENCE_THRESHOLD` — make the 0.65 threshold configurable
- `ML_MAX_FILE_SIZE_MB` — configurable upload limit
- `LOG_LEVEL` — structured log verbosity

### Scaling Behavior

```
Current:  CPU-bound synchronous inference inside async FastAPI route
          → Under concurrency, this blocks worker event loop progress

Short-term fix:   run_in_executor() to offload to thread pool
Medium-term:      Multiple Uvicorn worker processes
Long-term:        TorchScript / ONNX export + dedicated inference server
                  GPU serving for high-throughput deployments
                  Request batching
```

### Observability to Add

```
Metric category          │ What to track
─────────────────────────┼──────────────────────────────────────
Request metrics          │ Count, status distribution, P50/P95/P99 latency
Stage timing             │ Decode, preprocess, inference individually
Prediction distribution  │ Per-class prediction counts
Confidence distribution  │ Low-confidence rate, histogram
Validation errors        │ Invalid type, oversized, corrupt image counts
Artifact info            │ Model version, class_names.json checksum
Resource utilization     │ CPU%, memory MB, worker count
Drift signals            │ Confidence trend, class distribution shift
```

---

## 🤔 Why a Dedicated Microservice?

### Advantages

```
✅  PyTorch, torchvision, Pillow, NumPy stay isolated from Node.js dependencies
✅  Inference resources scale independently from CRUD/auth traffic
✅  Model deployment and version changes are independent from the public API
✅  Mobile response contract stays stable even if model architecture changes
✅  Python-native tooling simplifies experimentation (ONNX, quantization, etc.)
✅  Clear blast radius — an ML service crash doesn't take down auth or favorites
```

### Tradeoffs

```
⚠️  Extra network hop adds latency (internal network should be fast)
⚠️  Second failure domain — requires its own health checks and deployment
⚠️  Service discovery, monitoring, and deployment complexity
⚠️  Strict contract management needed (class names, response schema)
⚠️  Requires explicit service-to-service authentication in production
```

> The Node backend should remain the **only client-facing entry point**. Exposing FastAPI directly bypasses JWT authentication, history recording, metadata enrichment, and rate-control policy.

---

## 🗺️ Known Limitations & Roadmap

### Current Limitations

| Limitation | Impact |
|-----------|--------|
| Only 50 of 220 possible species | Can't identify unsupported birds |
| No "unknown species" class | Unsupported birds get confidently misclassified |
| Only top-1 prediction returned | No fallback for ambiguous images |
| Softmax confidence is uncalibrated | Overconfident predictions possible |
| Model always loads on CPU | Inference is slower than GPU-accelerated |
| Artifact paths relative to CWD | Deployment-environment sensitive |
| No automated tests | Regressions are caught manually |
| No internal service authentication | FastAPI accessible to any internal caller |

### Priority Improvements

```
Priority 1  ─  Unit tests for validation, preprocessing, and API contract
Priority 2  ─  Return model version in response + top-K predictions
Priority 3  ─  Confidence calibration (temperature scaling)
Priority 4  ─  Unknown-species rejection strategy
Priority 5  ─  Move paths/config to typed settings (Pydantic Settings)
Priority 6  ─  Readiness check, structured logs, metrics, tracing
Priority 7  ─  Benchmark ONNX/TorchScript/quantization for latency reduction
Priority 8  ─  run_in_executor for non-blocking async inference
```

---

## 🛠️ Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Model file not found` | Wrong working directory | Run from `ML_service/`; verify `app/models/birds50_best.pth` exists |
| `State-dict shape mismatch` | Weight file from different run | Confirm class count (50) and `class_names.json` length both match |
| `Backend says bird not found` | Class name mismatch | Ensure predicted class matches `birds.name` in PostgreSQL exactly |
| `Every result has low confidence` | Preprocessing mismatch | Verify normalization stats match training; check input image quality |
| `First request is slow` | Model warm-up / cold start | Expected — model is loaded at startup, not per-request |
| `Memory / latency rises under load` | Single-worker CPU saturation | Benchmark worker count; consider run_in_executor or ONNX export |
| `Service fails to start` | Missing or incompatible artifact | Check all four artifacts exist and match the same training run |

---

## 📋 Dependencies (requirements.txt)

Key pinned dependencies:

```
fastapi         — ASGI web framework
uvicorn         — ASGI server
pydantic        — Response schema validation
torch           — PyTorch inference runtime
torchvision     — MobileNetV2, transforms
Pillow          — Image decoding and RGB conversion
python-multipart — multipart/form-data parsing
```

---

<div align="center">

**This service is deliberately small.**
Its strength is a narrow, explicit contract around safe image validation and model inference.

*BirdLens ML Service — Part of the BirdLens full-stack AI bird identification system*

</div>