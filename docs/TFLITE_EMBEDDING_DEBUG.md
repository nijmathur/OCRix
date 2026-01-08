# TFLite Embedding Model Loading Issue - Debug Information

## Issue Summary

**Problem**: TFLite Interpreter fails to load embedding models with error: `Bad state: failed precondition`

**Impact**: Vector search cannot function because embeddings cannot be generated

**Status**: Blocking - tried multiple models and configurations, all fail with same error

---

## What Works ✅

1. **Model Download**: All models download successfully (100% completion)
2. **File Storage**: Model files are saved correctly to device storage
3. **File Size**: Downloaded files have correct size (verified)
4. **Database**: `document_embeddings` table exists and is accessible
5. **VectorSearchService**: Code logic is correct and ready to use embeddings
6. **Gemma LLM**: Loads and works perfectly (same TFLite library!)

## What Doesn't Work ❌

**TFLite Interpreter fails when loading embedding models** - Consistently fails at this line:
```dart
_interpreter = await Interpreter.fromFile(File(modelPath), options: options);
```

Error: `Bad state: failed precondition`

---

## Models Tried

### 1. Universal Sentence Encoder QA (Original)

**URL**:
```
https://tfhub.dev/google/lite-model/universal-sentence-encoder-qa-ondevice/1?lite-format=tflite
```

**Local Path**:
```
/data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
```

**File Size**: ~5.9 MB (6,120,274 bytes)

**Result**: ❌ Failed with "Bad state: failed precondition"

**Logs**:
```
01-05 12:40:53.887 19145 19145 I flutter : [EmbeddingService] Model downloaded successfully to: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
01-05 12:40:53.888 19145 19145 I flutter : [EmbeddingService] Loading model from: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
01-05 12:40:53.918 19145 19145 I flutter : [EmbeddingService] Failed to initialize: Bad state: failed precondition
```

---

### 2. MobileBERT (Alternative)

**URL**:
```
https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1?lite-format=tflite
```

**Local Path**:
```
/data/user/0/com.ocrix.app/app_flutter/models/mobilebert.tflite
```

**File Size**: Unknown (download appeared to succeed)

**Result**: ❌ Failed with same error

**Logs**:
```
01-05 12:50:24.409 21203 21203 I flutter : [EmbeddingService] Failed to generate embedding: Bad state: failed precondition
01-05 12:50:24.409 21203 21203 I flutter : [VectorDatabaseService] Failed to vectorize document: Bad state: failed precondition
```

---

## TFLite Configuration Attempted

### Code Location
`/home/nij/projects/OCRix/lib/services/embedding_service.dart`

### Configuration Used (Lines 98-107)
```dart
// Configure TFLite interpreter options
final options = InterpreterOptions()
  ..threads = 4  // Use multiple threads for better performance
  ..useNnApiForAndroid = false;  // Disable NNAPI (can cause compatibility issues)

// Load the TFLite model from file with options
_interpreter = await Interpreter.fromFile(
  File(modelPath),
  options: options,
);
```

### Options Tried
1. ✅ Default options (no configuration)
2. ✅ Multi-threading (4 threads)
3. ✅ NNAPI disabled
4. ❌ GPU delegates (not attempted - would require additional packages)

**Result**: All configurations fail with same error

---

## Dependencies

### pubspec.yaml
```yaml
dependencies:
  tflite_flutter: ^0.12.1
  dio: ^5.7.0  # For model download
  path_provider: ^2.1.5
```

### Native Libraries
- TFLite runtime is included with `tflite_flutter` package
- No additional native dependencies specified

---

## Device Information

**Device**: Pixel 10 Pro XL (59040DLCQ00008)
**Android Version**: Unknown (check via `adb shell getprop ro.build.version.release`)
**Architecture**: Unknown (check via `adb shell getprop ro.product.cpu.abi`)
**Available Storage**: 31 GB

---

## Comparison: Why Does Gemma Work?

**Gemma 2B Model**: ✅ Loads successfully using same TFLite library!

