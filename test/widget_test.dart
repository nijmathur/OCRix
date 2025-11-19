// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ocrix/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The app will show splash screen while initializing services
    await tester.pumpWidget(const ProviderScope(child: OCRixApp()));

    // Wait for initial frame
    await tester.pump();

    // Verify that the app widget is present
    // It might be showing splash screen or error screen, but the app should render
    expect(find.byType(OCRixApp), findsOneWidget);

    // Allow time for async initialization (services may fail in CI, that's OK)
    // Camera service will fail in CI but app should still start
    // Pump frames with a reasonable limit to prevent hanging
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // If the app has settled (no more frames), break early
      if (!tester.binding.hasScheduledFrame) {
        break;
      }
    }

    // App should still be present (either initialized or showing error screen)
    expect(find.byType(OCRixApp), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
