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
import org.json.JSONObject

/**
 * Android Credential Manager provider service.
 *
 * Surfaces Keyel as a passkey provider on supported devices (Android 14+/API 34)
 * by advertising request-scoped credential actions in the system picker. Actual
 * WebAuthn create/get ceremonies, vault unlock, candidate selection, and key
 * operations are completed in [PasskeyHandlerActivity] via Flutter/Rust.
 *
 * Security notes:
 * - No private key material or secrets are stored or logged here.
 * - Only non-secret request metadata (e.g. RP context from the request) is used
 *   for surfacing and is attached to intents/bundles.
 * - Individual passkey account metadata lives inside the encrypted vault and is
 *   not enumerated here without user authentication/unlock; the handler performs
 *   in-vault matching and selection.
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
        const val EXTRA_RP_ID = "rpId"
    }

    override fun onBeginCreateCredentialRequest(
        request: BeginCreateCredentialRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<BeginCreateCredentialResponse, CreateCredentialException>,
    ) {
        try {
            when (request) {
                is BeginCreatePublicKeyCredentialRequest -> {
                    val rpId = extractRpId(request.requestJson)
                    val rpName = extractRpName(request.requestJson) ?: rpId
                    val accountName = when {
                        !rpName.isNullOrBlank() -> "Save passkey for $rpName"
                        !rpId.isNullOrBlank() -> "Save passkey for $rpId"
                        else -> "Save passkey in Keyel"
                    }

                    val intent = Intent(ACTION_CREATE_PASSKEY).apply {
                        setClass(
                            this@KeyelCredentialProviderService,
                            PasskeyHandlerActivity::class.java,
                        )
                        putExtra(EXTRA_REQUEST_JSON, request.requestJson)
                        rpId?.let { putExtra(EXTRA_RP_ID, it) }
                        request.clientDataHash?.let { putExtra(EXTRA_CLIENT_DATA_HASH, it) }
                    }
                    val pendingIntent = PendingIntent.getActivity(
                        this,
                        uniqueRequestCode(),
                        intent,
                        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )

                    callback.onResult(
                        BeginCreateCredentialResponse(
                            createEntries = listOf(
                                CreateEntry(
                                    accountName = accountName,
                                    pendingIntent = pendingIntent,
                                ),
                            ),
                        ),
                    )
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
            val seenOptionKeys = mutableSetOf<String>()

            for (option in request.beginGetCredentialOptions) {
                if (option is BeginGetPublicKeyCredentialOption) {
                    val rpId = extractRpId(option.requestJson).orEmpty()
                    val optionKey = rpId.ifBlank { option.requestJson.hashCode().toString() }
                    // Surface one RP-contextual Keyel entry per request option scope.
                    // Specific passkey accounts are selected after unlock in Keyel.
                    if (!seenOptionKeys.add(optionKey)) continue

                    val username = if (rpId.isNotEmpty()) {
                        "Passkey for $rpId"
                    } else {
                        "Passkey in Keyel"
                    }

                    val data = Bundle().apply {
                        if (rpId.isNotEmpty()) putString(EXTRA_RP_ID, rpId)
                    }
                    val intent = Intent(ACTION_GET_PASSKEY).apply {
                        setClass(
                            this@KeyelCredentialProviderService,
                            PasskeyHandlerActivity::class.java,
                        )
                        putExtra(EXTRA_REQUEST_JSON, option.requestJson)
                        if (rpId.isNotEmpty()) putExtra(EXTRA_RP_ID, rpId)
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
                            username = username,
                            pendingIntent = pendingIntent,
                            beginGetPublicKeyCredentialOption = option,
                        ),
                    )
                }
            }

            val authenticationActions =
                if (credentialEntries.isEmpty()) {
                    val unlockIntent = Intent(ACTION_UNLOCK_FOR_PASSKEY).apply {
                        setClass(
                            this@KeyelCredentialProviderService,
                            PasskeyHandlerActivity::class.java,
                        )
                    }
                    val unlockPendingIntent = PendingIntent.getActivity(
                        this,
                        uniqueRequestCode(),
                        unlockIntent,
                        PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )
                    listOf(
                        AuthenticationAction(
                            title = "Unlock Keyel",
                            pendingIntent = unlockPendingIntent,
                        ),
                    )
                } else {
                    emptyList()
                }

            callback.onResult(
                BeginGetCredentialResponse(
                    credentialEntries = credentialEntries,
                    authenticationActions = authenticationActions,
                ),
            )
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

    private fun extractRpId(requestJson: String?): String? {
        if (requestJson.isNullOrBlank()) return null
        return try {
            val obj = JSONObject(requestJson)
            when {
                obj.has("rpId") -> obj.optString("rpId").takeIf { it.isNotBlank() }
                obj.has("rp") -> obj.optJSONObject("rp")
                    ?.optString("id")
                    ?.takeIf { it.isNotBlank() }
                else -> null
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun extractRpName(requestJson: String?): String? {
        if (requestJson.isNullOrBlank()) return null
        return try {
            JSONObject(requestJson)
                .optJSONObject("rp")
                ?.optString("name")
                ?.takeIf { it.isNotBlank() }
        } catch (_: Throwable) {
            null
        }
    }

    private fun uniqueRequestCode(): Int =
        ((System.currentTimeMillis() and 0x7fffffff).toInt() xor hashCode())
}
