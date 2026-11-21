import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/core/router/keyel_routes.dart';
import 'package:keyel/core/security/screenshot_protection_host.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/data/breach_provider.dart';
import 'package:keyel/features/settings/widgets/settings_dialogs.dart'
    show autoLockLabel, clipboardLabel;
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// One protection shown as a seal on [SecurityPostureCard].
///
/// Deliberately a plain data object so the card itself can be tested with an
/// all-on or mixed posture without standing up providers or preferences.
@immutable
class SecurityPostureSeal {
  /// Creates a seal.
  const new({
    required this.label,
    required this.value,
    required this.icon,
    required this.active,
    required this.semanticsLabel,
  });

  /// Short name of the protection (e.g. "Auto-lock").
  final String label;

  /// Current setting, already formatted for display.
  final String value;

  /// Leading glyph.
  final IconData icon;

  /// Whether the protection is currently engaged.
  final bool active;

  /// Complete screen-reader description of this seal.
  final String semanticsLabel;
}

/// Immutable snapshot of the four protections derived from real app state.
@immutable
class SecurityPosture {
  /// Creates a posture from its four seals.
  const new({
    required this.autoLock,
    required this.clipboard,
    required this.screenshot,
    required this.breach,
  });

  /// Background auto-lock setting.
  final SecurityPostureSeal autoLock;

  /// Timed clipboard wipe setting.
  final SecurityPostureSeal clipboard;

  /// Screenshot / Recents blocking (unconditional on supported platforms).
  final SecurityPostureSeal screenshot;

  /// Opt-in breach-check setting.
  final SecurityPostureSeal breach;

  /// All four seals in display order.
  List<SecurityPostureSeal> get seals => [
    autoLock,
    clipboard,
    screenshot,
    breach,
  ];

  /// Number of protections currently engaged.
  int get activeCount => seals.where((seal) => seal.active).length;
}

/// Connects the posture card to the same non-secret state the features use.
///
/// Auto-lock and clipboard values come from [AppPreferences] (the source the
/// settings screen writes); the breach and screenshot flags are Riverpod
/// providers so toggling them updates this card immediately. No state is
/// duplicated.
class SecurityPostureCardConnector extends ConsumerWidget {
  /// Creates the connected posture card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = AppPreferences.instance;
    final optedIn = ref.watch(breachOptInProvider);
    final screenshotsBlocked = ref.watch(screenshotProtectionProvider);

    final l10n = l10nOf(context);
    final lockLabel = autoLockLabel(prefs.autoLockDelay);
    final clipboardSeconds = prefs.clipboardClearSeconds;
    final clipboardActive = clipboardSeconds > 0;
    final clipboardValue = clipboardActive
        ? clipboardLabel(clipboardSeconds)
        : l10n.secOnLockOnly;

    return SecurityPostureCard(
      posture: SecurityPosture(
        autoLock: SecurityPostureSeal(
          label: l10n.autoLockTitle,
          value: lockLabel,
          icon: Icons.lock_clock_rounded,
          active: true,
          semanticsLabel: l10n.secAutoLockSemantics(lockLabel),
        ),
        clipboard: SecurityPostureSeal(
          label: l10n.secClipboardWipe,
          value: clipboardValue,
          icon: Icons.content_paste_off_rounded,
          active: clipboardActive,
          semanticsLabel: clipboardActive
              ? l10n.secClipboardActiveSemantics(clipboardValue)
              : l10n.secClipboardInactiveSemantics,
        ),
        screenshot: SecurityPostureSeal(
          label: l10n.secScreenshotBlocking,
          value: screenshotsBlocked ? l10n.secEnabled : l10n.secOff,
          icon: Icons.no_photography_rounded,
          active: screenshotsBlocked,
          semanticsLabel: screenshotsBlocked
              ? l10n.secScreenshotActiveSemantics
              : l10n.secScreenshotInactiveSemantics,
        ),
        breach: SecurityPostureSeal(
          label: l10n.secBreachCheck,
          value: optedIn ? l10n.secEnabled : l10n.secOff,
          icon: Icons.gpp_good_rounded,
          active: optedIn,
          semanticsLabel: optedIn
              ? l10n.secBreachActiveSemantics
              : l10n.secBreachInactiveSemantics,
        ),
      ),
      // `settings` is a shell branch, so push() used to strand the user on a
      // page without the tab bar. go() switches branches and keeps navigation
      // chrome; ?from=security adds an explicit back arrow in Settings.
      onReviewSettings: () =>
          context.go('${KeyelRoutes.settings}?from=security'),
    );
  }
}

