import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

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

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
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

  Future<bool> signIn() async {
    try {
      state = const AsyncValue.loading();
      final account = await _authService.signIn();
      state = AsyncValue.data(account);
      return account != null;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GoogleSignInAccount?>>(
        (ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});
