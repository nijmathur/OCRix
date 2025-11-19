import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import '../services/biometric_auth_service.dart';
import '../core/exceptions/app_exceptions.dart';

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
  final Logger _logger = Logger();

  BiometricAuthNotifier(this._biometricAuthService)
      : super(const BiometricAuthState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      final isAvailable = await _biometricAuthService.isBiometricAvailable();
      final isEnabled = await _biometricAuthService.isBiometricEnabled();
      final availableTypes =
          await _biometricAuthService.getAvailableBiometrics();

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        isLoading: false,
        availableTypes: availableTypes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> enableBiometricAuth() async {
    try {
      _logger.i(
          '[BiometricAuthNotifier] Starting enable biometric authentication');
      state = state.copyWith(isLoading: true, error: null);

      // enableBiometricAuth() already handles authentication internally
      await _biometricAuthService.enableBiometricAuth();

      _logger.i(
          '[BiometricAuthNotifier] Biometric authentication enabled successfully');
      state = state.copyWith(
        isEnabled: true,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e, stackTrace) {
      _logger.e(
          '[BiometricAuthNotifier] Failed to enable biometric authentication',
          error: e,
          stackTrace: stackTrace);
      _logger.e(
          '[BiometricAuthNotifier] Error details: type=${e.runtimeType}, message=${e.toString()}');

      String errorMessage;
      if (e is AuthException) {
        errorMessage = e.message;
        _logger
            .e('[BiometricAuthNotifier] AuthException message: $errorMessage');
      } else {
        errorMessage = 'Failed to enable biometric sign-in: ${e.toString()}';
        _logger.e(
            '[BiometricAuthNotifier] Non-AuthException error: $errorMessage');
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

      state = state.copyWith(
        isEnabled: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
  return BiometricAuthNotifier(service);
});
