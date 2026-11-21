import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// A category the health dashboard can list and explain.
enum HealthCategory {
  /// Passwords below the entropy threshold.
  weak(Icons.error_rounded),

  /// Passwords shared across more than one entry.
  reused(Icons.sync_rounded),

  /// Passwords older than a year.
  old(Icons.history_rounded),

  /// Logins without a TOTP secret.
  noTwoFactor(Icons.shield_rounded),

  /// Logins whose website uses plain HTTP.
  insecureUrl(Icons.no_encryption_rounded);

  // The lint fires on the enum's own generative constructor.
  // ignore: unnecessary_type_name_in_constructor
  HealthCategory(this.icon);

  /// Category glyph.
  final IconData icon;

  /// Human title for the category.
  String get title => switch (this) {
    HealthCategory.weak => currentL10n.secWeakPasswords,
    HealthCategory.reused => currentL10n.secReusedPasswords,
    HealthCategory.old => currentL10n.secOldPasswords,
    HealthCategory.noTwoFactor => currentL10n.secMissingTwoFactor,
    HealthCategory.insecureUrl => currentL10n.secInsecureWebsites,
  };

  /// Short explanation shown under the title.
  String get subtitle => switch (this) {
    HealthCategory.weak => currentL10n.secHighCompromiseRisk,
    HealthCategory.reused => currentL10n.secSharedAcrossServices,
    HealthCategory.old => currentL10n.secMoreThanOneYearOld,
    HealthCategory.noTwoFactor => currentL10n.secTotpSupported,
    HealthCategory.insecureUrl => currentL10n.secSentOverPlainHttp,
  };
}

/// The entries affected by [category] in [report].
List<HealthIssueDto> issuesFor(
  HealthReportDto report,
  HealthCategory category,
) => switch (category) {
  HealthCategory.weak => report.weak,
  HealthCategory.reused => [
    for (final group in report.reused) ...group.entries,
  ],
  HealthCategory.old => report.old,
  HealthCategory.noTwoFactor => report.noTwoFactor,
  HealthCategory.insecureUrl => report.insecureUrl,
};

/// Number of entries affected by [category].
int countFor(HealthReportDto report, HealthCategory category) =>
    issuesFor(report, category).length;

/// The first category that has issues, or `null` when the vault is clean.
HealthCategory? primaryCategory(HealthReportDto report) {
  for (final category in HealthCategory.values) {
    if (countFor(report, category) > 0) return category;
  }
  return null;
}
