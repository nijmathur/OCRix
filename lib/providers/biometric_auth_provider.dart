import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'troubleshooting_logger_provider.dart';
import '../core/interfaces/troubleshooting_logger_interface.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

class BiometricAuthState {
  final bool isAvailable;
  final bool isEnabled;
  final bool isLoading;
  final String? error;
  final List<BiometricType> availableTypes;

  const BiometricAuthState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
    this.availableTypes = const [],
  });

  BiometricAuthState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    bool? isLoading,
    String? error,
    List<BiometricType>? availableTypes,
  }) {
    return BiometricAuthState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      availableTypes: availableTypes ?? this.availableTypes,
    );
  }
}

class BiometricAuthNotifier extends StateNotifier<BiometricAuthState> {
  final BiometricAuthService _biometricAuthService;
  final ITroubleshootingLogger? _troubleshootingLogger;

  BiometricAuthNotifier(
    this._biometricAuthService, {
    ITroubleshootingLogger? troubleshootingLogger,
  }) : _troubleshootingLogger = troubleshootingLogger,
       super(const BiometricAuthState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      final isAvailable = await _biometricAuthService.isBiometricAvailable();
      final isEnabled = await _biometricAuthService.isBiometricEnabled();
      final availableTypes = await _biometricAuthService
          .getAvailableBiometrics();

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        isLoading: false,
        availableTypes: availableTypes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> enableBiometricAuth() async {
    try {
      _troubleshootingLogger?.info(
        'Starting enable biometric authentication',
        tag: 'BiometricAuthNotifier',
      );
      state = state.copyWith(isLoading: true, error: null);

      // enableBiometricAuth() already handles authentication internally
      await _biometricAuthService.enableBiometricAuth();

      _troubleshootingLogger?.info(
        'Biometric authentication enabled successfully',
        tag: 'BiometricAuthNotifier',
      );
      state = state.copyWith(isEnabled: true, isLoading: false, error: null);
      return true;
    } catch (e, stackTrace) {
      _troubleshootingLogger?.error(
        'Failed to enable biometric authentication',
        tag: 'BiometricAuthNotifier',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'errorType': e.runtimeType.toString(),
          'errorMessage': e.toString(),
        },
      );

      String errorMessage;
      if (e is AuthException) {
        errorMessage = e.message;
        _troubleshootingLogger?.error(
          'AuthException during biometric enable',
          tag: 'BiometricAuthNotifier',
          error: e,
          metadata: {'authExceptionMessage': errorMessage},
        );
      } else {
        errorMessage = 'Failed to enable biometric sign-in: ${e.toString()}';
        _troubleshootingLogger?.error(
          'Non-AuthException error during biometric enable',
          tag: 'BiometricAuthNotifier',
          error: e,
          metadata: {'errorMessage': errorMessage},
        );
      }

      state = state.copyWith(
        isEnabled: false, // Ensure it's false on failure
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> disableBiometricAuth() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _biometricAuthService.disableBiometricAuth();

      state = state.copyWith(isEnabled: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> authenticate({String? reason}) async {
    return await _biometricAuthService.authenticate(reason: reason);
  }

  Future<void> refresh() async {
    await _initialize();
  }
}

final biometricAuthNotifierProvider =
    StateNotifierProvider<BiometricAuthNotifier, BiometricAuthState>((ref) {
      final service = ref.read(biometricAuthServiceProvider);
      final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
      return BiometricAuthNotifier(
        service,
        troubleshootingLogger: troubleshootingLogger,
      );
    });
