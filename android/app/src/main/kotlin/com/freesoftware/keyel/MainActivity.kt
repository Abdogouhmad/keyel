package com.freesoftware.keyel

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

                    "isPasskeyProviderSupported" -> {
                        // Credential Manager provider services are supported on
                        // Android 14+ (API 34). Actual availability also depends
                        // on device/Play services; this is the coarse platform gate.
                        result.success(
                            android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        )
                    }

                    "openCredentialProviderSettings" -> {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                val intent = Intent(Settings.ACTION_CREDENTIAL_PROVIDER)
                                startActivity(intent)
                            } else {
                                startActivity(Intent(Settings.ACTION_SETTINGS))
                            }
                        } catch (_: Exception) {
                            try {
                                startActivity(Intent(Settings.ACTION_SETTINGS))
                            } catch (_: Exception) {
                                // Nothing we can do.
                            }
                        }
                        result.success(null)
                    }

                    "canInstallPackages" -> {
                        val canInstall = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            packageManager.canRequestPackageInstalls()
                        } else {
                            true
                        }
                        result.success(canInstall)
                    }

                    "openInstallPermissionSettings" -> {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = android.net.Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            }
                        } catch (_: Exception) {
                            try {
                                startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                            } catch (_: Exception) {
                                // Fallback
                            }
                        }
                        result.success(null)
                    }

                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            result.error("INVALID_PATH", "filePath is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = java.io.File(filePath)
                            val uri = androidx.core.content.FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