**Gemma Configuration**:
```dart
// Location: lib/services/llm_search/gemma_model_service.dart
// Gemma uses flutter_gemma package which wraps MediaPipe
// MediaPipe uses TFLite internally but with different loading mechanism
```

**Key Difference**:
- Gemma uses `flutter_gemma` package (MediaPipe-based)
- Embeddings use `tflite_flutter` directly
- Both use TFLite runtime, but different loading paths

**File Paths**:
- Gemma: `/storage/emulated/0/Android/data/com.ocrix.app/models/gemma2-2b-it.task`
- Embeddings: `/data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite`

---

## Complete Error Flow

### 1. Initialization Sequence
```
User opens AI Search screen
  ↓
VectorSearchService.initialize() called
  ↓
EmbeddingService.initialize() called
  ↓
Check if model exists
  ↓
Model not found → downloadModel() called
  ↓
Download succeeds (100% progress shown in logs)
  ↓
Interpreter.fromFile() called
  ↓
❌ FAILS: "Bad state: failed precondition"
```

### 2. Full Stack Trace
```
[EmbeddingService] Model downloaded successfully to: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
[EmbeddingService] Loading model from: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
[EmbeddingService] Failed to initialize: Bad state: failed precondition
[VectorSearchService] Embedding model failed to initialize: Bad state: failed precondition
[VectorSearchService] Initialization complete (but isReady = false)
```

### 3. When User Tries to Index
```
User clicks "Index Now"
  ↓
VectorDatabaseService.vectorizeAllDocuments() called
  ↓
Calls EmbeddingService.generateEmbedding(text)
  ↓
Tries to run interpreter.run(input, output)
  ↓
❌ FAILS: "Bad state: failed precondition"
  ↓
Result: "0 documents indexed"
```

---

## Code Snippets

### Model Download (Works ✅)
```dart
// Location: lib/services/embedding_service.dart:44-82
Future<void> downloadModel({Function(double)? onProgress}) async {
  if (_isDownloading) {
    throw StateError('Model download already in progress');
  }

  _isDownloading = true;
  _downloadProgress = 0.0;

  try {
    final modelPath = await _getModelPath();
    final modelFile = File(modelPath);

    // Create directory if it doesn't exist
    await modelFile.parent.create(recursive: true);

    print('[EmbeddingService] Downloading model from $modelUrl...');

    final dio = Dio();
    await dio.download(
      modelUrl,
      modelPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _downloadProgress = received / total;
          onProgress?.call(_downloadProgress);
          print('[EmbeddingService] Download progress: ${(_downloadProgress * 100).toStringAsFixed(1)}%');
        }
      },
    );

    print('[EmbeddingService] Model downloaded successfully to: $modelPath');
  } catch (e) {
    print('[EmbeddingService] Model download failed: $e');
    rethrow;
  } finally {
    _isDownloading = false;
  }
}
```

### Model Loading (Fails ❌)
```dart
// Location: lib/services/embedding_service.dart:85-109
Future<void> initialize() async {
  if (_isInitialized) return;

  try {
    // Check if model exists, download if not
    if (!await isModelDownloaded()) {
      print('[EmbeddingService] Model not found, downloading...');
      await downloadModel();
    }

    final modelPath = await _getModelPath();
    print('[EmbeddingService] Loading model from: $modelPath');

    // Configure TFLite interpreter options
    final options = InterpreterOptions()
      ..threads = 4  // Use multiple threads for better performance
      ..useNnApiForAndroid = false;  // Disable NNAPI (can cause compatibility issues)

    // Load the TFLite model from file with options
    _interpreter = await Interpreter.fromFile(
      File(modelPath),
      options: options,
    );

    _isInitialized = true;
    print('[EmbeddingService] Model loaded successfully');
    print('[EmbeddingService] Input shape: ${_interpreter!.getInputTensor(0).shape}');
    print('[EmbeddingService] Output shape: ${_interpreter!.getOutputTensor(0).shape}');
  } catch (e) {
    print('[EmbeddingService] Failed to initialize: $e');
    rethrow;
  }
}
```

---

## Potential Causes

