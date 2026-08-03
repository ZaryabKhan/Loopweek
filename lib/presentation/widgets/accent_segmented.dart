import 'package:flutter/material.dart';

/// Shared accent-filled segmented control. Per spec, the selected option is
/// filled with the accent color; the control stays flat, rounded ~10dp, with a
/// 48dp touch height. Used by the recurrence (Never/Daily/Weekly) and theme
/// (System/Light/Dark) selectors so both surfaces share one component.
class AccentSegmented<T> extends StatelessWidget {
  const AccentSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    this.onChanged,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final onAccent = theme.colorScheme.onPrimary;
    final trackColor = theme.colorScheme.onSurface.withValues(alpha: 0.07);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                selected: option == value,
                label: labelOf(option),
                accent: accent,
                onAccent: onAccent,
                onTap: onChanged == null ? null : () => onChanged!(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.label,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });

  final T option;
  final bool selected;
  final String label;
  final Color accent;
  final Color onAccent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? onAccent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
