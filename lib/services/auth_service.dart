import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

class AuthService extends BaseService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    'https://www.googleapis.com/auth/drive.appdata', // Required for appDataFolder access
  ];

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSubscription;

  @override
  String get serviceName => 'AuthService';

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialize and check if user is already signed in
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Initialize the GoogleSignIn instance
      await _googleSignIn.initialize();

      // Listen to authentication events to track current user
      _authEventsSubscription = _googleSignIn.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
            logInfo('User signed in via event: ${event.user.email}');
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
            logInfo('User signed out via event');
          }
        },
        onError: (error) {
          logError('Authentication event error', error);
        },
      );

      // Try lightweight authentication (previously signInSilently)
      final result = _googleSignIn.attemptLightweightAuthentication();
      if (result is Future<GoogleSignInAccount?>) {
        _currentUser = await result;
      }
      // If result is not a Future, we'll get updates via the event stream

      _isInitialized = true;
      logInfo('Auth service initialized. Signed in: $isSignedIn');
    } catch (e) {
      logError('Failed to initialize auth service', e);
      // Don't throw - allow app to show login screen
      _isInitialized = true;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      logInfo('Initiating Google Sign-In');

      // Check if platform supports authenticate method
      if (_googleSignIn.supportsAuthenticate()) {
        final user = await _googleSignIn.authenticate(scopeHint: _scopes);
        _currentUser = user;
        logInfo('User signed in: ${user.email}');
        return user;
      } else {
        // Platform doesn't support authenticate (e.g., web)
        // For web, you would need to use renderButton from google_sign_in_web
        throw AuthException('Platform does not support explicit authentication');
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        logWarning('User canceled sign-in');
        return null;
      }
      logError('Google Sign-In exception', e);
      throw AuthException(
        'Failed to sign in: ${e.description ?? e.code.toString()}',
        originalError: e,
      );
    } catch (e) {
      logError('Failed to sign in', e);
      throw AuthException(
        'Failed to sign in: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      logInfo('Signing out user');
      await _googleSignIn.signOut();
      _currentUser = null;
      logInfo('User signed out successfully');
    } catch (e) {
      logError('Failed to sign out', e);
      throw AuthException(
        'Failed to sign out: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Clean up resources
  void cleanup() {
    _authEventsSubscription?.cancel();
  }

  /// Get user email
  String? get userEmail => _currentUser?.email;

  /// Get user display name
  String? get userDisplayName => _currentUser?.displayName;

  /// Get user photo URL
  String? get userPhotoUrl => _currentUser?.photoUrl;
}
