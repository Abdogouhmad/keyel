import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keyel/data/vault_session_provider.dart';

/// Bridges the Riverpod vault session state into a [Listenable] so the
/// go_router redirect guard re-evaluates whenever the session changes.
class VaultSessionListenable extends ChangeNotifier {
  /// Creates the bridge; the provider container supplies initial state.
  new(this._container) {
    _subscription = _container.listen(
      vaultSessionProvider,
      (_, _) => notifyListeners(),
    );
  }

  final ProviderContainer _container;
  ProviderSubscription<VaultSessionState>? _subscription;
  bool _disposed = false;

  /// The latest snapshot from [vaultSessionProvider].
  VaultSessionState get state => _container.read(vaultSessionProvider);

  @override
  void dispose() {
    _disposed = true;
    _subscription?.close();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
