package com.freesoftware.keyel.passkeys

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.OutcomeReceiver
import androidx.annotation.RequiresApi
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.provider.AuthenticationAction
import androidx.credentials.provider.BeginCreateCredentialRequest
import androidx.credentials.provider.BeginCreateCredentialResponse
import androidx.credentials.provider.BeginCreatePublicKeyCredentialRequest
import androidx.credentials.provider.BeginGetCredentialRequest
import androidx.credentials.provider.BeginGetCredentialResponse
import androidx.credentials.provider.BeginGetPublicKeyCredentialOption
import androidx.credentials.provider.CreateEntry
import androidx.credentials.provider.CredentialProviderService
import androidx.credentials.provider.ProviderClearCredentialStateRequest
import androidx.credentials.provider.PublicKeyCredentialEntry

/**
 * Android Credential Manager provider service (prototype).
 *
 * This service surfaces Keyel as a passkey provider on supported devices
 * (Android 14+/API 34). The actual WebAuthn create/get ceremonies, vault
 * unlock, and key operations are completed in [PasskeyHandlerActivity]
 * via Flutter/Rust; this service only advertises entries and routes
 * selections through PendingIntents.
 *
 * Security notes:
 * - No private key material or secrets are stored or logged here.
 * - Only non-secret metadata needed for candidate selection is attached to
 *   intents/bundles.
 */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
class KeyelCredentialProviderService : CredentialProviderService() {

    companion object {
        const val ACTION_CREATE_PASSKEY = "com.freesoftware.keyel.action.CREATE_PASSKEY"
        const val ACTION_GET_PASSKEY = "com.freesoftware.keyel.action.GET_PASSKEY"
        const val ACTION_UNLOCK_FOR_PASSKEY = "com.freesoftware.keyel.action.UNLOCK_FOR_PASSKEY"
        const val EXTRA_REQUEST_JSON = "requestJson"
        const val EXTRA_CLIENT_DATA_HASH = "clientDataHash"
        const val EXTRA_CREDENTIAL_ID_B64 = "credentialIdB64"
    }

    override fun onBeginCreateCredentialRequest(
        request: BeginCreateCredentialRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<BeginCreateCredentialResponse, CreateCredentialException>,
    ) {
        try {
            when (request) {
                is BeginCreatePublicKeyCredentialRequest -> {
                    val intent = Intent(ACTION_CREATE_PASSKEY).apply {
                        setClass(this@KeyelCredentialProviderService, PasskeyHandlerActivity::class.java)
                        putExtra(EXTRA_REQUEST_JSON, request.requestJson)
                        request.clientDataHash?.let { putExtra(EXTRA_CLIENT_DATA_HASH, it) }
                    }
                    val pendingIntent = PendingIntent.getActivity(
                        this,
                        uniqueRequestCode(),
                        intent,
                        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )

                    val response = BeginCreateCredentialResponse(
                        createEntries = listOf(
                            CreateEntry(
                                accountName = "Save passkey in Keyel",
                                pendingIntent = pendingIntent,
                            ),
                        ),
                    )
                    callback.onResult(response)
                }

                else -> callback.onError(CreateCredentialUnknownException())
            }
        } catch (_: Throwable) {
            callback.onError(CreateCredentialUnknownException())
        }
    }

    override fun onBeginGetCredentialRequest(
        request: BeginGetCredentialRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<BeginGetCredentialResponse, GetCredentialException>,
    ) {
        try {
            val credentialEntries = mutableListOf<PublicKeyCredentialEntry>()

            for (option in request.beginGetCredentialOptions) {
                if (option is BeginGetPublicKeyCredentialOption) {
                    // Prototype: offer a single "use Keyel" entry that routes to
                    // the handler, which will unlock/pick/match inside Flutter/Rust.
                    // This avoids reading vault state from the provider process.
                    val data = Bundle()
                    val intent = Intent(ACTION_GET_PASSKEY).apply {
                        setClass(this@KeyelCredentialProviderService, PasskeyHandlerActivity::class.java)
                        putExtra(EXTRA_REQUEST_JSON, option.requestJson)
                        option.clientDataHash?.let { putExtra(EXTRA_CLIENT_DATA_HASH, it) }
                        putExtra("CREDENTIAL_DATA", data)
                    }
                    val pendingIntent = PendingIntent.getActivity(
                        this,
                        uniqueRequestCode(),
                        intent,
                        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )

                    credentialEntries.add(
                        PublicKeyCredentialEntry(
                            context = this,
                            username = "Keyel",
                            pendingIntent = pendingIntent,
                            beginGetPublicKeyCredentialOption = option,
                        ),
                    )
                }
            }

            // Always allow opening Keyel to unlock/select if needed.
            val unlockIntent = Intent(ACTION_UNLOCK_FOR_PASSKEY).apply {
                setClass(this@KeyelCredentialProviderService, PasskeyHandlerActivity::class.java)
            }
            val unlockPendingIntent = PendingIntent.getActivity(
                this,
                uniqueRequestCode(),
                unlockIntent,
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )

            val response = BeginGetCredentialResponse(
                credentialEntries = credentialEntries,
                authenticationActions = listOf(
                    AuthenticationAction(
                        title = "Open Keyel",
                        pendingIntent = unlockPendingIntent,
                    ),
                ),
            )
            callback.onResult(response)
        } catch (_: Throwable) {
            callback.onError(GetCredentialUnknownException())
        }
    }

    override fun onClearCredentialStateRequest(
        request: ProviderClearCredentialStateRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<Void?, ClearCredentialException>,
    ) {
        // No persisted credential-selection state is maintained by the provider.
        callback.onResult(null)
    }

    private fun uniqueRequestCode(): Int = (System.currentTimeMillis() and 0x7fffffff).toInt()
}
