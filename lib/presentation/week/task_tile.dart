import 'package:flutter/material.dart';
import 'package:loopweek/domain/models/task.dart';

/// Compact trailing "bell + time" indicator shown next to tasks that have a
/// time set. Also shows a recurring loop icon when the task has a recurrence
/// rule — purely informational on the occurrence side.
class TaskMetaTrailing extends StatelessWidget {
  const TaskMetaTrailing({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    final children = <Widget>[];

    if (task.hasTime && task.time != null) {
      final hh = task.time!.hour.toString().padLeft(2, '0');
      final mm = task.time!.minute.toString().padLeft(2, '0');
      children.add(
        Text(
          '$hh:$mm',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      );
      children.add(const SizedBox(width: 6));
      children.add(Icon(Icons.notifications_none, size: 16, color: muted));
    } else if (task.hasReminder) {
      children.add(Icon(Icons.notifications_none, size: 16, color: muted));
    }

    if (task.recurrence.isRecurring) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 4));
      children.add(Icon(Icons.loop, size: 16, color: muted));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// A single task row in the day-section list: square checkbox on the left,
/// the title, and the trailing meta. Tap toggles completion; long-press opens
/// the edit sheet (handled by the caller via [onTap] / [onLongPress]).
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
    required this.accent,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Checkbox(
              checked: task.isCompleted,
              accent: accent,
              onTap: onToggle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted
                      ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TaskMetaTrailing(task: task),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.checked,
    required this.accent,
    required this.onTap,
  });

  final bool checked;
  final Color accent;
  final VoidCallback onTap;

  GestureTapCallback? get onToggle => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent = theme.colorScheme.onPrimary;

    // 48x48 touch target (Android minimum) with the 24x24 checkbox centered.
    // Opaque hit-test consumes the tap so the row's edit action is not fired.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: checked ? accent : theme.dividerColor,
                width: 2,
              ),
              color: checked ? accent : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: checked
                ? Icon(Icons.check, size: 16, color: onAccent)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
