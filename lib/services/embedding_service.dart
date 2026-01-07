/// Embedding Service using Character N-gram Hashing
/// Generates semantic embeddings for document text using locality-sensitive hashing
/// This approach is fast, works 100% offline, and avoids TFLite compatibility issues
library;

import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EmbeddingService {
  static const int embeddingDimension = 384;
  static const int _ngramSize = 3; // Character trigrams
  static const int _wordNgramSize = 2; // Word bigrams for better semantics

  bool _isInitialized = false;

  // Common English stopwords to filter out
  static const Set<String> _stopwords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'this',
    'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'what', 'which', 'who', 'whom', 'when', 'where', 'why', 'how', 'all',
    'each', 'every', 'both', 'few', 'more', 'most', 'other', 'some', 'such',
    'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
  };

  /// Initialize the embedding service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // No external model needed - using hash-based embeddings
    _isInitialized = true;
    print('[EmbeddingService] Initialized with hash-based embeddings (${embeddingDimension}D)');
  }

  /// Generate embedding for a single text using locality-sensitive hashing
  /// Combines character n-grams with word n-grams for semantic similarity
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return List.filled(embeddingDimension, 0.0);
    }

    // Normalize text
    final normalizedText = _normalizeText(text);

    // Generate embedding components
    final charNgramEmbedding = _generateCharNgramEmbedding(normalizedText);
    final wordNgramEmbedding = _generateWordNgramEmbedding(normalizedText);
    final keywordEmbedding = _generateKeywordEmbedding(normalizedText);

    // Combine embeddings with weights (word n-grams weighted higher for semantics)
    final combined = List<double>.filled(embeddingDimension, 0.0);
    for (int i = 0; i < embeddingDimension; i++) {
      combined[i] = charNgramEmbedding[i] * 0.2 +
          wordNgramEmbedding[i] * 0.5 +
          keywordEmbedding[i] * 0.3;
    }

    return _normalizeVector(combined);
  }

  /// Generate embeddings for multiple texts (batched)
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    final embeddings = <List<double>>[];
    for (final text in texts) {
      final embedding = await generateEmbedding(text);
      embeddings.add(embedding);
    }
    return embeddings;
  }

  /// Normalize text for embedding generation
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse whitespace
        .trim();
  }

  /// Generate embedding from character n-grams using hash projection
  List<double> _generateCharNgramEmbedding(String text) {
    final embedding = List<double>.filled(embeddingDimension, 0.0);

    if (text.length < _ngramSize) {
      return embedding;
    }

    // Generate character n-grams and hash them to embedding dimensions
    for (int i = 0; i <= text.length - _ngramSize; i++) {
      final ngram = text.substring(i, i + _ngramSize);
      final hash = _hashString(ngram);

      // Use multiple hash projections for better distribution
      for (int j = 0; j < 3; j++) {
        final idx = ((hash >> (j * 8)) & 0xFF) % embeddingDimension;
        final sign = ((hash >> (j * 2)) & 1) == 0 ? 1.0 : -1.0;
        embedding[idx] += sign;
      }
    }

    return embedding;
  }

  /// Generate embedding from word n-grams (better semantic capture)
  List<double> _generateWordNgramEmbedding(String text) {
    final embedding = List<double>.filled(embeddingDimension, 0.0);

    // Split into words and filter stopwords
    final words = text
        .split(' ')
        .where((w) => w.length > 1 && !_stopwords.contains(w))
        .toList();

    if (words.isEmpty) {
      return embedding;
    }

    // Single words (unigrams)
    for (final word in words) {
      final hash = _hashString(word);
      for (int j = 0; j < 4; j++) {
        final idx = ((hash >> (j * 8)) & 0xFF) % embeddingDimension;
        final sign = ((hash >> (j * 2)) & 1) == 0 ? 1.0 : -1.0;
        embedding[idx] += sign * 2.0; // Weight unigrams
      }
    }

    // Word bigrams for phrase-level semantics
    if (words.length >= _wordNgramSize) {
      for (int i = 0; i <= words.length - _wordNgramSize; i++) {
        final bigram = words.sublist(i, i + _wordNgramSize).join('_');
        final hash = _hashString(bigram);
        for (int j = 0; j < 3; j++) {
          final idx = ((hash >> (j * 8)) & 0xFF) % embeddingDimension;
          final sign = ((hash >> (j * 2)) & 1) == 0 ? 1.0 : -1.0;
          embedding[idx] += sign * 1.5; // Weight bigrams
        }
      }
    }

    return embedding;
  }

  /// Generate embedding from domain-specific keywords
  /// Boosts similarity for documents with matching categories
  List<double> _generateKeywordEmbedding(String text) {
    final embedding = List<double>.filled(embeddingDimension, 0.0);

    // Category keywords with semantic groupings
    const categoryKeywords = {
      'grocery': ['grocery', 'food', 'produce', 'dairy', 'meat', 'vegetables', 'fruits', 'kroger', 'walmart', 'safeway', 'publix', 'aldi', 'trader'],
      'restaurant': ['restaurant', 'cafe', 'diner', 'pizza', 'burger', 'coffee', 'starbucks', 'mcdonalds', 'chipotle', 'subway', 'tip', 'server'],
      'medical': ['medical', 'doctor', 'hospital', 'pharmacy', 'prescription', 'health', 'clinic', 'patient', 'diagnosis', 'treatment', 'cvs', 'walgreens'],
      'utilities': ['utility', 'electric', 'gas', 'water', 'internet', 'phone', 'cable', 'bill', 'payment', 'due', 'account'],
      'fuel': ['gas', 'fuel', 'gasoline', 'diesel', 'gallon', 'pump', 'shell', 'exxon', 'chevron', 'bp', 'speedway'],
      'retail': ['store', 'shop', 'purchase', 'item', 'product', 'sale', 'discount', 'return', 'receipt', 'target', 'amazon', 'costco'],
      'financial': ['bank', 'credit', 'debit', 'transaction', 'deposit', 'withdrawal', 'balance', 'statement', 'account', 'interest', 'fee'],
    };

    // Check for category keywords and add to embedding
    for (final entry in categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;

      int matchCount = 0;
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        // Hash category to consistent positions
        final hash = _hashString(category);
        final weight = math.min(matchCount * 0.5, 3.0);

        for (int j = 0; j < 5; j++) {
          final idx = ((hash >> (j * 6)) & 0x3F) % embeddingDimension;
          embedding[idx] += weight;
        }
      }
    }

    // Also detect amounts and dates for receipt-like documents
    final hasAmount = RegExp(r'\$\d+\.?\d*').hasMatch(text);
    final hasDate = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text);

    if (hasAmount) {
      final hash = _hashString('HAS_AMOUNT');
      embedding[hash % embeddingDimension] += 2.0;
    }

    if (hasDate) {
      final hash = _hashString('HAS_DATE');
      embedding[hash % embeddingDimension] += 2.0;
    }

    return embedding;
  }

  /// Hash a string to an integer using MD5
  int _hashString(String s) {
    final bytes = utf8.encode(s);
    final digest = md5.convert(bytes);
    // Use first 4 bytes as int
    return digest.bytes[0] |
        (digest.bytes[1] << 8) |
        (digest.bytes[2] << 16) |
        (digest.bytes[3] << 24);
  }

  /// Normalize vector to unit length (for cosine similarity)
  List<double> _normalizeVector(List<double> vector) {
    double magnitude = 0.0;
    for (final value in vector) {
      magnitude += value * value;
    }
    magnitude = math.sqrt(magnitude);

    if (magnitude == 0) {
      return vector; // Avoid division by zero
    }

    return vector.map((v) => v / magnitude).toList();
  }

  /// Calculate cosine similarity between two vectors
  static double cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) {
      throw ArgumentError('Vectors must have same dimension');
    }

    double dotProduct = 0.0;
    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
    }

    // Vectors are already normalized, so cosine similarity = dot product
    return dotProduct;
  }

  /// Convert embedding to bytes for storage
  static Uint8List embeddingToBytes(List<double> embedding) {
    final buffer = ByteData(embedding.length * 4); // 4 bytes per float32
    for (int i = 0; i < embedding.length; i++) {
      buffer.setFloat32(i * 4, embedding[i], Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  /// Convert bytes back to embedding
  static List<double> bytesToEmbedding(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    final embedding = <double>[];
    for (int i = 0; i < bytes.length; i += 4) {
      embedding.add(buffer.getFloat32(i, Endian.little));
    }
    return embedding;
  }

  /// Check if model is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    print('[EmbeddingService] Disposed');
  }
}
