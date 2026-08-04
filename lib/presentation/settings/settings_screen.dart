import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/settings/dummy_data.dart';
import 'package:loopweek/presentation/week/week_providers.dart';
import 'package:loopweek/presentation/week/week_view.dart';
import 'package:loopweek/presentation/widgets/accent_segmented.dart';

const _swatchLabel = {
  ColorTag.orange: 'Orange',
  ColorTag.pink: 'Pink',
  ColorTag.blue: 'Blue',
  ColorTag.green: 'Green',
};

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _gestureTapCount = 0;
  Timer? _gestureTapTimer;

  @override
  void dispose() {
    _gestureTapTimer?.cancel();
    super.dispose();
  }

  void _onGestureTap() {
    setState(() {
      _gestureTapCount += 1;
    });
    _gestureTapTimer?.cancel();
    // Reset the count if the user stops tapping within this window.
    _gestureTapTimer = Timer(const Duration(milliseconds: 1000), () {
      setState(() => _gestureTapCount = 0);
    });

    if (_gestureTapCount >= 7) {
      _gestureTapTimer?.cancel();
      setState(() => _gestureTapCount = 0);
      _showTestingModeDialog();
    }
  }

  void _showTestingModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Testing mode'),
        content: const Text(
          'This will add dummy data to all 7 days and replace any existing '
          'data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _populateDummyData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dummy data populated for this week.'),
                  ),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _populateDummyData() async {
    final repo = ref.read(taskRepositoryProvider);
    final today = ref.read(todayProvider);
    await repo.clearAllTasks();
    final tasks = buildDummyTasksForWeek(today);
    await repo.insertTaskBatch(tasks);
    final settings = ref.read(settingsProvider);
    await ref
        .read(homeWidgetServiceProvider)
        .pushTodaySnapshot(
          accent: settings.colorTag,
          themeMode: settings.themeMode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Settings', style: theme.textTheme.headlineMedium),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _LabelRow('Task Colour'),
            const SizedBox(height: 8),
            const _ColorSwatch(),
            const SizedBox(height: 8),
            Text(
              'Used for checkboxes, toggles, and the home-screen widget accent.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _LabelRow('Appearance'),
            const SizedBox(height: 8),
            const _ThemeSelector(),
            const SizedBox(height: 24),
            _LabelRow('Times & Alerts'),
            const SizedBox(height: 8),
            _TimesAndAlerts(),
            const SizedBox(height: 24),
            _LabelRow('Also on your home screen'),
            const SizedBox(height: 8),
            const _WidgetPreview(),
            const SizedBox(height: 24),
            _LabelRow('Gestures'),
            const SizedBox(height: 8),
            _GestureField(tapCount: _gestureTapCount, onTap: _onGestureTap),
            const SizedBox(height: 8),
            Text(
              'Hold to remove tasks or reorder by time and priority.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          letterSpacing: 1.0,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ColorSwatch extends ConsumerWidget {
  const _ColorSwatch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ColorTag.values.map((tag) {
        final selected = active.colorTag == tag;
        final color = AccentColors.of(tag);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                final themeMode = active.themeMode;
                await active.setColorTag(tag);
                await ref
                    .read(homeWidgetServiceProvider)
                    .pushTodaySnapshot(accent: tag, themeMode: themeMode);
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.0)
                        : Colors.transparent,
                    width: 0,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 28,
                        color: AccentColors.onAccentOf(color),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _swatchLabel[tag] ?? tag.name,
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(settingsProvider);
    return AccentSegmented<ThemeMode>(
      value: active.themeMode,
      options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
      labelOf: (mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      },
      onChanged: (mode) async {
        // The widget receives the raw mode; "system" is resolved natively.
        await active.setThemeMode(mode);
        await ref
            .read(homeWidgetServiceProvider)
            .pushTodaySnapshot(accent: active.colorTag, themeMode: mode);
      },
    );
  }
}

class _TimesAndAlerts extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TimesAndAlerts> createState() => _TimesAndAlertsState();
}

class _TimesAndAlertsState extends ConsumerState<_TimesAndAlerts> {
  bool _alerts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await ref.read(sharedPreferencesProvider.future);
    setState(() {
      _alerts = sp.getBool('settings.alertsEnabled') ?? false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final notif = ref.read(notificationServiceProvider);
      final granted = await notif.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications were not allowed.')),
          );
        }
        return;
      }
    }
    final sp = await ref.read(sharedPreferencesProvider.future);
    await sp.setBool('settings.alertsEnabled', value);
    setState(() => _alerts = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Get a notification when you set a reminder on a task. '
              'Loopweek never asks for permission unless you turn this on.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: _alerts, onChanged: _toggle),
        ],
      ),
    );
  }
}

class _WidgetPreview extends ConsumerWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final accentTag = ref.watch(settingsProvider).colorTag;
    final accent = AccentColors.of(accentTag);
    final onAccent = AccentColors.onAccentOf(accent);
    final theme = Theme.of(context);
    final todayTasks =
        ref.watch(tasksForDateProvider(today)).valueOrNull ?? const [];

    // Mirrors the home widget: incomplete first, then today's tasks capped.
    final ordered = [...todayTasks]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return 0;
      });
    final shown = ordered.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Today \u00B7 ${WeekView.weekdayNames[today.weekday % 7]}',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Text('Nothing on the list yet.', style: theme.textTheme.bodySmall),
          for (final t in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: t.isCompleted ? accent : theme.dividerColor,
                        width: 2,
                      ),
                      color: t.isCompleted ? accent : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: t.isCompleted
                        ? Icon(Icons.check, size: 12, color: onAccent)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: t.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: t.isCompleted
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.5,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GestureField extends StatelessWidget {
  const _GestureField({required this.tapCount, required this.onTap});

  final int tapCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = tapCount > 0 ? '$tapCount / 7' : 'Gestures';
    return Material(
      type: MaterialType.button,
      borderRadius: BorderRadius.circular(12),
      color: theme.cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.gesture_outlined, size: 20),
              const SizedBox(width: 10),
              Text(label, style: theme.textTheme.titleMedium),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
