import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';

import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/archive/archive_sheet.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/day_header.dart';
import 'package:loopweek/presentation/week/ritual_banner.dart';
import 'package:loopweek/presentation/week/task_tile.dart';
import 'package:loopweek/presentation/week/week_providers.dart';
import 'package:loopweek/presentation/week/someday_sheet.dart';
import 'package:loopweek/presentation/task_sheet/task_edit_sheet.dart';
import 'package:loopweek/presentation/settings/settings_screen.dart';
import 'package:loopweek/presentation/widgets/accent_segmented.dart';
import 'package:loopweek/core/theme/accent_colors.dart';

/// Main week view — one screen, seven days, nothing else.
///
/// Vertical list of all 7 day sections. Today is expanded by default. Only
/// one day is expanded at a time (accordion). Each expanded section shows its
/// tasks and an "Add a new task..." row pinned at the bottom with a + button.
class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  static const weekdayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final dates = ref.watch(weekDatesProvider);
    final expanded = ref.watch(expandedDayProvider);
    final accentTag = ref.watch(settingsProvider).colorTag;
    final accent = AccentColors.of(accentTag);
    final somedayCount =
        ref.watch(somedayTasksProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(shownWeekStart: dates.first)),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            const SliverToBoxAdapter(child: _WeekSwitcher()),
            const SliverToBoxAdapter(child: RitualBanner()),
            ...days(ref, dates, expanded, today, accent),
            if (somedayCount > 0)
              SliverToBoxAdapter(
                child: _SomedayStrip(
                  count: somedayCount,
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SomedaySheet(),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  List<Widget> days(
    WidgetRef ref,
    List<DateTime> dates,
    DateTime? expanded,
    DateTime today,
    Color accent,
  ) {
    final widgets = <Widget>[];
    for (final date in dates) {
      final bool isExpanded = expanded == null
          ? date == today
          : date == expanded;
      widgets.add(
        SliverToBoxAdapter(
          key: ValueKey('day-${date.toIso8601String()}'),
          child: _DaySection(
            date: date,
            isToday: date == today,
            isExpanded: isExpanded,
            accent: accent,
          ),
        ),
      );
      widgets.add(const SliverToBoxAdapter(child: Divider(height: 1)));
    }
    return widgets;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.shownWeekStart});
  final DateTime shownWeekStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOOPWEEK',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM yyyy').format(shownWeekStart),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Past weeks',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            onPressed: () {
              Haptics.light();
              showArchiveSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}

/// This-week / next-week segmented swap. Session-only: switching re-anchors
/// the accordion to the matching week's "today" position so exactly one day
/// stays open with the same orientation.
class _WeekSwitcher extends ConsumerWidget {
  const _WeekSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(weekOffsetProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AccentSegmented<int>(
        value: offset,
        options: const [0, 7],
        labelOf: (offset) => offset == 0 ? 'This week' : 'Next week',
        onChanged: (value) {
          Haptics.selection();
          ref.read(weekOffsetProvider.notifier).state = value;
          final today = ref.read(todayProvider);
          ref.read(expandedDayProvider.notifier).state =
              value == 0 ? today : today.add(const Duration(days: 7));
        },
      ),
    );
  }
}

