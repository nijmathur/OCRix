# AI/LLM Requirements: Natural Language Document Querying

## Overview

Enable users to query their OCR-processed documents using natural English, e.g.:
- "How much did I spend on Kroger last week?"
- "Show me all medical bills"
- "What was my total spending in December?"
- "Find receipts over $100"

**Key Constraints:**
- All processing must be done **locally** (no cloud APIs)
- Prioritize **fast processing** and responsive queries
- Support background processing or on-demand button trigger

---

## Approach Comparison

| Approach | Processing Speed | Query Speed | Accuracy | Storage | Complexity |
|----------|-----------------|-------------|----------|---------|------------|
| 1. Structured Extraction + SQL | Fast | Very Fast | High (for known formats) | Low | Medium |
| 2. Vector Embeddings + Semantic Search | Medium | Fast | High | Medium | Medium |
| 3. Local LLM with RAG | Slow | Medium | Very High | High | High |
| 4. Hybrid (Recommended) | Medium | Fast | Very High | Medium | Medium-High |

---

## Approach 1: Structured Entity Extraction + SQL

### Concept
Extract structured data (vendor, amount, date, category) from documents during OCR, store in SQLite, translate natural language to SQL queries.

### Architecture
```
Document → OCR → Entity Extraction → SQLite DB
                                          ↓
User Query → Intent Parser → SQL Generator → Results
```

### Implementation

#### Entity Extraction (During OCR Processing)
```dart
class DocumentEntity {
  String? vendor;        // "Kroger", "CVS Pharmacy"
  double? amount;        // 47.52
  DateTime? date;        // 2024-01-15
  String? category;      // "grocery", "medical", "utility"
  String? documentType;  // "receipt", "bill", "statement"
  Map<String, dynamic>? metadata;
}
```

#### Local NER Options
1. **flutter_nlp** - Basic NER, fast but limited
2. **On-device ML Kit** - Entity extraction (dates, money, addresses)
3. **Custom regex patterns** - For amounts, dates, common vendors
4. **Small ONNX model** - MobileBERT for NER (~25MB)

#### Query Translation
Use pattern matching + small local LLM to convert queries:
```
"How much did I spend on Kroger last month?"
→ SELECT SUM(amount) FROM documents
  WHERE vendor LIKE '%kroger%'
  AND date >= date('now', '-1 month')
```

### Pros
- Very fast query execution
- Minimal storage overhead
- Works offline with zero latency
- Predictable, debuggable

### Cons
- Requires good entity extraction
- Limited to predefined query patterns
- Can't handle complex semantic queries

---

## Approach 2: Vector Embeddings + Semantic Search

### Concept
Convert document text to vector embeddings, store in local vector database, use similarity search for queries.

### Architecture
```
Document → OCR → Text Chunking → Embedding Model → Vector DB
                                                        ↓
User Query → Embedding Model → Similarity Search → Results
```

### Implementation

#### Local Embedding Models
| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| all-MiniLM-L6-v2 (ONNX) | 23MB | Fast | Good |
| gte-small | 67MB | Medium | Better |
| nomic-embed-text | 137MB | Slower | Best |
| Gemma 2B (for embeddings) | 1.4GB | Slow | Excellent |

#### Flutter/Dart Options
1. **onnxruntime_flutter** - Run ONNX embedding models
2. **tflite_flutter** - TensorFlow Lite models
3. **Native C++ via FFI** - For maximum performance

#### Local Vector Databases
1. **SQLite with sqlite-vss** - Vector similarity extension
2. **Hive + custom HNSW** - Pure Dart solution
3. **ObjectBox** - Has vector search support
4. **LanceDB** - Embedded vector DB (via FFI)

#### Example Schema
```dart
class DocumentVector {
  int id;
  String documentId;
  String textChunk;
  List<double> embedding;  // 384-dim for MiniLM
  Map<String, dynamic> metadata;
}
```

### Pros
- Handles semantic similarity ("grocery store" matches "Kroger")
- No need for perfect entity extraction
- Flexible query understanding

### Cons
- Requires embedding model in app (~25-150MB)
- Vector storage grows with documents
- May return semantically similar but irrelevant results

---

## Approach 3: Local LLM with RAG

### Concept
Use a local LLM to understand queries and reason over document content using Retrieval-Augmented Generation.

### Architecture
```
Document → OCR → Chunking → Vector DB (for retrieval)
                                    ↓
User Query → Retriever → Context Builder → Local LLM → Answer
```

### Local LLM Options for Mobile

