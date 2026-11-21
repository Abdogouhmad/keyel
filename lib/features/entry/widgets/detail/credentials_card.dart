import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Username, password and website block for login entries.
class CredentialsCard extends StatelessWidget {
  /// Creates the credentials card.
  const new({
    required this.entry,
    required this.detail,
    required this.revealedPassword,
    required this.onToggleReveal,
    required this.onCopy,
    required this.onCopyPassword,
    required this.onOpenUrl,
    super.key,
  });

  /// Entry being displayed.
  final VaultEntry entry;

  /// Detail record of the entry.
  final EntryDetailDto detail;

  /// Plaintext password when revealed, otherwise `null`.
  final String? revealedPassword;

  /// Called to reveal or hide the password.
  final VoidCallback onToggleReveal;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Copies the password, revealing it first if needed.
  final VoidCallback onCopyPassword;

  /// Opens a URL shown on the credentials card.
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final username = detail.login?.username ?? entry.username;
    final url = detail.login?.url ?? '';
    final isRevealed = revealedPassword != null;
    final displayPass = isRevealed ? revealedPassword! : '••••••••••••';

    return KeyelSectionCard(
      title: l10n.entryCredentials,
      icon: Icons.key_rounded,
      showBorder: true,
      child: Column(
        children: [
          if (username.isNotEmpty)
            KeyelFieldSurface(
              label: l10n.fieldUsername,
              leading: _FieldIcon(Icons.person_outline_rounded, scheme),
              trailing: KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: l10n.entryCopyUsername,
                onPressed: () => onCopy(username, l10n.entryUsernameCopied),
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (username.isNotEmpty) const SizedBox(height: KeyelSpacing.sm + 4),
          KeyelFieldSurface(
            label: l10n.fieldPassword,
            leading: _FieldIcon(Icons.key_rounded, scheme),
            // A revealed secret gets a soft tint so its sensitive state is
            // obvious at a glance without exposing it to a screenshot buffer.
            color: isRevealed
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : null,
            trailing: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(KeyelRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyelIconHull(
                    icon: isRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    tooltip: isRevealed
                        ? l10n.entryHidePassword
                        : l10n.entryRevealPassword,
                    onPressed: onToggleReveal,
                    size: 44,
                    iconSize: 20,
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  KeyelIconHull(
                    icon: Icons.content_copy_rounded,
                    tooltip: l10n.entryCopyPassword,
                    onPressed: onCopyPassword,
                    foreground: scheme.primary,
                    size: 44,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            child: Text(
              displayPass,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KeyelTheme.mono(
                context,
                fontSize: isRevealed ? 18 : 19,
                fontWeight: FontWeight.w700,
                letterSpacing: isRevealed ? 1.2 : 3,
              ),
            ),
          ),
          if (url.isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            PressableScale(
              onTap: () => onOpenUrl(url),
              borderRadius: BorderRadius.circular(KeyelRadii.field),
              semanticLabel: l10n.entryOpenWebsite,
              child: KeyelFieldSurface(
                label: l10n.entryWebsiteUrl,
                leading: _FieldIcon(Icons.language_rounded, scheme),
                trailing: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(KeyelRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeyelIconHull(
                        icon: Icons.content_copy_rounded,
                        tooltip: l10n.entryCopyWebsiteUrl,
                        onPressed: () =>
                            onCopy(url, l10n.entryWebsiteUrlCopied),
                        size: 44,
                        iconSize: 20,
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                      KeyelIconHull(
                        icon: Icons.open_in_new_rounded,
                        tooltip: l10n.entryOpenWebsite,
                        onPressed: () => onOpenUrl(url),
                        foreground: scheme.primary,
                        size: 44,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small tonal glyph tile that anchors a credential field.
class _FieldIcon extends StatelessWidget {
  const new(this.icon, this.scheme);

  final IconData icon;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(KeyelRadii.field),
    ),
    child: Icon(icon, size: 20, color: scheme.primary),
  );
}
