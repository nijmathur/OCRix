import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import '../core/interfaces/database_service_interface.dart';
import '../core/interfaces/encryption_service_interface.dart';
import 'document_provider.dart';
import 'troubleshooting_logger_provider.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
      final databaseService = ref.read(databaseServiceProvider);
      final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
      return SettingsNotifier(
        databaseService,
        troubleshootingLogger: troubleshootingLogger,
      );
    });

class SettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  final IDatabaseService _databaseService;
  final ITroubleshootingLogger? _troubleshootingLogger;

  SettingsNotifier(
    this._databaseService, {
    ITroubleshootingLogger? troubleshootingLogger,
  }) : _troubleshootingLogger = troubleshootingLogger,
       super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _databaseService.getUserSettings();
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      _troubleshootingLogger?.error(
        'Failed to load settings',
        tag: 'SettingsNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    try {
      state = const AsyncValue.loading();
      await _databaseService.updateUserSettings(newSettings);
      state = AsyncValue.data(newSettings);
      _troubleshootingLogger?.info(
        'Settings updated successfully',
        tag: 'SettingsNotifier',
      );
    } catch (e, stackTrace) {
      _troubleshootingLogger?.error(
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
      final updatedSettings = currentSettings.copyWith(
        metadataStorageProvider: provider,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateFileStorageProvider(String provider) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        fileStorageProvider: provider,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleAutoSync() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        autoSync: !currentSettings.autoSync,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateSyncInterval(int minutes) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        syncIntervalMinutes: minutes,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleBiometricAuth() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        biometricAuth: !currentSettings.biometricAuth,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleEncryption() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        encryptionEnabled: !currentSettings.encryptionEnabled,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateDefaultDocumentType(String type) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        defaultDocumentType: type,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateDefaultTags(List<String> tags) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(defaultTags: tags);
      await updateSettings(updatedSettings);
    }
  }

  Future<void> togglePrivacyAudit() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        privacyAuditEnabled: !currentSettings.privacyAuditEnabled,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateLanguage(String language) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(language: language);
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateTheme(String theme) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(theme: theme);
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleNotifications() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        notificationsEnabled: !currentSettings.notificationsEnabled,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleAutoCategorization() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        autoCategorization: !currentSettings.autoCategorization,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateOCRConfidenceThreshold(double threshold) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        ocrConfidenceThreshold: threshold,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> toggleBackup() async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final updatedSettings = currentSettings.copyWith(
        backupEnabled: !currentSettings.backupEnabled,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> updateCustomSetting(String key, dynamic value) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final customSettings = Map<String, dynamic>.from(
        currentSettings.customSettings,
      );
      customSettings[key] = value;

      final updatedSettings = currentSettings.copyWith(
        customSettings: customSettings,
      );
      await updateSettings(updatedSettings);
    }
  }

  Future<void> resetToDefaults() async {
    try {
      state = const AsyncValue.loading();
      final defaultSettings = UserSettings.defaultSettings();
      await _databaseService.updateUserSettings(defaultSettings);
      state = AsyncValue.data(defaultSettings);
      _troubleshootingLogger?.info(
        'Settings reset to defaults',
        tag: 'SettingsNotifier',
      );
    } catch (e, stackTrace) {
      _troubleshootingLogger?.error(
        'Failed to reset settings',
        tag: 'SettingsNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshSettings() async {
    await _loadSettings();
  }
}

class EncryptionNotifier extends StateNotifier<EncryptionState> {
  final IEncryptionService _encryptionService;
  final ITroubleshootingLogger? _troubleshootingLogger;

  EncryptionNotifier(
    this._encryptionService, {
    ITroubleshootingLogger? troubleshootingLogger,
  }) : _troubleshootingLogger = troubleshootingLogger,
       super(const EncryptionState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
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

      _troubleshootingLogger?.info(
        'Encryption service initialized',
        tag: 'EncryptionNotifier',
      );
    } catch (e) {
      _troubleshootingLogger?.error(
        'Failed to initialize encryption service',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> authenticateWithBiometrics() async {
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
      _troubleshootingLogger?.error(
        'Biometric authentication failed',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isAuthenticating: false, error: e.toString());
      return false;
    }
  }

  Future<void> changeEncryptionKey() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _encryptionService.changeEncryptionKey();

      final encryptionInfo = await _encryptionService.getEncryptionInfo();

      state = state.copyWith(isLoading: false, encryptionInfo: encryptionInfo);

      _troubleshootingLogger?.info(
        'Encryption key changed successfully',
        tag: 'EncryptionNotifier',
      );
    } catch (e) {
      _troubleshootingLogger?.error(
        'Failed to change encryption key',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clearEncryptionKey() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _encryptionService.clearEncryptionKey();

      state = state.copyWith(
        isLoading: false,
        isInitialized: false,
        isAuthenticated: false,
        encryptionInfo: {},
      );

      _troubleshootingLogger?.info(
        'Encryption key cleared',
        tag: 'EncryptionNotifier',
      );
    } catch (e) {
      _troubleshootingLogger?.error(
        'Failed to clear encryption key',
        tag: 'EncryptionNotifier',
        error: e,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> encryptText(String text) async {
    try {
      return await _encryptionService.encryptText(text);
    } catch (e) {
      _troubleshootingLogger?.error(
        'Failed to encrypt text',
        tag: 'EncryptionNotifier',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> decryptText(String encryptedText) async {
    try {
      return await _encryptionService.decryptText(encryptedText);
    } catch (e) {
      _troubleshootingLogger?.error(
        'Failed to decrypt text',
        tag: 'EncryptionNotifier',
        error: e,
      );
      rethrow;
    }
  }

  // Note: generateHash, generateFileHash, and verifyFileIntegrity are not in the interface
  // They are utility methods in EncryptionService. These would need to be added to the interface
  // or accessed through a different mechanism if needed.
}

final encryptionNotifierProvider =
    StateNotifierProvider<EncryptionNotifier, EncryptionState>((ref) {
      final encryptionService = ref.read(encryptionServiceProvider);
      final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
      return EncryptionNotifier(
        encryptionService,
        troubleshootingLogger: troubleshootingLogger,
      );
    });

class EncryptionState {
  final bool isLoading;
  final bool isInitialized;
  final bool isAuthenticating;
  final bool isAuthenticated;
  final bool isBiometricAvailable;
  final String? error;
  final Map<String, dynamic> encryptionInfo;

  const EncryptionState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isAuthenticating = false,
    this.isAuthenticated = false,
    this.isBiometricAvailable = false,
    this.error,
    this.encryptionInfo = const {},
  });

  const EncryptionState.initial() : this();

  EncryptionState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isAuthenticating,
    bool? isAuthenticated,
    bool? isBiometricAvailable,
    String? error,
    Map<String, dynamic>? encryptionInfo,
  }) {
    return EncryptionState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      error: error,
      encryptionInfo: encryptionInfo ?? this.encryptionInfo,
    );
  }
}