| Model | Size | RAM Required | Speed (tokens/s) | Quality |
|-------|------|--------------|------------------|---------|
| Gemma 2B | 1.4GB | 2GB | 15-30 | Good |
| Phi-3 Mini | 2.3GB | 3GB | 10-20 | Better |
| Llama 3.2 1B | 1.2GB | 2GB | 20-40 | Good |
| Qwen2 0.5B | 500MB | 1GB | 40-60 | Acceptable |
| SmolLM 135M | 135MB | 512MB | 80+ | Basic |

### Flutter Integration Options
1. **flutter_gemma** (already integrated) - MediaPipe Gemma
2. **llama_cpp_dart** - Llama.cpp bindings
3. **mlc_llm** - Optimized for mobile
4. **Custom ONNX runtime** - For smaller models

### RAG Pipeline
```dart
Future<String> queryDocuments(String userQuery) async {
  // 1. Retrieve relevant chunks
  final relevantDocs = await vectorDb.similaritySearch(
    query: userQuery,
    topK: 5,
  );

  // 2. Build context
  final context = relevantDocs.map((d) => d.text).join('\n\n');

  // 3. Generate answer with LLM
  final prompt = '''
Based on the following documents:
$context

Answer this question: $userQuery
''';

  return await localLlm.generate(prompt);
}
```

### Pros
- Handles complex, nuanced queries
- Can reason and compute (sums, comparisons)
- Natural conversational interface

### Cons
- Slow on mobile devices (2-10 seconds per query)
- High memory usage
- May hallucinate if context is insufficient

---

## Approach 4: Hybrid (Recommended)

### Concept
Combine structured extraction for known patterns with semantic search and optional LLM for complex queries.

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Document Processing                   │
├─────────────────────────────────────────────────────────┤
│  OCR Text → Entity Extractor → Structured DB (SQLite)   │
│          → Text Chunker → Embeddings → Vector DB        │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                      Query Router                        │
├─────────────────────────────────────────────────────────┤
│  User Query → Intent Classifier                         │
│       ├── Structured Query → SQL Executor → Fast Result │
│       ├── Semantic Search → Vector Search → Results     │
│       └── Complex Query → RAG + LLM → Detailed Answer   │
└─────────────────────────────────────────────────────────┘
```

### Query Classification
```dart
enum QueryType {
  structured,   // "total spending on Kroger" → SQL
  semantic,     // "show me medical bills" → Vector search
  complex,      // "which month had highest spending?" → LLM
}

QueryType classifyQuery(String query) {
  // Use small classifier or pattern matching
  if (hasAggregation(query)) return QueryType.structured;
  if (isSimpleSearch(query)) return QueryType.semantic;
  return QueryType.complex;
}
```

### Entity Extraction Pipeline

#### Phase 1: Rule-Based (Fast, During OCR)
```dart
class QuickEntityExtractor {
  // Regex patterns for common entities
  static final _amountPattern = RegExp(r'\$[\d,]+\.?\d{0,2}');
  static final _datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');

  // Vendor dictionary (expandable)
  static final _vendors = {
    'kroger': 'Kroger',
    'walmart': 'Walmart',
    'cvs': 'CVS Pharmacy',
    'walgreens': 'Walgreens',
    // ... loaded from local DB
  };

  DocumentEntity extract(String ocrText) {
    return DocumentEntity(
      amount: _extractAmount(ocrText),
      date: _extractDate(ocrText),
      vendor: _extractVendor(ocrText),
      category: _inferCategory(ocrText),
    );
  }
}
```

#### Phase 2: ML-Enhanced (Background Processing)
```dart
class MLEntityExtractor {
  late final OnnxModel _nerModel;  // MobileBERT NER

  Future<DocumentEntity> enhancedExtract(String text) async {
    final entities = await _nerModel.extractEntities(text);
    // Merge with rule-based results
    // Classify document type
    // Infer category with higher accuracy
  }
}
```

### Recommended Stack

| Component | Technology | Size | Notes |
|-----------|-----------|------|-------|
| Structured DB | SQLite + drift | Built-in | Fast queries |
| Vector DB | sqlite-vss or ObjectBox | ~2MB | Semantic search |
| Embeddings | all-MiniLM-L6-v2 (ONNX) | 23MB | Good balance |
| NER | ML Kit + Custom patterns | Built-in | Entity extraction |
| LLM (optional) | Gemma 2B via flutter_gemma | 1.4GB | Complex queries |
| Query Router | Small classifier or rules | <1MB | Route queries |

---

## Processing Pipeline

### Background Processing Service

```dart
class DocumentIndexingService {
  final _queue = StreamController<Document>();

  void startBackgroundProcessing() {
    _queue.stream
      .asyncMap(_processDocument)
      .listen((_) {});
  }

