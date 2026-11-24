import 'package:flutter/material.dart';

/// Direction-aware icons and alignments for user-facing chrome.
///
/// Flutter mirrors `EdgeInsetsDirectional` and `AlignmentDirectional`, but
/// material arrow and chevron glyphs are physical: an "arrow back" pointing
/// left is wrong in an RTL locale. These getters pick the mirrored glyph from
/// the ambient [Directionality] instead.
extension DirectionalChrome on BuildContext {
  /// Whether the ambient text direction is right-to-left.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Arrow that points towards the previous screen.
  IconData get backArrow =>
      isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;

  /// Arrow that points towards the next screen.
  IconData get forwardArrow =>
      isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;

  /// Chevron that points towards more content at the end of a row.
  IconData get forwardChevron =>
      isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;

  /// Physical alignment of the reading start edge.
  AlignmentGeometry get alignStart =>
      isRtl ? Alignment.centerRight : Alignment.centerLeft;

  /// Physical alignment of the reading end edge.
  AlignmentGeometry get alignEnd =>
      isRtl ? Alignment.centerLeft : Alignment.centerRight;
}
