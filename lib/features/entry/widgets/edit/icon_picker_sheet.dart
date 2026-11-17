import 'package:flutter/material.dart';
import 'package:keyel/features/entry/models/entry_icon.dart';
import 'package:keyel/features/entry/vault_entry.dart';
import 'package:keyel/ui/keyel.dart';

/// Modal bottom sheet allowing the user to select an icon for a vault entry.
class IconPickerSheet extends StatefulWidget {
  /// Creates the icon picker sheet.
  const new({
    required this.selectedKey,
    required this.kind,
    required this.title,
    super.key,
  });

  /// Currently selected icon key, or null for default.
  final String? selectedKey;

  /// Entry kind for default icon display.
  final VaultEntryKind kind;

  /// Current title of the entry (for preview and suggestions).
  final String title;

  /// Shows the icon picker modal sheet.
  static Future<String?> show(
    BuildContext context, {
    required String? currentKey,
    required VaultEntryKind kind,
    required String title,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          IconPickerSheet(selectedKey: currentKey, kind: kind, title: title),
    );
  }

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  EntryIconCategory _selectedCategory = EntryIconCategory.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EntryIcon> get _filteredIcons {
    return kEntryIconCatalog.where((icon) {
      if (_selectedCategory != EntryIconCategory.all &&
          icon.category != _selectedCategory) {
        return false;
      }
      return icon.matches(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    final filtered = _filteredIcons;
    final suggested = widget.selectedKey == null
        ? suggestEntryIcon(widget.title, null)
        : null;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KeyelRadii.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: KeyelSpacing.xs),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(KeyelRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: KeyelSpacing.sm),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Icon',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Select an icon for this entry',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.selectedKey != null)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(''),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const SizedBox(height: KeyelSpacing.xs),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KeyelSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search icons (e.g. GitHub, Bank, Mail)...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KeyelSpacing.md,
                    vertical: KeyelSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KeyelRadii.field),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: KeyelSpacing.xs),

            // Category filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeyelSpacing.md,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: EntryIconCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = EntryIconCategory.values[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Grid of icons
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: KeyelSpacing.sm),
                          Text(
                            'No matching icons',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(KeyelSpacing.md),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 80,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = widget.selectedKey == item.key;
                        final isSuggested = suggested == item.key;

                        return Tooltip(
                          message: item.label,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(item.key),
                            borderRadius: BorderRadius.circular(
                              KeyelRadii.field,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.primaryContainer
                                    : (isSuggested
                                          ? scheme.tertiaryContainer.withValues(
                                              alpha: 0.4,
                                            )
                                          : scheme.surfaceContainerLow),
                                borderRadius: BorderRadius.circular(
                                  KeyelRadii.field,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : (isSuggested
                                            ? scheme.tertiary
                                            : scheme.outlineVariant.withValues(
                                                alpha: 0.4,
                                              )),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 28,
                                    color: isSelected
                                        ? scheme.onPrimaryContainer
                                        : (isSuggested
                                              ? scheme.onTertiaryContainer
                                              : scheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
