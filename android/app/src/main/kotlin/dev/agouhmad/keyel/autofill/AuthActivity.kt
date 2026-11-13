package dev.agouhmad.keyel.autofill

import android.app.Activity
import android.content.Intent
import android.service.autofill.Dataset
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activity launched by [KeyelAutofillService] to authenticate and pick an
 * entry, or to confirm saving a new one.
 *
 * It hosts a Flutter view that shows the autofill picker (or save) screen.
 * When the user picks an entry, Flutter calls back through a method channel
 * and this activity builds the final [Dataset] that the framework fills into
 * the requesting app. In save mode the entry is written by Flutter through
 * Rust and the activity simply closes.
 */
class AuthActivity : FlutterActivity() {

    private val channelName = "keyel/autofill"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAutofillArgs" -> {
                        // Send the target info to Flutter so it can query
                        // matching entries (fill) or pre-fill the save form.
                        val args = mapOf(
                            "mode" to if (intent.action == ACTION_SAVE) "save" else "fill",
                            "package" to intent.getStringExtra(EXTRA_PACKAGE),
                            "webDomain" to intent.getStringExtra(EXTRA_WEB_DOMAIN),
                            "username" to intent.getStringExtra(EXTRA_USERNAME),
                            "password" to intent.getStringExtra(EXTRA_PASSWORD),
                        )
                        result.success(args)
                    }

                    "returnCredentials" -> {
                        val username = call.argument<String>("username") ?: ""
                        val password = call.argument<String>("password") ?: ""

                        val dataset = buildDataset(username, password)
                        if (dataset != null) {
                            val replyIntent = Intent().apply {
                                putExtra(
                                    AutofillManager.EXTRA_AUTHENTICATION_RESULT,
                                    dataset,
                                )
                            }
                            setResult(Activity.RESULT_OK, replyIntent)
                        } else {
                            setResult(Activity.RESULT_CANCELED)
                        }
                        finish()
                        result.success(null)
                    }

                    // Save flow: Flutter already persisted the entry through
                    // Rust; just close the activity.
                    "saveCompleted" -> {
                        setResult(Activity.RESULT_OK)
                        finish()
                        result.success(null)
                    }

                    "cancel" -> {
                        setResult(Activity.RESULT_CANCELED)
                        finish()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Build a [Dataset] for the framework to fill into the requesting app.
     */
    private fun buildDataset(username: String, password: String): Dataset? {
        val usernameIds = intent.getParcelableArrayListExtra<AutofillId>(EXTRA_USERNAME_IDS)
            ?: emptyList()
        val passwordIds = intent.getParcelableArrayListExtra<AutofillId>(EXTRA_PASSWORD_IDS)
            ?: emptyList()

        if (usernameIds.isEmpty() && passwordIds.isEmpty()) return null

        val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
            setTextViewText(android.R.id.text1, "Keyel")
        }

        val builder = Dataset.Builder(presentation)

        for (id in usernameIds) {
            builder.setValue(id, AutofillValue.forText(username), presentation)
        }
        for (id in passwordIds) {
            builder.setValue(id, AutofillValue.forText(password), presentation)
        }

        return builder.build()
    }

    override fun getDartEntrypointFunctionName(): String = "mainAutofill"

    companion object {
        /** Action for the "save new login" flow; default action is fill. */
        const val ACTION_SAVE = "dev.agouhmad.keyel.action.SAVE"

        const val EXTRA_PACKAGE = "dev.agouhmad.keyel.PACKAGE"
        const val EXTRA_WEB_DOMAIN = "dev.agouhmad.keyel.WEB_DOMAIN"
        const val EXTRA_USERNAME = "dev.agouhmad.keyel.USERNAME"
        const val EXTRA_PASSWORD = "dev.agouhmad.keyel.PASSWORD"
        const val EXTRA_USERNAME_IDS = "dev.agouhmad.keyel.USERNAME_IDS"
        const val EXTRA_PASSWORD_IDS = "dev.agouhmad.keyel.PASSWORD_IDS"
    }
}
