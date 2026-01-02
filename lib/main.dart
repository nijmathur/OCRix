import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/document_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/biometric_auth_provider.dart';
import 'providers/audit_provider.dart';
import 'providers/troubleshooting_logger_provider.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/ocr_service.dart';
import 'services/storage_provider_service.dart';
import 'utils/navigation_observer.dart';
import 'utils/error_handler.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app in error zone to catch async errors
  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: OCRixApp()));
    },
    (error, stackTrace) {
      // This will be handled by ErrorHandler once initialized
      // For now, just print to console as fallback
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
      // Note: ErrorHandler will log this once app is initialized
    },
  );
}

class OCRixApp extends ConsumerWidget {
  const OCRixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLoggingService = ref.read(auditLoggingServiceProvider);
    final navigationObserver = AuditNavigationObserver(auditLoggingService);

    return MaterialApp(
      title: 'OCRix',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [navigationObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF2E7D32,
          ), // Green theme for privacy/security
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;
  bool _isAuthenticated = false;
  bool _isCheckingBiometric = false;
  DateTime? _lastBackgroundTime; // Track when app was actually backgrounded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only mark as not authenticated when app is actually paused (backgrounded)
    // Don't reset on inactive state (which happens during navigation)
    if (state == AppLifecycleState.paused) {
      _isAuthenticated = false;
      _lastBackgroundTime = DateTime.now();
    }

    // When app comes back to foreground, check if biometric auth is needed
    // Only check if app was actually backgrounded (paused) and not just navigating
    if (state == AppLifecycleState.resumed) {
      // Only check if we have a background time recorded (app was actually backgrounded)
      // and it was more than 1 second ago (to avoid checking on quick navigation)
      if (_lastBackgroundTime != null) {
        final timeSinceBackground = DateTime.now().difference(
          _lastBackgroundTime!,
        );
        if (timeSinceBackground.inSeconds >= 1) {
          _checkBiometricOnResume();
        }
        // Clear background time after checking
        _lastBackgroundTime = null;
      }
    }
  }

