import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/data/services/home_widget_service.dart';
import 'package:loopweek/domain/models/task.dart';

// Built-in PDF fonts (Helvetica) only cover WinAnsi, so the ✓ checkbox and
// the recurrence ↻ meta glyph are drawn as vector marks instead of text.
const _nearBlack = PdfColor(0.13, 0.13, 0.13);
const _gray = PdfColor(0.45, 0.45, 0.45);
const _hairline = PdfColor(0.80, 0.80, 0.80);

/// Builds the "print this week" sheet as PDF bytes for [pageFormat] (the
/// Android print dialog defaults this to A4 portrait).
///
/// [weekDates] is the shown week (already offset); [tasksForDate] reads one
/// day from the repository — `TaskRepository.watchTasksForDate` already
/// excludes Someday tasks. Each day is re-ordered with
/// [HomeWidgetService.sortForSnapshot], matching the week view.
///
/// One page by design: weeks up to ~40 tasks fill it comfortably, and >40
/// tasks switch to denser type (10pt tasks, 5pt day gaps) rather than a
/// second column. Known gap: extreme weeks (~100+ tasks) spill onto a second
/// page instead of compressing into two columns.
Future<Uint8List> buildWeekPdf(
  PdfPageFormat pageFormat, {
  required List<DateTime> weekDates,
  required Future<List<Task>> Function(DateTime date) tasksForDate,
  required Color accent,
}) async {
  final days = <List<Task>>[
    for (final date in weekDates)
      HomeWidgetService.sortForSnapshot(await tasksForDate(date)),
  ];
  final dense = days.fold<int>(0, (sum, day) => sum + day.length) > 40;
  final accentPdf = PdfColor.fromInt(accent.toARGB32());
  final onAccentPdf =
      PdfColor.fromInt(AccentColors.onAccentOf(accent).toARGB32());

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.fromLTRB(42, 44, 42, 40),
      build: (context) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LOOPWEEK',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 3,
                color: accentPdf,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              '${DateFormat('MMM d').format(weekDates.first)} – '
              '${DateFormat('MMM d, yyyy').format(weekDates.last)}',
              style: pw.TextStyle(fontSize: 10, color: _gray),
            ),
            pw.SizedBox(height: 7),
            pw.Container(
              height: 0.6,
              decoration: const pw.BoxDecoration(color: _hairline),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        for (var i = 0; i < weekDates.length; i++)
          _DayBlock(
            date: weekDates[i],
            tasks: days[i],
            first: i == 0,
            gapAbove: dense ? 5 : 6,
            taskFontSize: dense ? 10 : 11,
            accent: accentPdf,
            onAccent: onAccentPdf,
          ),
      ],
    ),
  );
  return doc.save();
}

/// One calendar day: caps day name + 'MMM d' date, then the day's task rows
/// (or 'No tasks').
class _DayBlock extends pw.StatelessWidget {
  _DayBlock({
    required this.date,
    required this.tasks,
    required this.first,
    required this.gapAbove,
    required this.taskFontSize,
    required this.accent,
    required this.onAccent,
  });

  final DateTime date;
  final List<Task> tasks;
  final bool first;
  final double gapAbove;
  final double taskFontSize;
  final PdfColor accent;
  final PdfColor onAccent;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: first ? 0 : gapAbove),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                DateFormat('EEEE').format(date).toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.8,
                  color: _nearBlack,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                DateFormat('MMM d').format(date),
                style: pw.TextStyle(fontSize: 9, color: _gray),
              ),
            ],
          ),
          for (final task in tasks)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _TaskCheckbox(
                    completed: task.isCompleted,
                    accent: accent,
                    onAccent: onAccent,
                    border: _gray,
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(
                      task.title,
                      style: pw.TextStyle(
                        fontSize: taskFontSize,
                        color: task.isCompleted ? _gray : _nearBlack,
                        decoration: task.isCompleted
                            ? pw.TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (task.hasTime && task.time != null)
                    pw.Text(
                      '${task.time!.hour.toString().padLeft(2, '0')}:'
                      '${task.time!.minute.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(fontSize: 9, color: _gray),
                    ),
                  if (task.recurrence.isRecurring) ...[
                    pw.SizedBox(width: 4),
                    _RecurrenceMark(color: _gray),
                  ],
                ],
              ),
            ),
          if (tasks.isEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'No tasks',
                style: pw.TextStyle(fontSize: 9, color: _gray),
              ),
            ),
        ],
      ),
    );
  }
}

/// 7pt square: outlined when open, accent-filled with a vector check when
/// done (the built-in PDF fonts cannot encode the '✓' glyph).
class _TaskCheckbox extends pw.StatelessWidget {
  _TaskCheckbox({
    required this.completed,
    required this.accent,
    required this.onAccent,
    required this.border,
  });

  final bool completed;
  final PdfColor accent;
  final PdfColor onAccent;
  final PdfColor border;

  @override
  pw.Widget build(pw.Context context) {
    return pw.CustomPaint(
      size: const PdfPoint(7, 7),
      painter: (canvas, size) {
        if (completed) {
          canvas
            ..setFillColor(accent)
            ..drawRect(0, 0, size.x, size.y)
            ..fillPath();
          canvas
            ..setStrokeColor(onAccent)
            ..setLineWidth(1.1)
            ..setLineCap(PdfLineCap.round)
            ..moveTo(1.7, 3.5)
            ..lineTo(3.0, 2.2)
            ..lineTo(5.3, 4.7)
            ..strokePath();
        } else {
          canvas
            ..setStrokeColor(border)
            ..setLineWidth(0.8)
            ..drawRect(0, 0, size.x, size.y)
            ..strokePath();
        }
      },
    );
  }
}

/// Small vector stand-in for the '↻' meta glyph, which the built-in PDF
/// fonts cannot encode: a circle with a solid arrowhead.
class _RecurrenceMark extends pw.StatelessWidget {
  _RecurrenceMark({required this.color});

  final PdfColor color;

  @override
  pw.Widget build(pw.Context context) {
    return pw.CustomPaint(
      size: const PdfPoint(8, 8),
      painter: (canvas, size) {
        canvas
          ..setStrokeColor(color)
          ..setLineWidth(1)
          ..drawEllipse(4, 4, 2.6, 2.6)
          ..strokePath();
        canvas
          ..setFillColor(color)
          ..moveTo(3.9, 6.8)
          ..lineTo(6.2, 5.2)
          ..lineTo(4.5, 4.7)
          ..fillPath();
      },
    );
  }
}
