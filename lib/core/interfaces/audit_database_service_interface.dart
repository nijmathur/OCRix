import '../../models/audit_entry.dart';
import '../../models/audit_log.dart';
import '../models/audit_log_level.dart';

/// Interface for tamper-proof audit database operations
abstract class IAuditDatabaseService {
  /// Initialize the audit database
  Future<void> initialize();

  /// Insert an audit entry (tamper-proof)
  /// Returns the entry ID
  Future<String> insertAuditEntry(AuditEntry entry);

  /// Get audit entries with optional filtering
  Future<List<AuditEntry>> getAuditEntries({
    int? limit,
    int? offset,
    AuditLogLevel? level,
    AuditAction? action,
    String? resourceType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Verify integrity of all audit entries
  /// Returns list of entry IDs that failed verification
  Future<List<String>> verifyIntegrity();

  /// Get the last audit entry (for chain linking)
  Future<AuditEntry?> getLastEntry();

  /// Get entry count
  Future<int> getEntryCount({AuditLogLevel? level});

  /// Close the database
  Future<void> close();
}