  Future<void> _processDocument(Document doc) async {
    // 1. Quick entity extraction (sync, fast)
    final entities = QuickEntityExtractor.extract(doc.ocrText);
    await _structuredDb.insert(doc.id, entities);

    // 2. Generate embeddings (async, slower)
    final chunks = TextChunker.chunk(doc.ocrText, maxLength: 512);
    for (final chunk in chunks) {
      final embedding = await _embeddingModel.embed(chunk);
      await _vectorDb.insert(doc.id, chunk, embedding);
    }

    // 3. ML entity enhancement (lowest priority)
    if (_mlExtractor.isAvailable) {
      final enhanced = await _mlExtractor.enhancedExtract(doc.ocrText);
      await _structuredDb.update(doc.id, enhanced);
    }
  }
}
```

### Trigger Options

1. **Automatic on OCR completion**
   ```dart
   ocrService.onDocumentProcessed.listen((doc) {
     indexingService.enqueue(doc);
   });
   ```

2. **Manual button trigger**
   ```dart
   ElevatedButton(
     onPressed: () => indexingService.processAll(),
     child: Text('Index All Documents'),
   )
   ```

3. **Scheduled background task**
   ```dart
   // Using workmanager
   Workmanager().registerPeriodicTask(
     'document-indexing',
     'indexDocuments',
     frequency: Duration(hours: 1),
   );
   ```

---

## Query Interface Design

### Natural Language Input
```dart
class SearchScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Natural language search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Ask anything... "How much did I spend on groceries?"',
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.mic),
              onPressed: _voiceSearch,
            ),
          ),
          onSubmitted: _executeQuery,
        ),

        // Quick filters
        Wrap(
          children: [
            FilterChip(label: Text('Receipts')),
            FilterChip(label: Text('Medical')),
            FilterChip(label: Text('This Month')),
          ],
        ),

        // Results
        Expanded(child: _buildResults()),
      ],
    );
  }
}
```

### Response Types
```dart
sealed class QueryResponse {
  // For aggregation queries
  factory QueryResponse.aggregate(String label, double value) = AggregateResponse;

  // For document list queries
  factory QueryResponse.documents(List<Document> docs) = DocumentListResponse;

  // For complex LLM answers
  factory QueryResponse.detailed(String answer, List<Document> sources) = DetailedResponse;
}
```

---

## Performance Optimization

### Embedding Caching
```dart
class EmbeddingCache {
  final _cache = LruCache<String, List<double>>(maxSize: 1000);

  Future<List<double>> getEmbedding(String text) async {
    final hash = text.hashCode.toString();
    return _cache.putIfAbsent(hash, () => _model.embed(text));
  }
}
```

### Incremental Indexing
```dart
class IncrementalIndexer {
  Future<void> indexNewOnly() async {
    final lastIndexed = await _prefs.getLastIndexedTimestamp();
    final newDocs = await _docRepo.getDocumentsAfter(lastIndexed);

    for (final doc in newDocs) {
      await _indexDocument(doc);
    }

    await _prefs.setLastIndexedTimestamp(DateTime.now());
  }
}
```

### Query Optimization
- Cache frequent queries and their results
- Pre-compute common aggregations (daily/weekly/monthly totals)
- Use SQLite indexes on date, vendor, amount, category
- Limit vector search to recent documents first

---

## Recommended Implementation Phases

### Phase 1: Structured Search (1-2 weeks)
- Implement entity extraction during OCR
- Create SQLite schema for structured data
- Build simple query parser for common patterns
- Support: "spending on X", "total in [month]", "documents from [vendor]"

### Phase 2: Semantic Search (1-2 weeks)
- Integrate ONNX embedding model
- Set up sqlite-vss or similar vector store
- Enable similarity search for document discovery
- Support: "medical bills", "car expenses", "tax documents"

### Phase 3: Smart Query Router (1 week)
- Implement query classification
- Route to appropriate search method
- Combine results from multiple sources

### Phase 4: LLM Enhancement (Optional, 2 weeks)
- Integrate Gemma 2B for complex queries
- Implement RAG pipeline
- Support: complex reasoning, comparisons, summaries

---

## Storage Estimates

| Component | Per Document | 10K Documents |
|-----------|-------------|---------------|
| Structured entities | ~500 bytes | ~5 MB |
| Text chunks (avg 3) | ~1.5 KB | ~15 MB |
| Embeddings (384-dim) | ~4.6 KB | ~46 MB |
| **Total** | ~6.6 KB | ~66 MB |

---

## Security Considerations

- All processing local - no data leaves device
- Embeddings are not reversible to original text
- SQLite database should be encrypted (sqlcipher)
- Clear indexed data when document is deleted

---

## Open Questions

1. Should indexing be opt-in per document or automatic?
2. What's the acceptable query latency? (<500ms for simple, <3s for complex?)
3. Should we support voice queries?
4. Multi-language support needed?
5. Should complex LLM queries require explicit user action (button) due to battery/performance?
