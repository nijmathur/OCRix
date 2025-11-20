import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_database_service.dart';
import '../services/audit_logging_service.dart';
import '../core/interfaces/audit_database_service_interface.dart';
import 'document_provider.dart';

// Audit database service provider
// Uses the same database as documents for simplicity
final auditDatabaseServiceProvider = Provider<IAuditDatabaseService>((ref) {
  final auditService = AuditDatabaseService();
  // Set main database service so audit uses same database
  final mainDbService = ref.read(databaseServiceProvider);
  auditService.setMainDatabaseService(mainDbService);
  return auditService;
});

// Audit logging service provider
final auditLoggingServiceProvider = Provider<AuditLoggingService>((ref) {
  final auditDatabase = ref.read(auditDatabaseServiceProvider);
  return AuditLoggingService(auditDatabase);
});

