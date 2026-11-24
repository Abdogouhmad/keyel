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
    this.loadCode,
    this.now = DateTime.now,
    super.key,
  });

  /// Identifier of the entry whose stored secret is used.
  final String entryId;

  /// Copies a value to the clipboard with feedback.
  final void Function(String value, String message) onCopy;

  /// Fallback period used before the first code arrives.
  final int period;

  /// Optional code source for tests. Production always uses the Rust bridge.
  final Future<TotpCodeDto> Function(String entryId)? loadCode;

  /// Injectable clock so period rollover can be tested deterministically.
  final DateTime Function() now;

  @override
  State<EntryTotpCard> createState() => _EntryTotpCardState();
}

class _EntryTotpCardState extends State<EntryTotpCard>
    with WidgetsBindingObserver {
  TotpCodeDto? _code;
  Timer? _timer;
  int _counter = -1;
  int _period = 30;
  bool _foreground = true;

  /// Invalidates a refresh that is still waiting on the Rust bridge.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _period = widget.period;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // A one-time code should not be readable from a background snapshot, and
      // a bridge response that lands after this point must not bring it back.
      _foreground = false;
      _generation++;
      if (mounted && _code != null) {
        setState(() {
          _code = null;
          _counter = -1;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _generation++;
      if (mounted) unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    // Backgrounding must not turn the ticker into a one-per-second bridge poll.
    if (!_foreground) return;
    final now = widget.now().millisecondsSinceEpoch ~/ 1000;
    if (now ~/ _period != _counter) {
      // Drop the previous code at rollover instead of leaving an expired code
      // on screen while the replacement is being computed.
      // Record the attempt so the ticker does not call the bridge again on
      // every second while a slow refresh is still in flight.
      _counter = now ~/ _period;
      if (_code != null && mounted) setState(() => _code = null);
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (!_foreground) return;
    final generation = _generation;
    final requestedAt = widget.now().millisecondsSinceEpoch ~/ 1000;
    final load = widget.loadCode ?? (String id) => totp_api.currentCode(id: id);
    try {
      final code = await load(widget.entryId);
      if (!mounted || !_foreground || generation != _generation) return;
      final currentCounter =
          widget.now().millisecondsSinceEpoch ~/ 1000 ~/ code.period;
      if (currentCounter != requestedAt ~/ code.period) {
        // The response crossed a period boundary, so the code is already
        // expired. Retry on the next rollover rather than showing a stale code.
        if (_code != null) {
          setState(() {
            _code = null;
            _counter = currentCounter;
            _period = code.period;
          });
        }
        return;
      }
      setState(() {
        _code = code;
        _counter = currentCounter;
        _period = code.period;
      });
    } on Object catch (_) {
      if (!mounted || generation != _generation) return;
      // Never keep an expired code on screen, but do record this counter so a
      // failed bridge call does not retry every second.
      final now = widget.now().millisecondsSinceEpoch ~/ 1000;
      setState(() {
        _code = null;
        _counter = now ~/ _period;
      });
    }
  }

  void _copy() {
    final code = _code;
    if (code == null || !_foreground) return;
    final now = widget.now().millisecondsSinceEpoch ~/ 1000;
    if (now ~/ code.period != _counter) {
      if (mounted) setState(() => _code = null);
      return;
    }
    widget.onCopy(code.code, l10nOf(context).entry2FaCodeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = l10nOf(context);
    final now = widget.now().millisecondsSinceEpoch ~/ 1000;
    final code = _code != null && now ~/ _code!.period == _counter
        ? _code
        : null;

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
