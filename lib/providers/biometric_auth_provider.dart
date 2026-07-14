import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/exceptions/app_exceptions.dart';
import '../services/biometric_auth_service.dart';
import 'troubleshooting_logger_provider.dart';

part 'biometric_auth_provider.freezed.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

@freezed
abstract class BiometricAuthState with _$BiometricAuthState {
  const factory BiometricAuthState({
    @Default(false) bool isAvailable,
    @Default(false) bool isEnabled,
    @Default(false) bool isLoading,
    String? error,
    @Default([]) List<BiometricType> availableTypes,
  }) = _BiometricAuthState;
}

class BiometricAuthNotifier extends Notifier<BiometricAuthState> {
  @override
  BiometricAuthState build() {
    Future.microtask(_initialize);
    return const BiometricAuthState(isLoading: true);
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      final service = ref.read(biometricAuthServiceProvider);
      final isAvailable = await service.isBiometricAvailable();
      final isEnabled = await service.isBiometricEnabled();
      final availableTypes = await service.getAvailableBiometrics();

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
    final logger = ref.read(troubleshootingLoggerProvider);
    final service = ref.read(biometricAuthServiceProvider);
    try {
      await logger.info(
        'Starting enable biometric authentication',
        tag: 'BiometricAuthNotifier',
      );
      state = state.copyWith(isLoading: true, error: null);

      await service.enableBiometricAuth();

      await logger.info(
        'Biometric authentication enabled successfully',
        tag: 'BiometricAuthNotifier',
      );
      state = state.copyWith(isEnabled: true, isLoading: false, error: null);
      return true;
    } catch (e, stackTrace) {
      await logger.error(
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
      if (e case AuthException(:final message)) {
        errorMessage = message;
        await logger.error(
          'AuthException during biometric enable',
          tag: 'BiometricAuthNotifier',
          error: e,
          metadata: {'authExceptionMessage': errorMessage},
        );
      } else {
        errorMessage = 'Failed to enable biometric sign-in: ${e.toString()}';
        await logger.error(
          'Non-AuthException error during biometric enable',
          tag: 'BiometricAuthNotifier',
          error: e,
          metadata: {'errorMessage': errorMessage},
        );
      }

      state = state.copyWith(
        isEnabled: false,
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> disableBiometricAuth() async {
    final service = ref.read(biometricAuthServiceProvider);
    try {
      state = state.copyWith(isLoading: true, error: null);
      await service.disableBiometricAuth();

      state = state.copyWith(isEnabled: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> authenticate({String? reason}) async {
    final service = ref.read(biometricAuthServiceProvider);
    return service.authenticate(reason: reason);
  }

  Future<void> refresh() async {
    await _initialize();
  }
}

final biometricAuthNotifierProvider =
    NotifierProvider<BiometricAuthNotifier, BiometricAuthState>(
      BiometricAuthNotifier.new,
    );
