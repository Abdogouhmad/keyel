package com.freesoftware.keyel.quicklock

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Shared one-tap lock plumbing for the launcher shortcut and the Quick
 * Settings tile. Both routes go through MainActivity, so the Rust session is
 * always dropped by the same Dart lock path instead of by a native flag.
 */
object LockController {
    const val ACTION_LOCK = "com.freesoftware.keyel.action.LOCK"

    private const val LOCK_CHANNEL = "keyel/lock"
    private const val LOCK_REQUESTED_METHOD = "lockRequested"

    @Volatile
    private var messenger: BinaryMessenger? = null

    /** Called when the Flutter engine is ready to receive a lock request. */
    fun attach(messenger: BinaryMessenger) {
        this.messenger = messenger
    }

    fun detach() {
        messenger = null
    }

    /** Asks the running Flutter app to lock; a no-op when no engine is live. */
    fun notifyLockRequested() {
        val activeMessenger = messenger ?: return
        MethodChannel(activeMessenger, LOCK_CHANNEL)
            .invokeMethod(LOCK_REQUESTED_METHOD, null)
    }

    /**
     * Wipes the clipboard before Flutter is involved. A lock request must
     * never leave a secret available to paste, even if Dart is still starting.
     */
    fun clearClipboard(context: Context) {
        val clipboard = context.getSystemService(ClipboardManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            clipboard.clearPrimaryClip()
        } else {
            // API 26/27 has no clear API; overwriting with an empty clip is the
            // only available option and is still safer than leaving the secret.
            clipboard.setPrimaryClip(ClipData.newPlainText("Keyel", ""))
        }
    }
}
