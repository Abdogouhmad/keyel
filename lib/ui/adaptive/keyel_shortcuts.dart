import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intent dispatched when the user triggers global find (Ctrl+F / Cmd+F).
class KeyelFindIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Intent dispatched when the user triggers "new item" (Ctrl+N / Cmd+N).
class KeyelNewEntryIntent extends Intent {
  /// Creates the intent.
  const new();
}

/// Global keyboard shortcut scaffold for the adaptive shell.
///
/// Wraps [child] with [Shortcuts] and [Actions] so screens and text fields
/// can participate without each one re-registering bindings. Screen-level
/// behaviour arrives via [onFind] and [onNewEntry] callbacks.
class KeyelShortcuts extends StatelessWidget {
  /// Creates the shortcut wrapper.
  const new({required this.child, this.onFind, this.onNewEntry, super.key});

  /// Wrapped content.
  final Widget child;

  /// Handler for the find shortcut.
  final VoidCallback? onFind;

  /// Handler for the new-entry shortcut.
  final VoidCallback? onNewEntry;

  static Map<ShortcutActivator, Intent> get _shortcuts => {
    // Control for Windows/Linux/desktop web, Meta for macOS.
    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
        const KeyelFindIntent(),
    const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
        const KeyelFindIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const KeyelNewEntryIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
        const KeyelNewEntryIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          KeyelFindIntent: CallbackAction<KeyelFindIntent>(
            onInvoke: (_) => onFind?.call(),
          ),
          KeyelNewEntryIntent: CallbackAction<KeyelNewEntryIntent>(
            onInvoke: (_) => onNewEntry?.call(),
          ),
        },
        child: child,
      ),
    );
  }
}
