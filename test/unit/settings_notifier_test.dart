import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocrix/models/user_settings.dart';
import 'package:ocrix/providers/document_provider.dart';
import 'package:ocrix/providers/settings_provider.dart';
import 'package:ocrix/providers/troubleshooting_logger_provider.dart';
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
    when(
      () => mockLogger.info(
        any(),
        tag: any(named: 'tag'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockLogger.error(
        any(),
        tag: any(named: 'tag'),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDb),
        troubleshootingLoggerProvider.overrideWithValue(mockLogger),
      ],
    );
  }

  group('SettingsNotifier', () {
    test('loads settings on creation', () async {
      when(
        () => mockDb.getUserSettings(),
      ).thenAnswer((_) async => testSettings);

      final container = createContainer();
      addTearDown(container.dispose);

      // Trigger the provider
      final future = container.read(settingsNotifierProvider.future);
      final result = await future;

      expect(result, testSettings);
      verify(() => mockDb.getUserSettings()).called(1);
    });

    test('handles load error', () async {
      when(() => mockDb.getUserSettings()).thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container
          .read(settingsNotifierProvider.future)
          .then((_) => false)
          .catchError((_) => true);

      expect(state, true);
    });

    test('updateSettings persists and updates state', () async {
      when(
        () => mockDb.getUserSettings(),
      ).thenAnswer((_) async => testSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(settingsNotifierProvider.future);

      final updated = testSettings.copyWith(theme: 'dark');
      await container
          .read(settingsNotifierProvider.notifier)
          .updateSettings(updated);

      final current = container.read(settingsNotifierProvider).value;
      expect(current?.theme, 'dark');
      verify(() => mockDb.updateUserSettings(updated)).called(1);
    });

    test('updateSettings handles error', () async {
      when(
        () => mockDb.getUserSettings(),
      ).thenAnswer((_) async => testSettings);
      when(
        () => mockDb.updateUserSettings(any()),
      ).thenThrow(Exception('Write failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(settingsNotifierProvider.future);

      await container
          .read(settingsNotifierProvider.notifier)
          .updateSettings(testSettings.copyWith(theme: 'dark'));

      expect(container.read(settingsNotifierProvider).hasError, true);
    });

    test('updateMetadataStorageProvider updates specific field', () async {
      when(
        () => mockDb.getUserSettings(),
      ).thenAnswer((_) async => testSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(settingsNotifierProvider.future);

      await container
          .read(settingsNotifierProvider.notifier)
          .updateMetadataStorageProvider('googleDrive');

      final captured =
          verify(() => mockDb.updateUserSettings(captureAny())).captured.single
              as UserSettings;
      expect(captured.metadataStorageProvider, 'googleDrive');
    });
  });
}
