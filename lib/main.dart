import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/presentation/onboarding/welcome_sheet.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock flow to portrait on phones so the week view stays compact. Set once
  // at process start; rebuilding the app does not need to re-apply it.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Allow the home-screen widget's checkbox taps to toggle completion in a
  // background isolate without opening the app. Registered once at startup.
  HomeWidget.registerInteractivityCallback(_widgetToggleCallback);

  runApp(const ProviderScope(child: LoopweekApp()));
}

/// Runs in a background isolate when the user taps a widget checkbox. The
/// widget encodes the tapped task id as `loopweek://toggle?id=<taskId>`.
@pragma('vm:entry-point')
Future<void> _widgetToggleCallback(Uri? uri) async {
  if (uri == null || uri.host != 'toggle') return;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'loopweek.db'));
    final executor = NativeDatabase.createInBackground(file);
    final db = LoopweekDatabase.forTesting(executor);
    await db.customStatement(
      'UPDATE tasks SET is_completed = (1 - is_completed) WHERE id = ?;',
      [id],
    );
    await db.close();
  } catch (e) {
    debugPrint('widget toggle callback error: $e');
  }
}

class LoopweekApp extends ConsumerWidget {
  const LoopweekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Keep the lightweight haptics helper in sync with the user's toggle.
    Haptics.enabled = settings.hapticsEnabled;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loopweek',
      theme: settings.lightTheme(),
      darkTheme: settings.darkTheme(),
      themeMode: settings.themeMode,
      home: OnboardingGate(
        child: KeyedSubtree(
          key: ValueKey(settings.colorTag),
          child: const ReminderBootstrapper(child: WeekView()),
        ),
      ),
    );
  }
}

/// Runs the one-shot reminder reconciliation right after the first frame.
///
/// Scheduled notifications are the one feature that can be silently lost
/// behind the app's back (force-stop, plugin cache wipe, alarms dropped by
/// the OS, ids from an older build). Reconciling against the database on
/// every start makes reminders self-healing instead.
class ReminderBootstrapper extends ConsumerStatefulWidget {
  const ReminderBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderBootstrapper> createState() =>
      _ReminderBootstrapperState();
}

class _ReminderBootstrapperState extends ConsumerState<ReminderBootstrapper> {
  /// The subtree is re-keyed whenever the accent color changes; the sync must
  /// still run only once per process.
  static bool _syncStarted = false;

  @override
  void initState() {
    super.initState();
    if (_syncStarted) return;
    _syncStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Kick-and-forget: the provider captures the result (and any error is
      // logged inside the provider itself, never thrown here).
      unawaited(ref.read(reminderSyncProvider.future));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
