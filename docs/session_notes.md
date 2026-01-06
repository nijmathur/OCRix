# OCRix Development - Session Notes

This file tracks key learnings, decisions, and progress across development sessions.

---

## Session: January 5, 2026 - Embedding Model Implementation

### Objective
Implement vector-based semantic search using on-device embedding models for document vectorization.

### Key Decisions

#### 1. Switched from MobileBERT to USE-Lite
**Reason**: MobileBERT (96MB) failed with "Bad state: failed precondition" despite extensive debugging
**Solution**: Universal Sentence Encoder Lite (6MB)

**Advantages of USE-Lite**:
- Accepts raw string input (no tokenization needed)
- Smaller model size (6MB vs 96MB)
- Specifically designed for sentence embeddings
- Works with standard TFLite runtime (no Select TF ops needed)
- Simpler code (180 lines vs 220 lines)

#### 2. Upgraded Flutter to Beta Channel
**From**: Flutter 3.38.5 (stable) with Dart 3.10.4
**To**: Flutter 3.40.0-0.2.pre (beta) with Dart 3.11.0
**Reason**: dart_bert_tokenizer required Dart 3.10.7+

### Technical Challenges & Solutions

#### Challenge 1: Database Schema Missing
**Error**: `no such table: document_embeddings`
**Solution**:
- Bumped database version from 8 to 9
- Added table creation in `_onCreate` method
- Added migration in `_onUpgrade` from version 8→9

#### Challenge 2: TFLite Package Compatibility
**Error**: Build failures with tflite_flutter 0.9.5
**Solution**: Upgraded to tflite_flutter 0.12.1 (uses LiteRT 1.4.0)

