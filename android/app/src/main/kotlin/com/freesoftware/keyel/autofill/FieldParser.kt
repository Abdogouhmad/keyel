package com.freesoftware.keyel.autofill

import android.app.assist.AssistStructure
import android.text.InputType
import android.view.View
import android.view.autofill.AutofillId

/**
 * Describes a single autofillable field found in the [AssistStructure].
 */
data class ParsedField(
    val autofillId: AutofillId,
    val kind: FieldKind,
)

/**
 * The semantic role of an autofill field.
 */
enum class FieldKind {
    USERNAME,
    EMAIL,
    PASSWORD,
}

/**
 * Result of walking an [AssistStructure]: the fields we can fill and the
 * identity of the requesting app / web domain.
 */
data class ParseResult(
    val fields: List<ParsedField>,
    val packageName: String?,
    val webDomain: String?,
) {
    val hasUsername get() = fields.any { it.kind == FieldKind.USERNAME || it.kind == FieldKind.EMAIL }
    val hasPassword get() = fields.any { it.kind == FieldKind.PASSWORD }

    fun usernameIds(): List<AutofillId> =
        fields.filter { it.kind == FieldKind.USERNAME || it.kind == FieldKind.EMAIL }
            .map { it.autofillId }

    fun passwordIds(): List<AutofillId> =
        fields.filter { it.kind == FieldKind.PASSWORD }
            .map { it.autofillId }
}

/**
 * Credentials the user submitted in a login form, captured by the framework
 * so the save flow can offer to store them.
 */
data class SaveCredentials(
    val username: String,
    val password: String,
)

/**
 * Walks the [AssistStructure] and finds username, email and password fields
 * along with the requesting package / web domain.
 *
 * Matching uses Android autofill hints first, then falls back to
 * [android.view.View] input types.
 */
object FieldParser {

    /** Safety bound to prevent pathological / malicious layouts from blowing the stack. */
    private const val MAX_NODES = 500

    fun parse(structures: List<AssistStructure>): ParseResult {
        val fields = mutableListOf<ParsedField>()
        var packageName: String? = null
        var nodeBudget = MAX_NODES

        for (structure in structures) {
            for (i in 0 until structure.windowNodeCount) {
                val windowNode = structure.getWindowNodeAt(i)
                val rootView = windowNode.rootViewNode ?: continue

                if (nodeBudget > 0) {
                    nodeBudget = walkNode(rootView, fields, nodeBudget)
                }

                if (packageName == null) {
                    packageName = rootView.idPackage
                }
            }
        }

        // Fallback: if we still don't have the package name, look through
        // all nodes for any idPackage.
        if (packageName == null) {
            for (structure in structures) {
                for (i in 0 until structure.windowNodeCount) {
                    val root = structure.getWindowNodeAt(i).rootViewNode ?: continue
                    packageName = findPackage(root)
                    if (packageName != null) break
                }
                if (packageName != null) break
            }
        }

        // Only trust webDomain when it comes from an actual WebView node.
        // ViewNode.webDomain is otherwise unused/undefined for native views.
        val webDomain = findWebViewDomain(structures)

        return ParseResult(
            fields = fields,
            packageName = packageName,
            webDomain = webDomain,
        )
    }

    /**
     * Reads the values the user submitted in a login form so the save flow
     * can offer to store them.
     *
     * Returns `null` when no password value was captured: without a password
     * there is nothing worth saving.
     */
    fun extractSaveCredentials(structures: List<AssistStructure>): SaveCredentials? {
        val accumulator = SaveAccumulator()
        for (structure in structures) {
            for (i in 0 until structure.windowNodeCount) {
                val root = structure.getWindowNodeAt(i).rootViewNode ?: continue
                collectSaveValues(root, accumulator)
            }
        }
        val password = accumulator.password ?: return null
        return SaveCredentials(username = accumulator.username, password = password)
    }

    /** Mutable holder used while walking for a save request. */
    private class SaveAccumulator {
        var username = ""
        var password: String? = null
    }

