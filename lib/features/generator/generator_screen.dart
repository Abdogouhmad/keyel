import 'dart:async';

import 'package:flutter/material.dart';

import 'package:keyel/core/platform/sensitive_clipboard.dart';
import 'package:keyel/core/security/password_strength.dart';
import 'package:keyel/data/app_preferences.dart';
import 'package:keyel/features/generator/widgets/generator_body.dart';
import 'package:keyel/src/rust/api/generator.dart';
import 'package:keyel/ui/keyel.dart';

/// Generator screen — password and passphrase generation.
class GeneratorScreen extends StatefulWidget {
  /// Creates the generator screen.
  const new({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  GeneratorMode _mode = GeneratorMode.password;
  int _length = 20;
  int _wordCount = 8;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeAmbiguous = true;
  bool _capitalizeFirst = true;
  bool _includeNumber = false;
  String _separator = '-';

  late String _password;
  late String _passphrase;

  @override
  void initState() {
    super.initState();
    final prefs = AppPreferences.instance;
    _mode = prefs.generatorMode == 'passphrase'
        ? GeneratorMode.passphrase
        : GeneratorMode.password;
    _length = prefs.generatorLength;
    _wordCount = prefs.generatorWordCount;
    _includeUppercase = prefs.generatorUppercase;
    _includeLowercase = prefs.generatorLowercase;
    _includeNumbers = prefs.generatorNumbers;
    _includeSymbols = prefs.generatorSymbols;
    _excludeAmbiguous = prefs.generatorExcludeAmbiguous;
    _capitalizeFirst = prefs.generatorCapitalize;
    _includeNumber = prefs.generatorIncludeNumber;
    _separator = prefs.generatorSeparator;
    _password = _generatePassword();
    _passphrase = _generatePassphrase();
  }

  String get _display =>
      _mode == GeneratorMode.password ? _password : _passphrase;

  PasswordStrength get _strength => _mode == GeneratorMode.password
      ? PasswordStrength.estimate(_password)
      : PasswordStrength.estimatePassphrase(_wordCount);

  String get _modeName =>
      _mode == GeneratorMode.password ? 'Password' : 'Passphrase';

  String _generatePassword() {
    try {
      return generatePassword(
        length: _length,
        lowercase: _includeLowercase,
        uppercase: _includeUppercase,
        digits: _includeNumbers,
        symbols: _includeSymbols,
        excludeAmbiguous: _excludeAmbiguous,
      );
    } on Exception {
      showKeyelSnack(
        context,
        'Could not generate password. Check constraints.',
        icon: Icons.error_outline_rounded,
      );
      return 'Error';
    }
  }

  String _generatePassphrase() {
    try {
      return generatePassphrase(
        wordCount: _wordCount,
        capitalize: _capitalizeFirst,
        includeNumber: _includeNumber,
        separator: _separator,
      );
    } on Exception {
      showKeyelSnack(
        context,
        'Could not generate passphrase.',
        icon: Icons.error_outline_rounded,
      );
      return 'Error';
    }
  }

  /// Remember the current options so they survive an app restart.
  void _persist() {
    final prefs = AppPreferences.instance
      ..generatorMode = _mode == GeneratorMode.passphrase
          ? 'passphrase'
          : 'password'
      ..generatorLength = _length
      ..generatorWordCount = _wordCount
      ..generatorUppercase = _includeUppercase
      ..generatorLowercase = _includeLowercase
      ..generatorNumbers = _includeNumbers
      ..generatorSymbols = _includeSymbols
      ..generatorExcludeAmbiguous = _excludeAmbiguous
      ..generatorCapitalize = _capitalizeFirst
      ..generatorIncludeNumber = _includeNumber
      ..generatorSeparator = _separator;
    unawaited(prefs.save());
  }

  void _regenerate() {
    setState(() {
      if (_mode == GeneratorMode.password) {
        _password = _generatePassword();
      } else {
        _passphrase = _generatePassphrase();
      }
    });
  }

  void _setMode(GeneratorMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == GeneratorMode.password) {
        _password = _generatePassword();
      } else {
        _passphrase = _generatePassphrase();
      }
    });
    _persist();
  }

  void _setCharacterClass({
    bool? uppercase,
    bool? lowercase,
    bool? numbers,
    bool? symbols,
  }) {
    final nextUppercase = uppercase ?? _includeUppercase;
    final nextLowercase = lowercase ?? _includeLowercase;
    final nextNumbers = numbers ?? _includeNumbers;
    final nextSymbols = symbols ?? _includeSymbols;

    if (!nextUppercase && !nextLowercase && !nextNumbers && !nextSymbols) {
      showKeyelSnack(
        context,
        'Keep at least one character type switched on.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() {
      _includeUppercase = nextUppercase;
      _includeLowercase = nextLowercase;
      _includeNumbers = nextNumbers;
      _includeSymbols = nextSymbols;
      _password = _generatePassword();
    });
    _persist();
  }

  void _setExcludeAmbiguous(bool value) {
    setState(() {
      _excludeAmbiguous = value;
      _password = _generatePassword();
    });
    _persist();
  }

  void _copy() {
    unawaited(SensitiveClipboard.instance.copy(_display));
    showKeyelSnack(
      context,
      '$_modeName copied to clipboard${SensitiveClipboard.instance.clearHint}',
      icon: Icons.content_copy_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            KeyelTopBar(
              title: 'Generator',
              icon: Icons.password_rounded,
              iconTooltip: 'About generation',
              onIconTap: () => showKeyelSnack(
                context,
                'Keyel always generates locally on your device.',
                icon: Icons.security_rounded,
              ),
              trailing: KeyelIconHull(
                icon: Icons.history_rounded,
                tooltip: 'Generation history',
                onPressed: () => showKeyelSnack(
                  context,
                  'Generation history arrives with encrypted storage.',
                  icon: Icons.history_rounded,
                ),
              ),
            ),
            GeneratorBody(
              mode: _mode,
              onModeChanged: _setMode,
              display: _display,
              modeName: _modeName,
              strength: _strength,
              onRegenerate: _regenerate,
              onCopy: _copy,
              length: _length,
              onLengthChanged: (value) {
                setState(() => _length = value);
                _persist();
              },
              onLengthChangeEnd: _regenerate,
              wordCount: _wordCount,
              onWordCountChanged: (value) {
                setState(() => _wordCount = value);
                _persist();
              },
              onWordCountChangeEnd: _regenerate,
              includeUppercase: _includeUppercase,
              includeLowercase: _includeLowercase,
              includeNumbers: _includeNumbers,
              includeSymbols: _includeSymbols,
              excludeAmbiguous: _excludeAmbiguous,
              onUppercaseChanged: (value) =>
                  _setCharacterClass(uppercase: value),
              onLowercaseChanged: (value) =>
                  _setCharacterClass(lowercase: value),
              onNumbersChanged: (value) => _setCharacterClass(numbers: value),
              onSymbolsChanged: (value) => _setCharacterClass(symbols: value),
              onExcludeAmbiguousChanged: _setExcludeAmbiguous,
              capitalizeFirst: _capitalizeFirst,
              includeNumber: _includeNumber,
              separator: _separator,
              onCapitalizeFirstChanged: (value) {
                setState(() {
                  _capitalizeFirst = value;
                  _passphrase = _generatePassphrase();
                });
                _persist();
              },
              onIncludeNumberChanged: (value) {
                setState(() {
                  _includeNumber = value;
                  _passphrase = _generatePassphrase();
                });
                _persist();
              },
              onSeparatorChanged: (value) {
                setState(() {
                  _separator = value;
                  _passphrase = _generatePassphrase();
                });
                _persist();
              },
            ),
          ],
        ),
      ),
    );
  }
}
