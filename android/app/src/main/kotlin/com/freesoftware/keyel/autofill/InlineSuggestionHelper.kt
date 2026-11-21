package com.freesoftware.keyel.autofill

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.service.autofill.Dataset
import android.service.autofill.FillRequest
import android.service.autofill.InlinePresentation
import android.view.inputmethod.InlineSuggestionsRequest
import androidx.annotation.RequiresApi
import androidx.autofill.inline.UiVersions
import androidx.autofill.inline.v1.InlineSuggestionUi
import com.freesoftware.keyel.R

/**
 * Adds an Android 11+ inline suggestion chip to the auth-gated dataset.
 *
 * The chip contains only static, non-secret copy. Tapping it runs the same
 * authentication PendingIntent as the normal dropdown row, so no credential is
 * ever placed in the IME surface. If the IME does not advertise the V1 style or
 * allows no suggestions, we simply do nothing and keep the existing behaviour.
 */
object InlineSuggestionHelper {

    @RequiresApi(Build.VERSION_CODES.R)
    @SuppressLint("RestrictedApi")
    fun attach(
        datasetBuilder: Dataset.Builder,
        request: FillRequest,
        authIntent: PendingIntent,
        context: Context,
    ) {
        val inlineRequest: InlineSuggestionsRequest =
            request.inlineSuggestionsRequest ?: return
        if (inlineRequest.maxSuggestionCount <= 0) return
        val spec = inlineRequest.inlinePresentationSpecs.firstOrNull() ?: return
        if (!UiVersions.getVersions(spec.style)
                .contains(UiVersions.INLINE_UI_VERSION_1)
        ) {
            return
        }

        val slice = InlineSuggestionUi.newContentBuilder(authIntent)
            .setTitle(context.getString(R.string.autofill_inline_title))
            .setSubtitle(context.getString(R.string.autofill_inline_subtitle))
            .build()
            .slice
        datasetBuilder.setInlinePresentation(
            InlinePresentation(slice, spec, /* pinned= */ false),
        )
    }
}
