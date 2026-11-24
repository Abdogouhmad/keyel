import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:keyel/l10n/generated/app_localizations.dart';
import 'package:keyel/ui/keyel.dart';
import 'package:keyel/ui/l10n/l10n.dart';

/// The width classes and accessibility scales the responsive layout promises
/// to support. Every combination runs in both text directions and locales.
const _widths = [360.0, 400.0, 700.0, 840.0, 1000.0, 1200.0, 1600.0, 2560.0];
const _scales = [1.0, 1.4, 2.0];
const _locales = ['en', 'fr'];

double _expectedChrome(double width) => switch (width) {
  < 600 => 0,
  < 840 => 76,
  < 1200 => 108,
  _ => 280,
};

double _expectedMargin(double width) =>
    width < 600 ? 16 : (width >= 1200 ? 32 : 24);

/// Mirrors [EffectiveLayoutData] so the test catches accidental changes to the
/// shared capacity formula rather than restating the observed values.
double _expectedCapacity(double width, double scale) =>
    (width - _expectedChrome(width) - 2 * _expectedMargin(width)).clamp(
      240.0,
      width,
    ) /
    scale.clamp(1.0, 2.0);

void main() {
  for (final localeId in _locales) {
    for (final direction in TextDirection.values) {
      for (final scale in _scales) {
        for (final width in _widths) {
          testWidgets(
            '${width.toInt()}dp @ ${scale}x ${direction.name} $localeId: '
            'shell gives the page its effective width',
            (tester) async {
              late EffectiveLayoutData observed;
              final router = GoRouter(
                initialLocation: '/probe',
                routes: [
                  StatefulShellRoute.indexedStack(
                    builder: (context, state, shell) =>
                        KeyelShell(navigationShell: shell),
                    branches: [
                      StatefulShellBranch(
                        routes: [
                          GoRoute(
                            path: '/probe',
                            builder: (context, state) {
                              observed = context.maybeEffectiveLayout!;
                              // Localized, representative copy so the matrix
                              // checks EN/FR rendering, not just capacity math.
                              return Scaffold(
                                body: Center(
                                  child: Text(l10nOf(context).actionCopy),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );

              await tester.pumpWidget(
                ProviderScope(
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 800),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: MaterialApp.router(
                      theme: KeyelTheme.light(),
                      locale: Locale(localeId),
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      routerConfig: router,
                      builder: (context, child) => Directionality(
                        textDirection: direction,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              expect(
                find.text(localizationsFor(localeId).actionCopy),
                findsOneWidget,
              );
              expect(observed.windowWidth, width);
              expect(observed.chromeWidth, _expectedChrome(width));
              expect(observed.pageMargin, _expectedMargin(width));
              expect(
                observed.contentWidth,
                closeTo(
                  (width - _expectedChrome(width) - 2 * _expectedMargin(width))
                      .clamp(240.0, width),
                  0.01,
                ),
              );
              expect(
                observed.capacity,
                closeTo(_expectedCapacity(width, scale), 0.01),
              );
              expect(observed.supportsTwoColumns, observed.capacity >= 900);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
