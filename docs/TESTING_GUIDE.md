# Testing Guide: Vector Search Implementation

## Device Status ✅

- **Device**: Pixel 10 Pro XL (59040DLCQ00008)
- **Storage**: 31 GB available
- **App**: OCRix Debug build installed
- **Models Directory**: Created at `/sdcard/Android/media/com.ocrix.app/models/`

## Current Setup

### ✅ What's Installed:
- OCRix app (debug build)
- Models directory created

### ⚠️ What's Missing:
- Gemma LLM model (1.5-2 GB) - **optional for now**
- Embedding model - **will auto-download on first search**
- Sample documents - **need to add some to test**

## Testing Steps

### Phase 1: Test Without LLM (Recommended First)

This tests vector similarity search without the Gemma model.

#### Step 1: Add Sample Documents

1. **Open OCRix app** on device
2. **Add some test documents**:
   - Use camera to scan receipts/documents, OR
   - Import existing images/PDFs

#### Step 2: Navigate to AI Search

1. **Tap** the menu or navigate to **AI Search** screen
2. **Observe** the initial state:
   - Should show "Model Not Available" (Gemma not installed)
   - Or show a download button

#### Step 3: Try a Simple Search

1. **Enter query**: "receipts" or "documents"
2. **Tap Search**
3. **Observe**:
   - Embedding model should auto-download (~1-2 MB, 10-30 seconds)
   - Progress bar should show download
   - After download, search should execute
   - Results should show semantically similar documents

#### Step 4: Verify Vector Search Works

Try these queries (no LLM needed):
- "find receipts"
- "food purchases"
- "bills"
- "invoices"

**Expected**: Documents matching semantic meaning (not just exact keywords)

### Phase 2: Add LLM for Analytical Queries (Optional)

Only do this if you want to test analytical queries like "how much did I spend?"

#### Step 1: Download Gemma Model

**On your computer**:
```bash
# Visit Kaggle and download
# URL: https://www.kaggle.com/models/google/gemma/tfLite/gemma2-2b-it
# File: gemma2-2b-it.task (~1.5-2 GB)

# Then push to device:
adb push ~/Downloads/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/
```

**Or via app UI**:
1. Download model to device (e.g., Downloads folder)
2. In app, tap "Download Model" or "Install from Storage"
3. Select the .task file
4. Wait for installation

#### Step 2: Restart App

1. Close and reopen OCRix
2. Go to AI Search screen
3. Should now show "AI Ready ✓"

#### Step 3: Try Analytical Queries

These require LLM analysis:
- "How much did I spend on food?"
- "Compare receipts from January vs December"
- "Total amount spent this month"
- "When was my last grocery purchase?"

**Expected**:
- Natural language answer with confidence score
- Retrieved documents shown
- Processing time ~30-60 seconds

## Monitoring & Debugging

### Watch Logs in Real-Time

```bash
# Terminal 1: Monitor all app logs
adb logcat | grep -i "flutter"

# Terminal 2: Monitor vector search specifically
adb logcat | grep -E "Embedding|Vector|Gemma|LLM"

# Terminal 3: Monitor database
adb logcat | grep -i "database"
```

### Check Model Status

```bash
# Check if embedding model downloaded
adb shell "ls -lh /data/data/com.ocrix.app/app_flutter/models/ 2>&1"

# Check if Gemma model exists
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/

# Expected output:
# -rw-rw---- 1 u0_a651 media_rw 1.5G 2026-01-05 12:00 gemma2-2b-it.task
```

### Check Database

```bash
# Access app database (debug builds only)
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/ocrix.db"

# Once in sqlite3 shell:
# Check documents count
SELECT COUNT(*) FROM documents;

# Check embeddings count
SELECT COUNT(*) FROM document_embeddings;

# View a sample embedding
SELECT document_id, length(embedding), text_hash FROM document_embeddings LIMIT 1;

# Exit
.exit
```

## Expected Behavior

### First Search (No Models Yet):

1. User enters query and taps Search
2. App shows "Downloading embedding model..."
3. Progress bar: 0% → 100% (~10-30 seconds)
4. Model loads and initializes
5. Query embedding generated
6. ⚠️ If no documents exist: "No documents found"
7. ✅ If documents exist: Results with similarity scores

### With Documents, Without LLM:

```
Query: "food receipts"
↓
[Stage 1: Vector Search]
├─ Generate query embedding (512-dim)
├─ Compute similarity with all documents
├─ Return top 10 matches (similarity > 0.5)
└─ Results:
    1. "Walmart Receipt" (similarity: 0.87)
    2. "McDonald's Order" (similarity: 0.82)
    3. "Grocery Store Receipt" (similarity: 0.79)
```

### With Documents + LLM:

```
Query: "How much did I spend on food?"
↓
[Stage 1: Vector Search]
├─ Find food-related receipts
└─ Retrieved: 10 receipts

↓
[Stage 2: LLM Analysis]
├─ Send receipts + query to Gemma 2B
├─ LLM extracts prices from food items
├─ Sums total
└─ Answer: "You spent $347.82 on food" (confidence: 0.92)
```

## Troubleshooting

### Issue: "Embedding model download failed"

**Solution**:
```bash
# Check network connectivity
adb shell ping -c 3 storage.googleapis.com

# Clear app data and retry
adb shell pm clear com.ocrix.app

# Reinstall
flutter install
```

### Issue: "No documents to search"

