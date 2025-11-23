import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/database_export_service.dart';
import 'document_provider.dart'; // Import existing providers

/// Provider for DatabaseExportService
final databaseExportServiceProvider = Provider<DatabaseExportService>((ref) {
  // Use existing providers from document_provider.dart
  final databaseService = DatabaseService(); // Get concrete instance
  final encryptionService = ref.read(encryptionServiceProvider);
  final storageProviderService = ref.read(storageProviderServiceProvider);

  return DatabaseExportService(
    databaseService: databaseService,
    encryptionService: encryptionService,
    storageProviderService: storageProviderService,
  );
});

/// State for database export/import operations
class DatabaseExportState {
  final bool isExporting;
  final bool isImporting;
  final double progress;
  final String? error;
  final String? lastExportFileId;
  final List<Map<String, dynamic>> availableBackups;

  const DatabaseExportState({
    this.isExporting = false,
    this.isImporting = false,
    this.progress = 0.0,
    this.error,
    this.lastExportFileId,
    this.availableBackups = const [],
  });

  DatabaseExportState copyWith({
    bool? isExporting,
    bool? isImporting,
    double? progress,
    String? error,
    String? lastExportFileId,
    List<Map<String, dynamic>>? availableBackups,
  }) {
    return DatabaseExportState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      progress: progress ?? this.progress,
      error: error,
      lastExportFileId: lastExportFileId ?? this.lastExportFileId,
      availableBackups: availableBackups ?? this.availableBackups,
    );
  }
}

/// Notifier for database export/import operations
class DatabaseExportNotifier extends StateNotifier<DatabaseExportState> {
  final DatabaseExportService _exportService;

  DatabaseExportNotifier(this._exportService)
      : super(const DatabaseExportState());

  /// Export database to Google Drive
  Future<String?> exportDatabase({String? customFileName}) async {
    try {
      state = state.copyWith(
        isExporting: true,
        progress: 0.0,
        error: null,
      );

      final fileId = await _exportService.exportDatabaseToGoogleDrive(
        customFileName: customFileName,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        isExporting: false,
        progress: 1.0,
        lastExportFileId: fileId,
      );

      // Refresh available backups
      await refreshBackups();

      return fileId;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Import database from Google Drive
  Future<bool> importDatabase({
    required String driveFileId,
    bool backupCurrent = true,
  }) async {
    try {
      state = state.copyWith(
        isImporting: true,
        progress: 0.0,
        error: null,
      );

      await _exportService.importDatabaseFromGoogleDrive(
        driveFileId: driveFileId,
        backupCurrent: backupCurrent,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        isImporting: false,
        progress: 1.0,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// List available database backups
  Future<void> refreshBackups() async {
    try {
      final backups = await _exportService.listDatabaseBackups();
      state = state.copyWith(availableBackups: backups);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a database backup
  Future<bool> deleteBackup(String driveFileId) async {
    try {
      await _exportService.deleteDatabaseBackup(driveFileId);
      await refreshBackups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for DatabaseExportNotifier
final databaseExportNotifierProvider =
    StateNotifierProvider<DatabaseExportNotifier, DatabaseExportState>((ref) {
  final exportService = ref.read(databaseExportServiceProvider);
  return DatabaseExportNotifier(exportService);
});