/// Information-bearing card showing the vault's current security posture.
///
/// The seals reveal in a restrained stagger on first build. The whole sequence
/// resolves through [KeyelMotion.resolve], so it disappears for users with
/// reduced motion or animations disabled in Settings.
class SecurityPostureCard extends StatefulWidget {
  /// Creates the posture card for [posture].
  const new({required this.posture, required this.onReviewSettings, super.key});

  /// The state to display.
  final SecurityPosture posture;

  /// Opens the settings screen when "Review settings" is tapped.
  final VoidCallback onReviewSettings;

  @override
  State<SecurityPostureCard> createState() => _SecurityPostureCardState();
}

class _SecurityPostureCardState extends State<SecurityPostureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final duration = KeyelMotion.resolve(context, KeyelMotion.medium);
    _controller.duration = duration;
    if (duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _sealAnimation(int index) {
    final count = widget.posture.seals.length;
    final step = 0.4 / count;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        index * step,
        0.6 + index * step,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final posture = widget.posture;
    final allActive = posture.activeCount == posture.seals.length;
    final badgeColor = allActive ? scheme.strong : scheme.fair;
    final badgeBackground = allActive
        ? scheme.strongContainer
        : scheme.fairContainer;

    return Semantics(
      container: true,
      label: l10n.secVaultPostureSemantics(
        '${posture.activeCount}',
        '${posture.seals.length}',
      ),
      child: Container(
        padding: const EdgeInsets.all(KeyelSpacing.lg - 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KeyelRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(KeyelRadii.field),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: KeyelSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.secVaultPosture,
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.secVaultPostureSubtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KeyelSpacing.xs),
                KeyelBadge(
                  label: '${posture.activeCount}/${posture.seals.length}',
                  compact: true,
                  background: badgeBackground,
                  foreground: badgeColor,
                ),
              ],
            ),
            const SizedBox(height: KeyelSpacing.md),
            for (var i = 0; i < posture.seals.length; i++)
              _SealTile(
                seal: posture.seals[i],
                animation: _sealAnimation(i),
                transitionKey: ValueKey<String>('posture-seal-$i'),
              ),
            const SizedBox(height: KeyelSpacing.md),
            KeyelPillButton(
              label: l10n.secReviewSettings,
              icon: Icons.tune_rounded,
              tone: KeyelButtonTone.neutral,
              height: 48,
              onPressed: widget.onReviewSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _SealTile extends StatelessWidget {
  const new({
    required this.seal,
    required this.animation,
    required this.transitionKey,
  });

  final SecurityPostureSeal seal;
  final Animation<double> animation;

  /// Lets layout tests find this seal's transition among other fades.
  final Key transitionKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = seal.active ? scheme.strong : scheme.onSurfaceVariant;
    final background = seal.active
        ? scheme.strongContainer
        : scheme.surfaceContainerHigh;

    return Semantics(
      label: seal.semanticsLabel,
      child: FadeTransition(
        key: transitionKey,
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: KeyelSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(KeyelRadii.sm),
                  ),
                  child: Icon(seal.icon, size: 18, color: accent),
                ),
                const SizedBox(width: KeyelSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seal.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        seal.value,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KeyelSpacing.xs),
                Icon(
                  seal.active
                      ? Icons.verified_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
