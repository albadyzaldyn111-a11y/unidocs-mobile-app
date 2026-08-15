import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:unidocs_mobile/app.dart';

/// Run with a live backend reachable at the configured API_BASE_URL:
///   flutter test integration_test/app_test.dart \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8000
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash redirects to onboarding when logged out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UniDocsApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('تخطي'), findsOneWidget);
  });

  testWidgets('login screen renders required fields', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UniDocsApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate from onboarding to login.
    final skipButton = find.text('تخطي');
    if (skipButton.evaluate().isNotEmpty) {
      await tester.tap(skipButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