### 1. Model Format Issues
- **TFHub models might not be directly compatible** with tflite_flutter
- May need conversion or specific format
- TFHub "?lite-format=tflite" parameter might not return valid TFLite

### 2. TFLite Operations Not Supported
- Model uses operations not available in TFLite runtime
- Device may not support required ops
- Need to check model's required operations

### 3. Input/Output Tensor Configuration
- Model expects specific input format we're not providing
- Signature mismatch between model and loading code

### 4. Native Library Issues
- TFLite native library may be missing on device
- ARM64 vs ARM compatibility issue
- Android version compatibility

### 5. File Corruption
- Downloaded file may be corrupt despite showing 100%
- HTTP redirect or content-type issue

---

## Debugging Commands

### Check Device Architecture
```bash
adb shell getprop ro.product.cpu.abi
```

### Check Android Version
```bash
adb shell getprop ro.build.version.release
```

### Verify Model File Exists
```bash
adb shell "run-as com.ocrix.app ls -lh /data/data/com.ocrix.app/app_flutter/models/"
```

### Check File Permissions
```bash
adb shell "run-as com.ocrix.app stat /data/data/com.ocrix.app/app_flutter/models/mobilebert.tflite"
```

### Pull Model File for Inspection
```bash
adb shell "run-as com.ocrix.app cat /data/data/com.ocrix.app/app_flutter/models/mobilebert.tflite" > /tmp/model_from_device.tflite
```

### Check TFLite Model Info (requires tflite tools)
```bash
# Install tensorflow
pip install tensorflow

# Check model
python3 -c "
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path='/tmp/model_from_device.tflite')
print('Signatures:', interpreter.get_signature_list())
print('Input details:', interpreter.get_input_details())
print('Output details:', interpreter.get_output_details())
"
```

---

## Alternative Solutions to Try

### 1. Use Different TFLite Package
```yaml
# Try older version
tflite_flutter: ^0.9.0

# Or try alternative
tflite_flutter_helper: ^0.3.1
```

### 2. Use Pre-converted Model
- Download model manually
- Convert using TFLite converter
- Test locally before deploying

### 3. Use Remote Embedding API
```dart
// Use OpenAI, HuggingFace, or custom API
// Requires internet but avoids TFLite issues
```

### 4. Use Different Embedding Library
```yaml
# Try dart-based embedding (slower but works)
dependencies:
  sentence_transformers_dart: ^1.0.0
```

### 5. Manual Model Inspection
```bash
# Download model manually
wget -O /tmp/test_model.tflite "https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1?lite-format=tflite"

# Check if it's valid TFLite
file /tmp/test_model.tflite
hexdump -C /tmp/test_model.tflite | head -20
```

---

## Files to Check

1. **Embedding Service Implementation**:
   - `/home/nij/projects/OCRix/lib/services/embedding_service.dart`

2. **Vector Search Service**:
   - `/home/nij/projects/OCRix/lib/services/llm_search/vector_search_service.dart`

3. **Vector Database Service**:
   - `/home/nij/projects/OCRix/lib/services/vector_database_service.dart`

4. **Dependencies**:
   - `/home/nij/projects/OCRix/pubspec.yaml`

5. **Build Configuration**:
   - `/home/nij/projects/OCRix/android/app/build.gradle`

---

## Logs Collection

### Get Full App Logs
```bash
adb logcat -d > /tmp/ocrix_full_logs.txt
```

### Get Filtered Logs
```bash
adb logcat -d | grep -E "flutter.*(Embedding|TFLite|Interpreter)" > /tmp/ocrix_tflite_logs.txt
```

### Monitor Live Logs
```bash
adb logcat | grep -E "flutter|TFLite|libtflite"
```

---

## Next Steps for Local Debugging

1. **Verify Model File Integrity**:
   - Pull model file from device
   - Check if it's valid TFLite format
   - Try loading it with Python tensorflow locally

2. **Test Simple TFLite Model**:
   - Create minimal test app with simple TFLite model
   - If simple model works → issue is with these specific models
   - If simple model fails → issue is with TFLite on device

