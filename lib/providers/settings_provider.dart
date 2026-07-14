import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/interfaces/encryption_service_interface.dart';
import '../models/user_settings.dart';
import 'document_provider.dart';
import 'troubleshooting_logger_provider.dart';

part 'settings_provider.freezed.dart';

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final databaseService = ref.read(databaseServiceProvider);
    return databaseService.getUserSettings();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    final databaseService = ref.read(databaseServiceProvider);
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = const AsyncValue.loading();
      await databaseService.updateUserSettings(newSettings);
      state = AsyncValue.data(newSettings);
      await logger.info('Settings updated successfully', tag: 'SettingsNotifier');
    } catch (e, stackTrace) {
      await logger.error(
        'Failed to update settings',
        tag: 'SettingsNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateMetadataStorageProvider(String provider) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(metadataStorageProvider: provider),
      );
    }
  }

  Future<void> updateFileStorageProvider(String provider) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(fileStorageProvider: provider),
      );
    }
  }

  Future<void> toggleAutoSync() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(autoSync: !currentSettings.autoSync),
      );
    }
  }

  Future<void> updateSyncInterval(int minutes) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(syncIntervalMinutes: minutes),
      );
    }
  }

  Future<void> toggleBiometricAuth() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(biometricAuth: !currentSettings.biometricAuth),
      );
    }
  }

  Future<void> toggleEncryption() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(
          encryptionEnabled: !currentSettings.encryptionEnabled,
        ),
      );
    }
  }

  Future<void> updateDefaultDocumentType(String type) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(currentSettings.copyWith(defaultDocumentType: type));
    }
  }

  Future<void> updateDefaultTags(List<String> tags) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(currentSettings.copyWith(defaultTags: tags));
    }
  }

  Future<void> togglePrivacyAudit() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(
          privacyAuditEnabled: !currentSettings.privacyAuditEnabled,
        ),
      );
    }
  }

  Future<void> updateLanguage(String language) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(currentSettings.copyWith(language: language));
    }
  }

  Future<void> updateTheme(String theme) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(currentSettings.copyWith(theme: theme));
    }
  }

  Future<void> toggleNotifications() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(
          notificationsEnabled: !currentSettings.notificationsEnabled,
        ),
      );
    }
  }

  Future<void> toggleAutoCategorization() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(
          autoCategorization: !currentSettings.autoCategorization,
        ),
      );
    }
  }

  Future<void> toggleLLMCategorization() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(
          useLLMCategorization: !currentSettings.useLLMCategorization,
        ),
      );
    }
  }

  Future<void> updateOCRConfidenceThreshold(double threshold) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(ocrConfidenceThreshold: threshold),
      );
    }
  }

  Future<void> toggleBackup() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      await updateSettings(
        currentSettings.copyWith(backupEnabled: !currentSettings.backupEnabled),
      );
    }
  }

  Future<void> updateCustomSetting(String key, dynamic value) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final customSettings = Map<String, dynamic>.from(
        currentSettings.customSettings,
      );
      customSettings[key] = value;
      await updateSettings(
        currentSettings.copyWith(customSettings: customSettings),
      );
    }
  }

  Future<void> resetToDefaults() async {
    final databaseService = ref.read(databaseServiceProvider);
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = const AsyncValue.loading();
      final defaultSettings = UserSettings.defaultSettings();
      await databaseService.updateUserSettings(defaultSettings);
      state = AsyncValue.data(defaultSettings);
      await logger.info('Settings reset to defaults', tag: 'SettingsNotifier');
    } catch (e, stackTrace) {
      await logger.error(
        'Failed to reset settings',
        tag: 'SettingsNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshSettings() async {
    ref.invalidateSelf();
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);

class EncryptionNotifier extends Notifier<EncryptionState> {
  @override
  EncryptionState build() {
    Future.microtask(_initialize);
    return const EncryptionState();
  }

  IEncryptionService get _encryptionService =>
      ref.read(encryptionServiceProvider);

  Future<void> _initialize() async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = state.copyWith(isLoading: true);
      await _encryptionService.initialize();

      final isBiometricAvailable = await _encryptionService
          .isBiometricAvailable();
      final encryptionInfo = await _encryptionService.getEncryptionInfo();

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isBiometricAvailable: isBiometricAvailable,
        encryptionInfo: encryptionInfo,
      );

      await logger.info('Encryption service initialized', tag: 'EncryptionNotifier');
    } catch (e) {
      await logger.error(
        'Failed to initialize encryption service',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = state.copyWith(isAuthenticating: true, error: null);

      final isAuthenticated = await _encryptionService
          .authenticateWithBiometrics();

      state = state.copyWith(
        isAuthenticating: false,
        isAuthenticated: isAuthenticated,
        error: isAuthenticated ? null : 'Authentication failed',
      );

      return isAuthenticated;
    } catch (e) {
      await logger.error(
        'Biometric authentication failed',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isAuthenticating: false, error: e.toString());
      return false;
    }
  }

  Future<void> changeEncryptionKey() async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _encryptionService.changeEncryptionKey();

      final encryptionInfo = await _encryptionService.getEncryptionInfo();

      state = state.copyWith(isLoading: false, encryptionInfo: encryptionInfo);

      await logger.info(
        'Encryption key changed successfully',
        tag: 'EncryptionNotifier',
      );
    } catch (e) {
      await logger.error(
        'Failed to change encryption key',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clearEncryptionKey() async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _encryptionService.clearEncryptionKey();

      state = state.copyWith(
        isLoading: false,
        isInitialized: false,
        isAuthenticated: false,
        encryptionInfo: {},
      );

      await logger.info('Encryption key cleared', tag: 'EncryptionNotifier');
    } catch (e) {
      await logger.error(
        'Failed to clear encryption key',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> encryptText(String text) async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      return await _encryptionService.encryptText(text);
    } catch (e) {
      await logger.error(
        'Failed to encrypt text',
        tag: 'EncryptionNotifier',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> decryptText(String encryptedText) async {
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      return await _encryptionService.decryptText(encryptedText);
    } catch (e) {
      await logger.error(
        'Failed to decrypt text',
        tag: 'EncryptionNotifier',
        error: e,
      );
      rethrow;
    }
  }
}

final encryptionNotifierProvider =
    NotifierProvider<EncryptionNotifier, EncryptionState>(
      EncryptionNotifier.new,
    );

@freezed
abstract class EncryptionState with _$EncryptionState {
  const factory EncryptionState({
    @Default(false) bool isLoading,
    @Default(false) bool isInitialized,
    @Default(false) bool isAuthenticating,
    @Default(false) bool isAuthenticated,
    @Default(false) bool isBiometricAvailable,
    String? error,
    @Default({}) Map<String, dynamic> encryptionInfo,
  }) = _EncryptionState;
}
