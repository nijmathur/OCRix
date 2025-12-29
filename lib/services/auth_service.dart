import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../core/base/base_service.dart';
import '../core/exceptions/app_exceptions.dart';

class AuthService extends BaseService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/drive.appdata', // Required for appDataFolder access
    ],
  );

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

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
      // Check if user is already signed in (silent sign-in)
      _currentUser = _googleSignIn.currentUser;

      // If not signed in, try to restore previous session
      _currentUser ??= await _googleSignIn.signInSilently();

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
      final account = await _googleSignIn.signIn();

      if (account != null) {
        _currentUser = account;
        logInfo('User signed in: ${account.email}');
      } else {
        logWarning('Google Sign-In cancelled by user');
      }

      return account;
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

  /// Get user email
  String? get userEmail => _currentUser?.email;

  /// Get user display name
  String? get userDisplayName => _currentUser?.displayName;

  /// Get user photo URL
  String? get userPhotoUrl => _currentUser?.photoUrl;
}
