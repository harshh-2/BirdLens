# 🧠 BirdLens — Model Training

> **Reproducible MobileNetV2 transfer-learning pipeline that converts a 220-category bird dataset into a focused 50-class production classifier. Trains, evaluates, and exports all artifacts required by the FastAPI inference service.**

---

## 📑 Table of Contents

- [Purpose & Outputs](#-purpose--outputs)
- [Quick Start](#-quick-start)
- [Pipeline Walkthrough](#️-pipeline-walkthrough)
- [Training Configuration](#-training-configuration)
- [Model Architecture](#-model-architecture)
- [Training Loop](#-training-loop)
- [Exported Artifacts](#-exported-artifacts)
- [Reproducibility & Data Integrity](#-reproducibility--data-integrity)
- [Evaluation & Model Governance](#-evaluation--model-governance)
- [Running the Notebook](#-running-the-notebook)
- [Known Limitations & Next Experiments](#-known-limitations--next-experiments)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Purpose & Outputs

`training.ipynb` is the **source of truth for every artifact** served by `ML_service`. It does not just train a model — it defines the complete deployment artifact set and the cross-system naming contract.

### What the Notebook Produces

```
training.ipynb
      │
      ├─ birds50_best.pth          ← Best model weights (saved when accuracy improves)
      │
      ├─ class_names.json          ← Index → species name map (CRITICAL cross-service key)
      │
      └─ selected_classes.json     ← Records which 50 classes were sampled (reproducibility)
```

### Artifact Consumers

| Artifact | Consumer | Why it Matters |
|----------|----------|---------------|
| `birds50_best.pth` | FastAPI inference service | The actual model weights |
| `class_names.json` | FastAPI + PostgreSQL seeding | Maps model output indices to species strings |
| `selected_classes.json` | Engineers / retraining workflow | Records sampled class provenance |

> 🔗 **The exported class-name order is operationally critical.** The classifier uses array index to decode logits. The backend uses the resulting string to query `birds.name`. A single character difference breaks metadata enrichment silently.

---

## ⚡ Quick Start

### Recommended: Google Colab (GPU)

```
1. Upload training.ipynb to Google Colab
2. Runtime → Change runtime type → GPU (T4 is sufficient)
3. Run all cells in order
4. Review: selected classes printout + sample image visualization
5. Wait for 10-epoch training loop to complete
6. Download all three exported artifacts together
7. Move artifacts to ML_service/app/models/
```

### Local Environment

```bash
cd notebooks
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
jupyter notebook training.ipynb
```

> ⚠️ The notebook contains Colab-specific paths (`/content/...`) and `google.colab` download helpers. Local execution requires adapting these paths and the artifact download cells.

### After Training: Artifact Handoff Checklist

```
□ Place birds50_best.pth      → ML_service/app/models/
□ Place class_names.json      → ML_service/app/models/
□ Place selected_classes.json → ML_service/app/models/
□ Update model_config.json with verified accuracy, class count, input size
□ Confirm: len(class_names.json) == 50
□ Confirm: final classifier output size == 50
□ Confirm: all 50 class strings exist in PostgreSQL birds.name
□ Run inference smoke tests before deploying
```

---

## 🔧 Pipeline Walkthrough

The training notebook executes 8 sequential stages:

### Stage 1 — Imports & Environment

```python
# Core dependencies
import torch, torchvision         # Model and transforms
import kagglehub                  # Dataset retrieval
from torchvision import datasets  # Folder-based image loading
import random, shutil, json       # Utility and artifact export
import matplotlib.pyplot as plt   # Sample visualization
```

---

### Stage 2 — Dataset Download & Class Selection

**Source dataset:**
```
kedarsai/bird-species-classification-220-categories
```

**Selection process:**
```
All 220 class folders
        │
        ▼
Sort alphabetically (deterministic ordering)
        │
        ▼
random.seed(42)
        │
        ▼
random.sample(all_classes, 50)   ← 50 random classes
        │
        ▼
Copy Train/ and Test/ folders → /content/Birds50/
```

**Why 50 classes?**

| Reason | Detail |
|--------|--------|
| Reduces training cost | 10× fewer classes = faster iterations |
| Manageable proof of concept | Complete end-to-end system without full-scale complexity |
| Smaller deployment artifacts | Lighter model, smaller class maps |
| Focus on architecture quality | Value is the full system, not maximizing species count |

> ⚠️ The selection is **random, not curated** — class similarity, geographic usefulness, and visual difficulty are not explicitly optimized. A production-quality dataset would apply domain curation.

---

### Stage 3 — Augmentation Strategy

**Training transforms** (applied per-batch, random each epoch):

```
┌──────────────────────────────────────────────────────┐
│  INPUT: Raw bird image (variable size)               │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
              Resize(224 × 224)            ← Fixed input size for MobileNetV2
                       │
                       ▼
          RandomHorizontalFlip(p=0.5)      ← Handles left/right-facing birds
                       │
                       ▼
          RandomRotation(±15°)             ← Handles angled photographs
                       │
                       ▼
     AutoAugment(ImageNet policy)          ← Learned augmentation strategy:
                       │                    color jitter, shear, posterize, etc.
                       ▼
                  ToTensor()               ← [H,W,C] uint8 → [C,H,W] float32 ∈ [0,1]
                       │
                       ▼
       Normalize(ImageNet mean/std)        ← mean=[0.485,0.456,0.406]
                       │                    std =[0.229,0.224,0.225]
                       ▼
              ┌─────────────────┐
              │  Training Batch │
              └─────────────────┘
```

**Test transforms** (deterministic — no randomness):

```
Resize(224 × 224) → ToTensor() → Normalize(ImageNet stats)
```

> ℹ️ Test and inference preprocessing **must stay identical** to avoid distribution mismatch between evaluation and deployment.

---

### Stage 4 — Data Loaders

```python
DataLoader(
    train_dataset,
    batch_size=32,
    shuffle=True,      # Randomize order each epoch
    num_workers=2,
    pin_memory=True    # Faster GPU transfers
)

DataLoader(
    test_dataset,
    batch_size=32,
    shuffle=False,     # Deterministic evaluation order
    num_workers=2,
    pin_memory=True
)
```

---

### Stage 5 — Model Adaptation (Transfer Learning)

```
MobileNetV2 (ImageNet pretrained)
       │
       │  All convolutional feature layers
       │  ↑ Pretrained on 1.2M ImageNet images
       │  ↑ Learns edges → textures → parts → objects
       │
       ▼
┌─────────────────────────────────────┐
│  Original Classifier Head           │
│  Dropout → Linear(1280, 1000)       │
│  (ImageNet 1000 classes)            │
└──────────────────┬──────────────────┘
                   │  REPLACED WITH:
                   ▼
┌─────────────────────────────────────┐
│  New Classifier Head                │
│  Dropout → Linear(1280, 50)         │  ← 50 bird species
└─────────────────────────────────────┘
```

**Transfer learning note:**

```python
model.classifier[1] = nn.Linear(1280, num_classes)
```

> ⚠️ The checked-in notebook does **not** explicitly freeze backbone parameters (`requires_grad = False`). The actual training fine-tunes all parameters. Experiment reports should state which strategy was used — full fine-tuning vs. head-only vs. staged unfreezing.

| Strategy | Speed | Overfitting Risk | Typical Accuracy |
|---------|-------|-----------------|-----------------|
| Head-only (frozen backbone) | Fastest | Lowest | Good baseline |
| Staged unfreezing | Medium | Medium | Often best |
| Full fine-tuning (current) | Slowest | Highest | Potentially highest |

---

### Stage 6 — Optimization Setup

```python
criterion = nn.CrossEntropyLoss()

optimizer = AdamW(
    model.parameters(),
    lr=3e-4,
    weight_decay=1e-2
)

scheduler = CosineAnnealingLR(
    optimizer,
    T_max=10        # Cosine cycle over full training run
)
```

**Learning rate schedule over 10 epochs:**

```
LR
3e-4 │ ╲
     │  ╲
     │   ╲
     │    ╲
     │     ╲
     │      ╲
     │       ╲___
0    └─────────────────
     0        5       10  Epoch
       (cosine decay to near 0)
```

**Why these choices?**

| Choice | Reason |
|--------|--------|
| AdamW | Decoupled weight decay — more principled than Adam for generalization |
| lr = 3e-4 | Standard good starting point for transfer learning fine-tuning |
| weight_decay = 1e-2 | Regularizes to reduce overfitting on 50-class subset |
| CosineAnnealing | Smooth LR decay — avoids abrupt drops, often better final accuracy |
| CrossEntropyLoss | Standard multi-class classification loss |

---

### Stage 7 — Training Loop

```
For each of 10 epochs:
       │
       ├─ model.train()  — enable dropout, batch norm in train mode
       │
       ├─ For each batch in train_loader:
       │     │
       │     ├─ Forward pass: logits = model(images)
       │     ├─ Compute loss: CrossEntropyLoss(logits, labels)
       │     ├─ Backward pass: loss.backward()
       │     └─ Parameter update: optimizer.step()
       │
       ├─ model.eval() + torch.no_grad()
       │
       ├─ Evaluate accuracy on test_loader
       │     └─ accuracy = correct / total × 100
       │
       ├─ If accuracy > best_accuracy:
       │     └─ Save checkpoint → birds50_best.pth  ✅
       │
       └─ scheduler.step()  — advance cosine LR
```

**Reported best accuracy: 91.02%**

---

### Stage 8 — Export

```python
# 1. Best model weights
torch.save(model.state_dict(), "birds50_best.pth")

# 2. Class name mapping (sorted dataset class order)
class_names = train_dataset.classes  # Must match training index order
with open("class_names.json", "w") as f:
    json.dump(class_names, f)

# 3. Original sampled class list
with open("selected_classes.json", "w") as f:
    json.dump(selected_classes, f)
```

---

## ⚙️ Training Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| Source categories | 220 | Full Kaggle dataset |
| Selected categories | **50** | Random sample, seed=42 |
| Class selection seed | `42` | Reproducible |
| Architecture | MobileNetV2 | ImageNet pretrained |
| Input size | `224 × 224 × 3` (RGB) | |
| Batch size | 32 | |
| Epochs | **10** | |
| Loss function | CrossEntropyLoss | |
| Optimizer | **AdamW** | |
| Learning rate | `3e-4` | |
| Weight decay | `1e-2` | |
| Scheduler | **CosineAnnealingLR** | T_max=10 |
| Augmentation | RandomHFlip + Rotation + AutoAugment | |
| Reported best accuracy | **91.02%** | On test split |

---

## 🏛️ Model Architecture

```
Input: [batch, 3, 224, 224]
       │
       ▼
MobileNetV2 Feature Extractor
├─ Initial Conv2d (32 filters, stride 2)
├─ 17× Inverted Residual Blocks
│   ├─ Depthwise separable convolutions
│   ├─ Linear bottlenecks
│   └─ Skip connections (same shape)
├─ Final Conv2d (1280 filters)
└─ AdaptiveAvgPool2d → [batch, 1280]
       │
       ▼
Classifier Head
├─ Dropout(p=0.2)
└─ Linear(1280 → 50)
       │
       ▼
Output: [batch, 50] logits
       │
       ▼
Softmax → Probabilities [batch, 50]
       │
       ▼
argmax → predicted class index
       │
       ▼
class_names[index] → "Baird_Sparrow"
```

**Why MobileNetV2?**

| Criterion | MobileNetV2 |
|-----------|------------|
| Parameters | ~3.4M (lightweight) |
| Inference speed | Fast on CPU |
| Memory footprint | Small |
| Accuracy on fine-grained tasks | Competitive for 50 classes |
| Mobile deployment suitability | Excellent |
| Available in torchvision | ✅ |

---

## 🔄 Training Loop

```
Epoch 1 of 10
     train_loss: 1.2341   test_acc: 72.4%
     ↳ New best! Saved birds50_best.pth ✅

Epoch 2 of 10
     train_loss: 0.8821   test_acc: 81.7%
     ↳ New best! Saved birds50_best.pth ✅

Epoch 3 of 10
     train_loss: 0.6543   test_acc: 85.3%
     ↳ New best! Saved birds50_best.pth ✅

...

Epoch N of 10
     train_loss: 0.3102   test_acc: 91.02%
     ↳ New best! Saved birds50_best.pth ✅
```

Best checkpoint is saved whenever test accuracy improves. Final artifact is the **best epoch across the run**, not necessarily the last.

---

## 📦 Exported Artifacts

Three files must move together into `ML_service/app/models/`:

### `birds50_best.pth`
PyTorch state dictionary. Contains all learned weights and biases.

```python
# How it's loaded in production
model.load_state_dict(
    torch.load("birds50_best.pth", map_location="cpu")
)
```

### `class_names.json`
The **most operationally critical artifact.** Maps model output index to species string.

```json
["American_Crow", "Anna_Hummingbird", "Baird_Sparrow", ...]
```

Index 0 → "American_Crow", Index 1 → "Anna_Hummingbird", etc.

> 🚨 This ordering **must match the training dataset class ordering exactly**. It is the cross-system contract between ML and the database.

### `selected_classes.json`
Records which 50 classes were randomly sampled. Enables:
- Retraining with the same class set
- Auditing what the model was trained on
- Engineering communication about coverage

### `model_config.json`
Human/machine-readable deployment metadata:

```json
{
  "architecture": "MobileNetV2",
  "input_size": [224, 224],
  "num_classes": 50,
  "best_accuracy": 91.02,
  "framework": "PyTorch"
}
```

---

## 🔬 Reproducibility & Data Integrity

### What IS Reproducible

```
✅  Python class selection: random.seed(42) before random.sample()
✅  Source class folders sorted before sampling
✅  Selected classes and class-index order exported to JSON
✅  Hyperparameters and transforms documented in notebook
✅  Dataset accessible via KaggleHub with fixed dataset ID
```

### What SHOULD Be Improved

```
❌  PyTorch CPU/CUDA RNGs are not seeded (torch.manual_seed, cuda.manual_seed_all)
❌  Deterministic mode not configured (torch.backends.cudnn.deterministic)
❌  Dataset version/checksum not recorded
❌  Python and library versions not pinned in a lockfile
❌  Optimizer/scheduler state not saved in checkpoint
❌  No experiment tracker (MLflow, W&B, etc.)
❌  No code commit hash recorded with artifacts
❌  No artifact checksums recorded
```

### Leakage & Evaluation Caution

```
Current workflow:
┌─────────────────────────────────────────────────────┐
│  train set  │  test set (used as validation)         │
└─────────────────────────────────────────────────────┘

The test set is used for epoch selection (checkpoint saving).
This means the test set functions as a VALIDATION set.

Correct workflow:
┌──────────────────────────────────────────────────────────────┐
│  train set  │  validation set  │  test set (touch once only) │
└──────────────────────────────────────────────────────────────┘
                      ↑                      ↑
               select model here      report final metric here
```

> The reported 91.02% accuracy is on the source test split that guided checkpoint selection — it is an **optimistic estimate** of true generalization. A held-out test set would give a more honest number.

---

## 📊 Evaluation & Model Governance

Accuracy alone is not sufficient for a bird-identification product. Every production release should include:

### Recommended Metrics

| Metric | Why It Matters |
|--------|---------------|
| **Top-1 accuracy** | Primary success metric |
| **Top-5 accuracy** | Useful for visually similar species |
| **Per-class precision / recall / F1** | Reveals weak species hidden by aggregate accuracy |
| **Confusion matrix** | Identifies systematic confusion pairs (e.g., sparrow species) |
| **Expected Calibration Error (ECE)** | Determines if confidence scores are trustworthy |
| **Low-confidence coverage** | How often can the product safely answer? |
| **Inference latency** | P50, P95, P99 on target hardware |
| **Memory footprint** | Critical for mobile/edge deployment |

### Model Release Checklist

```
□ Unique model version identifier
□ Immutable artifact checksums (SHA-256)
□ Dataset version and provenance
□ Training code commit hash
□ Full evaluation report (all metrics above)
□ Known limitations documented
□ Rollback path confirmed
□ Compatibility check: class names vs backend birds catalog
□ Smoke test suite passing
□ Latency benchmarks on target hardware
```

### Robustness Test Scenarios

Real-world bird photographs differ significantly from dataset images:

| Scenario | Why Hard |
|----------|---------|
| Backlit birds | Silhouette only, no color |
| Partial occlusion | Bird behind branches |
| Motion blur | Bird in flight |
| Distant birds | Small, noisy pixels |
| Unusual poses | Upside-down, wings spread |
| Non-bird images | Model always predicts something |
| Similar-looking species | Sparrow/sparrow confusion |
| Different lighting | Harsh sun vs. shade |

---

## 🖥️ Running the Notebook

### Google Colab (Recommended)

```
Step 1  →  Open training.ipynb in Colab
Step 2  →  Runtime → Change runtime type → GPU (T4 recommended, free tier)
Step 3  →  Connect KaggleHub credentials if prompted
Step 4  →  Run all cells (Runtime → Run All)
Step 5  →  Review selected classes output
Step 6  →  Review sample image visualization
Step 7  →  Wait for training to complete (~10-30 min on T4)
Step 8  →  Download artifacts via Colab's file panel or auto-download cells
Step 9  →  Verify all three files: birds50_best.pth, class_names.json, selected_classes.json
```

### Local Execution

```bash
# Prerequisites: Python 3.9+, pip
cd notebooks
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Adapt Colab-specific paths in the notebook first:
# - /content/Birds50 → ./Birds50 (or your preferred local path)
# - google.colab.files.download() → shutil.copy() or similar

jupyter notebook training.ipynb
```

### Adapting for Local Paths

Find and replace these Colab-specific patterns:

| Colab Pattern | Local Replacement |
|--------------|------------------|
| `/content/Birds50/` | `./Birds50/` |
| `from google.colab import files` | Remove or replace |
| `files.download("artifact.pth")` | `shutil.copy("artifact.pth", output_dir)` |
| `drive.mount('/content/drive')` | Remove if not needed |

---

## 🔭 Known Limitations & Next Experiments

### Current Limitations

| Limitation | Impact | Priority |
|-----------|--------|---------|
| Only 50/220 classes modeled | Product coverage | Medium |
| Random (not curated) class selection | May include hard lookalike groups | Medium |
| Test set used for checkpoint selection | Optimistic accuracy estimate | High |
| Only top-1 accuracy tracked | No visibility into per-class weakness | High |
| No confidence calibration | Overconfident predictions possible | Medium |
| Direct square resize (no aspect-ratio preservation) | Distorts tall/wide birds | Low |
| No explicit backbone freezing (despite transfer-learning docs) | Ambiguous training strategy | Medium |
| No automated test suite | Regressions caught manually | High |

### High-Value Next Experiments

```
Experiment 1  ─  Proper train/val/test splits
                 Train on train, tune on val, report once on test
                 Expected: more honest accuracy metric

Experiment 2  ─  Compare training strategies
                 (a) Frozen backbone, train head only  ~5 epochs
                 (b) Frozen backbone first, unfreeze after 3 epochs
                 (c) Full fine-tune (current)
                 Expected: staged unfreezing often wins

Experiment 3  ─  Top-K evaluation + temperature scaling
                 Return top-3 predictions with calibrated confidence
                 Expected: better UX for ambiguous images

Experiment 4  ─  Unknown / out-of-distribution detection
                 Add a "not a supported bird" test set
                 Evaluate confidence threshold effectiveness

Experiment 5  ─  Aspect-preserving preprocessing
                 Resize shortest edge → CenterCrop(224)
                 Match both training and inference
                 Expected: better results for elongated birds

Experiment 6  ─  Architecture comparison
                 EfficientNet-B0/B4, ConvNeXt-Tiny, RegNet
                 Benchmark: accuracy vs. latency vs. memory
                 Target: beat MobileNetV2 at same inference budget

Experiment 7  ─  Class-balanced training
                 Weighted sampling or weighted loss for imbalanced classes
                 Expected: better per-class recall for rare classes

Experiment 8  ─  Mixed precision training
                 torch.cuda.amp.autocast()
                 Expected: 1.5-2x faster training on GPU, same accuracy

Experiment 9  ─  ONNX / TorchScript export
                 Export and benchmark quantized (INT8) model
                 Expected: 2-4x inference speedup, smaller artifact

Experiment 10 ─  Curated class expansion
                 Add classes by geographic prevalence, user demand
                 Expected: better product utility
```

---

## 🛠️ Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Dataset download fails` | KaggleHub auth or network | Verify Kaggle credentials, check dataset availability |
| `Out of memory (OOM) error` | Batch size or image size too large | Reduce batch size (32→16→8) or lower num_workers |
| `Accuracy stays near random (~2%)` | Wrong labels, bad preprocessing | Verify class mapping, normalization, correct dataset split |
| `Inference classes are wrong` | class_names.json from different run | Confirm JSON came from the exact same training run |
| `FastAPI can't load weights` | Architecture mismatch | Confirm output size is 50 and matches the .pth checkpoint |
| `Backend metadata enrichment fails` | Class name mismatch | Add/fix exact class string in PostgreSQL birds.name |
| `Colab disconnects during training` | Runtime timeout | Enable "stay connected" or use Colab Pro; save checkpoints more often |
| `Random selection changes` | Seed not set | Ensure `random.seed(42)` runs before `random.sample()` |

---

## 📈 Model Lifecycle

The training notebook is the **beginning of the model lifecycle**, not the end:

```
training.ipynb
      │
      │  Produces artifacts
      ▼
ML_service/app/models/      ← Inference deployment
      │
      │  Served via FastAPI
      ▼
Express API                 ← Metadata enrichment
      │
      │  Consumed by
      ▼
Flutter App                 ← User-facing predictions
      │
      │  Generates
      ▼
Real-world prediction logs  ← Drift monitoring
      │
      │  Informs
      ▼
Next training run           ← Improved model
```

Its most important responsibility is producing a **traceable, compatible artifact set** that behaves predictably at every stage downstream.

---

<div align="center">

**The notebook trains the model. The architecture around it makes the model useful.**

*BirdLens Training — Part of the BirdLens full-stack AI bird identification system*

</div>