import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/data/repositories/week_template_repository.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_providers.dart';

/// Sheet naming and saving the given week as a template. The rows' subtitles
/// on the Settings screen update via the templates stream — no snackbar.
Future<void> showSaveTemplateSheet(
  BuildContext context, {
  required List<DateTime> weekDates,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SaveTemplateSheet(weekDates: weekDates),
    ),
  );
}

/// Sheet listing saved templates, then confirming the apply onto the shown
/// week. Returns through nested pushes: the confirm sheet pops with `true`
/// and this sheet closes itself, so "Apply" closes everything at once.
Future<void> showApplyTemplateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ApplyTemplateSheet(),
  );
}

class SaveTemplateSheet extends ConsumerStatefulWidget {
  const SaveTemplateSheet({super.key, required this.weekDates});

  final List<DateTime> weekDates;

  @override
  ConsumerState<SaveTemplateSheet> createState() => _SaveTemplateSheetState();
}

class _SaveTemplateSheetState extends ConsumerState<SaveTemplateSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: 'Week of ${DateFormat('MMM d').format(widget.weekDates.first)}',
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final canSave = _nameController.text.trim().isNotEmpty;

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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: theme.textTheme.titleLarge,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Template name',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving || !canSave ? null : _onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Haptics.light();
                              Navigator.of(context).maybePop();
                            },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    try {
      await ref
          .read(weekTemplateRepositoryProvider)
          .saveFromWeek(name, widget.weekDates);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not save template.')));
      }
      debugPrint('Template save failed: $e');
    }
  }
}

class ApplyTemplateSheet extends ConsumerWidget {
  const ApplyTemplateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templates =
        ref.watch(weekTemplatesProvider).valueOrNull ?? const <TemplateSummary>[];

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
                'Apply a template',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: templates.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No templates yet.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill a week, then save it from Settings → '
                            'Templates.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _TemplateTile(
                          template: template,
                          onSelected: () async {
                            Haptics.light();
                            final applied = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _ConfirmApplySheet(template),
                            );
                            if (applied == true && context.mounted) {
                              Navigator.of(context).pop();
                              Haptics.medium();
                            }
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

/// One saved template row. The semantics label carries name + task count so
/// screen readers announce what applying will add.
class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onSelected});

  final TemplateSummary template;
  final VoidCallback onSelected;

  String get _savedCaption => DateFormat('MMM d').format(template.createdAt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '${template.name}, ${template.itemCount} tasks',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(template.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${template.itemCount} tasks · saved $_savedCaption',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        onTap: onSelected,
      ),
    );
  }
}

/// Confirmation before seeding. The apply itself happens here — the sheet
/// pops with `true` once the tasks and the home-widget snapshot are written,
/// letting the picker close the whole stack and fire the completion haptic.
class _ConfirmApplySheet extends ConsumerWidget {
  const _ConfirmApplySheet(this.template);

  final TemplateSummary template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final weekDates = ref.watch(weekDatesProvider);
    final today = ref.watch(todayProvider);
    final hasPastDays = weekDates.any((date) => date.isBefore(today));

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
            Text(
              'Apply "${template.name}"?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This adds ${template.itemCount} tasks to this week's matching "
              'days. Nothing you added is deleted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (hasPastDays) ...[
              const SizedBox(height: 4),
              Text(
                'Tasks for days already past are skipped.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _apply(context, ref),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    child: const Text('Apply'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Haptics.light();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(weekTemplateRepositoryProvider);
    final widgetSvc = ref.read(homeWidgetServiceProvider);
    final settings = ref.read(settingsProvider);
    final weekDates = ref.read(weekDatesProvider);
    final today = ref.read(todayProvider);

    try {
      await repo.applyToWeek(template.id, weekDates, today, settings.colorTag);
      await widgetSvc.pushTodaySnapshot(
        accent: settings.colorTag,
        themeMode: settings.themeMode,
      );
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not apply template.')),
        );
      }
      debugPrint('Template apply failed: $e');
    }
  }
}
