package com.freesoftware.keyel.passkeys

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Base64
import androidx.annotation.RequiresApi
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.provider.PendingIntentHandler
import androidx.credentials.provider.ProviderCreateCredentialRequest
import androidx.credentials.provider.ProviderGetCredentialRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.security.MessageDigest

/**
 * Handles the selection phase of Credential Manager provider requests.
 *
 * Hosts a Flutter UI (unlock/confirm/pick) and returns the resulting
 * WebAuthn response to the calling app. Key generation/signing and vault
 * persistence happen inside Rust/session boundaries; this activity only
 * shuttles request metadata and response JSON.
 */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
class PasskeyHandlerActivity : FlutterActivity() {

    private val channelName = "keyel/passkey"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Ensure we have a resolvable request early; fail closed if not.
        val action = intent?.action
        if (action == null) {
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRequest" -> result.success(buildRequestArgs())

                    "returnCreateResponse" -> {
                        val responseJson = call.argument<String>("responseJson")
                        if (responseJson.isNullOrBlank()) {
                            failCreate(CreateCredentialUnknownException("Missing response"))
                        } else {
                            try {
                                val intentResult = Intent()
                                PendingIntentHandler.setCreateCredentialResponse(
                                    intentResult,
                                    CreatePublicKeyCredentialResponse(responseJson),
                                )
                                setResult(Activity.RESULT_OK, intentResult)
                                finish()
                            } catch (e: Throwable) {
                                failCreate(CreateCredentialUnknownException(e.message ?: "Create failed"))
                            }
                        }
                        result.success(null)
                    }

                    "returnGetResponse" -> {
                        val responseJson = call.argument<String>("responseJson")
                        if (responseJson.isNullOrBlank()) {
                            failGet(GetCredentialUnknownException("Missing response"))
                        } else {
                            try {
                                val intentResult = Intent()
                                PendingIntentHandler.setGetCredentialResponse(
                                    intentResult,
                                    androidx.credentials.GetCredentialResponse(
                                        PublicKeyCredential(responseJson),
                                    ),
                                )
                                setResult(Activity.RESULT_OK, intentResult)
                                finish()
                            } catch (e: Throwable) {
                                failGet(GetCredentialUnknownException(e.message ?: "Get failed"))
                            }
                        }
                        result.success(null)
                    }

                    "cancel" -> {
                        val message = call.argument<String>("message")
                        when (intent?.action) {
                            KeyelCredentialProviderService.ACTION_CREATE_PASSKEY ->
                                failCreate(CreateCredentialUnknownException(message ?: "Canceled"))
                            else -> failGet(GetCredentialUnknownException(message ?: "Canceled"))
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun buildRequestArgs(): Map<String, Any?> {
        return try {
            when (intent?.action) {
                KeyelCredentialProviderService.ACTION_CREATE_PASSKEY -> {
                    val request = PendingIntentHandler.retrieveProviderCreateCredentialRequest(intent)
                    if (request == null) {
                        mapOf("mode" to "unknown")
                    } else {
                        val callingRequest = request.callingRequest
                        val requestJson = if (callingRequest is androidx.credentials.CreatePublicKeyCredentialRequest) {
                            callingRequest.requestJson
                        } else null
                        val origin = computeOrigin(request.callingAppInfo)
                        val rpId = extractRpId(requestJson)
                        mapOf(
                            "mode" to "create",
                            "requestJson" to requestJson,
                            "origin" to origin,
                            "rpId" to rpId,
                            "callingPackage" to request.callingAppInfo.packageName,
                        )
                    }
                }

                KeyelCredentialProviderService.ACTION_GET_PASSKEY,
                KeyelCredentialProviderService.ACTION_UNLOCK_FOR_PASSKEY -> {
                    val request = PendingIntentHandler.retrieveProviderGetCredentialRequest(intent)
                    if (request == null) {
                        // Unlock-only/auth action without a specific selection.
                        mapOf(
                            "mode" to "unlock",
                            "requestJson" to intent?.getStringExtra(KeyelCredentialProviderService.EXTRA_REQUEST_JSON),
                            "origin" to null,
                            "rpId" to extractRpId(intent?.getStringExtra(KeyelCredentialProviderService.EXTRA_REQUEST_JSON)),
                        )
                    } else {
                        val option = request.credentialOptions.firstOrNull {
                            it is androidx.credentials.GetPublicKeyCredentialOption
                        } as? androidx.credentials.GetPublicKeyCredentialOption
                        val requestJson = option?.requestJson
                        val origin = computeOrigin(request.callingAppInfo)
                        val rpId = extractRpId(requestJson)
                        mapOf(
                            "mode" to "get",
                            "requestJson" to requestJson,
                            "origin" to origin,
                            "rpId" to rpId,
                            "callingPackage" to request.callingAppInfo.packageName,
                        )
                    }
                }

                else -> mapOf("mode" to "unknown")
            }
        } catch (_: Throwable) {
            mapOf("mode" to "unknown")
        }
    }

    private fun extractRpId(requestJson: String?): String? {
        if (requestJson.isNullOrBlank()) return null
        return try {
            val obj = JSONObject(requestJson)
            when {
                obj.has("rpId") -> obj.optString("rpId", null)
                obj.has("rp") -> obj.optJSONObject("rp")?.optString("id", null)
                else -> null
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun computeOrigin(callingAppInfo: androidx.credentials.provider.CallingAppInfo?): String {
        if (callingAppInfo == null) return ""
        // Prefer an origin provided by the platform (e.g. privileged web callers)
        // when available in this library version.
        try {
            val method = callingAppInfo.javaClass.methods.firstOrNull { it.name == "getOrigin" && it.parameterCount == 0 }
            if (method != null) {
                val origin = method.invoke(callingAppInfo) as? String
                if (!origin.isNullOrBlank()) return origin
            }
        } catch (_: Throwable) {
            // Fall through to apk-key-hash origin.
        }

        return try {
            val cert = callingAppInfo.signingInfo.apkContentsSigners[0].toByteArray()
            val md = MessageDigest.getInstance("SHA-256")
            val certHash = md.digest(cert)
            val b64 = Base64.encodeToString(certHash, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
            "android:apk-key-hash:$b64"
        } catch (_: Throwable) {
            ""
        }
    }

    private fun failCreate(exception: CreateCredentialException) {
        try {
            val intentResult = Intent()
            PendingIntentHandler.setCreateCredentialException(intentResult, exception)
            setResult(Activity.RESULT_OK, intentResult)
        } catch (_: Throwable) {
            setResult(Activity.RESULT_CANCELED)
        }
        finish()
    }

    private fun failGet(exception: GetCredentialException) {
        try {
            val intentResult = Intent()
            PendingIntentHandler.setGetCredentialException(intentResult, exception)
            setResult(Activity.RESULT_OK, intentResult)
        } catch (_: Throwable) {
            setResult(Activity.RESULT_CANCELED)
        }
        finish()
    }

    override fun getDartEntrypointFunctionName(): String = "mainPasskey"

    companion object {
        // Intents/actions are defined on KeyelCredentialProviderService.
    }
}