3. **Check TFLite Runtime**:
   - Verify native libraries are present
   - Check logcat for native crashes
   - Look for "libtensorflowlite_jni.so" errors

4. **Try Different Model Source**:
   - Download from different source (not TFHub)
   - Use known-working TFLite model
   - Convert model manually with proper settings

5. **Investigate Device Compatibility**:
   - Check if device supports required TFLite operations
   - Test on different device/emulator
   - Check Android version requirements

---

---

## Exception Details

### Stack Trace Location

**Class**: `EmbeddingService`
**File**: `/home/nij/projects/OCRix/lib/services/embedding_service.dart`
**Method**: `initialize()` (line 85-109)
**Exception Line**: 104-107

```dart
// THIS IS WHERE IT FAILS:
_interpreter = await Interpreter.fromFile(
  File(modelPath),
  options: options,
);
```

**Exception Type**: `StateError`
**Exception Message**: `"Bad state: failed precondition"`
**Caught At**: Line 113, catch block

### Call Stack

```
1. User Action: Opens AI Search Screen
   ↓
2. _AISearchScreenState.initState()
   File: lib/ui/screens/ai_search_screen.dart:50
   ↓
3. _initializeSearchService()
   File: lib/ui/screens/ai_search_screen.dart:54-82
   ↓
4. VectorSearchService.initialize()
   File: lib/services/llm_search/vector_search_service.dart:32-67
   ↓
5. EmbeddingService.initialize()
   File: lib/services/embedding_service.dart:85
   ↓
6. await downloadModel() [if needed]
   File: lib/services/embedding_service.dart:91-92
   ↓
7. Interpreter.fromFile() ← ❌ FAILS HERE
   File: lib/services/embedding_service.dart:104-107
```

### Related Method Calls

**When User Clicks "Index Now"**:
```
1. _startBackgroundVectorization()
   File: lib/ui/screens/ai_search_screen.dart:84-111
   ↓
2. VectorSearchService.vectorizeAllDocuments()
   File: lib/services/llm_search/vector_search_service.dart:81-89
   ↓
3. VectorDatabaseService.vectorizeAllDocuments()
   File: lib/services/vector_database_service.dart:~120+
   ↓
4. EmbeddingService.generateEmbedding(text)
   File: lib/services/embedding_service.dart:112-137
   ↓
5. _interpreter!.run(input, output) ← ❌ ALSO FAILS
   File: lib/services/embedding_service.dart:128
```

---

## Complete ADB Logs

### Successful Model Download
```
01-05 12:40:53.855 19145 19145 I flutter : [EmbeddingService] Download progress: 98.6%
01-05 12:40:53.856 19145 19145 I flutter : [EmbeddingService] Download progress: 98.8%
01-05 12:40:53.857 19145 19145 I flutter : [EmbeddingService] Download progress: 98.8%
01-05 12:40:53.863 19145 19145 I flutter : [EmbeddingService] Download progress: 98.9%
01-05 12:40:53.865 19145 19145 I flutter : [EmbeddingService] Download progress: 99.0%
01-05 12:40:53.869 19145 19145 I flutter : [EmbeddingService] Download progress: 99.0%
01-05 12:40:53.870 19145 19145 I flutter : [EmbeddingService] Download progress: 99.2%
01-05 12:40:53.871 19145 19145 I flutter : [EmbeddingService] Download progress: 99.3%
01-05 12:40:53.872 19145 19145 I flutter : [EmbeddingService] Download progress: 99.3%
01-05 12:40:53.877 19145 19145 I flutter : [EmbeddingService] Download progress: 99.4%
01-05 12:40:53.878 19145 19145 I flutter : [EmbeddingService] Download progress: 99.6%
01-05 12:40:53.878 19145 19145 I flutter : [EmbeddingService] Download progress: 99.6%
01-05 12:40:53.880 19145 19145 I flutter : [EmbeddingService] Download progress: 99.7%
01-05 12:40:53.881 19145 19145 I flutter : [EmbeddingService] Download progress: 99.8%
01-05 12:40:53.882 19145 19145 I flutter : [EmbeddingService] Download progress: 99.8%
01-05 12:40:53.882 19145 19145 I flutter : [EmbeddingService] Download progress: 100.0%
01-05 12:40:53.885 19145 19145 I flutter : [EmbeddingService] Download progress: 100.0%
01-05 12:40:53.887 19145 19145 I flutter : [EmbeddingService] Model downloaded successfully to: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
```

