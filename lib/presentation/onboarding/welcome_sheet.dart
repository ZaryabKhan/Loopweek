import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/presentation/providers.dart';

// DIRECTION CONTRACT
// THESIS: Onboarding teaches the week, not the app — one sheet, three moves,
// then the product teaches itself. Refuses the pager-of-features tutorial.
// OWN-WORLD: Loopweek's flat bottom-sheet grammar — scaffold fill, rounded
// top, drag handle, dividers; one accent; bold tight-tracked wordmark.
// STORY: The first-run user learns tap-a-day, add-with-+, hold-to-remove,
// picks their accent live, and lands on a week that invites the first task.
// FIRST VIEWPORT: sheet over the live week (never gated): wordmark, value
// prop, three gesture rows, four swatches, accent CTA, quiet Skip.
// FORM: narrow specified extension of the established surface; shaped
// directly, no seed roll.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the
// finish review and the verdict (extension — DESIGN.md not rewritten).

/// Shows the first-run welcome sheet. Resolves when dismissed by any path —
/// CTA, Skip, barrier tap, swipe-down, or system Back.
Future<void> showWelcomeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: const WelcomeSheet(),
    ),
  );
}

/// Presents [WelcomeSheet] once on first run, after settings load. Every
/// dismiss path marks onboarding as seen, so the sheet never returns.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _presented = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!_presented && settings.isLoaded && !settings.onboardingSeen) {
      _presented = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showWelcomeSheet(context);
        await ref.read(settingsProvider).setOnboardingSeen();
      });
    }
    return widget.child;
  }
}

/// First-run sheet: value prop, the three gestures that run the app, and a
/// live accent pick. Skippable and non-blocking — the week stays usable
/// behind it, and dismissing it is all it takes to never see it again.
class WelcomeSheet extends ConsumerWidget {
  const WelcomeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SingleChildScrollView(
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'LOOPWEEK',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'One screen, seven days, nothing else.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),

              // The three gestures that run the whole app.
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _GestureRow(
                      icon: Icons.touch_app_outlined,
                      text: 'Tap a day to open it. Only one day stays open.',
                      accent: accent,
                    ),
                    Divider(height: 1, indent: 56, color: theme.dividerColor),
                    _GestureRow(
                      icon: Icons.add,
                      text: 'Tap + to add a task to that day.',
                      accent: accent,
                    ),
                    Divider(height: 1, indent: 56, color: theme.dividerColor),
                    _GestureRow(
                      icon: Icons.pan_tool_outlined,
                      text: 'Hold a task to remove it.',
                      accent: accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'PICK YOUR COLOUR',
                style: theme.textTheme.titleSmall?.copyWith(
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              const _AccentPicker(),
              const SizedBox(height: 8),
              Text(
                'Used for checkboxes, toggles, and the home-screen widget.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  Haptics.medium();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start my week'),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Haptics.light();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestureRow extends StatelessWidget {
  const _GestureRow({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Four accent swatches with live theme preview — tapping one rethemes the
/// app (and this sheet) instantly. Mirrors the Settings swatch row.
class _AccentPicker extends ConsumerWidget {
  const _AccentPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(settingsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final tag in ColorTag.values)
          _Swatch(tag: tag, selected: active.colorTag == tag),
      ],
    );
  }
}

class _Swatch extends ConsumerWidget {
  const _Swatch({required this.tag, required this.selected});

  final ColorTag tag;
  final bool selected;

  String get _label => switch (tag) {
    ColorTag.orange => 'Orange',
    ColorTag.pink => 'Pink',
    ColorTag.blue => 'Blue',
    ColorTag.green => 'Green',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AccentColors.of(tag);
    return Semantics(
      button: true,
      selected: selected,
      label: '$_label accent',
      child: InkWell(
        onTap: () async {
          Haptics.selection();
          final themeMode = ref.read(settingsProvider).themeMode;
          await ref.read(settingsProvider).setColorTag(tag);
          await ref
              .read(homeWidgetServiceProvider)
              .pushTodaySnapshot(accent: tag, themeMode: themeMode);
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          alignment: Alignment.center,
          child: selected
              ? Icon(
                  Icons.check,
                  size: 24,
                  color: AccentColors.onAccentOf(color),
                )
              : null,
        ),
      ),
    );
  }
}
