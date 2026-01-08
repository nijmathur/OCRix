# Downloading and Installing Gemma 2B Model

The Gemma 2B model is required for LLM-powered document analysis (Stage 2 of RAG). This is a **1.5-2 GB file** that must be downloaded manually.

## Why Manual Download?

- **Size**: 1.5-2 GB is too large to bundle in the app or auto-download
- **User Choice**: Users may prefer to download over WiFi
- **Storage**: Requires significant device storage space

## Download Options

### Option 1: Download from Google AI (Recommended)

1. **Visit Kaggle Models** (requires free account):
   - URL: https://www.kaggle.com/models/google/gemma/tfLite/gemma2-2b-it
   - Sign in with Google account
   - Click "Download" button
   - Download: `gemma2-2b-it.task` (~1.5-2 GB)

2. **Alternative - AI Edge Torch Converter**:
   - If the direct .task file is not available, you can convert from TensorFlow Lite
   - See: https://ai.google.dev/edge/litert/inference

### Option 2: Build from Source (Advanced)

If you want to convert the model yourself:

```bash
# Install dependencies
pip install ai-edge-torch tensorflow

# Download and convert
# See: https://github.com/google/generative-ai-android/tree/main/models
```

## Installation Methods

### Method A: Install Before Building App (Recommended for Development)

1. **Download the model file** using Option 1 above

2. **Connect your Android device** via USB (enable USB debugging)

3. **Copy to device storage**:
   ```bash
   # Create directory on device
   adb shell mkdir -p /sdcard/Android/media/com.ocrix.app/models

   # Push model file
   adb push /path/to/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/

   # Verify
   adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/
   ```

4. **Build and install app**:
   ```bash
   flutter build apk --debug
   flutter install
   ```

5. **Verify in app**:
   - Open OCRix app
   - Go to AI Search screen
   - Should show "AI Ready" badge (no download needed)

### Method B: Install via App UI (User-Friendly)

This is how end-users will install the model:

1. **Download model** to your device (e.g., to Downloads folder)

2. **Open OCRix app**

3. **Go to AI Search screen**

4. **Click "Download Model" button** (or "Install from Storage" if model is detected)

5. **Select the gemma2-2b-it.task file** from your Downloads

6. **Wait for installation** (shows progress)
   - App copies file to persistent storage
   - Initializes the model
   - Shows "AI Ready" when complete

### Method C: Use Asset Bundle (For Distribution)

To bundle the model in the app (increases APK size by 1.5-2 GB):

1. **Create assets directory**:
   ```bash
   mkdir -p assets/models
   ```

2. **Copy model file**:
   ```bash
   cp /path/to/gemma2-2b-it.task assets/models/
   ```

3. **Update pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - assets/images/
       - assets/icons/
       - assets/models/gemma2-2b-it.task  # Add this
   ```

4. **Update GemmaModelService.dart** to load from assets:
   ```dart
   Future<void> _loadFromAssets() async {
     final ByteData data = await rootBundle.load('assets/models/gemma2-2b-it.task');
     final buffer = data.buffer.asUint8List();

     // Write to app storage
     final destPath = await _getModelStoragePath();
     final file = File(destPath);
     await file.writeAsBytes(buffer);
   }
   ```

   **⚠️ WARNING**: This will make your APK 1.5-2 GB larger!

## Current App Behavior

### Without Model:
1. AI Search screen shows: **"Model Not Available"**
2. Displays two buttons:
   - **"Download Model"** - Opens file picker
   - **"Install from Storage"** - Checks if model exists in persistent storage
3. Vector search still works (Stage 1)
4. LLM analysis disabled (Stage 2)

### With Model:
1. Shows: **"AI Ready ✓"** badge
2. Search input enabled
3. Both vector search and LLM analysis work
4. Can answer analytical queries

## Verifying Installation

### Via ADB:
```bash
# Check if model file exists
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task

# Should show something like:
# -rw-rw---- 1 u0_a123 media_rw 1.5G 2026-01-05 12:34 gemma2-2b-it.task
```

### Via App:
1. Open AI Search screen
2. Look for "AI Ready" badge (green)
3. Try an analytical query: "How much did I spend on food?"
4. Should see LLM analysis result

### Via Logs:
```bash
# Watch app logs
adb logcat | grep -i "gemma\|model"

# Successful initialization shows:
# [GemmaModelService] Model file found at: /sdcard/Android/media/...
# [GemmaModelService] Model initialized successfully
```

## Storage Requirements

| Component | Size | Location |
|-----------|------|----------|
| Embedding Model | ~1-2 MB | Auto-downloaded to app docs |
| Gemma LLM | ~1.5-2 GB | Manual installation required |
| Document Embeddings | ~1-2 KB per doc | SQLite database |
| **Total** | **~1.5-2 GB + (docs × 2KB)** | - |

## Troubleshooting

### "Model not found" Error:
```bash
# Check if directory exists
adb shell ls /sdcard/Android/media/com.ocrix.app/models/

# If not, create it
adb shell mkdir -p /sdcard/Android/media/com.ocrix.app/models/

# Re-push model
adb push gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/
```

### "Failed to initialize model" Error:
- Ensure file is complete (not corrupted during download)
- Check file size matches expected (~1.5-2 GB)
- Verify file permissions: `adb shell ls -l /sdcard/Android/media/com.ocrix.app/models/`

### "OUT_OF_RANGE" Error During Inference:
- This is handled by the code (reduces maxTokens automatically)
- Model reinitializes on error
- Should recover automatically

### Storage Space Issues:
```bash
# Check available space
adb shell df -h /sdcard

# Free up space if needed
adb shell rm -rf /sdcard/Download/unnecessary_files
```

## Performance Expectations

### First Load (After Installation):
- **Initialization**: ~5-10 seconds (loads model into memory)
- **First Query**: ~30-60 seconds (cold start)

### Subsequent Queries:
- **Simple Search**: < 1 second (vector search only)
- **Analytical Query**: ~30-60 seconds (LLM analysis)

### Memory Usage:
- **Model in RAM**: ~2-3 GB
- **Recommended Device**: 4+ GB RAM

## Quick Start Command Sequence

For development testing:

```bash
# 1. Download model (do this manually from Kaggle)
# URL: https://www.kaggle.com/models/google/gemma/tfLite/gemma2-2b-it

# 2. Push to device
adb shell mkdir -p /sdcard/Android/media/com.ocrix.app/models
adb push ~/Downloads/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/

# 3. Verify
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/

# 4. Build and install app
flutter build apk --debug
flutter install

# 5. Watch logs
adb logcat | grep -i "gemma\|vector\|search"
```

## Alternative: Embedding Model Only

If you don't need LLM analysis and just want semantic search:

1. Skip Gemma model download entirely
2. App will still work with vector search (Stage 1)
3. Queries like "find receipts" work semantically
4. Analytical queries like "how much did I spend" won't work

This gives you:
- ✅ Semantic search with embeddings
- ✅ Fast retrieval
- ✅ No LLM overhead
- ❌ No document analysis/aggregation
