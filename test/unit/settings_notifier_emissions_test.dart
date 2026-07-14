/// SettingsNotifier state emission tests.
///
/// Verifies that SettingsNotifier:
/// 1. Loads initial settings from the database on build
/// 2. Transitions through loading → data on successful updateSettings
/// 3. Emits AsyncValue.error on failed updateSettings
/// 4. Convenience methods (toggleBiometricAuth, updateTheme, etc.) delegate to updateSettings
library;

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

  final defaultSettings = UserSettings.defaultSettings();

  setUpAll(() {
    registerFallbackValue(UserSettings.defaultSettings());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockLogger = MockTroubleshootingLogger();

    when(
      () => mockLogger.info(any(), tag: any(named: 'tag'), metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => mockLogger.warning(any(),
          tag: any(named: 'tag'),
          error: any(named: 'error'),
          metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => mockLogger.error(any(),
          tag: any(named: 'tag'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDb),
        troubleshootingLoggerProvider.overrideWithValue(mockLogger),
      ],
    );
  }

  group('Initial load', () {
    test('loads settings from DB on build', () async {
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => defaultSettings);

      final container = makeContainer();
      addTearDown(container.dispose);

      final settings = await container.read(settingsNotifierProvider.future);
      expect(settings, equals(defaultSettings));
      verify(() => mockDb.getUserSettings()).called(1);
    });

    test('emits AsyncError when DB throws on load', () async {
      when(() => mockDb.getUserSettings()).thenThrow(Exception('DB down'));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container
          .read(settingsNotifierProvider.future)
          .then((_) => null)
          .catchError((_) => null);

      expect(container.read(settingsNotifierProvider).hasError, isTrue);
    });
  });

  group('updateSettings', () {
    test('emits loading then data on success', () async {
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => defaultSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      final emitted = <AsyncValue<UserSettings>>[];
      container.listen<AsyncValue<UserSettings>>(
        settingsNotifierProvider,
        (_, next) => emitted.add(next),
      );

      final newSettings = defaultSettings.copyWith(language: 'es');
      await container.read(settingsNotifierProvider.notifier).updateSettings(newSettings);

      expect(emitted.any((s) => s.isLoading), isTrue);
      expect(emitted.last.value, equals(newSettings));
    });

    test('emits error on DB failure', () async {
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => defaultSettings);
      when(() => mockDb.updateUserSettings(any()))
          .thenThrow(Exception('write failed'));

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      await container
          .read(settingsNotifierProvider.notifier)
          .updateSettings(defaultSettings.copyWith(language: 'fr'));

      expect(container.read(settingsNotifierProvider).hasError, isTrue);
    });

    test('state reflects updated value after success', () async {
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => defaultSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      final updated = defaultSettings.copyWith(theme: 'dark');
      await container.read(settingsNotifierProvider.notifier).updateSettings(updated);

      final state = container.read(settingsNotifierProvider).value!;
      expect(state.theme, equals('dark'));
    });
  });

  group('Convenience mutation methods', () {
    test('toggleBiometricAuth flips the flag', () async {
      final settings = defaultSettings.copyWith(biometricAuth: false);
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => settings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      await container.read(settingsNotifierProvider.notifier).toggleBiometricAuth();

      expect(container.read(settingsNotifierProvider).value?.biometricAuth, isTrue);
    });

    test('updateTheme changes the theme setting', () async {
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => defaultSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      await container.read(settingsNotifierProvider.notifier).updateTheme('light');

      expect(container.read(settingsNotifierProvider).value?.theme, equals('light'));
    });

    test('resetToDefaults calls DB and emits default settings', () async {
      final customSettings = defaultSettings.copyWith(language: 'de', theme: 'dark');
      when(() => mockDb.getUserSettings()).thenAnswer((_) async => customSettings);
      when(() => mockDb.updateUserSettings(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      await container.read(settingsNotifierProvider.notifier).resetToDefaults();

      final state = container.read(settingsNotifierProvider).value!;
      expect(state.language, equals('en'));
      expect(state.theme, equals('system'));
    });
  });
}
