import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_providers.dart';

/// Opens the past-weeks archive as a bottom sheet: every week before the
/// current one that holds at least one day-anchored task, newest first.
/// Pass [initialWeekStart] to open with that week already expanded.
Future<void> showArchiveSheet(
  BuildContext context, {
  DateTime? initialWeekStart,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArchiveSheet(initialWeekStart: initialWeekStart),
  );
}

/// One past week: its 7 dates plus the day-anchored tasks bucketed by day.
class _WeekBucket {
  _WeekBucket(this.weekStart, this.dates)
    : byDay = {for (final d in dates) d: <Task>[]};

  final DateTime weekStart;
  final List<DateTime> dates;
  final Map<DateTime, List<Task>> byDay;

  int get total => byDay.values.fold(0, (sum, tasks) => sum + tasks.length);

  int get done => byDay.values.fold(
    0,
    (sum, tasks) => sum + tasks.where((t) => t.isCompleted).length,
  );
}

class _ArchiveSheet extends ConsumerStatefulWidget {
  const _ArchiveSheet({this.initialWeekStart});

  final DateTime? initialWeekStart;

  @override
  ConsumerState<_ArchiveSheet> createState() => _ArchiveSheetState();
}

class _ArchiveSheetState extends ConsumerState<_ArchiveSheet> {
  List<_WeekBucket>? _weeks;
  DateTime? _expanded;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWeekStart;
    if (initial != null) {
      _expanded = DateTime(initial.year, initial.month, initial.day);
    }
    _load();
  }

  /// One-shot snapshot read — the archive is history, not live state.
  Future<void> _load() async {
    final firstDay = ref.read(settingsProvider).firstDayOfWeek;
    final today = ref.read(todayProvider);
    final all = await ref.read(taskRepositoryProvider).getAllTasks();

    final currentWeekStart = weekDatesFor(today, firstDay).first;
    final buckets = <DateTime, _WeekBucket>{};
    for (final task in all) {
      if (task.isSomeday) continue;
      final weekStart = weekDatesFor(task.date, firstDay).first;
      if (!weekStart.isBefore(currentWeekStart)) continue;
      final bucket = buckets.putIfAbsent(
        weekStart,
        () => _WeekBucket(weekStart, weekDatesFor(weekStart, firstDay)),
      );
      final day = DateTime(task.date.year, task.date.month, task.date.day);
      bucket.byDay[day]!.add(task);
    }

    for (final bucket in buckets.values) {
      for (final tasks in bucket.byDay.values) {
        tasks.sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
        });
      }
    }
    final weeks =
        buckets.values.toList()..sort((a, b) => b.weekStart.compareTo(a.weekStart));

    if (mounted) setState(() => _weeks = weeks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = _weeks;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Past weeks',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: weeks == null
                  ? const SizedBox.shrink()
                  : weeks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No past weeks yet.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your finished weeks will collect here.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: weeks.length,
                      itemBuilder: (context, index) {
                        final week = weeks[index];
                        return _WeekRow(
                          week: week,
                          expanded: DateUtils.isSameDay(
                            _expanded,
                            week.weekStart,
                          ),
                          onToggle: () {
                            Haptics.light();
                            setState(() {
                              _expanded = DateUtils.isSameDay(
                                _expanded,
                                week.weekStart,
                              )
                                  ? null
                                  : week.weekStart;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.expanded,
    required this.onToggle,
  });

  final _WeekBucket week;
  final bool expanded;
  final VoidCallback onToggle;

  String get _rangeLabel =>
      '${DateFormat('MMM d').format(week.dates.first)} – '
      '${DateFormat('MMM d').format(week.dates.last)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          excludeSemantics: true,
          label: '$_rangeLabel, ${week.done} of ${week.total} done',
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_rangeLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${week.done} of ${week.total} done',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Semantics(
            readOnly: true,
            hint: 'Read-only preview',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final date in week.dates) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        DateFormat('EEE d').format(date),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    for (final task in week.byDay[date] ?? const <Task>[])
                      _ReadOnlyTaskRow(task: task),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Frozen copy of a task row: a plain divider-colored square stands in for
/// the checkbox and nothing here toggles, edits or reorders.
class _ReadOnlyTaskRow extends StatelessWidget {
  const _ReadOnlyTaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = task.isCompleted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: theme.dividerColor, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed
                    ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)
                    : null,
              ),
            ),
          ),
          if (task.hasTime && task.time != null) ...[
            const SizedBox(width: 8),
            Text(
              '${task.time!.hour.toString().padLeft(2, '0')}:'
              '${task.time!.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
