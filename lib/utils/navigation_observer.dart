import 'package:flutter/material.dart';
import '../services/audit_logging_service.dart';

/// Route observer that logs navigation events to audit database
class AuditNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  final AuditLoggingService? _auditLoggingService;

  AuditNavigationObserver(this._auditLoggingService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation(route, previousRoute, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation(previousRoute, route, 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation(newRoute, oldRoute, 'replace');
  }

  void _logNavigation(
    Route<dynamic>? toRoute,
    Route<dynamic>? fromRoute,
    String action,
  ) {
    final auditService = _auditLoggingService;
    if (auditService == null) return;

    final toScreen = _getScreenName(toRoute);
    final fromScreen = fromRoute != null
        ? _getScreenName(fromRoute)
        : 'unknown';

    // Log navigation (VERBOSE level)
    auditService.logNavigation(
      fromScreen: fromScreen,
      toScreen: toScreen,
      details: 'Navigation $action: $fromScreen -> $toScreen',
    );
  }

  String _getScreenName(Route<dynamic>? route) {
    if (route == null) return 'unknown';

    final settings = route.settings;
    if (settings.name != null) {
      return settings.name!;
    }

    // Extract screen name from route type
    final routeString = route.toString();
    if (routeString.contains('HomeScreen')) return 'HomeScreen';
    if (routeString.contains('DocumentListScreen')) return 'DocumentListScreen';
    if (routeString.contains('DocumentDetailScreen')) {
      return 'DocumentDetailScreen';
    }
    if (routeString.contains('ScannerScreen')) return 'ScannerScreen';
    if (routeString.contains('SettingsScreen')) return 'SettingsScreen';
    if (routeString.contains('LoginScreen')) return 'LoginScreen';
    if (routeString.contains('SplashScreen')) return 'SplashScreen';

    return 'unknown';
  }
}
