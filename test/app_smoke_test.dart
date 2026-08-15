import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unidocs_mobile/app.dart';

void main() {
  testWidgets('App boots to splash screen without throwing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: UniDocsApp()));
    await tester.pump();

    expect(find.text('UniDocs'), findsWidgets);
  });
}
