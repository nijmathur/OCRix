import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    required String metadataStorageProvider,
    required String fileStorageProvider,
    required bool autoSync,
    required int syncIntervalMinutes,
    required bool biometricAuth,
    required bool encryptionEnabled,
    required String defaultDocumentType,
    required List<String> defaultTags,
    required bool privacyAuditEnabled,
    required String language,
    required String theme,
    required bool notificationsEnabled,
    required bool autoCategorization,
    @Default(false) bool useLLMCategorization,
    required double ocrConfidenceThreshold,
    required bool backupEnabled,
    DateTime? lastBackupAt,
    required Map<String, dynamic> customSettings,
  }) = _UserSettings;

  factory UserSettings.defaultSettings() {
    return const UserSettings(
      metadataStorageProvider: 'local',
      fileStorageProvider: 'local',
      autoSync: false,
      syncIntervalMinutes: 60,
      biometricAuth: false,
      encryptionEnabled: true,
      defaultDocumentType: 'other',
      defaultTags: [],
      privacyAuditEnabled: true,
      language: 'en',
      theme: 'system',
      notificationsEnabled: true,
      autoCategorization: false,
      useLLMCategorization: false,
      ocrConfidenceThreshold: 0.7,
      backupEnabled: false,
      customSettings: {},
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
