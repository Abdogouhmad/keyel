import 'package:flutter/material.dart';

import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/features/vault/widgets/vault_recent_search.dart';
import 'package:keyel/ui/keyel.dart';

/// The vault search field plus its recent-search chips.
///
/// Tracks whether the field is focused so recent searches only appear while
/// the user is looking at an empty query, and commits finished queries to
/// [AppPreferences.rememberSearch] when the field is left or cleared.
class VaultSearchBar extends StatefulWidget {
  /// Creates the search field area.
  const new({required this.query, required this.onSearchChanged, super.key});

  /// The query the list is currently filtered by.
  final String query;

  /// Called with the search text whenever it changes.
  final ValueChanged<String> onSearchChanged;

  @override
  State<VaultSearchBar> createState() => _VaultSearchBarState();
}

class _VaultSearchBarState extends State<VaultSearchBar> {
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  String _previousQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VaultSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The filters were reset elsewhere (for example the empty state's
    // "Clear filters" button); clear the text field to match.
    if (widget.query.trim().isEmpty && _searchController.text.isNotEmpty) {
      _commitPendingSearch();
      _searchController.clear();
      _previousQuery = '';
    }
  }

  void _handleSearchChanged(String value) {
    // Backspacing the whole query counts as finishing that search.
    if (_previousQuery.trim().isNotEmpty && value.trim().isEmpty) {
      _commitPendingSearch();
    }
    _previousQuery = value;
    widget.onSearchChanged(value);
  }

  void _handleFocusChanged(bool focused) {
    // Leaving the field (keyboard "search", tapping elsewhere) commits the
    // query that was just run.
    if (!focused) _commitPendingSearch();
    setState(() => _searchFocused = focused);
  }

  void _commitPendingSearch() {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;
    AppPreferences.instance.rememberSearch(term);
  }

  void _runRecentSearch(String term) {
    _searchController.text = term;
    _previousQuery = term;
    widget.onSearchChanged(term);
  }

  bool get _showRecentSearches => _searchFocused && widget.query.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          onFocusChange: _handleFocusChanged,
          child: KeyelSearchField(
            controller: _searchController,
            hintText: 'Search items, tags or notes...',
            onChanged: _handleSearchChanged,
            trailing: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        if (_showRecentSearches)
          VaultRecentSearches(onSelected: _runRecentSearch),
      ],
    );
  }
}
