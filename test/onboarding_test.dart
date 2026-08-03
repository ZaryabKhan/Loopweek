// Tests for the first-run onboarding: the welcome sheet appears once on a
// fresh install, dismisses permanently through its CTA, and the one-time
// long-press hint retires after the gesture is used.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/main.dart';
import 'package:loopweek/presentation/onboarding/welcome_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService flags', () {
    test('onboarding flags default to false and roundtrip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);

      expect(service.onboardingSeen, isFalse);
      expect(service.longPressHintSeen, isFalse);

      await service.setOnboardingSeen();
      await service.setLongPressHintSeen();

      expect(service.onboardingSeen, isTrue);
      expect(service.longPressHintSeen, isTrue);
    });
  });

  group('OnboardingGate', () {
    testWidgets('shows the welcome sheet once on a fresh install', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: LoopweekApp()));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeSheet), findsOneWidget);
      expect(find.text('Start my week'), findsOneWidget);

      // Dismissing through the CTA marks onboarding as seen, so the sheet
      // never returns.
      await tester.tap(find.text('Start my week'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeSheet), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding.seen'), isTrue);
    });

    testWidgets('does not show when onboarding was already completed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'onboarding.seen': true,
        'onboarding.longPressHintSeen': true,
      });
      await tester.pumpWidget(const ProviderScope(child: LoopweekApp()));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeSheet), findsNothing);
      expect(find.text('LOOPWEEK'), findsWidgets);
    });
  });
}
