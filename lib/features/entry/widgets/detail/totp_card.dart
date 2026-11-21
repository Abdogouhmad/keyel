import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/src/rust/api/totp.dart' as totp_api;
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// Live two-factor code for an entry, refreshed once per period.
///
/// The code is computed in Rust and only re-fetched when the time step rolls
/// over, so the one-second ticker never crosses the bridge. The countdown ring
/// itself runs off the wall clock inside [KeyelTotpDisplay].
class EntryTotpCard extends StatefulWidget {
  /// Creates the TOTP card.
  const new({
    required this.entryId,
    required this.onCopy,
    this.period = 30,
    super.key,
  });

  /// Identifier of the entry whose stored secret is used.
  final String entryId;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Fallback period used before the first code arrives.
  final int period;

  @override
  State<EntryTotpCard> createState() => _EntryTotpCardState();
}

class _EntryTotpCardState extends State<EntryTotpCard> {
  TotpCodeDto? _code;
  Timer? _timer;
  int _counter = -1;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = _code?.period ?? widget.period;
    if (now ~/ period != _counter) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final code = await totp_api.currentCode(id: widget.entryId);
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      setState(() {
        _code = code;
        _counter = now ~/ code.period;
      });
    } on Object catch (_) {
      // A transient failure keeps the previous code on screen; the next
      // rollover retries automatically.
    }
  }

  void _copy() {
    final code = _code;
    if (code == null) return;
    widget.onCopy(code.code, l10nOf(context).entry2FaCodeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final code = _code;

    return KeyelSectionCard(
      title: l10n.entryTwoFactorCode,
      icon: Icons.phonelink_lock_rounded,
      showBorder: true,
      child: code == null
          ? Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: KeyelSpacing.sm),
                Text(
                  l10n.entryLoadingCode,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : KeyelTotpDisplay(
              code: code.code,
              period: code.period,
              onCopy: _copy,
            ),
    );
  }
}
