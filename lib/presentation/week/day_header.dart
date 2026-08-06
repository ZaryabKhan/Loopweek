import 'package:flutter/material.dart';

/// "SUNDAY" + "August 2" condensed sans-serif header. Tap toggles expanded
/// state for the parent accordion.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.weekdayName,
    required this.monthDay,
    required this.isToday,
    required this.isExpanded,
    required this.onTap,
    required this.onAddTapped,
  });

  final String weekdayName;
  final String monthDay;
  final bool isToday;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onAddTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.displaySmall?.copyWith(
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.8,
      fontWeight: FontWeight.w800,
    );
    final subStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w400,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (isToday) const _TodayDot(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(weekdayName.toUpperCase(), style: headingStyle),
                    const SizedBox(height: 2),
                    Text(monthDay, style: subStyle),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayDot extends StatelessWidget {
  const _TodayDot();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 10, bottom: 4),
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
    );
  }
}