### Failed Model Loading
```
01-05 12:40:53.888 19145 19145 I flutter : [EmbeddingService] Loading model from: /data/user/0/com.ocrix.app/app_flutter/models/sentence_encoder.tflite
01-05 12:40:53.918 19145 19145 I flutter : [EmbeddingService] Failed to initialize: Bad state: failed precondition
01-05 12:40:53.918 19145 19145 I flutter : [VectorSearchService] Embedding model failed to initialize: Bad state: failed precondition
01-05 12:40:53.921 19145 19145 I flutter : [VectorSearchService] Initialization complete
```

### Failed Vectorization Attempt
```
01-05 12:50:24.394 21203 21203 I flutter : [VectorDatabaseService] Starting vectorization of 1 documents...
01-05 12:50:24.409 21203 21203 I flutter : [EmbeddingService] Failed to generate embedding: Bad state: failed precondition
01-05 12:50:24.409 21203 21203 I flutter : [VectorDatabaseService] Failed to vectorize document: Bad state: failed precondition
01-05 12:50:24.409 21203 21203 I flutter : [VectorDatabaseService] Vectorization complete: 0 vectorized, 1 skipped in 0s
```

---

## Useful ADB Commands

### Device Information
```bash
# Get device model
adb shell getprop ro.product.model

# Get Android version
adb shell getprop ro.build.version.release

# Get CPU architecture
adb shell getprop ro.product.cpu.abi

# Get all device properties
adb shell getprop > device_properties.txt

# Check available RAM
adb shell cat /proc/meminfo | grep MemTotal

# Check storage
adb shell df -h
```

### App-Specific Debugging
```bash
# Get app package info
adb shell dumpsys package com.ocrix.app > app_info.txt

# Check if app is debuggable
adb shell run-as com.ocrix.app echo "App is debuggable"

# List app files (requires debuggable app)
adb shell "run-as com.ocrix.app ls -lR /data/data/com.ocrix.app/" > app_files.txt

# Check model files
adb shell "run-as com.ocrix.app ls -lh /data/data/com.ocrix.app/app_flutter/models/"

# Get file details
adb shell "run-as com.ocrix.app stat /data/data/com.ocrix.app/app_flutter/models/mobilebert.tflite"

# Calculate file checksum
adb shell "run-as com.ocrix.app md5sum /data/data/com.ocrix.app/app_flutter/models/mobilebert.tflite"
```

### Database Debugging
```bash
# Access database (debuggable builds only)
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db"

# Check database version
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'PRAGMA user_version;'"

# List all tables
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db '.tables'"

# Check document_embeddings table schema
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db '.schema document_embeddings'"

# Count documents
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'SELECT COUNT(*) FROM documents;'"

# Count embeddings
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'SELECT COUNT(*) FROM document_embeddings;'"

# View document info
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'SELECT id, title, type, length(extracted_text) as text_len FROM documents;'"

# Export database for inspection
adb shell "run-as com.ocrix.app cat /data/data/com.ocrix.app/databases/privacy_documents.db" > ocrix_database.db

# Then open locally with sqlite3
sqlite3 ocrix_database.db
```

### Log Collection
```bash
# Capture all logs
adb logcat -d > full_logs.txt

# Filter Flutter logs only
adb logcat -d | grep "flutter" > flutter_logs.txt

# Filter embedding-related logs
adb logcat -d | grep -E "flutter.*(Embedding|Vector|TFLite|Interpreter)" > embedding_logs.txt

# Monitor logs in real-time
adb logcat | grep -E "flutter|TFLite|libtflite"

# Clear logs and start fresh
adb logcat -c

# Get logs with timestamps
adb logcat -v time > timestamped_logs.txt

# Get logs for specific process
adb logcat | grep "$(adb shell pidof com.ocrix.app)"
```

