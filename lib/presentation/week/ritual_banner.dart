import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/presentation/archive/archive_sheet.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/settings/template_sheets.dart';
import 'package:loopweek/presentation/week/week_providers.dart';

/// Snapshot the fresh-week ritual banner needs: this week's start, the
/// previous week's task totals, and the two prefs gates (last-seen week,
/// per-week dismissal).
class RitualBannerData {
  const RitualBannerData({
    required this.weekStart,
    required this.previousWeekStart,
    required this.previousWeekTotal,
    required this.previousWeekDone,
    required this.lastSeenWeekStart,
    required this.dismissed,
  });

  final DateTime weekStart;
  final DateTime previousWeekStart;
  final int previousWeekTotal;
  final int previousWeekDone;
  final String? lastSeenWeekStart;
  final bool dismissed;
}

/// Re-runs whenever today (or the first-day setting) changes, so a week
/// rollover — including across resume — re-evaluates the banner.
final ritualBannerDataProvider = FutureProvider<RitualBannerData?>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (!settings.isLoaded) return null; // load() notifies, re-running this.

  final weekStart =
      weekDatesFor(ref.watch(todayProvider), settings.firstDayOfWeek).first;
  final previousWeekStart = weekStart.subtract(const Duration(days: 7));

  final sp = await ref.watch(sharedPreferencesProvider.future);
  final prefs = SettingsService(sp);

  // One-shot snapshot read, same as the archive sheet: last week is history,
  // not live state. Parked (Someday) tasks keep a date but never belong to a
  // day section, so they don't count.
  final tasks = await ref.watch(taskRepositoryProvider).getAllTasks();
  var total = 0;
  var done = 0;
  for (final task in tasks) {
    if (task.isSomeday) continue;
    final date = DateTime(task.date.year, task.date.month, task.date.day);
    if (date.isBefore(previousWeekStart) || !date.isBefore(weekStart)) {
      continue;
    }
    total++;
    if (task.isCompleted) done++;
  }

  final weekIso = _weekIso(weekStart);
  return RitualBannerData(
    weekStart: weekStart,
    previousWeekStart: previousWeekStart,
    previousWeekTotal: total,
    previousWeekDone: done,
    lastSeenWeekStart: prefs.ritualLastSeenWeekStart,
    dismissed: prefs.isRitualBannerDismissed(weekIso),
  );
});

/// Date-only ISO string (yyyy-MM-dd) used for ritual prefs keys and values.
String _weekIso(DateTime d) => d.toIso8601String().split('T').first;

/// Fresh-week banner (SPEC-9): on the first build of a week that follows a
/// populated one, summarizes last week and offers to seed the new week from
/// a template or peek at the archive.
///
/// Arming writes lastSeenWeekStart immediately, so the armed condition goes
/// false on the next build and on every later session — the [_RitualBanner]
/// state below keeps it visible for the rest of the session until dismissed,
/// which sets the per-week prefs flag.
class RitualBanner extends ConsumerStatefulWidget {
  const RitualBanner({super.key});

  @override
  ConsumerState<RitualBanner> createState() => _RitualBannerState();
}

class _RitualBannerState extends ConsumerState<RitualBanner> {
  String? _shownWeekIso;
  String? _dismissedWeekIso;

  void _markSeen(String weekIso) {
    if (_shownWeekIso == weekIso) return;
    _shownWeekIso = weekIso;
    final sp = ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp != null) SettingsService(sp).setRitualLastSeenWeekStart(weekIso);
  }

  Future<void> _dismiss(String weekIso) async {
    final sp = ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setRitualBannerDismissed(weekIso);
    if (mounted) setState(() => _dismissedWeekIso = weekIso);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(ritualBannerDataProvider).valueOrNull;
    final templates =
        ref.watch(weekTemplatesProvider).valueOrNull ?? const [];
    if (data == null) return const SizedBox.shrink();

    final weekIso = _weekIso(data.weekStart);
    final armed =
        data.lastSeenWeekStart != weekIso &&
        data.previousWeekTotal > 0 &&
        !data.dismissed;
    if (armed) _markSeen(weekIso);
    final dismissed = data.dismissed || _dismissedWeekIso == weekIso;
    if (dismissed || !(armed || _shownWeekIso == weekIso)) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label:
          'Fresh week, last week ${data.previousWeekDone} done, '
          'actions available',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fresh week. Last week: ${data.previousWeekDone} done.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Dismiss',
                    onPressed: () {
                      Haptics.light();
                      _dismiss(weekIso);
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (templates.isNotEmpty)
                  _BannerAction(
                    label: 'Start from template',
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    onTap: () => showApplyTemplateSheet(context),
                  ),
                _BannerAction(
                  label: 'Peek at last week',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  onTap: () => showArchiveSheet(
                    context,
                    initialWeekStart: data.previousWeekStart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat 40dp TextButton with a labelLarge label.
class _BannerAction extends StatelessWidget {
  const _BannerAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.fontWeight,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () {
        Haptics.light();
        onTap();
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
