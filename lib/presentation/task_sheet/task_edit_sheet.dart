import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_providers.dart';
import 'package:loopweek/presentation/week/week_view.dart' show WeekView;
import 'package:loopweek/presentation/widgets/accent_segmented.dart';

/// Modal sheet for adding or editing a task. Slides up from the bottom.
///
/// Header: Cancel (left) — "New Task"/"Edit Task" (center, bold) — Add/Save
/// (right, accent). Sections sit in rounded cards. Day / Repeat (segmented) /
/// Time (toggle + picker) / Reminder (toggle + Day/At preview).
class TaskEditSheet extends ConsumerStatefulWidget {
  const TaskEditSheet({super.key, this.task, required this.date});

  /// When provided, the sheet edits this task; otherwise it creates a new one.
  final Task? task;
  final DateTime date;

  @override
  ConsumerState<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends ConsumerState<TaskEditSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.task?.title ?? '',
  );
  late Recurrence _recurrence = widget.task?.recurrence ?? Recurrence.never;
  late DateTime _date = widget.task?.date ?? widget.date;
  late bool _hasTime = widget.task?.hasTime ?? false;
  late TimeOfDay _time = widget.task?.time ?? TimeOfDay.now();
  late bool _hasReminder = widget.task?.hasReminder ?? false;
  late int _reminderOffsetDays = 0;

  final _focusNode = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.task == null) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      widget.task == null ? 'New Task' : 'Edit Task',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _saving ? null : _onSave,
                      child: Text(
                        widget.task == null ? 'Add' : 'Save',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Title field with underline.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _titleController,
                  focusNode: _focusNode,
                  style: theme.textTheme.titleLarge,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Task name',
                    hintStyle: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _onSave(),
                ),
              ),

              const SizedBox(height: 16),

              // Day section.
              _SectionCard(
                child: _Row(
                  label: 'Day',
                  action: Text(
                    'Scheduled for',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  rightChild: InkWell(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEE, MMM d').format(_date),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Repeat section.
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Text(
                        'Repeat',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: AccentSegmented<Recurrence>(
                        value: _recurrence,
                        options: const [
                          Recurrence.never,
                          Recurrence.daily,
                          Recurrence.weekly,
                        ],
                        labelOf: (r) => switch (r) {
                          Recurrence.never => 'Never',
                          Recurrence.daily => 'Daily',
                          Recurrence.weekly => 'Weekly',
                        },
                        onChanged: (v) => setState(() => _recurrence = v),
                      ),
                    ),
                    if (_recurrence == Recurrence.weekly)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          _weeklyCaption(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Time section.
              _SectionCard(
                child: Column(
                  children: [
                    _ToggleRow(
                      label: 'Time',
                      actionText: 'Task has a time',
                      value: _hasTime,
                      accent: accent,
                      onChanged: (v) => setState(() => _hasTime = v),
                    ),
                    if (_hasTime)
                      _Row(
                        label: '',
                        action: Text('At', style: theme.textTheme.bodyMedium),
                        rightChild: InkWell(
                          onTap: _pickTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _time.format(context),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Reminder section.
              _SectionCard(
                child: Column(
                  children: [
                    _ToggleRow(
                      label: 'Reminder',
                      actionText: 'Remind me',
                      value: _hasReminder,
                      accent: accent,
                      onChanged: _toggleReminder,
                    ),
                    if (_hasReminder)
                      _Row(
                        label: 'Day',
                        action: Text('At', style: theme.textTheme.bodyMedium),
                        rightChild: DropdownButton<int>(
                          value: _reminderOffsetDays,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Same day')),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('1 day before'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('2 days before'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _reminderOffsetDays = v ?? 0),
                        ),
                      ),
                    if (_hasReminder && _hasTime)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          'Notification will fire ${_reminderPreview()}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---- helpers ------------------------------------------------------------

  String _weeklyCaption() {
    final name = WeekView.weekdayNames[_date.weekday % 7];
    return 'Every $name';
  }

  String _reminderPreview() {
    final fire = _fireDateTime();
    return fire == null
        ? 'when a date/time is set'
        : DateFormat('EEE, MMM d \u2014 HH:mm').format(fire);
  }

  DateTime? _fireDateTime() {
    if (!_hasReminder) return null;
    DateTime base = _date;
    if (_hasTime) {
      base = DateTime(
        base.year,
        base.month,
        base.day,
        _time.hour,
        _time.minute,
      );
    } else {
      base = DateTime(base.year, base.month, base.day, 9, 0);
    }
    return base.subtract(Duration(days: _reminderOffsetDays));
  }

  /// Fire time for a materialized occurrence: its own date + time, falling
  /// back to 09:00 for time-less tasks (same fallback as [_fireDateTime]).
  DateTime _occurrenceFire(Task occurrence) {
    final d = occurrence.date;
    final t = occurrence.time;
    return t == null
        ? DateTime(d.year, d.month, d.day, 9)
        : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _toggleReminder(bool v) async {
    if (!v) {
      setState(() => _hasReminder = false);
      return;
    }
    final prefs = ref.read(notificationServiceProvider);
    final granted = await prefs.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications were not allowed.')),
      );
      return;
    }
    setState(() => _hasReminder = true);
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _saving = true);

    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    final widgetSvc = ref.read(homeWidgetServiceProvider);
    final accentTag = ref.read(settingsProvider).colorTag;
    final themeMode = ref.read(settingsProvider).themeMode;

    final Task edited = widget.task == null
        ? Task(
            id: '',
            title: title,
            date: _date,
            colorTag: accentTag,
            hasTime: _hasTime,
            time: _hasTime ? _time : null,
            hasReminder: _hasReminder,
            recurrence: _recurrence,
            sortOrder: 0,
          )
        : widget.task!.copyWith(
            title: title,
            date: _date,
            hasTime: _hasTime,
            time: _hasTime ? _time : null,
            clearTime: !_hasTime,
            hasReminder: _hasReminder,
            recurrence: _recurrence,
            colorTag: accentTag,
          );

    final saved = await repo.insertTask(edited);

    // If recurring, materialize occurrences across a generous forward window
    // so the rest of the week view is populated immediately.
    var occurrences = const <Task>[];
    if (saved.recurrence.isRecurring) {
      final today = ref.read(todayProvider);
      final end = today.add(const Duration(days: 365));
      await repo.materializeOccurrences(rule: saved, start: today, end: end);
      // Re-schedule reminders for every occurrence (existing + just-created),
      // since each is an independent row with its own notification id.
      occurrences = await repo.getOccurrencesOf(saved.id);
    }

    if (saved.hasReminder) {
      final fire = _fireDateTime();
      if (fire != null) {
        await notif.scheduleTaskReminder(
          taskId: saved.id,
          title: saved.title,
          scheduled: fire,
        );
      }
      // Each recurring occurrence is an independent row with its own id, so
      // each one needs its own scheduled reminder. The service skips past
      // fire times.
      for (final occurrence in occurrences) {
        if (!occurrence.hasReminder) continue;
        await notif.scheduleTaskReminder(
          taskId: occurrence.id,
          title: occurrence.title,
          scheduled: _occurrenceFire(occurrence),
        );
      }
    } else if (widget.task != null) {
      await notif.cancelTaskReminder(widget.task!.id);
    }

    await widgetSvc.pushTodaySnapshot(
      accent: accentTag,
      themeMode: themeMode,
    );

    if (mounted) Navigator.of(context).pop(saved);
  }
}

// ---- reusable bits --------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.action,
    required this.rightChild,
  });
  final String label;
  final Widget action;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: action),
          rightChild,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.actionText,
    required this.value,
    required this.accent,
    required this.onChanged,
  });
  final String label;
  final String actionText;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(actionText, style: theme.textTheme.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
