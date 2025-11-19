import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

class BiometricAuthService extends BaseService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  static const String _biometricRegisteredKey = 'biometric_registered';

  @override
  String get serviceName => 'BiometricAuthService';

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return isAvailable && availableBiometrics.isNotEmpty;
    } catch (e) {
      logError('Failed to check biometric availability', e);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      logError('Failed to get available biometrics', e);
      return [];
    }
  }

  /// Check if biometric authentication is enabled for app sign-in
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      logError('Failed to check if biometric is enabled', e);
      return false;
    }
  }

  /// Enable biometric authentication for app sign-in
  Future<void> enableBiometricAuth() async {
    try {
      // First verify biometric works
      final isAuthenticated = await authenticate(
        reason: 'Enable biometric sign-in for faster access',
      );
      
      if (!isAuthenticated) {
        throw AuthException('Biometric authentication failed');
      }

      // Mark as enabled
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(key: _biometricRegisteredKey, value: 'true');
      
      logInfo('Biometric authentication enabled for app sign-in');
    } catch (e) {
      logError('Failed to enable biometric auth', e);
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Failed to enable biometric authentication: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _biometricRegisteredKey);
      logInfo('Biometric authentication disabled');
    } catch (e) {
      logError('Failed to disable biometric auth', e);
      throw AuthException(
        'Failed to disable biometric authentication: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Authenticate with biometrics (for app sign-in)
  Future<bool> authenticate({String? reason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        logWarning('Biometric authentication not available');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (isAuthenticated) {
        logInfo('Biometric authentication successful');
      } else {
        logWarning('Biometric authentication failed or cancelled');
      }

      return isAuthenticated;
    } catch (e) {
      logError('Biometric authentication error', e);
      return false;
    }
  }

  /// Check if user should use biometric sign-in
  Future<bool> shouldUseBiometricSignIn() async {
    final isAvailable = await isBiometricAvailable();
    final isEnabled = await isBiometricEnabled();
    return isAvailable && isEnabled;
  }
}

