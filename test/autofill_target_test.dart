import 'package:flutter_test/flutter_test.dart';

import 'package:keyel/data/autofill_target.dart';

void main() {
  group('canonicalAutofillTarget', () {
    test('uses the host for a trusted browser', () {
      expect(
        canonicalAutofillTarget(
          package: 'com.android.chrome',
          webDomain: 'HTTPS://WWW.Example.COM/login',
        ),
        'host:example.com',
      );
    });

    test('uses the host when no package is reported', () {
      expect(
        canonicalAutofillTarget(package: null, webDomain: 'sub.example.com'),
        'host:sub.example.com',
      );
    });

    test('uses the package when an untrusted app claims a web domain', () {
      expect(
        canonicalAutofillTarget(
          package: 'com.evil.webview',
          webDomain: 'victim.example',
        ),
        'package:com.evil.webview',
      );
    });

    test('does not deny a browser package without a host', () {
      expect(
        canonicalAutofillTarget(package: 'com.android.chrome', webDomain: null),
        isNull,
      );
    });

    test('normalizes case and rejects local hosts', () {
      expect(
        canonicalAutofillTarget(package: null, webDomain: 'LOCALHOST'),
        isNull,
      );
      expect(
        canonicalAutofillTarget(package: 'COM.Example.App', webDomain: null),
        'package:com.example.app',
      );
    });
  });

  group('isValidAutofillTarget', () {
    test('accepts only canonical keys', () {
      expect(isValidAutofillTarget('host:example.com'), isTrue);
      expect(isValidAutofillTarget('package:com.example.app'), isTrue);
      expect(isValidAutofillTarget('host:https://example.com'), isFalse);
      expect(isValidAutofillTarget('host:bad host'), isFalse);
      expect(isValidAutofillTarget('package:COM.Example'), isFalse);
      expect(isValidAutofillTarget('example.com'), isFalse);
    });
  });
}
