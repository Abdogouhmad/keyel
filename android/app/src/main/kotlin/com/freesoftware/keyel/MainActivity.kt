package com.freesoftware.keyel

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PersistableBundle
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
    private val notificationChannelName = "keyel/notifications"

    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "keyel_updates"
        private const val UPDATE_NOTIFICATION_ID = 1001
        private const val POST_NOTIFICATIONS_REQUEST_CODE = 4321
    }

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

                    // Android 13+ lets an app mark a clipboard entry as
                    // sensitive, which keeps it out of clipboard history and
                    // suppresses the on-screen preview/auto-suggestion. Use it
                    // for every secret copy; older Android ignores the flag but
                    // still gets the value via the same channel.
                    "copySensitive" -> {
                        val text = call.argument<String>("text") ?: ""
                        val clipboard = getSystemService(ClipboardManager::class.java)
                        val clip = ClipData.newPlainText("Keyel secret", text)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val extras = PersistableBundle()
                            extras.putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                            clip.description.extras = extras
                        }
                        clipboard.setPrimaryClip(clip)
                        result.success(null)
                    }

                    // Wipe with the platform clear API instead of writing an
                    // empty clip. setPrimaryClip(empty) looks like a normal copy
                    // to OEM keyboards/toasts, which surfaced a spurious
                    // "copied an empty text" notification after every wipe.
                    // clearPrimaryClip() removes the value without a copy event.
                    "clearSensitive" -> {
                        val clipboard = getSystemService(ClipboardManager::class.java)
                        clipboard.clearPrimaryClip()
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "areNotificationsEnabled" -> result.success(areNotificationsEnabled())

                    "requestPermission" -> requestNotificationPermission(result)

                    "showUpdate" -> showUpdateNotification(
                        call.argument<String>("version").orEmpty(),
                        call.argument<String>("channel").orEmpty(),
                        result
                    )

                    else -> result.notImplemented()
                }
            }
    }

    private fun areNotificationsEnabled(): Boolean {
        val manager = getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        // On API 33+ the runtime permission is separate from the app-level flag.
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    @Suppress("DEPRECATION")
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(areNotificationsEnabled())
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        // Only one request can be in flight; resolve a stale result if a
        // previous dialog never reported back (e.g. activity recreation).
        pendingNotificationPermissionResult?.success(false)
        pendingNotificationPermissionResult = result
        try {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                POST_NOTIFICATIONS_REQUEST_CODE
            )
        } catch (_: Exception) {
            pendingNotificationPermissionResult = null
            result.success(false)
        }
    }

    @Suppress("DEPRECATION")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != POST_NOTIFICATIONS_REQUEST_CODE) return
        val result = pendingNotificationPermissionResult ?: return
        pendingNotificationPermissionResult = null
        result.success(
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        )
    }

    private fun showUpdateNotification(
        version: String,
        channel: String,
        result: MethodChannel.Result
    ) {
        if (!areNotificationsEnabled()) {
            result.success(false)
            return
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Keyel updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifies about new Keyel releases available to install."
            }
        )

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        val contentIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
            )
        } else null

        val betaSuffix = if (channel.equals("beta", ignoreCase = true)) " (Beta)" else ""
        val notification = Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_keyel)
            .setContentTitle("Update available")
            .setContentText("Keyel v$version is ready to install$betaSuffix")
            .setAutoCancel(true)
            .apply { if (contentIntent != null) setContentIntent(contentIntent) }
            .build()
        manager.notify(UPDATE_NOTIFICATION_ID, notification)
        result.success(true)
    }
}
