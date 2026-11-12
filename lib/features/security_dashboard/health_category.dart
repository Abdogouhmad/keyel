import 'package:flutter/material.dart';

import 'package:keyel/src/rust/api/models.dart';

/// A category the health dashboard can list and explain.
enum HealthCategory {
  /// Passwords below the entropy threshold.
  weak('Weak passwords', 'High compromise risk', Icons.error_rounded),

  /// Passwords shared across more than one entry.
  reused('Reused passwords', 'Shared across services', Icons.sync_rounded),

  /// Passwords older than a year.
  old('Old passwords', 'More than 1 year old', Icons.history_rounded),

  /// Logins without a TOTP secret.
  noTwoFactor('Missing 2FA', 'TOTP supported', Icons.shield_rounded),

  /// Logins whose website uses plain HTTP.
  insecureUrl(
    'Insecure websites',
    'Sent over plain HTTP',
    Icons.no_encryption_rounded,
  );

  // The lint fires on the enum's own generative constructor.
  // ignore: unnecessary_type_name_in_constructor
  HealthCategory(this.title, this.subtitle, this.icon);

  /// Human title for the category.
  final String title;

  /// Short explanation shown under the title.
  final String subtitle;

  /// Category glyph.
  final IconData icon;
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
