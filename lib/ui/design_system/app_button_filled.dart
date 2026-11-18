import 'dart:async';

import 'package:flutter/material.dart';
import 'package:keyel/ui/design_system/app_button_spec.dart';
import 'package:keyel/ui/keyel.dart';

/// The filled variants of [AppButtonFilled]: a solid action and its outlined twin.
class AppButtonFilled {
  /// Creates the filled button variants.
  const new();

  /// Resolves the minimum size for the button.
  static Size? _resolveMinSize(AppButtonSpec spec) {
    final base = spec.minimumSize;
    if (base != null) {
      return spec.isFullWidth ? Size(0, base.height) : base;
    }
    return null;
  }

  /// The primary action: a solid surface with the label on top of it.
  static Widget primary(AppButtonSpec spec) {
    final onPressed = spec.onPressed;

    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () async {
              unawaited(Haptics.light());
              onPressed();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: spec.fill,
        foregroundColor: spec.onFill,
        elevation: 0,
        padding: spec.metrics.padding(spec.context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
        textStyle: spec.labelStyle(),
        minimumSize: _resolveMinSize(spec),
      ),
      child: spec.isLoading ? spec.spinner(spec.onFill) : Text(spec.label!),
    );
  }

  /// The secondary action: an outline instead of a fill.
  static Widget secondary(AppButtonSpec spec) {
    final onPressed = spec.onPressed;

    return OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () async {
              unawaited(Haptics.light());
              onPressed();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: spec.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
        side: BorderSide(color: spec.accent),
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(weight: FontWeight.w500),
        minimumSize: _resolveMinSize(spec),
      ),
      child: spec.isLoading ? spec.spinner(spec.accent) : Text(spec.label!),
    );
  }
}
