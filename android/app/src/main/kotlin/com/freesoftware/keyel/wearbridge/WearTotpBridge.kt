package com.freesoftware.keyel.wearbridge

import android.content.Context
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.util.Arrays
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Phone-side sender for the opt-in Wear OS TOTP companion.
 *
 * This bridge only forwards a secret the Flutter layer already revealed from
 * an unlocked vault. It never reads the vault itself, never keeps a copy in
 * memory after the call, and never logs a payload. If Play Services or a paired
 * watch is unavailable the call simply fails closed.
 */
object WearTotpBridge {
    private const val CHANNEL = "keyel/wear"
    private const val PATH_PUT = "/keyel/totp/put"
    private const val PATH_REMOVE = "/keyel/totp/remove"
    private const val PATH_CLEAR = "/keyel/totp/clear"
    private const val MAX_PAYLOAD = 4096

    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "keyel-wear-bridge").apply { isDaemon = true }
    }

    private var context: Context? = null

    fun attach(messenger: BinaryMessenger, appContext: Context) {
        context = appContext.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            executor.execute { handle(call, result) }
        }
    }

    fun detach() {
        context = null
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "available" -> result.success(available())
            "push" -> {
                val id = call.argument<String>("id")
                val secret = call.argument<String>("secret")
                val algorithm = call.argument<String>("algorithm")
                val digits = call.argument<Int>("digits")
                val period = call.argument<Int>("period")
                if (id.isNullOrBlank() || secret.isNullOrBlank() ||
                    algorithm.isNullOrBlank() || digits == null || period == null ||
                    digits !in 4..10 || period <= 0 ||
                    algorithm.lowercase() !in setOf("sha1", "sha256", "sha512")
                ) {
                    result.success(false)
                    return
                }
                val label = call.argument<String>("label").orEmpty()
                val payload = JSONObject()
                    .put("id", id)
                    .put("label", label)
                    .put("secret", secret)
                    .put("algorithm", algorithm.lowercase())
                    .put("digits", digits)
                    .put("period", period)
                    .toString()
                    .toByteArray(StandardCharsets.UTF_8)
                try {
                    result.success(if (payload.size <= MAX_PAYLOAD) send(PATH_PUT, payload) else false)
                } finally {
                    Arrays.fill(payload, 0.toByte())
                }
            }

            "remove" -> {
                val id = call.argument<String>("id")
                if (id.isNullOrBlank()) {
                    result.success(false)
                    return
                }
                val payload = id.toByteArray(StandardCharsets.UTF_8)
                try {
                    result.success(if (payload.size <= MAX_PAYLOAD) send(PATH_REMOVE, payload) else false)
                } finally {
                    Arrays.fill(payload, 0.toByte())
                }
            }

            "clear" -> result.success(send(PATH_CLEAR, ByteArray(0)))

            else -> result.notImplemented()
        }
    }

    private fun available(): Boolean {
        val ctx = context ?: return false
        if (GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(ctx) != ConnectionResult.SUCCESS
        ) {
            return false
        }
        return runCatching {
            Tasks.await(Wearable.getNodeClient(ctx).connectedNodes, 5, TimeUnit.SECONDS)
                .isNotEmpty()
        }.getOrDefault(false)
    }

    private fun send(path: String, payload: ByteArray): Boolean {
        val ctx = context ?: return false
        if (!available()) return false
        return runCatching {
            val nodes = Tasks.await(Wearable.getNodeClient(ctx).connectedNodes, 5, TimeUnit.SECONDS)
            val node = nodes.firstOrNull { it.isNearby } ?: nodes.firstOrNull() ?: return false
            Tasks.await(
                Wearable.getMessageClient(ctx).sendMessage(node.id, path, payload),
                10,
                TimeUnit.SECONDS,
            )
            true
        }.getOrDefault(false)
    }
}
