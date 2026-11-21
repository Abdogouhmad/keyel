package com.freesoftware.keyel.quickaccess

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.freesoftware.keyel.MainActivity
import com.freesoftware.keyel.R
import com.freesoftware.keyel.quicklock.LockController

/**
 * Small home-screen widget with three user-initiated shortcuts.
 *
 * No periodic refresh, no background service and no vault data: every button
 * is an immutable PendingIntent into [MainActivity]. The lock button uses the
 * same action as the launcher shortcut/tile, so the clipboard is wiped natively
 * and the Rust session is dropped by the normal Dart lock path. "Generate"
 * opens the generator screen; it never generates or copies a password itself.
 */
class KeyelQuickActionsWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)
            views.setOnClickPendingIntent(
                R.id.widget_open_vault,
                launchIntent(context, action = null, requestCode = 7101),
            )
            views.setOnClickPendingIntent(
                R.id.widget_generate,
                launchIntent(context, GenerateController.ACTION_GENERATE, 7102),
            )
            views.setOnClickPendingIntent(
                R.id.widget_lock_vault,
                launchIntent(context, LockController.ACTION_LOCK, 7103),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun launchIntent(
        context: Context,
        action: String?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            if (action != null) this.action = action
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
