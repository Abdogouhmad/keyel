package com.freesoftware.keyel.wear

import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.math.pow

/**
 * Minimal RFC 6238 TOTP implementation for the watch.
 *
 * The watch is deliberately standalone: it never calls the phone for a code,
 * so it needs no network, no vault and no Rust core. The shared secret is
 * supplied once by the phone over the encrypted Wearable channel and stored
 * only in [TotpStore]. No intermediate value in this file is logged.
 */
object TotpGenerator {

    /** Accepted algorithm names, matching the vault DTO wire values. */
    private val ALGORITHMS = mapOf(
        "sha1" to "HmacSHA1",
        "sha256" to "HmacSHA256",
        "sha512" to "HmacSHA512",
    )

    /** Decode a base32 secret, tolerating spacing, padding and lower case. */
    fun decodeBase32(input: String): ByteArray {
        val out = ByteArrayOutputStream()
        var buffer = 0
        var bits = 0
        for (raw in input) {
            val ch = raw.uppercaseChar()
            if (ch == '=' || ch == '-' || ch.isWhitespace()) continue
            val value = when (ch) {
                in 'A'..'Z' -> ch - 'A'
                in '2'..'7' -> ch - '2' + 26
                else -> throw IllegalArgumentException("invalid base32 secret")
            }
            buffer = (buffer shl 5) or value
            bits += 5
            if (bits >= 8) {
                bits -= 8
                out.write((buffer shr bits) and 0xFF)
            }
        }
        if (out.size() == 0) throw IllegalArgumentException("empty base32 secret")
        return out.toByteArray()
    }

    /** Compute a zero-padded TOTP code for [unixTimeSeconds]. */
    fun code(
        secret: String,
        digits: Int,
        period: Int,
        algorithm: String,
        unixTimeSeconds: Long,
    ): String {
        require(digits in 4..10) { "invalid TOTP digit count" }
        require(period > 0) { "invalid TOTP period" }
        val jcaName = ALGORITHMS[algorithm.lowercase()]
            ?: throw IllegalArgumentException("unsupported TOTP algorithm")

        val key = decodeBase32(secret)
        val counter = unixTimeSeconds / period
        val message = ByteBuffer.allocate(java.lang.Long.BYTES).putLong(counter).array()
        val digest = Mac.getInstance(jcaName).run {
            init(SecretKeySpec(key, jcaName))
            doFinal(message)
        }

        // RFC 4226 §5.3 dynamic truncation; the low nibble of the last byte
        // selects four bytes regardless of the digest length.
        val offset = digest[digest.lastIndex].toInt() and 0x0F
        val binary = ((digest[offset].toLong() and 0x7F) shl 24) or
            ((digest[offset + 1].toLong() and 0xFF) shl 16) or
            ((digest[offset + 2].toLong() and 0xFF) shl 8) or
            (digest[offset + 3].toLong() and 0xFF)

        val modulus = 10.0.pow(digits).toLong()
        return (binary % modulus).toString().padStart(digits, '0')
    }

    /** Seconds until the code for [unixTimeSeconds] rolls over. */
    fun secondsLeft(period: Int, unixTimeSeconds: Long): Long {
        val step = period.coerceAtLeast(1).toLong()
        return step - (unixTimeSeconds % step)
    }
}
