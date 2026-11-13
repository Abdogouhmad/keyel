package dev.agouhmad.keyel.autofill

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.Dataset
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.widget.RemoteViews

/**
 * The Keyel autofill service.
 *
 * When another app opens a login form, Android delivers a [FillRequest] here.
 * We parse the form fields, then return a [FillResponse] whose single
 * [Dataset] is gated behind an authentication [Intent] that launches
 * [AuthActivity]. The auth activity hosts the Flutter picker, which
 * unlocks the vault (if needed), lets the user choose an entry, and hands
 * the credentials back as a result. The framework then fills the requesting
 * app's fields.
 */
class KeyelAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback,
    ) {
        val structures = request.fillContexts.map { it.structure }
        val parsed = FieldParser.parse(structures)

        // Nothing we can fill.
        if (parsed.fields.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        // Build an authentication intent that launches the Flutter picker.
        val authIntent = Intent(this, AuthActivity::class.java).apply {
            putExtra(AuthActivity.EXTRA_PACKAGE, parsed.packageName)
            putExtra(AuthActivity.EXTRA_WEB_DOMAIN, parsed.webDomain)

            // Pass field IDs so AuthActivity can build the Dataset on success.
            putParcelableArrayListExtra(
                AuthActivity.EXTRA_USERNAME_IDS,
                ArrayList(parsed.usernameIds()),
            )
            putParcelableArrayListExtra(
                AuthActivity.EXTRA_PASSWORD_IDS,
                ArrayList(parsed.passwordIds()),
            )
        }

        val pendingIntentFlags = PendingIntent.FLAG_CANCEL_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }

        val pendingIntent = PendingIntent.getActivity(
            this,
            REQUEST_CODE_AUTH,
            authIntent,
            pendingIntentFlags,
        )

        // A presentation shown in the autofill dropdown before the user taps.
        val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
            setTextViewText(android.R.id.text1, "Fill with Keyel")
        }

        // Authentication-gated dataset: per-field values are intentionally
        // null. The framework calls the authentication IntentSender; if the
        // user picks an entry, AuthActivity returns a Dataset with real
        // values via EXTRA_AUTHENTICATION_RESULT, which the framework then
        // fills into the matching field IDs.
        val datasetBuilder = Dataset.Builder(presentation)
        for (field in parsed.fields) {
            datasetBuilder.setValue(field.autofillId, null)
        }
        datasetBuilder.setAuthentication(pendingIntent.intentSender)

        val responseBuilder = FillResponse.Builder()
            .addDataset(datasetBuilder.build())

        // Offer save when the user submits credentials we don't know about.
        val saveInfo = buildSaveInfo(parsed)
        if (saveInfo != null) {
            responseBuilder.setSaveInfo(saveInfo)
        }

        callback.onSuccess(responseBuilder.build())
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        val structures = request.fillContexts.map { it.structure }
        val credentials = FieldParser.extractSaveCredentials(structures)

        // Nothing worth saving (no password captured).
        if (credentials == null) {
            callback.onFailure(null)
            return
        }

        val parsed = FieldParser.parse(structures)

        // Hand the captured credentials to our own UI, which asks the user to
        // confirm before anything is written to the vault. We own the save
        // flow, so the framework's request is considered handled.
        val intent = Intent(this, AuthActivity::class.java).apply {
            action = AuthActivity.ACTION_SAVE
            putExtra(AuthActivity.EXTRA_PACKAGE, parsed.packageName)
            putExtra(AuthActivity.EXTRA_WEB_DOMAIN, parsed.webDomain)
            putExtra(AuthActivity.EXTRA_USERNAME, credentials.username)
            putExtra(AuthActivity.EXTRA_PASSWORD, credentials.password)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        callback.onSuccess()
    }

    /**
     * Constructs [SaveInfo] so the system can ask the user to save new
     * credentials after submitting a login form.
     */
    private fun buildSaveInfo(parsed: ParseResult): SaveInfo? {
        val usernameIds = parsed.usernameIds()
        val passwordIds = parsed.passwordIds()

        if (passwordIds.isEmpty()) return null

        val requiredIds = passwordIds.toTypedArray()
        val optionalIds = usernameIds.toTypedArray()

        val builder = SaveInfo.Builder(
            SaveInfo.SAVE_DATA_TYPE_PASSWORD or SaveInfo.SAVE_DATA_TYPE_USERNAME,
            requiredIds,
        )

        if (optionalIds.isNotEmpty()) {
            builder.setOptionalIds(optionalIds)
        }

        return builder.build()
    }

    companion object {
        private const val REQUEST_CODE_AUTH = 7301
    }
}
