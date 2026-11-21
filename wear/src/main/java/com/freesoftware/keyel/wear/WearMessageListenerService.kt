package com.freesoftware.keyel.wear

import android.content.Intent
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject
import java.nio.charset.StandardCharsets

/**
 * Receives seeds from the paired phone over the encrypted Wearable channel.
 *
 * Only small, explicit commands are accepted. Every payload is validated by
 * [TotpStore] before it is persisted, and an unknown path or malformed message
 * is ignored. The service never answers with secret material and never logs
 * a payload.
 */
class WearMessageListenerService : WearableListenerService() {

    override fun onCreate() {
        super.onCreate()
        TotpStore.init(applicationContext)
    }

    override fun onMessageReceived(event: MessageEvent) {
        val bytes = event.data
        // Bound the input so a malformed peer cannot exhaust watch memory.
        if (bytes.isEmpty() || bytes.size > MAX_PAYLOAD) return
        when (event.path) {
            PATH_PUT -> runCatching {
                val json = JSONObject(String(bytes, StandardCharsets.UTF_8))
                val entry = WatchEntry(
                    id = json.getString("id"),
                    label = json.optString("label"),
                    secret = json.getString("secret"),
                    algorithm = json.getString("algorithm"),
                    digits = json.getInt("digits"),
                    period = json.getInt("period"),
                )
                TotpStore.put(entry)
            }
            PATH_REMOVE -> runCatching {
                TotpStore.remove(String(bytes, StandardCharsets.UTF_8))
            }
            PATH_CLEAR -> TotpStore.clear()
            else -> return
        }
        sendBroadcast(Intent(ACTION_CHANGED).setPackage(packageName))
    }

    private companion object {
        const val PATH_PUT = "/keyel/totp/put"
        const val PATH_REMOVE = "/keyel/totp/remove"
        const val PATH_CLEAR = "/keyel/totp/clear"
        const val MAX_PAYLOAD = 4096
        const val ACTION_CHANGED = "com.freesoftware.keyel.wear.TOTP_CHANGED"
    }
}