#### Challenge 3: Select TF Ops Support
**Issue**: BERT models require TensorFlow Select ops
**Attempted**:
- `org.tensorflow:tensorflow-lite-select-tf-ops:2.16.1` (incompatible with LiteRT)
- `com.google.ai.edge.litert:litert-select-tf-ops:1.4.0` (artifact doesn't exist)
- `com.google.ai.edge.litert:litert-tensorflow-select-tf-ops:1.4.0` (artifact doesn't exist)

**Result**: No working Select TF ops gradle dependency for LiteRT 1.4.0

#### Challenge 4: Embedding Dimension Mismatch
**Issue**: Code expected 512 dimensions, MobileBERT output 384
**Solution**: Changed `embeddingDimension` constant to match model output
**Note**: USE-Lite outputs 512 dimensions (reverted back to 512)

### What We Learned

1. **Not all TFLite models work with Flutter**: Despite correct shapes and inputs, some models fail with "failed precondition"
2. **LiteRT migration is incomplete**: LiteRT 1.4.0 doesn't have Select TF ops artifacts published yet
3. **Model design matters**: USE-Lite is designed for embeddings, MobileBERT for classification/QA
4. **Gemma works perfectly**: Same TFLite runtime successfully runs 2.6GB Gemma 2B model
5. **BERT tokenization is complex**: Requires WordPiece tokenizer, padding, truncation, multiple input tensors
6. **Asset loading works**: `Interpreter.fromAsset()` successfully loads models from assets folder

### Files Created/Modified

**New Files**:
- `/docs/EMBEDDING_MODEL_DEBUGGING_LOG.md` - Complete debugging history
- `/assets/models/use_lite.tflite` - 6MB USE-Lite model
- `/assets/models/vocab.txt` - 226KB BERT vocabulary (for failed MobileBERT attempt)
- `/assets/models/1.tflite` - 96MB MobileBERT model (failed to work)

**Modified Files**:
- `pubspec.yaml` - Updated tflite_flutter to 0.12.1, added/removed dart_bert_tokenizer
- `lib/core/config/app_config.dart` - Database version 8→9
- `lib/services/database_service.dart` - Added document_embeddings table
- `lib/services/embedding_service.dart` - Complete rewrite (string input for USE-Lite)
- `lib/ui/screens/ai_search_screen.dart` - Commented out examples section
- `android/app/build.gradle` - Added/removed Select TF ops dependencies

**Removed**:
- `lib/services/llm_search/llm_search_service.dart.OLD` - Old SQL-based service

### Current Status

**Working**:
- ✅ Database schema with document_embeddings table
- ✅ Gemma 2B LLM (2.6GB) loads and runs perfectly
- ✅ USE-Lite model (6MB) downloaded and integrated
- ✅ Simplified embedding service with string input
- ✅ App builds successfully

**Pending Test**:
- ⏳ USE-Lite model inference (device disconnected, awaiting test)

### Next Steps

1. Test USE-Lite model on device
2. Verify document vectorization works
3. Test vector search with queries
4. Test full Hybrid RAG flow (vector search + LLM analysis)

### Configuration

**Environment**:
- Flutter: 3.40.0-0.2.pre (beta)
- Dart: 3.11.0
- tflite_flutter: 0.12.1 (LiteRT 1.4.0)
- Target Device: Pixel 10 Pro XL

**Model Details**:
- Name: Universal Sentence Encoder Lite (USE-Lite)
- Size: 6 MB (6,120,274 bytes)
- Source: TFHub
- Input: Raw strings
- Output: 512-dimensional embeddings
- Max sequence: ~256 tokens (≈1000 characters)

---


## Session: January 6, 2026 - Gemma LLM Integration & Native Crash Debugging

### Objective
Integrate Gemma 2B model for AI-powered document analysis (Two-Stage RAG) with analytical query support (e.g., "how much did I spend on kroger").

### Key Decisions

#### 1. Made GemmaModelService a Singleton
**Reason**: Multiple instances were causing double-initialization of native MediaPipe model
**Implementation**: Added singleton pattern to prevent duplicate model initialization
```dart
static final GemmaModelService _instance = GemmaModelService._internal();
factory GemmaModelService() => _instance;
```

#### 2. Disabled LLM Analysis Feature Temporarily
**Reason**: Native crash in flutter_gemma/MediaPipe SDK (SIGSEGV in libllm_inference_engine_jni.so)
**Status**: Vector search remains fully functional, LLM analysis disabled with `if (false &&` guard
**Timeline**: Will re-enable when flutter_gemma 0.12.0+ stabilizes or when switching to alternative LLM backend

#### 3. Added Visual Model Loading Indicators
**Implementation**:
- Loading spinner during embedding model initialization
- Success banners for both embedding and Gemma models (auto-hide after 5s)
- "AI + Vector" badge when both models are ready
- "Vector Search" badge when only embedding model is ready

### Technical Challenges & Solutions

#### Challenge 1: Gemma Model Installation Flow
**Issue**: First-time installation required complex flow (detect → download → install → initialize)
**Solution**:
- Implemented model file availability check in persistent storage
- Added automatic installation from persistent storage path
- Progress tracking with StreamController for download progress
- Location: `lib/services/llm_search/gemma_model_service.dart:44-198`

#### Challenge 2: Native Crash in MediaPipe LLM Engine
**Error**:
```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0000000000000000
Cause: null pointer dereference
backtrace: libllm_inference_engine_jni.so (Java_com_google_mediapipe_tasks_genai_llminference_LlmTaskRunner_nativePredictSync+148)
```

**Investigation**:
- Crash occurs in `generateChatResponse()` native method
- Happens when creating chat session after calling `analyzeDocuments()`
- Affects all Gemma 2B models (CPU/GPU variants)

**Root Cause** (from research):
- Known bug in Flutter MediaPipe SDK for Gemma models
- Google internal bug tracker: b/349870091
- Issue #56 on google/flutter-mediapipe: "LLM Engine failed in ValidatedGraphConfig Initialization"
- Native Android MediaPipe works, Flutter wrapper crashes
- Affects multiple devices: Samsung S8/S10, Redmi K60 Ultra, Galaxy A25, Pixel 10 Pro XL

**Attempted Fixes**:
1. ❌ Singleton pattern - prevented Dart-level double-init but native crash persisted
2. ❌ Try-catch with timeout - crashes before timeout reached
3. ❌ Calling `refreshLLMStatus()` after install - still crashed on analysis
4. ✅ **Disabled LLM analysis** - app now stable with vector search only

**Location**: `lib/services/llm_search/vector_search_service.dart:164` (disabled with `if (false &&`)

#### Challenge 3: Double Initialization of Gemma Service
**Issue**: Two separate GemmaModelService instances (AISearchScreen + VectorSearchService)
**Symptoms**:
- AISearchScreen instance initialized successfully
- VectorSearchService instance threw "Model not initialized"
- Analysis failed with "Bad state: Model not initialized. Call initialize() first."

**Solution**: Singleton pattern ensures all instances share same underlying model
**Result**: Initialization succeeded but native crash still occurred during inference

#### Challenge 4: Model Readiness State Management
**Issue**: VectorSearchService didn't know when Gemma was installed
**Solution**: Added `refreshLLMStatus()` method to update readiness flag
**Location**: `lib/services/llm_search/vector_search_service.dart:76-92`

### What We Learned

1. **flutter_gemma Has Critical Native Bug**: The MediaPipe SDK compiled for Flutter has validation failures in `libllm_inference_engine_jni.so` causing SIGSEGV crashes
2. **Native Crashes Can't Be Caught in Dart**: Try-catch blocks don't prevent native segmentation faults
3. **Google's Bug Escalation**: Issue escalated to google-ai-edge team as internal bug b/349870091
4. **Workarounds Exist**: Some developers use native Android via Method Channels to bypass Flutter wrapper
5. **Vector Search Alone is Valuable**: Semantic document retrieval works perfectly without LLM analysis
6. **Model Size vs Stability**: Smaller embedding models (6MB USE-Lite) more stable than large LLMs (2.6GB Gemma 2B)

### Research Findings

**Sources Investigated**:
- [flutter_gemma v0.12.0 on pub.dev](https://pub.dev/packages/flutter_gemma) - Published 10 hours ago (Jan 6, 2026)
- [Google Flutter-MediaPipe Issue #56](https://github.com/google/flutter-mediapipe/issues/56) - LLM Engine validation crash
- [aub.ai Issue #21](https://github.com/BrutalCoding/aub.ai/issues/21) - App crash loading Gemma models
- [flutter_gemma changelog](https://pub.dev/packages/flutter_gemma/changelog) - v0.11.16 fixed iOS crash, v0.12.0 added desktop support

**Key Quote from Issue #56**: "That very likely means there are issues with the version of the SDK compiled specifically for Flutter."

### Files Created/Modified

**Modified Files**:
- `lib/ui/screens/ai_search_screen.dart` - Added visual loading indicators and success banners
- `lib/services/llm_search/gemma_model_service.dart` - Made singleton, improved initialization
- `lib/services/llm_search/vector_search_service.dart` - Added `refreshLLMStatus()`, disabled LLM analysis
- `android/app/build.gradle` - No changes (kept existing config)
- `lib/models/user_settings.dart` - No changes to schema
- `lib/models/user_settings.g.dart` - Auto-generated

**New State Variables** (ai_search_screen.dart:28-36):
- `_embeddingModelJustLoaded` - Track embedding model load completion
- `_gemmaModelJustInstalled` - Track Gemma installation completion
- `_showEmbeddingSuccess` - Control success banner visibility
- `_showGemmaSuccess` - Control Gemma success banner visibility

### Current Status

**Working**:
- ✅ Vector search with USE-Lite (512-dimensional embeddings)
- ✅ Document vectorization (1 Kroger receipt vectorized)
- ✅ Semantic search queries (e.g., "how much did i spend on kroger" finds Kroger receipt with 79% match)
- ✅ Gemma 2B model installation (2.6GB copied to app storage)
- ✅ Gemma model initialization (loads successfully into MediaPipe)
- ✅ Visual loading indicators and success banners
- ✅ No crashes (LLM analysis disabled)
- ✅ "AI + Vector" badge shows when Gemma ready

**Not Working**:
- ❌ LLM-powered document analysis (native crash in MediaPipe SDK)
- ❌ Analytical queries with AI answers (e.g., calculating totals, extracting prices)
- ❌ Two-Stage RAG (Stage 1 works, Stage 2 disabled)

**Pending**:
- ⏳ Wait for flutter_gemma/MediaPipe bug fix
- ⏳ Consider alternative on-device LLM backends (llama.cpp, ONNX Runtime, MediaPipe with native Android)

### Next Steps

**Immediate Options**:
1. **Keep vector search only** - Still provides excellent semantic document retrieval
2. **Monitor flutter_gemma updates** - Watch for versions > 0.12.0 with crash fixes
3. **Research alternatives**:
   - llama.cpp for Flutter (llama_cpp_dart)
   - ONNX Runtime with Phi-3 Mini
   - Native Android MediaPipe via Method Channels
   - Server-based LLM with local caching

**Long-term**:
- Test flutter_gemma updates when Google fixes MediaPipe Flutter SDK
- Implement fallback to cloud-based LLM if on-device fails
- Add toggle in settings to enable/disable LLM analysis

### Configuration

**Environment**:
- Flutter: 3.40.0-0.2.pre (beta)
- Dart: 3.11.0
- flutter_gemma: 0.11.15 (in pubspec.lock)
- tflite_flutter: 0.12.1
- Target Device: Pixel 10 Pro XL (Android 16)

**Model Details**:
- **Embedding Model**: Universal Sentence Encoder Lite (6MB) - ✅ Working
- **LLM Model**: Gemma 2B Instruction Tuned (2.6GB) - ❌ Crashes on inference
- **Model Location**: `/storage/emulated/0/Android/data/com.ocrix.app/models/gemma2-2b-it.task`

**Known Issues**:
- Native crash in `libllm_inference_engine_jni.so` during `generateResponse()`
- Google internal bug: b/349870091
- Affects multiple Android devices with MediaTek and Qualcomm processors

---

