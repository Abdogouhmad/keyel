import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/core/ota/ota_provider.dart';
import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// Global top banner announcing a newly discovered update.
///
/// It sits above the routed page, so it works on every screen without a snackbar
/// or dialog. Dismissing hides only the currently offered version.
class UpdateAvailableBanner extends ConsumerWidget {
  /// Creates the banner wrapper around the routed app.
  const new({required this.child, required this.onOpen, super.key});

  /// Routed app content below the banner.
  final Widget child;

  /// Opens the software-update screen.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(otaProvider);
    final l10n = l10nOf(context);
    final release = state.availableRelease;
    final visible =
        state.hasUpdate &&
        release != null &&
        release.version != state.dismissedVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: KeyelMotion.resolve(context, KeyelMotion.fast),
          curve: Curves.easeOut,
          child: visible
              ? SafeArea(
                  bottom: false,
                  child: Material(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Semantics(
                      container: true,
                      button: true,
                      label: l10n.otaBannerSemantics(release.version),
                      child: InkWell(
                        onTap: onOpen,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KeyelSpacing.md,
                            vertical: KeyelSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.system_update_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                              const SizedBox(width: KeyelSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.otaUpdateAvailableTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      l10n.otaAvailableSubtitle(
                                        release.version,
                                        state.channel.label,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                // Dismissing is a separate action, so a screen
                                // reader does not treat the whole banner as the
                                // only way to act.
                                tooltip: l10n.otaDismissBanner,
                                icon: const Icon(Icons.close_rounded),
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                                onPressed: () => unawaited(
                                  ref
                                      .read(otaProvider.notifier)
                                      .dismissUpdateBanner(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
