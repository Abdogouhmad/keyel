package com.freesoftware.keyel.wear

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONArray
import org.json.JSONObject

/** One TOTP seed pushed from the phone. [secret] is base32 and never logged. */
data class WatchEntry(
    val id: String,
    val label: String,
    val secret: String,
    val algorithm: String,
    val digits: Int,
    val period: Int,
)

/**
 * App-private, Keystore-backed storage for the seeds on the watch.
 *
 * The master key is a hardware-backed AES-256-GCM key when the device supports
 * it. Values are encrypted at rest; there is no plain-text seed in preferences,
 * logs, backups or the UI tree. This store is the only owner of the secrets —
 * the adapter keeps labels and ids but never a raw seed.
 */
object TotpStore {
    private const val PREFS_NAME = "keyel_watch_totp"
    private const val KEY_ENTRIES = "entries"
    private const val MAX_ENTRIES = 50

    @Volatile
    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        if (prefs != null) return
        synchronized(this) {
            if (prefs != null) return
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .setRequestStrongBoxBacked(true)
                .build()
            prefs = EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
            )
        }
    }

    fun entries(): List<WatchEntry> {
        val store = prefs ?: return emptyList()
        val raw = store.getString(KEY_ENTRIES, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                array.optJSONObject(index)?.let(::parseEntry)
            }.take(MAX_ENTRIES)
        }.getOrDefault(emptyList())
    }

    fun put(entry: WatchEntry) {
        val store = prefs ?: return
        if (!isValid(entry)) return
        val next = entries().filterNot { it.id == entry.id }.toMutableList()
        next.add(0, entry)
        write(store, next.take(MAX_ENTRIES))
    }

    fun remove(id: String) {
        val store = prefs ?: return
        write(store, entries().filterNot { it.id == id })
    }

    fun clear() {
        prefs?.edit()?.remove(KEY_ENTRIES)?.apply()
    }

    private fun write(store: SharedPreferences, list: List<WatchEntry>) {
        val array = JSONArray()
        list.forEach { entry ->
            array.put(
                JSONObject().apply {
                    put("id", entry.id)
                    put("label", entry.label)
                    put("secret", entry.secret)
                    put("algorithm", entry.algorithm)
                    put("digits", entry.digits)
                    put("period", entry.period)
                },
            )
        }
        store.edit().putString(KEY_ENTRIES, array.toString()).apply()
    }

    private fun parseEntry(json: JSONObject): WatchEntry? = runCatching {
        WatchEntry(
            id = json.getString("id"),
            label = json.optString("label"),
            secret = json.getString("secret"),
            algorithm = json.getString("algorithm"),
            digits = json.getInt("digits"),
            period = json.getInt("period"),
        ).takeIf(::isValid)
    }.getOrNull()

    private fun isValid(entry: WatchEntry): Boolean = runCatching {
        entry.id.isNotBlank() &&
            entry.secret.isNotBlank() &&
            entry.digits in 4..10 &&
            entry.period > 0 &&
            entry.algorithm.lowercase() in setOf("sha1", "sha256", "sha512") &&
            TotpGenerator.decodeBase32(entry.secret).isNotEmpty()
    }.getOrDefault(false)
}
