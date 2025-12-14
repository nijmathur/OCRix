import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'troubleshooting_logger_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/audit_logging_service.dart';
import '../models/audit_log.dart';
import 'audit_provider.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = FutureProvider<GoogleSignInAccount?>((ref) async {
  final authService = ref.read(authServiceProvider);
  await authService.initialize();
  return authService.currentUser;
});

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

class AuthNotifier extends StateNotifier<AsyncValue<GoogleSignInAccount?>> {
  final AuthService _authService;
  final AuditLoggingService? _auditLoggingService;
  final ITroubleshootingLogger? _troubleshootingLogger;

  AuthNotifier(
    this._authService, {
    AuditLoggingService? auditLoggingService,
    ITroubleshootingLogger? troubleshootingLogger,
  })  : _auditLoggingService = auditLoggingService,
        _troubleshootingLogger = troubleshootingLogger,
        super(const AsyncValue.loading()) {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      await _authService.initialize();
      state = AsyncValue.data(_authService.currentUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Public method to refresh auth state (used after restoring session)
  Future<void> refreshAuthState() async {
    await _checkAuthState();
  }

  Future<bool> signIn() async {
    try {
      state = const AsyncValue.loading();
      final account = await _authService.signIn();

      // Update state with the account (even if null, to indicate sign-in attempt completed)
      state = AsyncValue.data(account);

      // If account is null, user cancelled - don't treat as error
      if (account == null) {
        // Log failed login attempt (INFO level)
        await _auditLoggingService?.logInfoAction(
          action: AuditAction.login,
          resourceType: 'auth',
          resourceId: 'login',
          details: 'Login cancelled by user',
          isSuccess: false,
        );
        return false;
      }

      // Log successful login (INFO level)
      await _auditLoggingService?.logInfoAction(
        action: AuditAction.login,
        resourceType: 'auth',
        resourceId: account.id,
        details: 'User logged in: ${account.email}',
        isSuccess: true,
      );

      // Update user ID in audit service
      final userId = account.email.isNotEmpty ? account.email : account.id;
      _auditLoggingService?.setUserId(userId);

      return true;
    } catch (e, stackTrace) {
      // Log the error for debugging
      _troubleshootingLogger?.error(
        'Google Sign-In error',
        tag: 'AuthNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();

      // Log logout before signing out (INFO level)
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _auditLoggingService?.logInfoAction(
          action: AuditAction.logout,
          resourceType: 'auth',
          resourceId: currentUser.id,
          details: 'User logged out: ${currentUser.email}',
          isSuccess: true,
        );
      }

      await _authService.signOut();
      state = const AsyncValue.data(null);

      // Clear user ID from audit service (set to unknown)
      _auditLoggingService?.setUserId('unknown');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GoogleSignInAccount?>>(
        (ref) {
  final authService = ref.read(authServiceProvider);
  final auditLoggingService = ref.read(auditLoggingServiceProvider);
  final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
  return AuthNotifier(
    authService,
    auditLoggingService: auditLoggingService,
    troubleshootingLogger: troubleshootingLogger,
  );
});
