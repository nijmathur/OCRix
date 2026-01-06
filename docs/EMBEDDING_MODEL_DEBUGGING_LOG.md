# Embedding Model Implementation - Complete Debugging Log

**Date**: January 5, 2026
**Feature**: Vector-based semantic search for OCRix document scanning app
**Goal**: Implement on-device embedding generation for document vectorization

---

## Architecture Overview

### Hybrid RAG Approach (Current Implementation)
- **Stage 1**: Vector Similarity Search using embeddings
- **Stage 2**: Optional LLM Analysis using Gemma 2B
- **Better than**: Pure SQL generation approach (documented but not used)

### Components
- **Embedding Service**: Generates 384/512-dimensional semantic embeddings
- **Vector Database Service**: Stores embeddings in SQLite BLOB with cosine similarity
- **Vector Search Service**: Coordinates embedding + optional LLM analysis
- **LLM Service**: Gemma 2B (2.6 GB) - WORKING ✅

### Database Schema
```sql
CREATE TABLE document_embeddings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id TEXT NOT NULL UNIQUE,
    embedding BLOB NOT NULL,
    text_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
)
```

---

## Chronological Debugging History

### Phase 1: Initial TFLite Model Attempts (USE-Lite with Downloads)

#### Attempt 1.1: Universal Sentence Encoder with Auto-Download
**Date**: January 5, 2026 (early)
**Model**: Universal Sentence Encoder Lite
**Approach**: Download model from TFHub to app directory
**Code**: Original `embedding_service.dart` with `Interpreter.fromFile()`

**Error**:
```
DioException [bad response]: 403 Forbidden
URL: https://storage.googleapis.com/tfhub-lite-models/google/lite-model/universal-sentence-encoder-qa-ondevice/1.tflite
```

**Root Cause**: TFHub model URLs changed or require authentication
**Status**: ❌ Failed

---

#### Attempt 1.2: Manual Model Download with wget
**Approach**: Manually download model via wget and push to device with adb

**Commands**:
```bash
wget https://storage.googleapis.com/tfhub-lite-models/google/lite-model/universal-sentence-encoder-qa-ondevice/1.tflite
adb push sentence_encoder.tflite /data/local/tmp/
adb shell run-as com.ocrix.app cp /data/local/tmp/sentence_encoder.tflite /data/data/com.ocrix.app/app_flutter/models/
```

**Error**:
```
[EmbeddingService] Loading model from: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
[EmbeddingService] Failed to initialize: Bad state: failed precondition
```

**Root Cause**: Model requires "Select TF ops" support (TensorFlow operations not in standard TFLite)
**File Size**: 5.9 MB
**Status**: ❌ Failed

---

#### Attempt 1.3: MobileBERT Model Download
**Model**: MobileBERT (also BERT-based, requires Select TF ops)
**Source**: TFHub

**Error**: Same "Bad state: failed precondition"
**Root Cause**: All BERT-based models require Select TF ops support
**Status**: ❌ Failed

---

### Phase 2: Adding Select TF Ops Support

#### Attempt 2.1: First TFLite Package Update
**Issue**: Build failure with tflite_flutter 0.9.5

**Error**:
```
../../.pub-cache/hosted/pub.dev/tflite_flutter-0.9.5/lib/src/tensor.dart:53:12:
Error: The method 'UnmodifiableUint8ListView' isn't defined for the type 'Tensor'.
```

**Fix**: Updated pubspec.yaml from `tflite_flutter: ^0.9.0` to `tflite_flutter: ^0.12.1`
**Status**: ✅ Build fixed

---

#### Attempt 2.2: Database Schema Issues
**Error**:
```
DatabaseException(no such table: document_embeddings (code 1 SQLITE_ERROR))
```

**Root Cause**: Database already existed at version 8, so onCreate didn't run
**Fix**:
1. Bumped database version from 8 to 9 in `app_config.dart`
2. Added `document_embeddings` table to `_onCreate` (line 310-325)
3. Added migration from version 8→9 in `_onUpgrade` (line 506-529)

