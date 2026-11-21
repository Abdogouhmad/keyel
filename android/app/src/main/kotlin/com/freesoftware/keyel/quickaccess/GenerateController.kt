package com.freesoftware.keyel.quickaccess

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Warm-launch notification for the "Generate password" shortcut/widget.
 *
 * Like the lock path, MainActivity is the only native entry point; this bridge
 * merely tells the running Flutter app to open the generator screen. It never
 * generates, reads or copies a secret.
 */
object GenerateController {
    const val ACTION_GENERATE = "com.freesoftware.keyel.action.GENERATE"

    private const val CHANNEL = "keyel/generate"
    private const val REQUESTED_METHOD = "generateRequested"

    @Volatile
    private var messenger: BinaryMessenger? = null

    fun attach(messenger: BinaryMessenger) {
        this.messenger = messenger
    }

    fun detach() {
        messenger = null
    }

    /** Asks the running Flutter app to open the generator; no-op when detached. */
    fun notifyGenerateRequested() {
        val activeMessenger = messenger ?: return
        MethodChannel(activeMessenger, CHANNEL)
            .invokeMethod(REQUESTED_METHOD, null)
    }
}
