# Models and Setup Summary

## Quick Overview

OCRix uses a **Hybrid RAG** approach combining vector similarity search with optional LLM analysis.

### Two Models Required:

| Model | Size | Download | Purpose | Status |
|-------|------|----------|---------|--------|
| **Embedding Model** | 1-2 MB | ✅ Auto | Semantic search (Stage 1) | Auto-downloads on first use |
| **Gemma LLM** | 1.5-2 GB | ⚠️ Manual | Document analysis (Stage 2) | Requires manual installation |

## Implementation Approach

**ACTUAL**: Hybrid of Approach 1 (Two-Stage RAG) + Approach 4 (Vector Similarity)

**NOT**: Pure Approach 1 (SQL generation) as recommended in docs

### Why This is Better:

```
┌─────────────────────────────────────────────────────────────┐
│ Documented Approach 1 (Two-Stage RAG)                       │
├─────────────────────────────────────────────────────────────┤
│ Stage 1: LLM generates SQL → Execute → Get documents       │
│ Stage 2: LLM analyzes documents → Generate answer          │
└─────────────────────────────────────────────────────────────┘

vs.

┌─────────────────────────────────────────────────────────────┐
│ Implemented Approach (Hybrid RAG)                           │
├─────────────────────────────────────────────────────────────┤
│ Stage 1: Vector similarity → Get semantically similar docs  │
│ Stage 2: LLM analyzes documents → Generate answer (optional)│
└─────────────────────────────────────────────────────────────┘
```

### Advantages:
- 🚀 Faster retrieval (pre-computed embeddings vs SQL generation)
- 🎯 Better semantic understanding (embeddings vs keywords)
- 🔒 No SQL injection risks (no SQL generation)
- 🌍 Language agnostic (embeddings work across languages)
- ⚡ Optional LLM (works without Gemma for simple searches)

## Model Details

### Model 1: Universal Sentence Encoder QA (Embedding Model)

```yaml
Name: sentence_encoder.tflite
Type: TensorFlow Lite
Size: 1-2 MB
Dimensions: 512
Source: https://storage.googleapis.com/tfhub-lite-models/google/lite-model/universal-sentence-encoder-qa-ondevice/1.tflite
Storage: {AppDocuments}/models/sentence_encoder.tflite
Download: Automatic via Dio library
Status: ✅ Implemented and working
```

**What it does**: Converts text to 512-dimensional vectors for semantic similarity search

**When downloaded**: First time user performs AI search

**Time to download**: 10-30 seconds (1-2 MB file)

### Model 2: Gemma 2B Instruction Tuned (LLM)

```yaml
Name: gemma2-2b-it.task
Type: MediaPipe LLM (TensorFlow Lite)
Size: 1.5-2 GB
Context: 8K tokens
Source: https://www.kaggle.com/models/google/gemma/tfLite/gemma2-2b-it
Storage: /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task
Download: Manual (user picks file or use adb)
Status: ⚠️ Requires manual installation
```

**What it does**: Analyzes retrieved documents to answer complex questions, extract data, and perform aggregations

**When needed**: Only for analytical queries (how much, compare, total, etc.)

**Time to analyze**: 30-60 seconds for 10 documents

## Setup Instructions

### For Development (Recommended):

```bash
# Step 1: Download Gemma model
# Visit: https://www.kaggle.com/models/google/gemma/tfLite/gemma2-2b-it
# Download: gemma2-2b-it.task (~1.5-2 GB)

# Step 2: Push to device via ADB
adb shell mkdir -p /sdcard/Android/media/com.ocrix.app/models
adb push ~/Downloads/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/

# Step 3: Build and install app
flutter build apk --debug
flutter install

# Step 4: The embedding model will auto-download on first search
# No action needed for embedding model!
```

### For End Users:

1. **Install OCRix app**
2. **Download Gemma model** to device (from Kaggle)
3. **Open AI Search** in app
4. **Click "Download Model"** button
5. **Select downloaded .task file**
6. **Wait for installation** (shows progress)
7. **Embedding model downloads automatically** on first search

### For Testing Without LLM:

You can test vector search without the Gemma model:

```bash
# Just build and install the app
flutter build apk --debug
flutter install

# Vector search works immediately (embedding model auto-downloads)
# LLM analysis will be unavailable but search still works
```

