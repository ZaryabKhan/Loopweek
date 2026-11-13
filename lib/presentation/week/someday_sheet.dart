import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_providers.dart';

/// Bottom sheet listing parked (Someday) tasks. Each row offers a compact day
/// picker — the shown week's 7 days plus a Next-week shortcut — that unparks
/// the task to the end of the chosen day and re-arms its reminder.
class SomedaySheet extends ConsumerStatefulWidget {
  const SomedaySheet({super.key});

  @override
  ConsumerState<SomedaySheet> createState() => _SomedaySheetState();
}

class _SomedaySheetState extends ConsumerState<SomedaySheet> {
  String? _pickerForId;

  Future<void> _moveTo(Task task, DateTime date) async {
    Haptics.light();
    setState(() => _pickerForId = null);

    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    final widgetSvc = ref.read(homeWidgetServiceProvider);
    final settings = ref.read(settingsProvider);

    try {
      await repo.moveTaskToEndOfDay(id: task.id, date: date);
    } catch (e) {
      // Rare: a parked occurrence dropped onto a date its rule already
      // materialized violates the (parent, date) unique index.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not move the task.')),
        );
      }
      return;
    }

    // Re-arm the reminder exactly like the editor's save flow does for a
    // single non-recurring task (parked tasks are never recurring rules).
    final moved = await repo.getTask(task.id);
    if (moved != null &&
        moved.hasReminder &&
        settings.alertsEnabled &&
        await notif.requestPermission()) {
      final fire = NotificationService.fireDateTimeFor(moved);
      if (fire.isAfter(DateTime.now())) {
        await notif.scheduleTaskReminder(
          taskId: moved.id,
          title: moved.title,
          scheduled: fire,
          taskDate: moved.date,
          accent: AccentColors.of(settings.colorTag),
        );
      }
    }

    await widgetSvc.pushTodaySnapshot(
      accent: settings.colorTag,
      themeMode: settings.themeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(somedayTasksProvider).valueOrNull ?? const <Task>[];
    final weekDates = ref.watch(weekDatesProvider);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Someday',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${tasks.length} waiting',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Someday is empty.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Park a task with the Someday chip in the task '
                            'editor.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _SomedayRow(
                          task: task,
                          weekDates: weekDates,
                          pickerOpen: _pickerForId == task.id,
                          onTogglePicker: () {
                            Haptics.light();
                            setState(() {
                              _pickerForId = _pickerForId == task.id
                                  ? null
                                  : task.id;
                            });
                          },
                          onPick: (date) => _moveTo(task, date),
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

class _SomedayRow extends StatelessWidget {
  const _SomedayRow({
    required this.task,
    required this.weekDates,
    required this.pickerOpen,
    required this.onTogglePicker,
    required this.onPick,
  });

  final Task task;
  final List<DateTime> weekDates;
  final bool pickerOpen;
  final VoidCallback onTogglePicker;
  final ValueChanged<DateTime> onPick;

  String get _parkedCaption => DateFormat('MMM d').format(task.date);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: '${task.title}, parked $_parkedCaption',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: theme.textTheme.bodyLarge),
                      Text(
                        'parked $_parkedCaption',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: onTogglePicker,
                child: const Text('Move to day…'),
              ),
            ],
          ),
        ),
        if (pickerOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final date in weekDates)
                  _DayChip(
                    label: DateFormat('EEE d').format(date),
                    onTap: () => onPick(date),
                  ),
                _DayChip(
                  label: 'Next week',
                  onTap: () =>
                      onPick(weekDates.first.add(const Duration(days: 7))),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact outlined day chip, same visual family as the editor's Someday
/// toggle chip.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
