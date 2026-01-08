# LLM Enhancement Approaches for OCRix AI Search

## Current Limitation
Currently, the LLM only generates SQL queries. It cannot:
- Analyze the actual content of documents
- Aggregate data (e.g., sum prices, count items)
- Filter by semantic meaning (e.g., "food" vs "non-food" in receipts)
- Answer questions that require data analysis

**Example Query That Fails:**
- "How much did I spend on food last month?"
- Current behavior: Returns all receipts from last month
- Desired behavior: Analyze receipts, extract food items, sum prices

---

## Proposed Architectures

### **Approach 1: Two-Stage RAG (Retrieval-Augmented Generation)**
**Feasibility: ✅ HIGHLY FEASIBLE with offline LLMs**

#### How it Works:
```
Stage 1: Document Retrieval
├─ User Query: "How much did I spend on food last month?"
├─ LLM generates SQL: SELECT * FROM documents WHERE type='receipt' AND scan_date > ...
├─ Execute SQL → Get 25 receipts
└─ Extract text from each receipt

Stage 2: Data Analysis
├─ Create analysis prompt with all extracted text
├─ LLM analyzes content:
│   ├─ Identify food items (grocery store, restaurant, etc.)
│   ├─ Extract prices for food items
│   ├─ Filter out non-food items (cleaning supplies, etc.)
│   └─ Sum total
└─ Generate natural language answer: "You spent $347.82 on food last month"
```

#### Implementation:
```dart
class EnhancedLLMSearchService {
  Future<AnalysisResult> searchAndAnalyze(String query) async {
    // Stage 1: Retrieve documents
    final sqlQuery = await _gemmaService.generateSQL(query);
    final documents = await _readOnlyDB.executeReadOnlyQuery(sqlQuery);

    // Stage 2: Analyze content
    final analysisPrompt = _buildAnalysisPrompt(
      userQuery: query,
      documents: documents,
    );

    final analysis = await _gemmaService.analyzeDocuments(analysisPrompt);

    return AnalysisResult(
      answer: analysis.answer,
      confidence: analysis.confidence,
      sourceDocuments: documents,
      reasoning: analysis.reasoning,
    );
  }
}
```

#### Prompt Example:
```
You are a document analyst. Answer the user's question based ONLY on the provided documents.

User Question: "How much did I spend on food last month?"

Documents:
---
Document 1 (Receipt from Walmart, 2026-01-15):
Milk $3.99
Bread $2.49
Laundry Detergent $12.99
Apples $4.50
Total: $23.97
---
Document 2 (Receipt from McDonald's, 2026-01-20):
Big Mac Meal $8.99
Total: $8.99
---
[... more documents ...]

Task:
1. Identify which items are food
2. Extract prices for food items only
3. Sum the total
4. Provide a clear answer

Answer:
```

#### Pros:
- ✅ Works entirely offline with Gemma 2B
- ✅ Can handle complex analytical queries
- ✅ Provides transparent reasoning
- ✅ Source documents preserved for verification

#### Cons:
- ⚠️ Token limit constraints (Gemma 2B: 8K context)
  - Solution: Chunk documents if too many
- ⚠️ Slower (2 LLM calls instead of 1)
  - Acceptable for analytical queries
- ⚠️ May hallucinate if documents are unclear
  - Mitigation: Ask for confidence scores

---

### **Approach 2: Iterative Refinement (Multi-Agent)**
**Feasibility: ✅ FEASIBLE but more complex**

#### How it Works:
```
Agent 1: Query Planner
├─ Breaks down complex query into steps
├─ "How much spent on food?" →
│   ├─ Step 1: Get receipts from last month
│   ├─ Step 2: Filter for food items
│   └─ Step 3: Sum prices

Agent 2: SQL Generator
├─ Executes each step with SQL

Agent 3: Content Analyzer
├─ Analyzes text to filter/extract data

Agent 4: Aggregator
└─ Combines results and generates final answer
```

#### Pros:
- ✅ Can handle very complex multi-step queries
- ✅ More accurate for difficult questions

#### Cons:
- ❌ More complex to implement
- ❌ Slower (multiple LLM calls)
- ❌ Higher battery usage on mobile

---

### **Approach 3: Hybrid SQL + LLM Functions**
**Feasibility: ✅ VERY FEASIBLE**

#### How it Works:
Extend SQL with LLM-powered functions:

```sql
SELECT
  SUM(llm_extract_price(extracted_text, 'food')) as total_food_cost
FROM documents
WHERE type = 'receipt'
  AND scan_date > date('now', '-1 month')
  AND llm_is_food_related(extracted_text) = 1
```

#### Implementation:
```dart
// Custom SQL functions powered by LLM
void registerLLMFunctions(Database db) {
  // Extract prices for specific categories
  db.createFunction(
    functionName: 'llm_extract_price',
    function: (args) async {
      final text = args[0] as String;
      final category = args[1] as String;

      final price = await _gemmaService.extractPrice(text, category);
      return price;
    },
  );

  // Semantic filtering
  db.createFunction(
    functionName: 'llm_is_food_related',
    function: (args) async {
      final text = args[0] as String;
      final isFood = await _gemmaService.classifyContent(text, 'food');
      return isFood ? 1 : 0;
    },
  );
}
```

