/// Embedding Service using MobileBERT
/// Generates semantic embeddings for document text using BERT tokenization
library;

import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:dart_bert_tokenizer/dart_bert_tokenizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EmbeddingService {
  static const int embeddingDimension = 384;
  static const int maxSequenceLength = 384; // Match model input shape

  Interpreter? _interpreter;
  WordPieceTokenizer? _tokenizer;
  bool _isInitialized = false;

  /// Initialize the embedding model and tokenizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Copy vocab.txt from assets to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final vocabPath = path.join(appDir.path, 'vocab.txt');
      final vocabFile = File(vocabPath);

      if (!vocabFile.existsSync()) {
        final vocabData = await rootBundle.load('assets/models/vocab.txt');
        await vocabFile.writeAsBytes(vocabData.buffer.asUint8List());
        print('[EmbeddingService] Vocab file copied to $vocabPath');
      }

      // Load tokenizer from file
      _tokenizer = await WordPieceTokenizer.fromVocabFile(vocabPath);
      print('[EmbeddingService] Tokenizer loaded successfully');

      // Configure TFLite interpreter options
      final options = InterpreterOptions()
        ..threads = 4
        ..useNnApiForAndroid = false;

      // Load MobileBERT model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/1.tflite',
        options: options,
      );

      _isInitialized = true;
      print('[EmbeddingService] Model loaded successfully');

      // Print input/output tensor info for debugging
      final numInputs = _interpreter!.getInputTensors().length;
      final numOutputs = _interpreter!.getOutputTensors().length;
      print('[EmbeddingService] Number of inputs: $numInputs');
      print('[EmbeddingService] Number of outputs: $numOutputs');

      for (int i = 0; i < numInputs; i++) {
        final tensor = _interpreter!.getInputTensor(i);
        print('[EmbeddingService] Input $i shape: ${tensor.shape}, type: ${tensor.type}');
      }

      for (int i = 0; i < numOutputs; i++) {
        final tensor = _interpreter!.getOutputTensor(i);
        print('[EmbeddingService] Output $i shape: ${tensor.shape}, type: ${tensor.type}');
      }
    } catch (e) {
      print('[EmbeddingService] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Generate embedding for a single text
  Future<List<double>> generateEmbedding(String text) async {
    if (!_isInitialized || _interpreter == null || _tokenizer == null) {
      throw StateError(
        'EmbeddingService not initialized. Call initialize() first.',
      );
    }

    try {
      // Tokenize text
      final encoding = _tokenizer!.encode(text, addSpecialTokens: true);

      print('[EmbeddingService] Token IDs length: ${encoding.ids.length}');
      print('[EmbeddingService] First 10 tokens: ${encoding.tokens.take(10).toList()}');
      print('[EmbeddingService] First 10 IDs: ${encoding.ids.take(10).toList()}');

      // Prepare input tensors with padding/truncation to [1, 384]
      final inputIds = _padOrTruncate(encoding.ids, maxSequenceLength, 0);
      final attentionMask = _padOrTruncate(encoding.attentionMask, maxSequenceLength, 0);
      final tokenTypeIds = Int32List(maxSequenceLength); // All zeros for single sentence

      // Model expects 3 inputs, each [1, 384] int32
      final inputs = [
        [inputIds],      // Input 0: [1, 384] int32
        [attentionMask], // Input 1: [1, 384] int32
        [tokenTypeIds],  // Input 2: [1, 384] int32
      ];

      // Model has 2 outputs, both [1, 384] float32
      // Allocate exact buffer sizes based on research findings
      final outputs = {
        0: [List<double>.filled(embeddingDimension, 0.0)],
        1: [List<double>.filled(embeddingDimension, 0.0)],
      };

      print('[EmbeddingService] Running inference...');

      // Run inference
      _interpreter!.runForMultipleInputs(inputs, outputs);

      print('[EmbeddingService] Inference complete');

      // Extract embedding from first output (pooled embeddings)
      final embedding = (outputs[0]![0] as List).cast<double>();

      print('[EmbeddingService] Generated embedding dimension: ${embedding.length}');

      // Normalize and return
      return _normalizeVector(embedding);
    } catch (e, stackTrace) {
      print('[EmbeddingService] Failed to generate embedding: $e');
      print('[EmbeddingService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Pad or truncate a list to the specified length
  Int32List _padOrTruncate(dynamic list, int targetLength, int padValue) {
    final result = Int32List(targetLength);

    // Fill with padding value
    for (int i = 0; i < targetLength; i++) {
      result[i] = padValue;
    }

    // Copy actual values (truncate if needed)
    final copyLength = math.min(list.length, targetLength);
    if (list is Uint8List) {
      for (int i = 0; i < copyLength; i++) {
        result[i] = list[i];
      }
    } else if (list is Int32List) {
      for (int i = 0; i < copyLength; i++) {
        result[i] = list[i];
      }
    }

    return result;
  }

  /// Generate embeddings for multiple texts (batched)
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    if (!_isInitialized || _interpreter == null || _tokenizer == null) {
      throw StateError(
        'EmbeddingService not initialized. Call initialize() first.',
      );
    }

    try {
      final embeddings = <List<double>>[];
      for (final text in texts) {
        final embedding = await generateEmbedding(text);
        embeddings.add(embedding);
      }
      return embeddings;
    } catch (e) {
      print('[EmbeddingService] Failed to generate batch embeddings: $e');
      rethrow;
    }
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
    _interpreter?.close();
    _interpreter = null;
    _tokenizer = null;
    _isInitialized = false;
    print('[EmbeddingService] Disposed');
  }
}
