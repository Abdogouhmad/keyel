import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:keyel/core/router/app_router.dart';
import 'package:keyel/src/rust/frb_generated.dart';
import 'package:keyel/ui/theme/keyel_theme.dart';

Future<void> main() async {
  // Edge-to-edge: draw behind system bars (docs/design.md).
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Bring up the Rust side (FRB).
  await RustLib.init();

  runApp(const KeyelApp());
}

/// The Keyel root widget.
///
/// Keyel uses a deliberately fixed brand palette. Dynamic color / Material
/// You is intentionally **not** used: the vault's security states, strength
/// colours and contrast ratios must stay identical on every device
/// (docs/design.md; docs/DECISIONS.md 2026-11-05).
class KeyelApp extends StatelessWidget {
  /// Creates the root application widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Keyel',
      debugShowCheckedModeBanner: false,
      theme: KeyelTheme.light(),
      darkTheme: KeyelTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