/// Flat row under the last day section opening the Someday parking sheet.
/// Hidden entirely when nothing is parked.
class _SomedayStrip extends StatelessWidget {
  const _SomedayStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Someday, $count tasks',
      child: InkWell(
        onTap: () {
          Haptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SOMEDAY · $count',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySection extends ConsumerStatefulWidget {
  const _DaySection({
    required this.date,
    required this.isToday,
    required this.isExpanded,
    required this.accent,
  });

  final DateTime date;
  final bool isToday;
  final bool isExpanded;
  final Color accent;

  @override
  ConsumerState<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends ConsumerState<_DaySection> {
  void _toggle() {
    Haptics.light();
    ref.read(expandedDayProvider.notifier).state =
        widget.isExpanded ? null : widget.date;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayHeader(
          weekdayName: WeekView.weekdayNames[widget.date.weekday % 7],
          monthDay: DateFormat('MMMM d').format(widget.date),
          isToday: widget.isToday,
          isExpanded: widget.isExpanded,
          onTap: _toggle,
          onAddTapped: () => _openEditor(context),
        ),
        // Note: no Slide/ClipRect — we just conditionally render body so the
        // accordion collapses cleanly under the divider.
        if (widget.isExpanded)
          _Body(
            date: widget.date,
            isToday: widget.isToday,
            accent: widget.accent,
          ),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: TaskEditSheet(date: widget.date),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.date,
    required this.isToday,
    required this.accent,
  });
  final DateTime date;
  final bool isToday;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTasks = ref.watch(tasksForDateProvider(date));
    final repo = ref.watch(taskRepositoryProvider);
    final widgetSvc = ref.watch(homeWidgetServiceProvider);
    final settings = ref.watch(settingsProvider);
    final accentTag = settings.colorTag;
    // While the count loads, assume a populated week so the orientation never
    // flashes on a returning user's screen.
    final hasAnyTasks = ref.watch(hasAnyTasksProvider).valueOrNull ?? true;

    return asyncTasks.maybeWhen(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isToday && !hasAnyTasks) const _FirstTaskOrientation(),
              _AddRow(date: date, accent: accent),
            ],
          );
        }

        Widget buildRow(int index, Task t) {
          final muted = Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.45);
          return Row(
            key: ValueKey(t.id),
            children: [
              Expanded(
                child: TaskTile(
                  task: t,
                  accent: accent,
                  onToggle: () async {
                    Haptics.light();
                    final themeMode = settings.themeMode;
                    await repo.setCompleted(
                      id: t.id,
                      completed: !t.isCompleted,
                    );
                    await widgetSvc.pushTodaySnapshot(
                      accent: accentTag,
                      themeMode: themeMode,
                    );
                  },
                  onTap: () async {
                    Haptics.light();
                    final themeMode = settings.themeMode;
                    final result = await showModalBottomSheet<TaskEditResult?>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                        ),
                        child: TaskEditSheet(task: t, date: date),
                      ),
                    );
                    if (result != null) {
                      switch (result) {
                        case TaskEditDeleted(:final task):
                          if (context.mounted) {
                            _showRemovedTaskSnackbar(context, ref, task);
                          }
                        case TaskEditSaved():
                          break;
                      }
                      await widgetSvc.pushTodaySnapshot(
                        accent: accentTag,
                        themeMode: themeMode,
                      );
                    }
                  },
                  onLongPress: () {
                    Haptics.medium();
                    _showQuickActions(context, ref, t);
                  },
                ),
              ),
              // Drag the grip to reorder within the day. The grip is the only
              // reorder target, so tap / check / long-press on the row are
              // left untouched.
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.drag_handle, size: 20, color: muted),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              // Keep the flat look while dragging: no shadow on the proxy.
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 0,
                child: child,
              ),
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) =>
                  _reorder(context, ref, date, oldIndex, newIndex, tasks),
              children: [
                for (var i = 0; i < tasks.length; i++) buildRow(i, tasks[i]),
              ],
            ),
            if (!settings.longPressHintSeen) const _LongPressHint(),
            _AddRow(date: date, accent: accent),
          ],
        );
      },
      orElse: () => const SizedBox(height: 8),
    );
  }

  Future<void> _showQuickActions(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    // The long-press gesture was just used — the hint has done its job.
    ref.read(settingsProvider).setLongPressHintSeen();
    final removed = await showModalBottomSheet<Task?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickActionsSheet(task: task),
    );
    if (removed != null && context.mounted) {
      _showRemovedTaskSnackbar(context, ref, removed);
    }
  }

  /// Floating undo snackbar after a removal (quick-actions or the edit
  /// sheet's Remove task button). Undo re-inserts the exact captured row —
  /// same id, so date, completion, color, time, reminder, recurrence parent
  /// and sort order all ride along — and re-arms its reminder through the
  /// editor's post-save path minus the permission re-request: the reminder
  /// existed before the delete, so this is never an opt-in moment.
  void _showRemovedTaskSnackbar(
    BuildContext context,
    WidgetRef ref,
    Task removed,
  ) {
    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    final widgetSvc = ref.read(homeWidgetServiceProvider);
    final settings = ref.read(settingsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task removed'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await repo.insertTask(removed);
            if (removed.isSomeday) {
              // Parked tasks never fire reminders.
              await notif.cancelTaskReminder(removed.id);
            } else if (removed.hasReminder && settings.alertsEnabled) {
              final fire = NotificationService.fireDateTimeFor(removed);
              if (fire.isAfter(DateTime.now())) {
                await notif.scheduleTaskReminder(
                  taskId: removed.id,
                  title: removed.title,
                  scheduled: fire,
                );
              }
            }
            await widgetSvc.pushTodaySnapshot(
              accent: settings.colorTag,
              themeMode: settings.themeMode,
            );
          },
        ),
      ),
    );
  }

  /// Persists a drag-reorder of one day's tasks (ordered ids -> new sortOrder)
  /// and refreshes the home widget when the reordered day is today.
  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    int oldIndex,
    int newIndex,
    List<Task> tasks,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final ordered = tasks.map((t) => t.id).toList();
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    await ref
        .read(taskRepositoryProvider)
        .reorderTasksForDate(date: date, orderedIds: ordered);

    Haptics.light();

    if (isToday) {
      final accentTag = ref.read(settingsProvider).colorTag;
      final themeMode = ref.read(settingsProvider).themeMode;
      await ref
          .read(homeWidgetServiceProvider)
          .pushTodaySnapshot(accent: accentTag, themeMode: themeMode);
    }
  }
}

