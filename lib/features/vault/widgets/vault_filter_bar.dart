import 'package:flutter/material.dart';
import 'package:keyel/features/vault/widgets/vault_filter.dart';
import 'package:keyel/ui/keyel.dart';

/// Horizontally scrolling row of filter chips for the vault.
class VaultFilterBar extends StatelessWidget {
  /// Creates the filter bar.
  const new({required this.filter, required this.onFilter, super.key});

  /// Currently selected filter family.
  final VaultFilter filter;

  /// Called with the newly selected filter family.
  final ValueChanged<VaultFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
      child: Row(
        children: [
          for (final candidate in VaultFilter.values) ...[
            KeyelFilterChip(
              label: candidate.label,
              selected: filter == candidate,
              onTap: () => onFilter(candidate),
            ),
            if (candidate != VaultFilter.values.last)
              const SizedBox(width: KeyelSpacing.sm),
          ],
        ],
      ),
    );
  }
}
