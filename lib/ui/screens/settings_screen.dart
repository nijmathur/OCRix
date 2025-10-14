import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/user_settings.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final encryptionState = ref.watch(encryptionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) =>
            _buildSettingsContent(context, ref, settings, encryptionState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(settingsNotifierProvider.notifier).refreshSettings();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
    EncryptionState encryptionState,
  ) {
    return ListView(
      children: [
        _buildStorageSection(context, ref, settings),
        _buildSecuritySection(context, ref, settings, encryptionState),
        _buildPrivacySection(context, ref, settings),
        _buildAppearanceSection(context, ref, settings),
        _buildScanningSection(context, ref, settings),
        _buildBackupSection(context, ref, settings),
        _buildAboutSection(context, ref),
      ],
    );
  }

  Widget _buildStorageSection(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      context,
      'Storage',
      Icons.storage,
      [
        SettingsTile(
          title: 'Metadata Storage',
          subtitle: _getStorageProviderName(settings.metadataStorageProvider),
          icon: Icons.storage,
          onTap: () => _showStorageProviderDialog(context, ref, 'metadata'),
        ),
        SettingsTile(
          title: 'File Storage',
          subtitle: _getStorageProviderName(settings.fileStorageProvider),
          icon: Icons.folder,
          onTap: () => _showStorageProviderDialog(context, ref, 'file'),
        ),
        SettingsTile(
          title: 'Auto Sync',
          subtitle: settings.autoSync ? 'Enabled' : 'Disabled',
          icon: Icons.sync,
          trailing: Switch(
            value: settings.autoSync,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).toggleAutoSync();
            },
          ),
        ),
        if (settings.autoSync)
          SettingsTile(
            title: 'Sync Interval',
            subtitle: '${settings.syncIntervalMinutes} minutes',
            icon: Icons.schedule,
            onTap: () => _showSyncIntervalDialog(
                context, ref, settings.syncIntervalMinutes),
          ),
      ],
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
    EncryptionState encryptionState,
  ) {
    return _buildSection(
      context,
      'Security',
      Icons.security,
      [
        SettingsTile(
          title: 'Encryption',
          subtitle: settings.encryptionEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.lock,
          trailing: Switch(
            value: settings.encryptionEnabled,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).toggleEncryption();
            },
          ),
        ),
        if (settings.encryptionEnabled) ...[
          SettingsTile(
            title: 'Biometric Authentication',
            subtitle: settings.biometricAuth ? 'Enabled' : 'Disabled',
            icon: Icons.fingerprint,
            trailing: Switch(
              value: settings.biometricAuth,
              onChanged: encryptionState.isBiometricAvailable
                  ? (value) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .toggleBiometricAuth();
                    }
                  : null,
            ),
          ),
          if (encryptionState.isInitialized)
            SettingsTile(
              title: 'Change Encryption Key',
              subtitle: 'Generate new encryption key',
              icon: Icons.key,
              onTap: () => _showChangeKeyDialog(context, ref),
            ),
        ],
        SettingsTile(
          title: 'Privacy Audit',
          subtitle: settings.privacyAuditEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.visibility,
          trailing: Switch(
            value: settings.privacyAuditEnabled,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).togglePrivacyAudit();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      context,
      'Privacy',
      Icons.privacy_tip,
      [
        SettingsTile(
          title: 'Data Collection',
          subtitle: 'Minimal data collection enabled',
          icon: Icons.data_usage,
          onTap: () => _showPrivacyInfoDialog(context),
        ),
        SettingsTile(
          title: 'Local Processing',
          subtitle: 'All processing done locally',
          icon: Icons.computer,
          onTap: () => _showLocalProcessingDialog(context),
        ),
        SettingsTile(
          title: 'Audit Logs',
          subtitle: 'View privacy audit logs',
          icon: Icons.assignment,
          onTap: () => _showAuditLogsDialog(context),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      context,
      'Appearance',
      Icons.palette,
      [
        SettingsTile(
          title: 'Theme',
          subtitle: _getThemeName(settings.theme),
          icon: Icons.brightness_6,
          onTap: () => _showThemeDialog(context, ref, settings.theme),
        ),
        SettingsTile(
          title: 'Language',
          subtitle: _getLanguageName(settings.language),
          icon: Icons.language,
          onTap: () => _showLanguageDialog(context, ref, settings.language),
        ),
        SettingsTile(
          title: 'Notifications',
          subtitle: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.notifications,
          trailing: Switch(
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).toggleNotifications();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanningSection(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      context,
      'Scanning',
      Icons.document_scanner,
      [
        SettingsTile(
          title: 'Default Document Type',
          subtitle: _getDocumentTypeName(settings.defaultDocumentType),
          icon: Icons.category,
          onTap: () => _showDocumentTypeDialog(
              context, ref, settings.defaultDocumentType),
        ),
        SettingsTile(
          title: 'Auto Categorization',
          subtitle: settings.autoCategorization ? 'Enabled' : 'Disabled',
          icon: Icons.auto_awesome,
          trailing: Switch(
            value: settings.autoCategorization,
            onChanged: (value) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .toggleAutoCategorization();
            },
          ),
        ),
        SettingsTile(
          title: 'OCR Confidence Threshold',
          subtitle: '${(settings.ocrConfidenceThreshold * 100).toInt()}%',
          icon: Icons.analytics,
          onTap: () => _showConfidenceThresholdDialog(
              context, ref, settings.ocrConfidenceThreshold),
        ),
      ],
    );
  }

  Widget _buildBackupSection(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    return _buildSection(
      context,
      'Backup & Export',
      Icons.backup,
      [
        SettingsTile(
          title: 'Backup',
          subtitle: settings.backupEnabled ? 'Enabled' : 'Disabled',
          icon: Icons.backup,
          trailing: Switch(
            value: settings.backupEnabled,
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).toggleBackup();
            },
          ),
        ),
        if (settings.backupEnabled && settings.lastBackupAt != null)
          SettingsTile(
            title: 'Last Backup',
            subtitle: _formatDate(settings.lastBackupAt!),
            icon: Icons.schedule,
          ),
        SettingsTile(
          title: 'Export Documents',
          subtitle: 'Export all documents',
          icon: Icons.download,
          onTap: () => _exportDocuments(context),
        ),
        SettingsTile(
          title: 'Import Documents',
          subtitle: 'Import from backup',
          icon: Icons.upload,
          onTap: () => _importDocuments(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    return _buildSection(
      context,
      'About',
      Icons.info,
      [
        SettingsTile(
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.info_outline,
        ),
        SettingsTile(
          title: 'Privacy Policy',
          subtitle: 'View privacy policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () => _showPrivacyPolicyDialog(context),
        ),
        SettingsTile(
          title: 'Terms of Service',
          subtitle: 'View terms of service',
          icon: Icons.description,
          onTap: () => _showTermsDialog(context),
        ),
        SettingsTile(
          title: 'Reset Settings',
          subtitle: 'Reset all settings to default',
          icon: Icons.restore,
          onTap: () => _showResetDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getStorageProviderName(String provider) {
    switch (provider) {
      case 'local':
        return 'Local Storage';
      case 'googleDrive':
        return 'Google Drive';
      case 'oneDrive':
        return 'OneDrive';
      case 'dropbox':
        return 'Dropbox';
      case 'box':
        return 'Box';
      default:
        return 'Unknown';
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return 'System';
    }
  }

  String _getLanguageName(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  String _getDocumentTypeName(String type) {
    switch (type) {
      case 'receipt':
        return 'Receipt';
      case 'contract':
        return 'Contract';
      case 'manual':
        return 'Manual';
      case 'invoice':
        return 'Invoice';
      case 'businessCard':
        return 'Business Card';
      case 'id':
        return 'ID Document';
      case 'passport':
        return 'Passport';
      case 'license':
        return 'License';
      case 'certificate':
        return 'Certificate';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Dialog methods
  void _showStorageProviderDialog(
      BuildContext context, WidgetRef ref, String type) {
    // Implementation for storage provider selection
  }

  void _showSyncIntervalDialog(
      BuildContext context, WidgetRef ref, int currentInterval) {
    // Implementation for sync interval selection
  }

  void _showChangeKeyDialog(BuildContext context, WidgetRef ref) {
    // Implementation for changing encryption key
  }

  void _showPrivacyInfoDialog(BuildContext context) {
    // Implementation for privacy information
  }

  void _showLocalProcessingDialog(BuildContext context) {
    // Implementation for local processing information
  }

  void _showAuditLogsDialog(BuildContext context) {
    // Implementation for audit logs
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, String currentTheme) {
    // Implementation for theme selection
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String currentLanguage) {
    // Implementation for language selection
  }

  void _showDocumentTypeDialog(
      BuildContext context, WidgetRef ref, String currentType) {
    // Implementation for document type selection
  }

  void _showConfidenceThresholdDialog(
      BuildContext context, WidgetRef ref, double currentThreshold) {
    // Implementation for confidence threshold selection
  }

  void _exportDocuments(BuildContext context) {
    // Implementation for document export
  }

  void _importDocuments(BuildContext context) {
    // Implementation for document import
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    // Implementation for privacy policy
  }

  void _showTermsDialog(BuildContext context) {
    // Implementation for terms of service
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to default? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