  Future<void> _checkBiometricOnResume() async {
    // Only check if user is signed in and app is initialized
    final authState = ref.read(authNotifierProvider);
    if (authState.valueOrNull == null || !_isInitialized) {
      return;
    }

    // Check if biometric is enabled and available
    final biometricState = ref.read(biometricAuthNotifierProvider);
    if (!biometricState.isEnabled || !biometricState.isAvailable) {
      return;
    }

    // If already authenticated in this session, skip
    if (_isAuthenticated) {
      return;
    }

    // Don't check multiple times simultaneously
    if (_isCheckingBiometric) {
      return;
    }

    setState(() {
      _isCheckingBiometric = true;
    });

    try {
      final biometricNotifier = ref.read(
        biometricAuthNotifierProvider.notifier,
      );
      final biometricService = ref.read(biometricAuthServiceProvider);

      biometricService.logInfo(
        'App resumed - requesting biometric authentication',
      );
      final authenticated = await biometricNotifier.authenticate(
        reason: 'Use your fingerprint to continue',
      );

      if (authenticated) {
        biometricService.logInfo(
          'Biometric authentication successful on app resume',
        );
        setState(() {
          _isAuthenticated = true;
          _isCheckingBiometric = false;
        });
      } else {
        // Biometric failed or cancelled - show login screen with Google Sign-In as backup
        biometricService.logWarning(
          'Biometric authentication failed or cancelled on app resume - showing login screen',
        );
        setState(() {
          _isAuthenticated = false;
          _isCheckingBiometric = false;
        });
        // Login screen will be shown automatically by build method
      }
    } catch (e, stackTrace) {
      // On error, show login screen with Google Sign-In as backup
      final biometricService = ref.read(biometricAuthServiceProvider);
      biometricService.logError(
        'Error during biometric check on app resume',
        e,
        stackTrace,
      );
      setState(() {
        _isAuthenticated = false;
        _isCheckingBiometric = false;
      });
      // Login screen will be shown automatically by build method
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize on first build when ref is available
    if (!_isInitialized && !_isInitializing && _error == null) {
      _isInitializing = true;
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize troubleshooting logger first (needed for all service logging)
      final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
      await troubleshootingLogger.initialize();

      // Initialize services using providers from widget tree
      // ref is available in ConsumerState after didChangeDependencies
      final databaseService = ref.read(databaseServiceProvider);
      final encryptionService = ref.read(encryptionServiceProvider);
      final ocrService = ref.read(ocrServiceProvider);
      final cameraService = ref.read(cameraServiceProvider);
      final storageService = ref.read(storageProviderServiceProvider);
      final auditLoggingService = ref.read(auditLoggingServiceProvider);

      // Inject troubleshooting logger into all services
      if (databaseService is DatabaseService) {
        (databaseService).setTroubleshootingLogger(troubleshootingLogger);
      }

      if (encryptionService is EncryptionService) {
        (encryptionService).setTroubleshootingLogger(troubleshootingLogger);
      }

      if (ocrService is OCRService) {
        (ocrService).setTroubleshootingLogger(troubleshootingLogger);
      }

      (cameraService).setTroubleshootingLogger(troubleshootingLogger);

      if (storageService is StorageProviderService) {
        (storageService).setTroubleshootingLogger(troubleshootingLogger);
      }

      // Initialize error handler
      ErrorHandler.initialize(troubleshootingLogger);

      // Log app initialization start
      troubleshootingLogger.info(
        'App initialization started',
        tag: 'AppInitializer',
      );

      // Initialize audit logging service (needed for DB logging)
      await auditLoggingService.initialize();

      // Set audit logging service in database service for COMPULSORY logging
      // Cast to concrete type to access setAuditLoggingService
      if (databaseService is DatabaseService) {
        (databaseService).setAuditLoggingService(auditLoggingService);
      }

      // Get current user ID for audit logging
      final authState = ref.read(authNotifierProvider);
      final user = authState.valueOrNull;
      if (user != null) {
        // Use email or id as user identifier
        final userId = user.email.isNotEmpty ? user.email : user.id;
        auditLoggingService.setUserId(userId);

        // Set user ID in database for SQLite triggers
        if (databaseService is DatabaseService) {
          await (databaseService).setCurrentUserIdForTriggers(userId);
        }
      }

      // No staging processing needed - audit is in main database

      // Initialize critical services (must succeed)
      await databaseService.initialize();
      troubleshootingLogger.info(
        'Database service initialized',
        tag: 'AppInitializer',
      );

      await encryptionService.initialize();
      troubleshootingLogger.info(
        'Encryption service initialized',
        tag: 'AppInitializer',
      );

      await ocrService.initialize();
      troubleshootingLogger.info(
        'OCR service initialized',
        tag: 'AppInitializer',
      );

      await storageService.initialize();
      troubleshootingLogger.info(
        'Storage service initialized',
        tag: 'AppInitializer',
      );

      // Camera service is optional (may fail in CI/test environments)
      try {
        await cameraService.initialize();
        troubleshootingLogger.info(
          'Camera service initialized',
          tag: 'AppInitializer',
        );
      } catch (e) {
        // Log but don't fail app initialization if camera is unavailable
        // Camera features will be disabled, but app can still function
        troubleshootingLogger.warning(
          'Camera service initialization failed',
          tag: 'AppInitializer',
          error: e,
          metadata: {'note': 'Camera features will be disabled'},
        );
        debugPrint('Warning: Camera service initialization failed: $e');
      }

      troubleshootingLogger.info(
        'App initialization completed successfully',
        tag: 'AppInitializer',
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });

        // After initialization, check if biometric auth is needed
        _checkBiometricOnResume();
      }
    } catch (e, stackTrace) {
      // Log critical error
      final troubleshootingLogger = ref.read(troubleshootingLoggerProvider);
      troubleshootingLogger.critical(
        'App initialization failed',
        tag: 'AppInitializer',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication state
    final authState = ref.watch(authNotifierProvider);
    final biometricState = ref.watch(biometricAuthNotifierProvider);
    final isSignedIn = authState.valueOrNull != null;
    final isLoadingAuth = authState.isLoading;

    // Show splash while checking auth
    if (isLoadingAuth || biometricState.isLoading) {
      return const SplashScreen();
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to initialize app',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                    _isInitializing = true;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const SplashScreen();
    }

    // Only check biometric if user is signed in
    // (Biometric is optional security layer, not required for app access)
    if (isSignedIn &&
        biometricState.isEnabled &&
        biometricState.isAvailable &&
        !_isAuthenticated &&
        !_isCheckingBiometric) {
      // This will trigger the biometric prompt via _checkBiometricOnResume
      // Show login screen as fallback
      return const LoginScreen();
    }

    // Show loading while checking biometric
    if (_isCheckingBiometric) {
      return const SplashScreen();
    }

    // App can be used without Google Sign-In
    // Sign-in is only required for cloud sync/export features
    return const HomeScreen();
  }
}
