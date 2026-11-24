import 'package:flutter/material.dart';

import 'package:keyel/ui/l10n/l10n.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

/// The 56 dp full-pill search bar used across the vault.
class KeyelSearchField extends StatefulWidget {
  /// Creates a search bar.
  const new({
    this.controller,
    this.hintText,
    this.onChanged,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  /// Optional controller owned by the caller.
  final TextEditingController? controller;

  /// Placeholder copy, or `null` for the localized default.
  final String? hintText;

  /// Live query callback.
  final ValueChanged<String>? onChanged;

  /// Optional action shown at the end of the bar.
  final Widget? trailing;

  /// Whether the field grabs focus on first build.
  final bool autofocus;

  /// Optional focus node owned by the caller (used by the global find action).
  /// When omitted the field creates and disposes its own node.
  final FocusNode? focusNode;

  @override
  State<KeyelSearchField> createState() => _KeyelSearchFieldState();
}

class _KeyelSearchFieldState extends State<KeyelSearchField> {
  late final FocusNode _ownedFocusNode;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownedFocusNode = FocusNode();
    _focusNode = widget.focusNode ?? _ownedFocusNode;
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    if (widget.focusNode == null) _ownedFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: KeyelMotion.resolve(context, KeyelMotion.fast),
      curve: Curves.easeOut,
      height: 56,
      decoration: BoxDecoration(
        color: _focused ? scheme.surfaceContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KeyelRadii.pill),
        border: Border.all(
          color: _focused ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: KeyelSpacing.sm),
          SizedBox(
            width: 40,
            child: Icon(
              Icons.search_rounded,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: widget.hintText ?? l10nOf(context).searchHint,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          if (widget.trailing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: KeyelSpacing.sm),
              child: widget.trailing,
            ),
        ],
      ),
    );
  }
}