#### Pros:
- ✅ Keeps SQL as primary interface
- ✅ Familiar to developers
- ✅ Can be combined with existing SQL validators

#### Cons:
- ⚠️ SQLite doesn't natively support async functions
  - Workaround: Pre-compute LLM results and store in temp table
- ⚠️ Slow for large datasets (LLM call per row)
  - Solution: Batch processing

---

### **Approach 4: Vector Similarity + Semantic Filtering**
**Feasibility: ⚠️ FEASIBLE but requires additional models**

#### How it Works:
```
1. Pre-compute embeddings for all documents (offline)
2. User asks: "How much spent on food?"
3. Use semantic search to find food-related receipts
4. LLM extracts and sums prices
```

#### Requirements:
- Embedding model (e.g., sentence-transformers, ~100MB)
- Vector database or similarity function
- Gemma 2B for final analysis

#### Pros:
- ✅ Very accurate semantic matching
- ✅ Faster retrieval (vector search vs full table scan)

#### Cons:
- ❌ Requires additional model (~100MB+)
- ❌ More complex setup
- ❌ Need to recompute embeddings when documents change

---

## Recommended Implementation: **Approach 1 (Two-Stage RAG)**

### Why This is Best:
1. **Simple to implement** - Only requires extending existing GemmaModelService
2. **Works offline** - No external APIs needed
3. **Transparent** - User sees which documents were analyzed
4. **Flexible** - Can handle wide variety of analytical queries
5. **Mobile-friendly** - Reasonable performance on-device

### Token Budget Management:
Gemma 2B has 8K token context. Strategy:

```
Query + Schema: ~200 tokens
Example prompts: ~300 tokens
Documents (max 10 x 500 tokens each): ~5,000 tokens
Analysis instructions: ~200 tokens
Response buffer: ~2,000 tokens
Total: ~7,700 tokens ✅ Fits in 8K
```

If more than 10 documents:
- Option A: Summarize each document first (100 tokens each → 50 docs fit)
- Option B: Process in batches and aggregate results

---

## Example Queries This Would Enable:

### Financial Analysis:
- ❌ **Current:** "Find receipts from last month" → Returns 50 receipts
- ✅ **Enhanced:** "How much did I spend on groceries last month?" → "$234.67 on groceries"

### Semantic Search:
- ❌ **Current:** "Find documents about insurance" → Returns docs with word "insurance"
- ✅ **Enhanced:** "Find documents about my health coverage" → Understands "health coverage" = medical insurance

### Comparative Analysis:
- ❌ **Current:** Can't do this
- ✅ **Enhanced:** "Compare my electricity bills from summer vs winter" → "Summer avg: $87, Winter avg: $145 (+67%)"

### Trend Detection:
- ❌ **Current:** Can't do this
- ✅ **Enhanced:** "Am I spending more on food this year?" → "Yes, up 15% from last year ($X vs $Y)"

### Smart Categorization:
- ❌ **Current:** "Find tax documents" → Only finds docs tagged as "tax"
- ✅ **Enhanced:** "Find documents I need for taxes" → Finds W2s, 1099s, receipts, donations, etc.

---

## Performance Considerations:

### Gemma 2B on Mobile:
- **Inference speed:** ~10-20 tokens/sec on mid-range phone
- **Analysis of 10 documents:** ~30-60 seconds
- **Battery impact:** Moderate (similar to video playback)

### Optimization Strategies:
1. **Document pre-summarization** - Cache 100-token summaries of each document
2. **Smart chunking** - Only send relevant sections to LLM
3. **Progressive results** - Show "Analyzing document 3/10..." with partial results
4. **Caching** - Cache analysis results for common queries

---

## Security Considerations:

All approaches maintain security:
- ✅ Still read-only database access
- ✅ No data sent to cloud
- ✅ All processing on-device
- ✅ SQL validation still applies (Stage 1)
- ✅ LLM only sees retrieved documents (can't access full DB)

---

## Implementation Roadmap:

### Phase 1: Basic Two-Stage RAG (1-2 weeks)
1. Add `analyzeDocuments()` method to GemmaModelService
2. Create analysis prompt templates
3. Add AnalysisResult model
4. Update UI to show analysis results

### Phase 2: Smart Query Routing (1 week)
1. Detect if query needs analysis (e.g., "how much", "compare", "trend")
2. Route simple queries to SQL-only path
3. Route analytical queries to two-stage path

### Phase 3: Advanced Features (2-3 weeks)
1. Document summarization for large result sets
2. Progressive/streaming results
3. Confidence scoring
4. Multi-document reasoning

---

## Code Size Impact:
- Two-stage RAG: +200-300 lines
- No additional dependencies
- No APK size increase (uses existing Gemma model)

## Conclusion:
**Yes, it's absolutely feasible to make the LLM much more useful with offline models!** The two-stage RAG approach provides the best balance of functionality, performance, and implementation simplicity.
