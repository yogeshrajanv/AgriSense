import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/main.dart';

void main() {
  testWidgets('AgriSense App renders Scaffold and NavigationBar',
      (WidgetTester tester) async {
    // Suppress image loading errors in test environment (no network)
    final List<FlutterErrorDetails> errors = [];
    FlutterError.onError = (details) => errors.add(details);

    await tester.pumpWidget(const AgriSenseApp());
    // Allow first frame to settle (ignore image network errors)
    await tester.pump();

    // Core structure checks — Scaffold and NavigationBar must be present
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Bottom nav should have 5 destinations
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    // Reset error handler
    FlutterError.onError = FlutterError.presentError;

    // Filter out only Flutter framework errors (not network image ones)
    final frameworkErrors = errors.where(
      (e) => !e.exception.toString().contains('NetworkImage') &&
             !e.exception.toString().contains('HTTP'),
    );
    expect(frameworkErrors, isEmpty,
        reason: 'Unexpected Flutter framework errors: $frameworkErrors');
  });
}
