import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/ui/design_system/app_button_spec.dart';
import 'package:keyel/ui/keyel.dart';

/// The text and icon-only variants of [AppButtonQuiet].
class AppButtonQuiet {
  /// Creates the quiet button variants.
  const new();

  /// A flat text button.
  static Widget text(AppButtonSpec spec) {
    final onPressed = spec.onPressed;

    return TextButton(
      onPressed: onPressed == null
          ? null
          : () async {
              unawaited(Haptics.light());
              onPressed();
            },
      style: TextButton.styleFrom(
        foregroundColor: spec.accent,
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
      ),
      child: spec.isLoading ? spec.spinner(spec.accent) : Text(spec.label!),
    );
  }

  /// A text button with a leading icon.
  static Widget textIcon(AppButtonSpec spec) {
    final onPressed = spec.onPressed;

    return TextButton.icon(
      onPressed: onPressed == null
          ? null
          : () async {
              unawaited(Haptics.light());
              onPressed();
            },
      icon: Icon(spec.icon, size: 18),
      label: spec.isLoading ? spec.spinner(spec.accent) : Text(spec.label!),
      style: TextButton.styleFrom(
        foregroundColor: spec.accent,
        padding: spec.metrics.padding(spec.context),
        textStyle: spec.labelStyle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
      ),
    );
  }

  /// A square icon-only button.
  static Widget iconOnly(AppButtonSpec spec) {
    final onPressed = spec.onPressed;

    return IconButton(
      onPressed: onPressed == null
          ? null
          : () async {
              unawaited(Haptics.light());
              onPressed();
            },
      icon: Icon(spec.icon),
      tooltip: spec.tooltip,
      color: spec.accent,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KeyelRadii.field),
        ),
      ),
    );
  }
}
