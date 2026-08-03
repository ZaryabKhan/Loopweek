// A smoke test that the Loopweek app builds and shows the top-of-page
// LOOPWEEK heading. A full UI suite should live in integration_test/.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loopweek/main.dart';

void main() {
  testWidgets('Loopweek renders week heading', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LoopweekApp()));
    expect(find.text('LOOPWEEK'), findsWidgets);
  });
}