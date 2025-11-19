import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';

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
      state = state.copyWith(isLoading: true, error: null);
      await _biometricAuthService.enableBiometricAuth();

      state = state.copyWith(
        isEnabled: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
