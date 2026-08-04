import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/day_header.dart';
import 'package:loopweek/presentation/week/task_tile.dart';
import 'package:loopweek/presentation/week/week_providers.dart';
import 'package:loopweek/presentation/task_sheet/task_edit_sheet.dart';
import 'package:loopweek/presentation/settings/settings_screen.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(today: today)),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            ...days(ref, dates, expanded, today, accent),
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
  const _TopBar({required this.today});
  final DateTime today;

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
                  DateFormat('MMMM yyyy').format(today),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Locale is surfaced as a visual affordance only — looping the week
          // view locale is not a feature yet, so this is not a tappable
          // control (no false affordance).
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.flag_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
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
  void _toggle() => ref.read(expandedDayProvider.notifier).state =
      widget.isExpanded ? null : widget.date;

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
          final muted =
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
          return Row(
            key: ValueKey(t.id),
            children: [
              Expanded(
                child: TaskTile(
                  task: t,
                  accent: accent,
                  onToggle: () async {
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
                    final themeMode = settings.themeMode;
                    final edited = await showModalBottomSheet<Task?>(
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
                    if (edited != null) {
                      await widgetSvc.pushTodaySnapshot(
                        accent: accentTag,
                        themeMode: themeMode,
                      );
                    }
                  },
                  onLongPress: () => _showQuickActions(context, ref, t.id),
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
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, elevation: 0, child: child),
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

  void _showQuickActions(BuildContext context, WidgetRef ref, String id) {
    final theme = Theme.of(context);
    final repo = ref.read(taskRepositoryProvider);
    final accentTag = ref.read(settingsProvider).colorTag;
    // The long-press gesture was just used — the hint has done its job.
    ref.read(settingsProvider).setLongPressHintSeen();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
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
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: const Text('Remove task'),
                onTap: () async {
                  final themeMode = ref.read(settingsProvider).themeMode;
                  await repo.deleteTask(id);
                  // Drop any pending reminder for the removed task.
                  await ref
                      .read(notificationServiceProvider)
                      .cancelTaskReminder(id);
                  await ref
                      .read(homeWidgetServiceProvider)
                      .pushTodaySnapshot(
                        accent: accentTag,
                        themeMode: themeMode,
                      );
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
            ],
          ),
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

    if (isToday) {
      final accentTag = ref.read(settingsProvider).colorTag;
      final themeMode = ref.read(settingsProvider).themeMode;
      await ref.read(homeWidgetServiceProvider).pushTodaySnapshot(
        accent: accentTag,
        themeMode: themeMode,
      );
    }
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
      onTap: () => _openEditor(context),
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