    private fun collectSaveValues(node: AssistStructure.ViewNode, accumulator: SaveAccumulator) {
        val value = node.autofillValue?.textValue?.toString()
        if (!value.isNullOrEmpty()) {
            when (classifyNode(node)) {
                FieldKind.PASSWORD ->
                    if (accumulator.password == null) accumulator.password = value
                FieldKind.USERNAME, FieldKind.EMAIL ->
                    if (accumulator.username.isEmpty()) accumulator.username = value
                null -> Unit
            }
        }
        for (i in 0 until node.childCount) {
            collectSaveValues(node.getChildAt(i), accumulator)
        }
    }

    /**
     * Walks the node tree, collecting fields and returning the remaining
     * node budget.
     */
    private fun walkNode(
        node: AssistStructure.ViewNode,
        out: MutableList<ParsedField>,
        budget: Int,
    ): Int {
        var remaining = budget - 1
        if (remaining <= 0) return remaining

        val id = node.autofillId
        if (id != null) {
            val kind = classifyNode(node)
            if (kind != null) {
                out.add(ParsedField(autofillId = id, kind = kind))
            }
        }

        for (i in 0 until node.childCount) {
            remaining = walkNode(node.getChildAt(i), out, remaining)
            if (remaining <= 0) return remaining
        }
        return remaining
    }

    /**
     * Classify a node by its autofill hints first, then by input type.
     */
    private fun classifyNode(node: AssistStructure.ViewNode): FieldKind? {
        // Prefer explicit autofill hints.
        val hints = node.autofillHints
        if (hints != null) {
            for (hint in hints) {
                when {
                    hint.equals(View.AUTOFILL_HINT_USERNAME, ignoreCase = true) ->
                        return FieldKind.USERNAME
                    hint.equals(View.AUTOFILL_HINT_EMAIL_ADDRESS, ignoreCase = true) ->
                        return FieldKind.EMAIL
                    hint.equals(View.AUTOFILL_HINT_PASSWORD, ignoreCase = true) ->
                        return FieldKind.PASSWORD
                    // Constant is API 26+; literal works on all versions and
                    // matches what web views put in autofillHints.
                    hint.equals("newPassword", ignoreCase = true) ->
                        return FieldKind.PASSWORD
                }
            }
        }

        // Fall back to input type when no hints are set.
        val inputType = node.inputType
        if (inputType <= 0) return null

        val variation = inputType and InputType.TYPE_MASK_VARIATION
        val cls = inputType and InputType.TYPE_MASK_CLASS

        return when {
            cls == InputType.TYPE_CLASS_TEXT &&
                (variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                    variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                    variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD) ->
                FieldKind.PASSWORD

            cls == InputType.TYPE_CLASS_TEXT &&
                (variation == InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS ||
                    variation == InputType.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS) ->
                FieldKind.EMAIL

            else -> null
        }
    }

    private fun findPackage(node: AssistStructure.ViewNode): String? {
        node.idPackage?.let { return it }
        for (i in 0 until node.childCount) {
            findPackage(node.getChildAt(i))?.let { return it }
        }
        return null
    }

    /**
     * Returns the webDomain from the first node that actually is a WebView
     * (identified by class name), so that a stray WebView embedded in a
     * native app cannot spoof the domain for native fields.
     */
    private fun findWebViewDomain(structures: List<AssistStructure>): String? {
        for (structure in structures) {
            for (i in 0 until structure.windowNodeCount) {
                val root = structure.getWindowNodeAt(i).rootViewNode ?: continue
                findWebViewDomain(root)?.let { return it }
            }
        }
        return null
    }

    private fun findWebViewDomain(node: AssistStructure.ViewNode): String? {
        if (node.webDomain != null && isWebView(node)) {
            return node.webDomain
        }
        for (i in 0 until node.childCount) {
            findWebViewDomain(node.getChildAt(i))?.let { return it }
        }
        return null
    }

    private fun isWebView(node: AssistStructure.ViewNode): Boolean {
        val cls = node.className ?: return false
        return cls == "android.webkit.WebView" || cls.endsWith(".WebView")
    }
}