**Solution**:
1. Add documents via camera or import
2. Wait for OCR processing
3. Check database:
   ```bash
   adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/ocrix.db 'SELECT COUNT(*) FROM documents;'"
   ```

### Issue: "Gemma model not found"

**Solution**:
```bash
# Verify model exists
adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task

# If missing, re-push
adb push ~/Downloads/gemma2-2b-it.task /sdcard/Android/media/com.ocrix.app/models/

# Restart app
adb shell am force-stop com.ocrix.app
adb shell am start -n com.ocrix.app/.MainActivity
```

### Issue: "Search is slow"

**Normal behavior**:
- First search: 10-30s (model download + initialization)
- Vector search: < 1s
- LLM analysis: 30-60s (for 10 documents)

**If slower**:
- Check device RAM (need 4+ GB for LLM)
- Check CPU usage
- Try fewer documents

### Issue: "Embeddings not generating"

**Check**:
```bash
# View app logs
adb logcat | grep -i "embedding"

# Expected logs:
# [EmbeddingService] Model downloaded successfully
# [VectorDatabaseService] Stored embedding for document: xxx
# [VectorSearchService] Initialization complete
```

**Fix**:
```bash
# Clear embeddings and regenerate
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/ocrix.db 'DELETE FROM document_embeddings;'"

# Restart app (will regenerate on next search)
```

## Performance Benchmarks

### Expected Timings:

| Operation | First Time | Subsequent |
|-----------|-----------|------------|
| Embedding model download | 10-30s | N/A |
| Gemma model load | 5-10s | 2-3s |
| Generate query embedding | 50-100ms | 50-100ms |
| Search 100 documents | 100-200ms | 100-200ms |
| Search 1000 documents | 500ms-1s | 500ms-1s |
| LLM analysis (10 docs) | 30-60s | 30-60s |
| Vectorize 1 document | 50-100ms | 50-100ms |
| Vectorize 100 documents | 5-10s | 5-10s |

### Device Requirements:

| Feature | Minimum | Recommended |
|---------|---------|-------------|
| RAM | 2 GB | 4+ GB |
| Storage | 500 MB | 2+ GB |
| Android | 7.0+ | 10.0+ |
| CPU | Quad-core | Octa-core |

## Quick Test Script

Save this as `test_vector_search.sh`:

```bash
#!/bin/bash

echo "🧪 Testing OCRix Vector Search Implementation"
echo "=============================================="

# 1. Check device connection
echo -n "1. Checking device connection... "
if adb devices | grep -q "device$"; then
    echo "✅"
else
    echo "❌ No device connected"
    exit 1
fi

# 2. Check app installed
echo -n "2. Checking app installation... "
if adb shell pm list packages | grep -q "com.ocrix.app"; then
    echo "✅"
else
    echo "❌ App not installed"
    exit 1
fi

# 3. Check models directory
echo -n "3. Checking models directory... "
if adb shell ls /sdcard/Android/media/com.ocrix.app/models/ 2>/dev/null; then
    echo "✅"
else
    echo "⚠️  Creating directory..."
    adb shell mkdir -p /sdcard/Android/media/com.ocrix.app/models/
fi

# 4. Check Gemma model
echo -n "4. Checking Gemma model... "
if adb shell ls /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task 2>/dev/null | grep -q "task"; then
    SIZE=$(adb shell ls -lh /sdcard/Android/media/com.ocrix.app/models/gemma2-2b-it.task | awk '{print $5}')
    echo "✅ ($SIZE)"
else
    echo "⚠️  Not found (LLM analysis will not work)"
fi

# 5. Launch app
echo -n "5. Launching app... "
adb shell am start -n com.ocrix.app/.MainActivity > /dev/null 2>&1
echo "✅"

# 6. Monitor logs
echo ""
echo "📊 Monitoring app logs (Ctrl+C to stop):"
echo "=========================================="
adb logcat | grep -i "flutter" | grep -E "embedding|vector|gemma|search"
```

Run with:
```bash
chmod +x test_vector_search.sh
./test_vector_search.sh
```

## Success Criteria

### ✅ Phase 1 (Vector Search Only):
- [ ] App launches without crashes
- [ ] AI Search screen accessible
- [ ] Embedding model auto-downloads
- [ ] Can search documents
- [ ] Results show similarity scores
- [ ] Semantic matching works (finds "invoice" when searching "receipt")

### ✅ Phase 2 (With LLM):
- [ ] Gemma model loads successfully
- [ ] "AI Ready" badge shows
- [ ] Analytical queries work
- [ ] LLM returns natural language answers
- [ ] Confidence scores provided
- [ ] No crashes during analysis

## Next Steps After Testing

1. **If vector search works**: Consider it ready for use!
2. **If LLM analysis works**: Full implementation is complete
3. **Performance issues**: Adjust similarity threshold, batch size
4. **Add more documents**: Test with realistic dataset (100+ docs)
5. **Production build**: Build release APK with signing

## Report Issues

If you encounter issues, collect:

```bash
# Full logs
adb logcat > ocrix_logs.txt

# App state
adb shell dumpsys package com.ocrix.app > app_state.txt

# Database info
adb shell "run-as com.ocrix.app sqlite3 /data/data/com.ocrix.app/databases/ocrix.db '.schema'" > db_schema.txt
```

Include in issue report:
- Device model and Android version
- Steps to reproduce
- Expected vs actual behavior
- Logs (ocrix_logs.txt)
