package com.appcodecraft.loopweek

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Android home-screen widget for Loopweek.
 *
 * Renders today's tasks. Tapping a row fires a [HomeWidgetBackgroundReceiver]
 * broadcast whose data Uri routes to the Dart interactivity callback
 * registered in `lib/main.dart` via `HomeWidget.registerInteractivityCallback`,
 * toggling the task's completed state in the background — without opening
 * the app.
 *
 * The Flutter side ships the data through `HomeWidget.saveWidgetData`:
 *  - `loopweek.tasks`  : newline-separated rows `id|done|title|HH:MM|`
 *  - `loopweek.accent` : "RR|GG|BB" accent color ints
 *  - `loopweek.date`   : ISO date of the snapshot
 *
 * Medium size shows up to 5 rows; tall widgets show up to 10.
 */
class LoopweekWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val KEY_TASKS = "loopweek.tasks"
        private const val KEY_ACCENT = "loopweek.accent"
        private const val KEY_THEME = "loopweek.theme"

        // App palette: light scaffold #F2F2F2 / white surface; dark near-black
        // #121212 / #1E1E1E. These mirror lib/core/theme/app_theme.dart.
        private const val LIGHT_BG = 0xFFF2F2F2.toInt()
        private const val DARK_BG = 0xFF121212.toInt()
        private const val LIGHT_TEXT = 0xFF212121.toInt()
        private const val DARK_TEXT = 0xFFE6E6E6.toInt()
        private const val LIGHT_DONE = 0xFF9E9E9E.toInt()
        private const val DARK_DONE = 0xFFBDBDBD.toInt()

        private val ROW_VIEWS = intArrayOf(
            R.id.widget_row1, R.id.widget_row2, R.id.widget_row3,
            R.id.widget_row4, R.id.widget_row5, R.id.widget_row6,
            R.id.widget_row7, R.id.widget_row8, R.id.widget_row9,
            R.id.widget_row10
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id, widgetData, ROW_VIEWS.size)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        prefs: SharedPreferences,
        maxRows: Int
    ) {
        val accent = parseAccent(prefs.getString(KEY_ACCENT, null))
        val rows = parseTasks(prefs.getString(KEY_TASKS, null)).take(maxRows)

        val dark = isDark(context, prefs)
        val background = if (dark) DARK_BG else LIGHT_BG
        val defaultText = if (dark) DARK_TEXT else LIGHT_TEXT
        val doneColor = if (dark) DARK_DONE else LIGHT_DONE

        val views = RemoteViews(context.packageName, R.layout.loopweek_widget)
        views.setInt(R.id.widget_root, "setBackgroundColor", background)

        views.setTextViewText(R.id.widget_header, "TODAY")
        if (accent != null) views.setTextColor(R.id.widget_header, accent)

        if (rows.isEmpty()) {
            views.setTextViewText(R.id.widget_row1, "Nothing on the list yet.")
            views.setTextColor(R.id.widget_row1, defaultText)
            views.setViewVisibility(R.id.widget_row1, View.VISIBLE)
            for (i in 1 until maxRows) {
                views.setTextViewText(ROW_VIEWS[i], "")
                views.setViewVisibility(ROW_VIEWS[i], View.GONE)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        for ((i, row) in rows.withIndex()) {
            val viewId = ROW_VIEWS[i]
            val label = buildString {
                if (row.done) append("\u2713  ")
                append(row.title)
                if (row.time.isNotEmpty()) append("   ").append(row.time)
            }
            views.setTextViewText(viewId, label)
            views.setViewVisibility(viewId, View.VISIBLE)
            val textColor = when {
                row.done -> doneColor       // muted, theme-appropriate
                accent != null -> accent    // incomplete task -> accent
                else -> defaultText
            }
            views.setTextColor(viewId, textColor)
            views.setOnClickPendingIntent(viewId, togglePendingIntent(context, row.id))
        }
        for (i in rows.size until maxRows) {
            views.setTextViewText(ROW_VIEWS[i], "")
            views.setViewVisibility(ROW_VIEWS[i], View.GONE)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /** Resolves the widget's light/dark theme from the pushed theme mode.
     *  "light"/"dark" honor the app's manual override; "system" (or not yet
     *  pushed) is resolved from the OS night mode at render time, so it stays
     *  in step with the device even while the app is closed. */
    private fun isDark(context: Context, prefs: SharedPreferences): Boolean {
        return when (prefs.getString(KEY_THEME, null)) {
            "light" -> false
            "dark" -> true
            else -> {
                val nightMode =
                    context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                nightMode == Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    /** Builds a broadcast PendingIntent so each row's taskId reaches the Dart
     *  background isolate as a distinct Uri. We intentionally construct the
     *  intent ourselves (targeting [HomeWidgetBackgroundReceiver]) with a
     *  per-taskId request code so Android keeps each row's PendingIntent
     *  distinct — the home_widget helper uses a single request code, which
     *  would collapse every row onto whatever was clicked last. */
    private fun togglePendingIntent(context: Context, taskId: String): PendingIntent {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            data = Uri.parse("loopweek://toggle?id=$taskId")
            action = "es.antonborri.home_widget.action.BACKGROUND"
        }
        return PendingIntent.getBroadcast(
            context,
            taskId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private data class TaskRow(val id: String, val done: Boolean, val title: String, val time: String)

    private fun parseTasks(raw: String?): List<TaskRow> {
        if (raw.isNullOrBlank()) return emptyList()
        val out = ArrayList<TaskRow>(10)
        for (line in raw.split("\n")) {
            if (line.isBlank()) continue
            val parts = line.split("|", limit = 4)
            if (parts.size < 3) continue
            out.add(TaskRow(
                id = parts[0],
                done = parts[1] == "1",
                title = parts[2],
                time = if (parts.size >= 4) parts[3] else "",
            ))
        }
        return out
    }

    private fun parseAccent(raw: String?): Int? {
        if (raw.isNullOrBlank()) return null
        val tokens = raw.split("|").mapNotNull { it.toIntOrNull() }
        if (tokens.size != 3) return null
        return Color.rgb(tokens[0], tokens[1], tokens[2])
    }
}