/// Long-press quick actions for one task row: move it to another day (or
/// park it) via a compact day picker, or remove it with an undo snackbar.
class _QuickActionsSheet extends ConsumerStatefulWidget {
  const _QuickActionsSheet({required this.task});

  final Task task;

  @override
  ConsumerState<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends ConsumerState<_QuickActionsSheet> {
  bool _pickingDay = false;

  Future<void> _pushWidget() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(homeWidgetServiceProvider)
        .pushTodaySnapshot(
          accent: settings.colorTag,
          themeMode: settings.themeMode,
        );
  }

  Future<void> _moveToDay(DateTime date) async {
    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    final settings = ref.read(settingsProvider);

    try {
      await repo.moveTaskToEndOfDay(id: widget.task.id, date: date);
    } catch (_) {
      // Rare: an occurrence dropped onto a date its rule already
      // materialized violates the (parent, date) unique index.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not move the task.')),
        );
      }
      return;
    }
    Haptics.light();

    // Re-arm the reminder at the new fire time, exactly like the someday
    // sheet's move path.
    final moved = await repo.getTask(widget.task.id);
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
        );
      }
    }

    await _pushWidget();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _park() async {
    final task = widget.task;
    // A recurring rule must stay day-anchored — parking it would strand the
    // whole schedule. Occurrences park fine (their row id is what moves).
    if (task.recurrenceParentId == null && task.recurrence.isRecurring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring tasks need a day.')),
      );
      return;
    }

    final repo = ref.read(taskRepositoryProvider);
    await repo.setSomeday(id: task.id, someday: true);
    // Parked tasks never fire reminders, same as the editor's save path.
    await ref.read(notificationServiceProvider).cancelTaskReminder(task.id);
    await _pushWidget();
    Haptics.light();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    // Capture the full row before it is gone so Undo can restore it exactly.
    final captured = await repo.getTask(widget.task.id) ?? widget.task;
    await repo.deleteTask(captured.id);
    // Drop any pending reminder for the removed task; Undo re-arms it.
    await notif.cancelTaskReminder(captured.id);
    await _pushWidget();
    Haptics.light();
    if (mounted) Navigator.of(context).pop(captured);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekDates = ref.watch(weekDatesProvider);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (_pickingDay)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final date in weekDates)
                      _MoveDayChip(
                        label: DateFormat('EEE d').format(date),
                        selected: DateUtils.isSameDay(date, widget.task.date),
                        onTap: () => _moveToDay(date),
                      ),
                    _MoveDayChip(
                      label: 'Someday',
                      selected: false,
                      onTap: _park,
                    ),
                  ],
                ),
              )
            else ...[
              ListTile(
                leading: Icon(
                  Icons.event_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Move to another day…'),
                onTap: () {
                  Haptics.light();
                  setState(() => _pickingDay = true);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: const Text('Remove task'),
                onTap: _remove,
              ),
              ListTile(
                leading: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: const Text('Cancel'),
                onTap: () {
                  Haptics.light();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Compact outlined day chip for the quick-actions move picker — same visual
/// family as the editor's Someday toggle chip; the task's current day shows
/// in the accent color.
class _MoveDayChip extends StatelessWidget {
  const _MoveDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: selected
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: selected ? 1.5 : 1,
        ),
        backgroundColor: selected ? accent.withValues(alpha: 0.12) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: selected
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.date, required this.accent});
  final DateTime date;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Haptics.light();
        _openEditor(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Add a new task...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: TaskEditSheet(date: date),
      ),
    );
  }
}

/// Shown in today's expanded section when the whole week is empty: what will
/// be here and how to start. The add row directly below is the action.
class _FirstTaskOrientation extends StatelessWidget {
  const _FirstTaskOrientation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing here yet.',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first task below. It stays on its day until you move it.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// One-time inline hint for the undiscoverable gesture. Disappears forever
/// once tapped, or as soon as the user long-presses any task.
class _LongPressHint extends ConsumerWidget {
  const _LongPressHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Hold a task to remove it. Activate to dismiss this hint.',
      child: InkWell(
        onTap: () => ref.read(settingsProvider).setLongPressHintSeen(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.pan_tool_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hold a task to remove it.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