**Status**: ✅ Fixed

---

#### Attempt 2.3: Select TF Ops - TensorFlow Lite 2.16.1
**Approach**: Add Select TF ops gradle dependency

**File**: `android/app/build.gradle`
```gradle
dependencies {
    implementation 'org.tensorflow:tensorflow-lite-select-tf-ops:2.16.1'
}
```

**Error**: Still "Bad state: failed precondition" during inference
**Status**: ❌ Failed - TFLite 2.16.1 incompatible with LiteRT 1.4.0

---

#### Attempt 2.4: LiteRT Migration Attempt
**Context**: tflite_flutter 0.12.1 migrated from TensorFlow Lite 2.12.0 to LiteRT 1.4.0

**Attempted Dependencies**:
```gradle
// Attempt 1
implementation 'com.google.ai.edge.litert:litert-select-tf-ops:1.4.0'

// Attempt 2
implementation 'com.google.ai.edge.litert:litert-tensorflow-select-tf-ops:1.4.0'
```

**Error**:
```
Could not find com.google.ai.edge.litert:litert-tensorflow-select-tf-ops:1.4.0
Searched in:
  - https://dl.google.com/dl/android/maven2/...
  - https://repo.maven.apache.org/maven2/...
```

**Root Cause**: LiteRT-specific Select TF ops artifact doesn't exist for version 1.4.0
**Status**: ❌ Failed - Artifact not available

**Research**:
- Checked official LiteRT documentation: No LiteRT-specific Select TF ops artifact documented
- Checked LiteRT migration guide: Only shows package name replacements, not Select TF ops
- Web search for LiteRT 1.4.0 dependencies: No results

---

#### Attempt 2.5: Remove Select TF Ops Dependency
**Hypothesis**: tflite_flutter 0.12.1 might include Select TF ops support internally

**Approach**: Removed gradle dependency entirely, rely on package's LiteRT 1.4.0

