# Vector Search Implementation Plan

## Overview
Replace SQL generation with semantic vector search using embeddings and RAG.

## Architecture

### 1. Embedding Model
- **Model**: all-MiniLM-L6-v2 (converted to TFLite)
- **Dimensions**: 384
- **Input**: Text (up to 512 tokens)
- **Output**: 384-dimensional embedding vector

### 2. Database Schema

```sql
CREATE TABLE document_embeddings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id TEXT NOT NULL UNIQUE,
    embedding BLOB NOT NULL,  -- 384 floats (1536 bytes)
    text_hash TEXT NOT NULL,  -- Hash to detect changes
    created_at INTEGER NOT NULL,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE INDEX idx_document_embeddings_doc_id ON document_embeddings(document_id);
```

### 3. Components

#### EmbeddingService
- Load TFLite model
- Generate embeddings from text (title + extracted_text)
- Normalize vectors

#### VectorDatabaseService
- Store embeddings in SQLite
- Perform cosine similarity search
- Background vectorization of existing documents

#### Updated LLMSearchService
- Convert query to embedding
- KNN search using cosine similarity
- Return top K results
- Optional: Re-rank with LLM for analytical queries

### 4. Search Flow

```
User Query
    ↓
[Generate Embedding]
    ↓
[Cosine Similarity Search]
    ↓
SELECT d.*,
       (e.embedding_dot_product / (e.embedding_norm * query_norm)) as similarity
FROM documents d
JOIN document_embeddings e ON d.id = e.document_id
WHERE similarity > 0.7
ORDER BY similarity DESC
LIMIT 10
```

### 5. Implementation Steps

1. **Add TFLite dependency** ✓
2. Download and bundle all-MiniLM-L6-v2 TFLite model
3. Create EmbeddingService
4. Create VectorDatabaseService
5. Add document_embeddings table migration
6. Implement background vectorization task
7. Update AI search to use vector search
8. Remove SQL generation code

### 6. Model Download
The TFLite model needs to be either:
- Bundled in assets/ (if small enough)
- Downloaded on first run (preferred for 25MB+ models)
- Stored in app documents directory

### 7. Performance Optimizations
- Batch embedding generation (10 docs at a time)
- Cache normalized vectors
- Use SIMD for cosine similarity if available
- Incremental vectorization (only new/changed docs)

### 8. Fallback Strategy
If vectorization isn't complete:
- Show warning: "AI search initializing... X/Y documents indexed"
- Allow search on vectorized subset
- Continue in background

## Benefits
- No SQL generation errors
- Semantic search (understands meaning, not just keywords)
- Works across languages
- Faster query processing
- More reliable results
