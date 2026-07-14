/// Vendor encryption fallback behavior tests.
///
/// Verifies that DatabaseService.encryptData / decryptData:
/// 1. Return the original text when the encryption service throws
/// 2. Gracefully handle null vendor in decryptDocumentVendor
/// 3. Auto-initialize the encryption service when needed
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/document.dart';
import 'package:ocrix/services/database_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockEncryptionService mockEncryption;
  late DatabaseService service;

  setUp(() {
    mockEncryption = MockEncryptionService();
    service = DatabaseService();
    service.setEncryptionService(mockEncryption);
  });

  group('encryptData fallback', () {
    test('returns original text when encryptionService throws', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.encryptText(any()))
          .thenThrow(Exception('key not found'));

      final result = await service.encryptData('plain text');
      // Fallback: returns original text on failure
      expect(result, equals('plain text'));
    });

    test('returns encrypted text on success', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.encryptText('hello'))
          .thenAnswer((_) async => 'encrypted_hello');

      final result = await service.encryptData('hello');
      expect(result, equals('encrypted_hello'));
    });
  });

  group('decryptData fallback', () {
    test('returns original ciphertext when decryptionService throws', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.decryptText(any()))
          .thenThrow(Exception('decryption failed'));

      final result = await service.decryptData('some_ciphertext');
      // Fallback: returns original (encrypted) value on failure
      expect(result, equals('some_ciphertext'));
    });

    test('returns decrypted text on success', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.decryptText('ciphertext'))
          .thenAnswer((_) async => 'plain');

      final result = await service.decryptData('ciphertext');
      expect(result, equals('plain'));
    });
  });

  group('decryptDocumentVendor', () {
    test('returns document unchanged when vendor is null', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);

      final doc = Document.create(
        title: 'Invoice',
        extractedText: 'text',
        type: DocumentType.other,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      );
      // vendor is null by default
      expect(doc.vendor, isNull);

      final result = await service.decryptDocumentVendor(doc);
      // Should return the same document, no decryption attempted
      expect(result.vendor, isNull);
      expect(result.id, equals(doc.id));
      verifyNever(() => mockEncryption.decryptText(any()));
    });

    test('decrypts vendor when present', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.decryptText('enc_vendor'))
          .thenAnswer((_) async => 'Kroger');

      final doc = Document.create(
        title: 'Receipt',
        extractedText: 'text',
        type: DocumentType.other,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      ).copyWith(vendor: 'enc_vendor');

      final result = await service.decryptDocumentVendor(doc);
      expect(result.vendor, equals('Kroger'));
    });

    test('returns original vendor string when decryption fails', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.decryptText(any()))
          .thenThrow(Exception('bad ciphertext'));

      final doc = Document.create(
        title: 'Receipt',
        extractedText: 'text',
        type: DocumentType.other,
        confidenceScore: 0.9,
        detectedLanguage: 'en',
        deviceInfo: 'test',
      ).copyWith(vendor: 'malformed_cipher');

      final result = await service.decryptDocumentVendor(doc);
      // Fallback: original ciphertext returned
      expect(result.vendor, equals('malformed_cipher'));
    });
  });
}
