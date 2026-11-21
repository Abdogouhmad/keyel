package com.freesoftware.keyel.wear

import org.junit.Assert.assertEquals
import org.junit.Test

/** RFC 6238 Appendix B vectors, with the ASCII seeds base32-encoded for storage. */
class TotpGeneratorTest {

    private fun base32(input: String): String {
        val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        val bytes = input.toByteArray(Charsets.US_ASCII)
        val out = StringBuilder()
        var buffer = 0
        var bits = 0
        for (byte in bytes) {
            buffer = (buffer shl 8) or (byte.toInt() and 0xFF)
            bits += 8
            while (bits >= 5) {
                bits -= 5
                out.append(alphabet[(buffer shr bits) and 0x1F])
            }
        }
        if (bits > 0) out.append(alphabet[(buffer shl (5 - bits)) and 0x1F])
        return out.toString()
    }

    private val sha1 = base32("12345678901234567890")
    private val sha256 = base32("12345678901234567890123456789012")
    private val sha512 =
        base32("1234567890123456789012345678901234567890123456789012345678901234")

    @Test
    fun `RFC 6238 vectors for SHA-1`() {
        val expected = listOf(
            59L to "94287082",
            1_111_111_109L to "07081804",
            1_111_111_111L to "14050471",
            1_234_567_890L to "89005924",
            2_000_000_000L to "69279037",
            20_000_000_000L to "65353130",
        )
        expected.forEach { (time, code) ->
            assertEquals(code, TotpGenerator.code(sha1, 8, 30, "sha1", time))
        }
    }

    @Test
    fun `RFC 6238 vectors for SHA-256`() {
        val expected = listOf(
            59L to "46119246",
            1_111_111_109L to "68084774",
            1_111_111_111L to "67062674",
            1_234_567_890L to "91819424",
            2_000_000_000L to "90698825",
            20_000_000_000L to "77737706",
        )
        expected.forEach { (time, code) ->
            assertEquals(code, TotpGenerator.code(sha256, 8, 30, "sha256", time))
        }
    }

    @Test
    fun `RFC 6238 vectors for SHA-512`() {
        val expected = listOf(
            59L to "90693936",
            1_111_111_109L to "25091201",
            1_111_111_111L to "99943326",
            1_234_567_890L to "93441116",
            2_000_000_000L to "38618901",
            20_000_000_000L to "47863826",
        )
        expected.forEach { (time, code) ->
            assertEquals(code, TotpGenerator.code(sha512, 8, 30, "sha512", time))
        }
    }

    @Test
    fun `normalizes spacing padding and case`() {
        val clean = TotpGenerator.code("JBSWY3DPEHPK3PXP", 6, 30, "sha1", 1_111_111_111L)
        assertEquals(clean, TotpGenerator.code("jbsw y3dp ehpk 3pxp==", 6, 30, "sha1", 1_111_111_111L))
    }

    @Test
    fun `rejects invalid parameters`() {
        assertRunCatchingFails { TotpGenerator.code(sha1, 3, 30, "sha1", 59) }
        assertRunCatchingFails { TotpGenerator.code(sha1, 6, 0, "sha1", 59) }
        assertRunCatchingFails { TotpGenerator.code(sha1, 6, 30, "md5", 59) }
        assertRunCatchingFails { TotpGenerator.decodeBase32("not base32 !!") }
    }

    @Test
    fun `seconds left stays inside the period`() {
        assertEquals(30L, TotpGenerator.secondsLeft(30, 60))
        assertEquals(1L, TotpGenerator.secondsLeft(30, 89))
        assertEquals(30L, TotpGenerator.secondsLeft(30, 90))
    }

    private fun assertRunCatchingFails(block: () -> Unit) {
        var threw = false
        try {
            block()
        } catch (_: Exception) {
            threw = true
        }
        assertEquals(true, threw)
    }
}
