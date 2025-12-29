import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final biometricState = ref.watch(biometricAuthNotifierProvider);

    // Check if biometric sign-in should be attempted
    if (!authState.isLoading &&
        authState.valueOrNull == null &&
        biometricState.isEnabled &&
        biometricState.isAvailable) {
      // Attempt biometric authentication
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptBiometricSignIn(context, ref);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.document_scanner,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // App Title
                Text(
                  'OCRix',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Privacy-First Document Scanner',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Biometric Sign-In Button (if available and enabled)
                if (biometricState.isAvailable &&
                    biometricState.isEnabled &&
                    !authState.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => _attemptBiometricSignIn(context, ref),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Sign in with Biometrics'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        minimumSize: const Size(280, 56),
                      ),
                    ),
                  ),

                // Sign In Button
                if (authState.isLoading)
                  const CircularProgressIndicator()
                else if (authState.hasError)
                  Column(
                    children: [
                      Text(
                        'Error: ${authState.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(authNotifierProvider.notifier).signIn(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Sign In'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .signIn();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign in cancelled or failed'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        // If success, the auth state will update and the app will navigate automatically
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign in error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      minimumSize: const Size(280, 56),
                    ),
                  ),

                const SizedBox(height: 32),

                // Privacy Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your documents are encrypted and stored securely. Google Sign-In is required to access your data.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _attemptBiometricSignIn(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final biometricNotifier = ref.read(biometricAuthNotifierProvider.notifier);
    final isAuthenticated = await biometricNotifier.authenticate(
      reason: 'Use biometrics to sign in to OCRix',
    );

    if (isAuthenticated && context.mounted) {
      // Biometric auth successful - check if user is already signed in with Google
      final authState = ref.read(authNotifierProvider);

      // First, try to restore any existing Google session
      if (authState.valueOrNull == null) {
        // Try to restore previous session silently
        try {
          final authService = ref.read(authServiceProvider);
          await authService.initialize();

          // Refresh the auth state after initialization
          await ref.read(authNotifierProvider.notifier).refreshAuthState();

          // Check again after refresh
          final updatedAuthState = ref.read(authNotifierProvider);
          if (updatedAuthState.valueOrNull == null) {
            // Still not signed in, need to sign in with Google
            final success = await ref
                .read(authNotifierProvider.notifier)
                .signIn();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Google Sign-In required after biometric authentication',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
          // If we got here, user is now signed in (either restored or just signed in)
        } catch (e) {
          // If restore fails, prompt for Google Sign-In
          if (context.mounted) {
            final success = await ref
                .read(authNotifierProvider.notifier)
                .signIn();
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Google Sign-In required: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
      // If already signed in with Google, biometric auth is enough - app will proceed
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication failed. Please sign in with Google.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