## Feature Matrix

| Feature | Embedding Only | Embedding + LLM |
|---------|---------------|-----------------|
| Semantic Search | ✅ | ✅ |
| Find similar documents | ✅ | ✅ |
| "Find receipts" | ✅ | ✅ |
| "Find food receipts" | ✅ | ✅ |
| "How much spent?" | ❌ | ✅ |
| "Compare X vs Y" | ❌ | ✅ |
| "Total spent on food" | ❌ | ✅ |
| Price extraction | ❌ | ✅ |
| Aggregations | ❌ | ✅ |
| Natural language answers | ❌ | ✅ |

## File Locations

### After Installation:

```
Device Storage:
├── /sdcard/Android/media/com.ocrix.app/models/
│   └── gemma2-2b-it.task (1.5-2 GB) [Manual]
│
App Documents:
├── {AppDocuments}/models/
│   └── sentence_encoder.tflite (1-2 MB) [Auto]
│
App Database:
└── {AppDocuments}/databases/
    ├── ocrix.db (SQLite database)
    └── [Contains document_embeddings table with vectors]
```

## Checking Model Status

### Via App UI:
- Open AI Search screen
- Look for status badges:
  - ⚠️ "Model Not Available" = Gemma not installed
  - ✅ "AI Ready" = Both models ready
  - 🔄 "Downloading..." = Embedding model downloading

### Via ADB:
```bash
# Check Gemma model
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/

# Check app logs
adb logcat | grep -E "Gemma|Embedding|VectorSearch"

# Expected logs:
# [EmbeddingService] Model downloaded successfully
# [GemmaModelService] Model file found at: ...
# [VectorSearchService] Initialization complete
```

## Performance

### First Use:
- Embedding model download: ~10-30 seconds
- Gemma model load: ~5-10 seconds
- Document vectorization: ~1-2 seconds per 100 docs

### Ongoing Use:
- Simple search query: < 1 second
- Analytical query: 30-60 seconds
- Re-vectorization: Only when docs change

## Storage Usage

```
Base App: ~50 MB
Embedding Model: +1-2 MB
Gemma Model: +1.5-2 GB
Document Embeddings: +1-2 KB per document

Example for 1000 documents:
- App: 50 MB
- Embedding model: 2 MB
- Gemma model: 1.5 GB
- 1000 doc embeddings: 2 MB
- Total: ~1.55 GB
```

## Troubleshooting

### Embedding Model Issues:
```bash
# Check if downloaded
adb shell ls {AppDocuments}/models/sentence_encoder.tflite

# If missing, clear app data and retry
adb shell pm clear com.ocrix.app

# Logs should show:
# [EmbeddingService] Downloading model from ...
# [EmbeddingService] Model downloaded successfully
```

### Gemma Model Issues:
```bash
# Check if exists
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task

# If missing or wrong size, re-push
adb push ~/Downloads/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/

# Verify size (should be ~1.5-2 GB)
adb shell du -h /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task
```

### Vectorization Issues:
```bash
# Check database
adb shell sqlite3 {AppDocuments}/databases/ocrix.db \
  "SELECT COUNT(*) FROM document_embeddings;"

# Should match document count or be close
```

## Quick Reference

| What | Where | How |
|------|-------|-----|
| Embedding Model | Auto-downloads | No action needed |
| Gemma Model | Manual install | See [DOWNLOAD_GEMMA_MODEL.md](./DOWNLOAD_GEMMA_MODEL.md) |
| Implementation Details | Code analysis | See [CURRENT_IMPLEMENTATION_ANALYSIS.md](./CURRENT_IMPLEMENTATION_ANALYSIS.md) |
| Vector Search Setup | Architecture | See [VECTOR_SEARCH_IMPLEMENTATION.md](./VECTOR_SEARCH_IMPLEMENTATION.md) |

## Summary

✅ **What works out of the box**:
- Semantic vector search
- Document similarity
- Embedding model auto-download

⚠️ **What needs setup**:
- Gemma LLM for analytical queries
- Manual download and installation required

🎯 **Recommended for testing**:
1. Start with vector search only (no Gemma needed)
2. Add Gemma later when you need analytical queries
3. Both approaches work independently
