package com.freesoftware.keyel.autofill

import android.content.Context
import java.io.File
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

/**
 * Reads the non-secret "Never for this site" choices written by Dart.
 *
 * The canonical keys mirror `lib/data/autofill_target.dart` and the Rust
 * matcher's trust model: a WebView domain is only trusted from a known browser,
 * otherwise the requesting package is denied. No vault data or credentials are
 * ever read here. Any parse failure fails open for *matching* (the choice is
 * simply unavailable) but never broadens the matcher itself.
 */
object NeverForSites {

    private const val MAX_ENTRIES = 100

    private val trustedBrowsers = setOf(
        "com.android.chrome",
        "com.chrome.beta",
        "com.chrome.dev",
        "com.chrome.canary",
        "com.google.android.apps.chrome",
        "com.android.browser",
        "org.mozilla.firefox",
        "org.mozilla.firefox_beta",
        "org.mozilla.fennec_fdroid",
        "com.microsoft.emmx",
        "com.brave.browser",
        "com.opera.browser",
        "com.opera.mini.native",
        "com.duckduckgo.mobile.android",
        "com.vivaldi.browser",
    )

    /** Canonical key for a fill target, or null when it has no trusted identity. */
    fun canonical(packageName: String?, webDomain: String?): String? {
        val pkg = packageName?.trim()?.lowercase(Locale.ROOT)?.takeIf { it.isNotEmpty() }
        val host = normalizeHost(webDomain)
        if (pkg == null || pkg in trustedBrowsers) {
            return host?.let { "host:$it" }
        }
        return "package:$pkg"
    }

    /** Whether [packageName]/[webDomain] were permanently denied by the user. */
    fun isDenied(context: Context, packageName: String?, webDomain: String?): Boolean {
        val key = canonical(packageName, webDomain) ?: return false
        return read(context).contains(key)
    }

    private fun normalizeHost(value: String?): String? {
        if (value == null) return null
        var host = value.trim().lowercase(Locale.ROOT)
        if (host.isEmpty() || host.any { it.isWhitespace() }) return null
        val scheme = host.indexOf("://")
        if (scheme >= 0) host = host.substring(scheme + 3)
        val slash = host.indexOf('/')
        if (slash >= 0) host = host.substring(0, slash)
        val colon = host.indexOf(':')
        if (colon >= 0) host = host.substring(0, colon)
        if (host.startsWith("www.")) host = host.substring(4)
        host = host.trimEnd('.')
        if (host.isEmpty() || !host.contains('.')) return null
        return host
    }

    private fun read(context: Context): Set<String> {
        return try {
            val file = File(File(context.applicationContext.filesDir, "keyel"), "settings.json")
            if (!file.exists()) return emptySet()
            val root = JSONObject(file.readText())
            val raw: JSONArray = root.optJSONArray("autofillNeverForSites") ?: return emptySet()
            val result = LinkedHashSet<String>()
            for (i in 0 until minOf(raw.length(), MAX_ENTRIES)) {
                val value = raw.optString(i)?.trim() ?: continue
                if (isValid(value)) result.add(value)
            }
            result
        } catch (_: Exception) {
            // Preferences are optional; never break the autofill service.
            emptySet()
        }
    }

    private fun isValid(value: String): Boolean {
        if (value.startsWith("host:")) {
            return normalizeHost(value.substring(5))?.let { value == "host:$it" } == true
        }
        if (value.startsWith("package:")) {
            val pkg = value.substring(8)
            return pkg.isNotEmpty() && pkg.none { it.isWhitespace() } &&
                pkg == pkg.lowercase(Locale.ROOT)
        }
        return false
    }
}
