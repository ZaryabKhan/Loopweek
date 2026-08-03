import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:loopweek/data/database/database.dart';
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loopweek',
      theme: settings.lightTheme(),
      darkTheme: settings.darkTheme(),
      themeMode: settings.themeMode,
      home: KeyedSubtree(
        key: ValueKey(settings.colorTag),
        child: const WeekView(),
      ),
    );
  }
}