### Native Library Debugging
```bash
# List all .so files in app
adb shell "run-as com.ocrix.app find /data/data/com.ocrix.app -name '*.so' -type f"

# Check if TFLite library exists
adb shell "run-as com.ocrix.app ls -l /data/app/com.ocrix.app*/lib/arm64/"

# Search for tflite libraries
adb shell "find /data -name '*tflite*.so' 2>/dev/null"

# Check native crashes
adb logcat -d | grep -E "FATAL|DEBUG|libc|crash"
```

### Model File Extraction
```bash
# Pull model file for local inspection
adb shell "run-as com.ocrix.app cat /data/data/com.ocrix.app/app_flutter/models/mobilebert.tflite" > model_from_device.tflite

# Check file type
file model_from_device.tflite

# View hex dump (first 512 bytes)
hexdump -C model_from_device.tflite | head -32

# Check if it's a valid FlatBuffer (TFLite format)
strings model_from_device.tflite | head -20

# Compare with freshly downloaded model
wget -O model_fresh.tflite "https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1?lite-format=tflite"
diff <(md5sum model_from_device.tflite) <(md5sum model_fresh.tflite)
```

### Performance Monitoring
```bash
# Monitor CPU usage
adb shell top | grep com.ocrix.app

# Monitor memory usage
adb shell dumpsys meminfo com.ocrix.app

# Get app process info
adb shell ps -A | grep ocrix

# Monitor system properties
adb shell getprop | grep -E "ro.build|ro.product|dalvik"
```

### Network Debugging (for model download issues)
```bash
# Check network connectivity
adb shell ping -c 3 tfhub.dev

# Check DNS resolution
adb shell nslookup tfhub.dev

# Monitor network traffic
adb shell tcpdump -i any -w /sdcard/capture.pcap
adb pull /sdcard/capture.pcap
```

---

## Quick Debug Script

Save this as `debug_tflite.sh`:

```bash
#!/bin/bash

echo "=== OCRix TFLite Debugging ==="
echo ""

# Device info
echo "1. Device Information:"
echo "   Model: $(adb shell getprop ro.product.model)"
echo "   Android: $(adb shell getprop ro.build.version.release)"
echo "   CPU: $(adb shell getprop ro.product.cpu.abi)"
echo ""

# App status
echo "2. App Status:"
adb shell dumpsys package com.ocrix.app | grep -E "versionCode|versionName|debuggable" | head -3
echo ""

# Model files
echo "3. Model Files:"
adb shell "run-as com.ocrix.app ls -lh /data/data/com.ocrix.app/app_flutter/models/ 2>&1"
echo ""

# Database
echo "4. Database Info:"
echo "   Tables: $(adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db '.tables'" 2>&1)"
echo "   Documents: $(adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'SELECT COUNT(*) FROM documents;'" 2>&1)"
echo "   Embeddings: $(adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/privacy_documents.db 'SELECT COUNT(*) FROM document_embeddings;'" 2>&1)"
echo ""

# Recent logs
echo "5. Recent TFLite Logs:"
adb logcat -d | grep -E "flutter.*(Embedding|TFLite|failed)" | tail -10
echo ""

echo "=== End Debug Info ==="
```

Run with:
```bash
chmod +x debug_tflite.sh
./debug_tflite.sh > debug_output.txt
```

---

## Contact Information

**Project**: OCRix - Vector Search Implementation
**Issue Date**: January 5, 2026
**Device**: Pixel 10 Pro XL
**Environment**: Flutter Debug Build
**Flutter Version**: Check with `flutter --version`
**Dart Version**: Check with `dart --version`

**Key Finding**: Gemma 2B (1.5GB) loads perfectly, but small embedding models (5MB) fail with same TFLite error. This suggests the issue is model-specific, not device-related.

**Debug Document**: `/home/nij/projects/OCRix/docs/TFLITE_EMBEDDING_DEBUG.md`
