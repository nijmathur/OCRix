/// Encryption service auto-init order tests.
///
/// Verifies that DatabaseService.encryptData / decryptData call
/// encryptionService.initialize() when the service is not yet initialized.
/// This ensures encryption is always ready before use, regardless of call order.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  group('encryptData auto-initializes', () {
    test('calls initialize() when service is not yet initialized', () async {
      when(() => mockEncryption.isInitialized).thenReturn(false);
      when(() => mockEncryption.initialize()).thenAnswer((_) async {});
      when(() => mockEncryption.encryptText(any()))
          .thenAnswer((_) async => 'encrypted');

      await service.encryptData('hello');

      verify(() => mockEncryption.initialize()).called(1);
    });

    test('skips initialize() when service is already initialized', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.encryptText(any()))
          .thenAnswer((_) async => 'encrypted');

      await service.encryptData('hello');

      verifyNever(() => mockEncryption.initialize());
    });

    test('still returns result after auto-init', () async {
      when(() => mockEncryption.isInitialized).thenReturn(false);
      when(() => mockEncryption.initialize()).thenAnswer((_) async {});
      when(() => mockEncryption.encryptText('secret'))
          .thenAnswer((_) async => 'enc_secret');

      final result = await service.encryptData('secret');
      expect(result, equals('enc_secret'));
    });
  });

  group('decryptData auto-initializes', () {
    test('calls initialize() when service is not yet initialized', () async {
      when(() => mockEncryption.isInitialized).thenReturn(false);
      when(() => mockEncryption.initialize()).thenAnswer((_) async {});
      when(() => mockEncryption.decryptText(any()))
          .thenAnswer((_) async => 'plain');

      await service.decryptData('ciphertext');

      verify(() => mockEncryption.initialize()).called(1);
    });

    test('skips initialize() when service is already initialized', () async {
      when(() => mockEncryption.isInitialized).thenReturn(true);
      when(() => mockEncryption.decryptText(any()))
          .thenAnswer((_) async => 'plain');

      await service.decryptData('ciphertext');

      verifyNever(() => mockEncryption.initialize());
    });

    test('multiple calls only initialize once per call', () async {
      // Each call checks isInitialized; if always false, initializes every time
      // This verifies the check happens per-call
      when(() => mockEncryption.isInitialized).thenReturn(false);
      when(() => mockEncryption.initialize()).thenAnswer((_) async {});
      when(() => mockEncryption.encryptText(any()))
          .thenAnswer((_) async => 'enc');

      await service.encryptData('a');
      await service.encryptData('b');

      // initialize() called once per encryptData call when not initialized
      verify(() => mockEncryption.initialize()).called(2);
    });
  });
}
