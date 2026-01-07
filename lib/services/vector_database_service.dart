/// Vector Database Service
/// Manages semantic embeddings storage and vector similarity search
library;

import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'embedding_service.dart';

class VectorDatabaseService {
  final Database _db;
  final EmbeddingService _embeddingService;

  VectorDatabaseService(this._db, this._embeddingService);

  /// Initialize vector database tables
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_embeddings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT NOT NULL UNIQUE,
        embedding BLOB NOT NULL,
        text_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_document_embeddings_doc_id
      ON document_embeddings(document_id)
    ''');

    print('[VectorDatabaseService] Tables created successfully');
  }

  /// Store embedding for a document
  Future<void> storeEmbedding({
    required String documentId,
    required String text,
    required List<double> embedding,
  }) async {
    final textHash = _computeTextHash(text);
    final embeddingBytes = EmbeddingService.embeddingToBytes(embedding);

    await _db.insert('document_embeddings', {
      'document_id': documentId,
      'embedding': embeddingBytes,
      'text_hash': textHash,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print('[VectorDatabaseService] Stored embedding for document: $documentId');
  }

  /// Check if document has embedding and if text changed
  Future<bool> needsEmbedding(String documentId, String text) async {
    final result = await _db.query(
      'document_embeddings',
      columns: ['text_hash'],
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    if (result.isEmpty) {
      return true; // No embedding exists
    }

    final storedHash = result.first['text_hash'] as String;
    final currentHash = _computeTextHash(text);

    return storedHash != currentHash; // Needs update if text changed
  }

  /// Search for similar documents using cosine similarity
  Future<List<Map<String, dynamic>>> searchSimilar({
    required String queryText,
    int limit = 10,
    double minSimilarity = 0.1,
  }) async {
    // Generate query embedding
    final queryEmbedding = await _embeddingService.generateEmbedding(queryText);

    // Get all document embeddings
    final embeddings = await _db.query('document_embeddings');

    // Calculate similarities
    final similarities = <Map<String, dynamic>>[];

    for (final row in embeddings) {
      final documentId = row['document_id'] as String;
      final embeddingBytes = row['embedding'] as Uint8List;
      final embedding = EmbeddingService.bytesToEmbedding(embeddingBytes);

      final similarity = EmbeddingService.cosineSimilarity(
        queryEmbedding,
        embedding,
      );

      print('[VectorDatabaseService] Document $documentId similarity: $similarity (threshold: $minSimilarity)');

      if (similarity >= minSimilarity) {
        similarities.add({'document_id': documentId, 'similarity': similarity});
      }
    }

    // Sort by similarity (highest first)
    similarities.sort(
      (a, b) =>
          (b['similarity'] as double).compareTo(a['similarity'] as double),
    );

    // Limit results
    final topResults = similarities.take(limit).toList();

    // Join with documents table to get full document data
    final results = <Map<String, dynamic>>[];
    for (final sim in topResults) {
      final docs = await _db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [sim['document_id']],
      );

      if (docs.isNotEmpty) {
        final doc = Map<String, dynamic>.from(docs.first);
        doc['similarity'] = sim['similarity'];
        results.add(doc);
      }
    }

    print(
      '[VectorDatabaseService] Found ${results.length} similar documents for: "$queryText"',
    );
    return results;
  }

  /// Vectorize a single document
  Future<void> vectorizeDocument(Map<String, dynamic> document) async {
    final documentId = document['id'] as String;
    final title = document['title'] as String? ?? '';
    final extractedText = document['extracted_text'] as String? ?? '';

    // Combine title and text for embedding
    final text = '$title. $extractedText'.trim();

    if (text.isEmpty) {
      print('[VectorDatabaseService] Skipping empty document: $documentId');
      return;
    }

    // Check if we need to generate embedding
    if (!await needsEmbedding(documentId, text)) {
      print('[VectorDatabaseService] Document already vectorized: $documentId');
      return;
    }

    // Generate embedding
    final embedding = await _embeddingService.generateEmbedding(text);

    // Store embedding
    await storeEmbedding(
      documentId: documentId,
      text: text,
      embedding: embedding,
    );
  }

  /// Vectorize all documents in background
  Future<VectorizationProgress> vectorizeAllDocuments({
    Function(int current, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();

    // Get all documents
    final documents = await _db.query('documents');
    final total = documents.length;

    if (total == 0) {
      print('[VectorDatabaseService] No documents to vectorize');
      return VectorizationProgress(
        totalDocuments: 0,
        vectorizedDocuments: 0,
        skippedDocuments: 0,
        duration: Duration.zero,
      );
    }

    int vectorized = 0;
    int skipped = 0;

    print(
      '[VectorDatabaseService] Starting vectorization of $total documents...',
    );

    for (int i = 0; i < documents.length; i++) {
      final document = documents[i];

      try {
        final documentId = document['id'] as String;
        final title = document['title'] as String? ?? '';
        final extractedText = document['extracted_text'] as String? ?? '';
        final text = '$title. $extractedText'.trim();

        if (text.isEmpty) {
          skipped++;
          continue;
        }

        if (!await needsEmbedding(documentId, text)) {
          skipped++;
        } else {
          final embedding = await _embeddingService.generateEmbedding(text);
          await storeEmbedding(
            documentId: documentId,
            text: text,
            embedding: embedding,
          );
          vectorized++;
        }

        // Report progress
        onProgress?.call(i + 1, total);

        // Small delay to avoid overwhelming the system
        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('[VectorDatabaseService] Failed to vectorize document: $e');
        skipped++;
      }
    }

    final duration = DateTime.now().difference(startTime);
    print(
      '[VectorDatabaseService] Vectorization complete: $vectorized vectorized, $skipped skipped in ${duration.inSeconds}s',
    );

    return VectorizationProgress(
      totalDocuments: total,
      vectorizedDocuments: vectorized,
      skippedDocuments: skipped,
      duration: duration,
    );
  }

  /// Get vectorization statistics
  Future<Map<String, int>> getStatistics() async {
    final totalDocs =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM documents'),
        ) ??
        0;

    final vectorizedDocs =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM document_embeddings'),
        ) ??
        0;

    print('[VectorDatabaseService] Stats: total=$totalDocs, vectorized=$vectorizedDocs, pending=${totalDocs - vectorizedDocs}');

    return {
      'total_documents': totalDocs,
      'vectorized_documents': vectorizedDocs,
      'pending_documents': totalDocs - vectorizedDocs,
    };
  }

  /// Delete embedding for a document
  Future<void> deleteEmbedding(String documentId) async {
    await _db.delete(
      'document_embeddings',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Compute hash of text to detect changes
  String _computeTextHash(String text) {
    return md5.convert(utf8.encode(text)).toString();
  }
}

/// Progress information for vectorization
class VectorizationProgress {
  final int totalDocuments;
  final int vectorizedDocuments;
  final int skippedDocuments;
  final Duration duration;

  VectorizationProgress({
    required this.totalDocuments,
    required this.vectorizedDocuments,
    required this.skippedDocuments,
    required this.duration,
  });

  double get progress =>
      totalDocuments > 0 ? vectorizedDocuments / totalDocuments : 0.0;

  bool get isComplete =>
      vectorizedDocuments + skippedDocuments >= totalDocuments;

  @override
  String toString() {
    return 'VectorizationProgress(total: $totalDocuments, vectorized: $vectorizedDocuments, skipped: $skippedDocuments, duration: ${duration.inSeconds}s)';
  }
}
