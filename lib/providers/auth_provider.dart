import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/audit_log.dart';
import '../services/auth_service.dart';
import 'audit_provider.dart';
import 'troubleshooting_logger_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.valueOrNull != null;
});

class AuthNotifier extends AsyncNotifier<GoogleSignInAccount?> {
  @override
  Future<GoogleSignInAccount?> build() async {
    final authService = ref.read(authServiceProvider);
    await authService.initialize();
    return authService.currentUser;
  }

  Future<bool> signIn() async {
    final authService = ref.read(authServiceProvider);
    final auditLoggingService = ref.read(auditLoggingServiceProvider);
    final logger = ref.read(troubleshootingLoggerProvider);
    try {
      state = const AsyncValue.loading();
      final account = await authService.signIn();

      state = AsyncValue.data(account);

      if (account == null) {
        await auditLoggingService.logInfoAction(
          action: AuditAction.login,
          resourceType: 'auth',
          resourceId: 'login',
          details: 'Login cancelled by user',
          isSuccess: false,
        );
        return false;
      }

      await auditLoggingService.logInfoAction(
        action: AuditAction.login,
        resourceType: 'auth',
        resourceId: account.id,
        details: 'User logged in: ${account.email}',
        isSuccess: true,
      );

      final userId = account.email.isNotEmpty ? account.email : account.id;
      auditLoggingService.setUserId(userId);

      return true;
    } catch (e, stackTrace) {
      logger.error(
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
    final authService = ref.read(authServiceProvider);
    final auditLoggingService = ref.read(auditLoggingServiceProvider);
    try {
      state = const AsyncValue.loading();

      final currentUser = authService.currentUser;
      if (currentUser != null) {
        await auditLoggingService.logInfoAction(
          action: AuditAction.logout,
          resourceType: 'auth',
          resourceId: currentUser.id,
          details: 'User logged out: ${currentUser.email}',
          isSuccess: true,
        );
      }

      await authService.signOut();
      state = const AsyncValue.data(null);

      auditLoggingService.setUserId('unknown');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Public method to refresh auth state
  Future<void> refreshAuthState() async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.initialize();
      state = AsyncValue.data(authService.currentUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, GoogleSignInAccount?>(AuthNotifier.new);