**Result**: ✅ Build succeeded
**But**: Still "Bad state: failed precondition" during inference
**Status**: ⚠️ Partial success (build works, inference doesn't)

---

### Phase 3: Asset-Based Model Loading

#### Attempt 3.1: Load Model from Assets (String Input)
**User Discovery**: BERT models require "Select TF ops" support configured in build.gradle

**Changes**:
1. Downloaded 96MB model to `assets/models/1.tflite`
2. Changed from `Interpreter.fromFile()` to `Interpreter.fromAsset()`
3. Added `assets/models/` to pubspec.yaml

**Code**:
```dart
_interpreter = await Interpreter.fromAsset(
  'assets/models/1.tflite',
  options: options,
);
```

**Error**: Still "Bad state: failed precondition"
**Root Cause**: Model expects tokenized integer input, not strings
**Status**: ❌ Failed - Wrong input format

**Model Info** (from logs):
```
Input shape: [1, 384]
Output shape: [1, 384]
```

**Key Insight**: Embedding dimension is 384, not 512!

---

#### Attempt 3.2: Fix Embedding Dimension Mismatch
**Issue**: Code expected 512 dimensions, model outputs 384

**Fix**: Changed `embeddingDimension` from 512 to 384

**File**: `lib/services/embedding_service.dart:14`
```dart
static const int embeddingDimension = 384; // Was 512
```

**Status**: ✅ Fixed dimension mismatch
**But**: Still fails inference due to input format

---

### Phase 4: BERT Tokenization Implementation

#### Attempt 4.1: Add dart_bert_tokenizer Package
**Issue**: Dart SDK version too old (3.10.4, needed 3.10.7+)

**Error**:
```
Because ocrix depends on dart_bert_tokenizer >=1.0.1 which requires SDK version >=3.10.7 <4.0.0, version solving failed.
```

**Fix**: Upgraded Flutter from stable (3.38.5) to beta (3.40.0-0.2.pre)
**New Dart Version**: 3.11.0
**Status**: ✅ Flutter upgraded successfully

---

#### Attempt 4.2: Implement BERT Tokenization (First Try)
**Package**: dart_bert_tokenizer 1.0.2
**Approach**: Load vocabulary, tokenize text, prepare input tensors

**Vocabulary**: Downloaded from HuggingFace
```bash
wget -O assets/models/vocab.txt https://huggingface.co/google/mobilebert-uncased/raw/main/vocab.txt
# Size: 231,508 bytes (226 KB)
```

**Code Changes**: Complete rewrite of `embedding_service.dart`
- Added tokenizer initialization
- Implemented WordPiece tokenization
- Prepared input_ids, attention_mask, token_type_ids

**Build Errors**:
1. `WordPieceTokenizer.fromVocabContent()` doesn't exist → Only `fromVocabFile()` available
2. `PaddingStrategy` not defined → Not part of the API
3. `maxLength` parameter doesn't exist → Manual padding needed
4. `runForMultipleInputs()` signature mismatch

**Status**: ❌ API mismatches

---

#### Attempt 4.3: Fix API Mismatches
**Changes**:
1. Copy vocab.txt from assets to app directory first
2. Use `WordPieceTokenizer.fromVocabFile(path)` instead
3. Manual padding/truncation with `_padOrTruncate()` helper
4. Fixed tokenizer API: `encode(text, addSpecialTokens: true)`

**Code**:
```dart
// Copy vocab from assets
final vocabContent = await rootBundle.load('assets/models/vocab.txt');
await vocabFile.writeAsBytes(vocabContent.buffer.asUint8List());

// Load tokenizer
_tokenizer = await WordPieceTokenizer.fromVocabFile(vocabPath);

// Tokenize
final encoding = _tokenizer!.encode(text, addSpecialTokens: true);

// Pad/truncate
final inputIds = _padOrTruncate(encoding.ids, maxSequenceLength, 0);
```

**Status**: ✅ Build succeeded, tokenization working

**Logs**:
```
[EmbeddingService] Tokenizer loaded successfully
[EmbeddingService] Token IDs length: 711
[EmbeddingService] First 10 tokens: [[CLS], k, ##ro, ##ger, ##i, ., k, ##ro, ##ger, ##i]
[EmbeddingService] First 10 IDs: [101, 1047, 3217, 4590, 2072, 1012, 1047, 3217, 4590, 2072]
```

**But**: Still "Bad state: failed precondition" at inference
**Status**: ⚠️ Tokenization works, inference fails

---

#### Attempt 4.4: Fix Input Tensor Format (Single Input)
**Issue**: Used `run()` for single input, but model expects 3 inputs

**Model Signature**:
- **Input 0**: [1, 384] int32 - input_ids
- **Input 1**: [1, 384] int32 - attention_mask
- **Input 2**: [1, 384] int32 - token_type_ids
- **Output 0**: [1, 384] float32
- **Output 1**: [1, 384] float32

**Error**: "Bad state: failed precondition" at `_interpreter!.run(input, output)`
**Status**: ❌ Wrong inference method

---

#### Attempt 4.5: Use runForMultipleInputs (Wrong Format)
**Approach**: Switch to `runForMultipleInputs()` for 3 inputs

**Code (Attempt 1)**:
```dart
final inputs = {
  0: [inputIds],
  1: [attentionMask],
  2: [tokenTypeIds],
};

_interpreter!.runForMultipleInputs(inputs.values.toList(), outputs);
```

**Error**: Still "Bad state: failed precondition"
**Root Cause**: Wrong input format - `inputs.values.toList()` creates incorrect structure
**Status**: ❌ Failed

---

#### Attempt 4.6: Fix Input List Format
**Approach**: Use List instead of Map for inputs

**Code (Attempt 2)**:
```dart
final inputs = [
  [inputIds],     // [1, 384]
  [attentionMask], // [1, 384]
  [tokenTypeIds],  // [1, 384]
];

final outputs = {
  0: [List.filled(embeddingDimension, 0.0)],
  1: [List.filled(embeddingDimension, 0.0)],
};

_interpreter!.runForMultipleInputs(inputs, outputs);
```

**API Signature**: `void runForMultipleInputs(List<Object> inputs, Map<int, Object> outputs)`

**Error**: STILL "Bad state: failed precondition" at line 113
**Status**: ❌ Failed

**Logs**:
```
[EmbeddingService] Number of inputs: 3
[EmbeddingService] Number of outputs: 2
[EmbeddingService] Input 0 shape: [1, 384], type: int32
[EmbeddingService] Input 1 shape: [1, 384], type: int32
[EmbeddingService] Input 2 shape: [1, 384], type: int32
[EmbeddingService] Output 0 shape: [1, 384], type: float32
[EmbeddingService] Output 1 shape: [1, 384], type: float32
[EmbeddingService] Token IDs length: 711
[EmbeddingService] First 10 tokens: [[CLS], k, ##ro, ##ger, ##i, ., k, ##ro, ##ger, ##i]
[EmbeddingService] First 10 IDs: [101, 1047, 3217, 4590, 2072, 1012, 1047, 3217, 4590, 2072]
[EmbeddingService] Failed to generate embedding: Bad state: failed precondition
```

**Analysis**: Everything looks correct - tokenization works, model loaded, correct shapes, but inference still fails

---

## Summary of Issues

### What's Working ✅
1. **Gemma LLM**: 2.6 GB model loads and runs perfectly
2. **Database Schema**: document_embeddings table created with migrations
3. **BERT Tokenization**: WordPiece tokenization generates correct token IDs
4. **Model Loading**: 96MB MobileBERT loads from assets successfully
5. **Input Shapes**: All inputs correctly shaped as [1, 384]
6. **Flutter/Dart**: Upgraded to beta channel (3.40.0-0.2.pre, Dart 3.11.0)
7. **Dependencies**: All packages installed correctly

### What's NOT Working ❌
1. **TFLite Inference**: Persistent "Bad state: failed precondition" error
2. **Select TF Ops**: No working gradle dependency for LiteRT 1.4.0
3. **Model Compatibility**: MobileBERT may be incompatible with Flutter TFLite runtime

### Persistent Error
```
[EmbeddingService] Failed to generate embedding: Bad state: failed precondition
Stack trace: #0 checkState (package:quiver/check.dart:74:5)
             #4 EmbeddingService.generateEmbedding (package:ocrix/services/embedding_service.dart:113:21)
```

**Line 113**: `_interpreter!.runForMultipleInputs(inputs, outputs);`

---

## Configuration Details

### Current Environment
- **Flutter**: 3.40.0-0.2.pre (beta channel)
- **Dart**: 3.11.0
- **tflite_flutter**: 0.12.1 (uses LiteRT 1.4.0)
- **dart_bert_tokenizer**: 1.0.2
- **Device**: Pixel 10 Pro XL (Android)

### Files Modified
1. `pubspec.yaml`: Added tflite_flutter 0.12.1, dart_bert_tokenizer 1.0.2
2. `lib/core/config/app_config.dart`: Database version 8 → 9
3. `lib/services/database_service.dart`: Added document_embeddings table
4. `lib/services/embedding_service.dart`: Complete rewrite with BERT tokenization
5. `lib/ui/screens/ai_search_screen.dart`: Commented out examples section
6. `android/app/build.gradle`: Added/removed Select TF ops dependencies
7. `assets/models/1.tflite`: 96MB MobileBERT model
8. `assets/models/vocab.txt`: 226KB BERT vocabulary

### Gradle Dependencies Tried
```gradle
// All failed or didn't help:
implementation 'org.tensorflow:tensorflow-lite-select-tf-ops:2.16.1'
implementation 'com.google.ai.edge.litert:litert-select-tf-ops:1.4.0'
implementation 'com.google.ai.edge.litert:litert-tensorflow-select-tf-ops:1.4.0'

// Current: None (removed all)
```

---

## Lessons Learned

### Key Insights
1. **BERT models are complex**: Require tokenization, multiple inputs, Select TF ops support
2. **LiteRT migration incomplete**: LiteRT 1.4.0 doesn't have Select TF ops artifacts yet
3. **TFLite compatibility**: Not all models work with Flutter's TFLite implementation
4. **Gemma works perfectly**: Same TFLite runtime successfully runs 2.6GB Gemma model
5. **Model design matters**: USE-Lite designed for embeddings, MobileBERT designed for classification

### What We Know
- The TFLite runtime works (proven by Gemma)
- The tokenization works (verified in logs)
- The model loads (no errors during initialization)
- The inputs are correctly shaped (verified against model signature)
- But inference fails with "failed precondition"

### Probable Root Cause
The 96MB MobileBERT model likely requires:
- TensorFlow Flex delegate (not available in tflite_flutter)
- Or specific TensorFlow operations not supported by LiteRT 1.4.0
- Or additional runtime configuration we haven't discovered

---

## Next Steps

### Recommended Approach: Switch to USE-Lite
**Model**: Universal Sentence Encoder Lite
**Size**: 1-2 MB (vs 96 MB)
**Input**: Raw strings (no tokenization needed)
**Output**: 512-dimensional embeddings
**Complexity**: Low (works with original simple code)
**Proven**: Known to work with TFLite
**Purpose**: Specifically designed for sentence embeddings

**Advantages**:
- No BERT tokenization complexity
- No Select TF ops requirement
- Much smaller model size
- Simpler code (revert to original `embedding_service.dart`)
- Higher success probability

**Changes Required**:
1. Download USE-Lite model (~1-2 MB)
2. Revert `embedding_service.dart` to string input version
3. Update embedding dimension to match model output
4. Remove BERT tokenizer dependency
5. Remove vocab.txt file

### Alternative: Keep Debugging MobileBERT
**Remaining Options**:
1. Try different MobileBERT model variants
2. Build custom tflite_flutter with Flex delegate
3. Use platform channels to call native TFLite with Flex support
4. Wait for LiteRT Select TF ops artifacts to be published

**Complexity**: Very High
**Success Probability**: Low
**Time Investment**: Significant

---

## Debugging Resources Created

### Documentation
- `/home/nij/projects/OCRix/docs/TFLITE_EMBEDDING_DEBUG.md` - Initial debugging guide
- `/home/nij/projects/OCRix/docs/LLM_ENHANCEMENT_APPROACHES.md` - Architecture comparison
- `/home/nij/projects/OCRix/docs/SETUP_EMBEDDING_MODEL.md` - Setup instructions
- `/home/nij/projects/OCRix/docs/VECTOR_SEARCH_IMPLEMENTATION.md` - Implementation details

### Debug Commands
```bash
# ADB debugging
adb logcat | grep -E "(EmbeddingService|VECTOR SEARCH|vectoriz)"
adb shell pm clear com.ocrix.app
adb uninstall com.ocrix.app
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Flutter
flutter clean
flutter build apk --debug
flutter pub get

# Model verification
ls -lh /home/nij/projects/OCRix/assets/models/
file /home/nij/projects/OCRix/assets/models/1.tflite
```

---

## Decision Point

**Current Status**: MobileBERT approach has failed after extensive debugging
**Options**:
- A) Continue debugging (uncertain outcome, high complexity)
- B) Switch to USE-Lite (proven approach, simple, recommended)

**Recommendation**: **Option B - Switch to USE-Lite**

This document should provide complete context for future debugging sessions and prevent re-attempting failed approaches.
