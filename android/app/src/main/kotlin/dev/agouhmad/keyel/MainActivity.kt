package dev.agouhmad.keyel

import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import android.view.autofill.AutofillManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth drives the system BiometricPrompt, which requires the host
// activity to be a FragmentActivity, so this extends FlutterFragmentActivity
// rather than the default FlutterActivity.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "keyel/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: true
                        if (secure) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }

                    "isAutofillEnabled" -> {
                        val afm = getSystemService(AutofillManager::class.java)
                        if (afm == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        // Check if autofill is supported and Keyel is the
                        // active autofill service.
                        val enabled = afm.isAutofillSupported &&
                            afm.hasEnabledAutofillServices()
                        result.success(enabled)
                    }

                    "openAutofillSettings" -> {
                        try {
                            // ACTION_REQUEST_SET_AUTOFILL_SERVICE directly
                            // opens the picker on Android 8.0+.
                            val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE).apply {
                                data = android.net.Uri.parse(
                                    "package:$packageName"
                                )
                            }
                            startActivity(intent)
                        } catch (_: Exception) {
                            // Fallback to the general settings page.
                            try {
                                startActivity(Intent(Settings.ACTION_SETTINGS))
                            } catch (_: Exception) {
                                // Nothing we can do.
                            }
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
