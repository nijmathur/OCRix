import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/user_settings.dart';
import 'package:ocrix/providers/settings_provider.dart';
import '../helpers/mocks.dart';

void main() {
  late MockDatabaseService mockDb;
  late MockTroubleshootingLogger mockLogger;

  final testSettings = UserSettings.defaultSettings();

  setUpAll(() {
    registerFallbackValue(UserSettings.defaultSettings());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockLogger = MockTroubleshootingLogger();

    // Stub logger methods so they don't return null
    when(() => mockLogger.info(any(), tag: any(named: 'tag'), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => mockLogger.error(any(), tag: any(named: 'tag'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
  });

  group('SettingsNotifier', () {
    test('loads settings on creation', () async {
      when(() => mockDb.getUserSettings())
          .thenAnswer((_) async => testSettings);

      final notifier = SettingsNotifier(
        mockDb,
        troubleshootingLogger: mockLogger,
      );

      // Initially loading
      expect(notifier.state, const AsyncValue<UserSettings>.loading());

      // Wait for settings to load
      await Future.delayed(Duration.zero);

      expect(notifier.state.value, testSettings);
      verify(() => mockDb.getUserSettings()).called(1);
    });

    test('handles load error', () async {
      when(() => mockDb.getUserSettings())
          .thenThrow(Exception('DB error'));

      final notifier = SettingsNotifier(
        mockDb,
        troubleshootingLogger: mockLogger,
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.hasError, true);
    });

    test('updateSettings persists and updates state', () async {
      when(() => mockDb.getUserSettings())
          .thenAnswer((_) async => testSettings);
      when(() => mockDb.updateUserSettings(any()))
          .thenAnswer((_) async {});

      final notifier = SettingsNotifier(
        mockDb,
        troubleshootingLogger: mockLogger,
      );
      await Future.delayed(Duration.zero);

      final updated = testSettings.copyWith(theme: 'dark');
      await notifier.updateSettings(updated);

      expect(notifier.state.value?.theme, 'dark');
      verify(() => mockDb.updateUserSettings(updated)).called(1);
    });

    test('updateSettings handles error', () async {
      when(() => mockDb.getUserSettings())
          .thenAnswer((_) async => testSettings);
      when(() => mockDb.updateUserSettings(any()))
          .thenThrow(Exception('Write failed'));

      final notifier = SettingsNotifier(
        mockDb,
        troubleshootingLogger: mockLogger,
      );
      await Future.delayed(Duration.zero);

      await notifier.updateSettings(testSettings.copyWith(theme: 'dark'));

      expect(notifier.state.hasError, true);
    });

    test('updateMetadataStorageProvider updates specific field', () async {
      when(() => mockDb.getUserSettings())
          .thenAnswer((_) async => testSettings);
      when(() => mockDb.updateUserSettings(any()))
          .thenAnswer((_) async {});

      final notifier = SettingsNotifier(
        mockDb,
        troubleshootingLogger: mockLogger,
      );
      await Future.delayed(Duration.zero);

      await notifier.updateMetadataStorageProvider('googleDrive');

      final captured = verify(
        () => mockDb.updateUserSettings(captureAny()),
      ).captured.single as UserSettings;
      expect(captured.metadataStorageProvider, 'googleDrive');
    });
  });
}
