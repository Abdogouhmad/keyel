import 'package:flutter/material.dart';

import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/keyel.dart';

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
    required this.onOpenWebsite,
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

  /// Opens the entry's website.
  final VoidCallback onOpenWebsite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final username = detail.login?.username ?? entry.username;
    final isRevealed = revealedPassword != null;
    final displayPass = isRevealed ? revealedPassword! : '••••••••••••';

    return KeyelSectionCard(
      title: 'Credentials',
      icon: Icons.key_rounded,
      showBorder: true,
      child: Column(
        children: [
          if (username.isNotEmpty)
            KeyelFieldSurface(
              label: 'Username',
              trailing: KeyelIconHull(
                icon: Icons.content_copy_rounded,
                tooltip: 'Copy username',
                onPressed: () =>
                    onCopy(username, 'Username copied to clipboard'),
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
            label: 'Password',
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
                    tooltip: isRevealed ? 'Hide password' : 'Reveal password',
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
                    tooltip: 'Copy password',
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
          if ((detail.login?.url ?? '').isNotEmpty) ...[
            const SizedBox(height: KeyelSpacing.sm + 4),
            KeyelFieldSurface(
              label: 'Website URL',
              trailing: KeyelIconHull(
                icon: Icons.open_in_new_rounded,
                tooltip: 'Website link',
                onPressed: onOpenWebsite,
                background: scheme.surfaceContainerHighest,
              ),
              child: Text(
                detail.login!.url,
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
          ],
        ],
      ),
    );
  }
}
