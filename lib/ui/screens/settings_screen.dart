import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_auth_provider.dart';
import '../../providers/database_export_provider.dart';
import '../../models/user_settings.dart';
import '../widgets/settings_tile.dart';
import '../widgets/password_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final encryptionState = ref.watch(encryptionNotifierProvider);
    final biometricState = ref.watch(biometricAuthNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsContent(
            context, ref, settings, encryptionState, biometricState),
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
    BiometricAuthState biometricState,
  ) {
    return ListView(
      children: [
        _buildStorageSection(context, ref, settings),
        _buildSecuritySection(
            context, ref, settings, encryptionState, biometricState),
        _buildPrivacySection(context, ref, settings),
        _buildAppearanceSection(context, ref, settings),
        _buildScanningSection(context, ref, settings),
        _buildBackupSection(context, ref, settings),
        _buildAccountSection(context, ref),
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
    BiometricAuthState biometricState,
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
          if (encryptionState.isInitialized)
            SettingsTile(
              title: 'Change Encryption Key',
              subtitle: 'Generate new encryption key',
              icon: Icons.key,
              onTap: () => _showChangeKeyDialog(context, ref),
            ),
        ],
        // Biometric Sign-In for App
        if (biometricState.isAvailable) ...[
          const Divider(),
          SettingsTile(
            title: 'Biometric Sign-In',
            subtitle: biometricState.isEnabled
                ? 'Use biometrics to sign in to app'
                : 'Enable biometric sign-in for faster access',
            icon: Icons.fingerprint,
            trailing: Switch(
              value: biometricState.isEnabled,
              onChanged: biometricState.isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        // Log attempt to enable
                        final notifier =
                            ref.read(biometricAuthNotifierProvider.notifier);
                        final service = ref.read(biometricAuthServiceProvider);
                        service.logInfo(
                            'User attempting to enable biometric sign-in from settings');

                        try {
                          final success = await notifier.enableBiometricAuth();

                          // Wait a bit for state to update
                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          if (!success && context.mounted) {
                            final errorState =
                                ref.read(biometricAuthNotifierProvider);
                            final errorMessage = errorState.error ??
                                'Failed to enable biometric sign-in';

                            service.logError(
                                'Biometric enable failed in UI: $errorMessage');
                            service.logError(
                                'Current state: isEnabled=${errorState.isEnabled}, isLoading=${errorState.isLoading}, error=${errorState.error}');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else if (success && context.mounted) {
                            service.logInfo(
                                'Biometric sign-in enabled successfully from settings');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Biometric sign-in enabled successfully'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e, stackTrace) {
                          service.logError(
                              'Exception caught in settings toggle handler',
                              e,
                              stackTrace);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } else {
                        final service = ref.read(biometricAuthServiceProvider);
                        service.logInfo(
                            'User disabling biometric sign-in from settings');
                        await ref
                            .read(biometricAuthNotifierProvider.notifier)
                            .disableBiometricAuth();
                      }
                    },
            ),
          ),
          if (biometricState.isEnabled)
            SettingsTile(
              title: 'Test Biometric',
              subtitle: 'Test your biometric authentication',
              icon: Icons.verified_user,
              onTap: () async {
                final success = await ref
                    .read(biometricAuthNotifierProvider.notifier)
                    .authenticate(reason: 'Test biometric authentication');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Biometric authentication successful!'
                          : 'Biometric authentication failed'),
                      backgroundColor: success ? Colors.green : Colors.orange,
                    ),
                  );
                }
              },
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
          title: 'Export Database',
          subtitle: 'Export entire database to Google Drive',
          icon: Icons.cloud_upload,
          onTap: () => _exportDatabase(context, ref),
        ),
        SettingsTile(
          title: 'Import Database',
          subtitle: 'Import database from Google Drive backup',
          icon: Icons.cloud_download,
          onTap: () => _importDatabase(context, ref),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header with Picture
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Display Name
                  if (user.displayName != null) ...[
                    Text(
                      user.displayName!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Email
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          // Account Details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                if (user != null) ...[
                  SettingsTile(
                    title: 'Email',
                    subtitle: user.email,
                    icon: Icons.email,
                  ),
                  if (user.displayName != null)
                    SettingsTile(
                      title: 'Display Name',
                      subtitle: user.displayName!,
                      icon: Icons.badge,
                    ),
                  SettingsTile(
                    title: 'Account ID',
                    subtitle: user.id,
                    icon: Icons.perm_identity,
                  ),
                  const Divider(height: 1),
                ],
                SettingsTile(
                  title: 'Sign Out',
                  subtitle: 'Sign out of your Google account',
                  icon: Icons.logout,
                  onTap: () => _showSignOutDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You will need to sign in again to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
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

  void _exportDatabase(BuildContext context, WidgetRef ref) async {
    // Check if user is signed in
    final authState = ref.read(authNotifierProvider);
    if (authState.valueOrNull == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in with Google to export database'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show password dialog
    final password = await showExportPasswordDialog(context);

    if (password == null || password.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Database'),
        content: const Text(
          'This will export your entire database to Google Drive. '
          'The database will be encrypted with your password before upload. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show progress dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExportProgressDialog(),
    );

    // Perform export with password
    final notifier = ref.read(databaseExportNotifierProvider.notifier);
    final fileId = await notifier.exportDatabase(password: password);

    if (!context.mounted) return;
    Navigator.pop(context); // Close progress dialog

    if (fileId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database exported successfully to Google Drive'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final state = ref.read(databaseExportNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.error ?? 'Failed to export database',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _importDatabase(BuildContext context, WidgetRef ref) async {
    // Check if user is signed in
    final authState = ref.read(authNotifierProvider);
    if (authState.valueOrNull == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in with Google to import database'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show loading dialog while fetching backups
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Fetch available backups
    final notifier = ref.read(databaseExportNotifierProvider.notifier);
    await notifier.refreshBackups();

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    final state = ref.read(databaseExportNotifierProvider);
    final backups = state.availableBackups;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No backups found in Google Drive'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show backup selection dialog
    if (!context.mounted) return;
    final selectedBackup = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BackupSelectionDialog(backups: backups),
    );

    if (selectedBackup == null) return;

    // Show password dialog
    if (!context.mounted) return;
    final password = await showImportPasswordDialog(context);

    if (password == null || password.isEmpty) return;

    // Show confirmation dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Database'),
        content: Text(
          'This will replace your current database with the backup from '
          '${selectedBackup['fileName']}. Your current database will be backed up first. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show progress dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportProgressDialog(),
    );

    // Perform import with password
    final success = await notifier.importDatabase(
      driveFileId: selectedBackup['fileId'] as String,
      password: password,
      backupCurrent: true,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Close progress dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database imported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorState = ref.read(databaseExportNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorState.error ?? 'Failed to import database',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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

/// Dialog showing export progress
class _ExportProgressDialog extends ConsumerWidget {
  const _ExportProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseExportNotifierProvider);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isExporting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Exporting database... ${(state.progress * 100).toInt()}%'),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Export complete!'),
          ],
        ],
      ),
    );
  }
}

/// Dialog showing import progress
class _ImportProgressDialog extends ConsumerWidget {
  const _ImportProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseExportNotifierProvider);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isImporting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Importing database... ${(state.progress * 100).toInt()}%'),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Import complete!'),
          ],
        ],
      ),
    );
  }
}

/// Dialog for selecting a backup to import
class _BackupSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> backups;

  const _BackupSelectionDialog({required this.backups});

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatSize(int? size) {
    if (size == null) return 'Unknown size';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Backup to Import'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: backups.length,
          itemBuilder: (context, index) {
            final backup = backups[index];
            return ListTile(
              title: Text(backup['fileName'] as String? ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Created: ${_formatDate(backup['createdAt'] as String?)}'),
                  if (backup['size'] != null)
                    Text('Size: ${_formatSize(backup['size'] as int?)}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, backup),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
