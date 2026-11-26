// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Keyel';

  @override
  String get navVault => 'Vault';

  @override
  String get navGenerator => 'Generator';

  @override
  String get navSecurity => 'Security';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionShare => 'Share';

  @override
  String get actionDone => 'Done';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionLockVault => 'Lock vault';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionContinue => 'Continue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the language used by Keyel';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get securityTitle => 'Security Health';

  @override
  String get generatorTitle => 'Generator';

  @override
  String get vaultTitle => 'Vault';

  @override
  String get softwareUpdate => 'Software Update';

  @override
  String get foldersTitle => 'Folders';

  @override
  String get trashTitle => 'Trash';

  @override
  String get importExportTitle => 'Import & export';

  @override
  String get syncTitle => 'Sync';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get searchHint => 'Search';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get aboutGeneration => 'About generation';

  @override
  String get generationHistory => 'Generation history';

  @override
  String get aboutGenerationMessage =>
      'Keyel always generates locally on your device.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get themeModeTitle => 'Theme';

  @override
  String get paletteTitle => 'Accent colour';

  @override
  String get amoledTitle => 'Pure black (AMOLED)';

  @override
  String get animationsTitle => 'Animations';

  @override
  String get hapticsTitle => 'Haptics';

  @override
  String get screenshotTitle => 'Screenshot protection';

  @override
  String get clipboardTitle => 'Clear clipboard';

  @override
  String get autoLockTitle => 'Auto-lock';

  @override
  String get healthLoading => 'Checking your vault health…';

  @override
  String get healthErrorTitle => 'Could not check vault health';

  @override
  String get folderEmpty => 'No folders yet';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get currentVersion => 'Current version';

  @override
  String get appearanceHeadline => 'Personalize Keyel';

  @override
  String get appearanceSubtitle =>
      'Choose your theme, accent palette, and interaction preferences. Security indicators stay consistent.';

  @override
  String paletteColors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colors',
      one: '$count color',
    );
    return '$_temp0';
  }

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get interactionTitle => 'Interaction';

  @override
  String get amoledSubtitle =>
      'Use true black backgrounds in dark mode to reduce OLED glow and save power on supported displays.';

  @override
  String get animationsSubtitle =>
      'Enable motion and transitions throughout the app. System reduced-motion settings are always respected.';

  @override
  String get hapticsSubtitle =>
      'Enable tactile feedback for taps and actions where supported by your device.';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get autofillFillTitle => 'Fill from Keyel';

  @override
  String autofillFilling(String target) {
    return 'Filling $target';
  }

  @override
  String get autofillTargetThisApp => 'this app';

  @override
  String get autofillSearchVault => 'Search vault';

  @override
  String get autofillCreateNewLogin => 'Create new login';

  @override
  String get autofillNeverForSite => 'Never for this site';

  @override
  String get autofillSaveTitle => 'Save login?';

  @override
  String get autofillSaveLogin => 'Save login';

  @override
  String get autofillNotNow => 'Not now';

  @override
  String get autofillNewLogin => 'New login';

  @override
  String get autofillNameRequired => 'Give this login a name first.';

  @override
  String get autofillFindingMatches => 'Finding matching logins…';

  @override
  String get autofillNoMatches => 'No matching logins';

  @override
  String get autofillNoMatchesBody =>
      'Create a new login for this app or site.';

  @override
  String get autofillDisabledTitle => 'Autofill is off for this site';

  @override
  String get autofillDisabledBody =>
      'You chose never to fill here. Remove this choice from Keyel\'s autofill settings to turn it back on.';

  @override
  String autofillStoreCredentials(String target) {
    return 'Store these credentials for $target';
  }

  @override
  String get fieldName => 'Name';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String autofillMismatchBody(String target) {
    return 'Some results are text matches only. Check that the login really belongs to $target before filling.';
  }

  @override
  String get autofillVaultLocked => 'Vault locked';

  @override
  String get autofillUnlockToFill => 'Unlock Keyel to fill this form.';

  @override
  String get autofillLoadError => 'Could not load matches';

  @override
  String get autofillNeverTitle => 'Never for these sites';

  @override
  String get autofillNeverSubtitle =>
      'Where Keyel will not offer to fill or save';

  @override
  String get autofillNeverEmpty => 'No blocked sites yet';

  @override
  String autofillNeverCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocked sites',
      one: '$count blocked site',
    );
    return '$_temp0';
  }

  @override
  String get actionManage => 'Manage';

  @override
  String get autofillVerifiedTitle => 'Verified sites only';

  @override
  String get autofillVerifiedSubtitle =>
      'Exact package or host matches only (offline Digital Asset Links substitute)';

  @override
  String get coreAutofillAppTitle => 'Keyel Autofill';

  @override
  String get coreBiometricEnableReason => 'Confirm your identity to enable it';

  @override
  String get coreBreachCheckActive => 'A breach check is already in progress.';

  @override
  String get coreBreachCheckFailed => 'Breach check failed. Please try again.';

  @override
  String get coreBreachInvalidResponse =>
      'The breach service returned an unexpected response.';

  @override
  String get coreBreachInvalidToken => 'That breach check has expired.';

  @override
  String get coreBreachUnreachable => 'Could not reach the breach service.';

  @override
  String get coreEmptyImport => 'That file has no entries to import.';

  @override
  String get coreEntryNotFound => 'Entry not found.';

  @override
  String get coreInternalError => 'Internal error.';

  @override
  String get coreInvalidEntryId => 'Invalid entry id.';

  @override
  String get coreInvalidKdfParams => 'Invalid key-derivation parameters.';

  @override
  String get coreInvalidRecoveryKey => 'That recovery key is not valid.';

  @override
  String get coreMalformedImport => 'That file is not a valid CSV export.';

  @override
  String get corePaletteAmber => 'Amber';

  @override
  String get corePaletteAmberDesc => 'Warm golden tones';

  @override
  String get corePaletteForest => 'Forest';

  @override
  String get corePaletteForestDesc => 'Deep green tones';

  @override
  String get corePaletteGraphite => 'Graphite';

  @override
  String get corePaletteGraphiteDesc => 'Neutral monochrome tones';

  @override
  String get corePaletteIndigo => 'Indigo';

  @override
  String get corePaletteIndigoDesc => 'Classic Keyel brand colors';

  @override
  String get corePaletteOcean => 'Ocean';

  @override
  String get corePaletteOceanDesc => 'Calm blue tones';

  @override
  String get corePaletteRose => 'Rose';

  @override
  String get corePaletteRoseDesc => 'Soft red and pink tones';

  @override
  String get corePaletteTeal => 'Teal';

  @override
  String get corePaletteTealDesc => 'Balanced blue-green tones';

  @override
  String get corePaletteViolet => 'Violet';

  @override
  String get corePaletteVioletDesc => 'Rich purple tones';

  @override
  String get corePasskeyAppTitle => 'Keyel Passkeys';

  @override
  String get corePasskeyRequestUnreadable =>
      'Could not read the passkey request. Try again.';

  @override
  String get corePasskeyRequestUnsupported =>
      'This passkey request is not supported.';

  @override
  String get corePasskeyUnavailable => 'Passkey unavailable';

  @override
  String get coreRequiredFields => 'Please fill in the required fields.';

  @override
  String get coreStorageError => 'Could not read or write the vault file.';

  @override
  String get coreThemeDark => 'Dark';

  @override
  String get coreThemeLight => 'Light';

  @override
  String get coreThemeSystem => 'System';

  @override
  String coreThrottled(String seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get coreUnsupportedCsvFormat =>
      'That CSV format is not supported. Use a Bitwarden or Chrome export.';

  @override
  String get coreVaultCorrupted => 'The vault file is damaged.';

  @override
  String get coreVaultExists => 'A vault already exists.';

  @override
  String get coreVaultInvalidPath => 'The vault path is invalid.';

  @override
  String get coreVaultLocked => 'Unlock the vault first.';

  @override
  String get coreVaultMissing => 'No vault file was found.';

  @override
  String get coreVaultNotInitialized => 'Vault storage is not initialized.';

  @override
  String get coreVaultUnsupportedVersion =>
      'This vault was created by a newer Keyel version.';

  @override
  String get coreWrongPassword => 'Wrong password or damaged vault.';

  @override
  String get entry2FaCodeCopied => '2FA code copied to clipboard';

  @override
  String get entry2FaEnabled => '2FA enabled';

  @override
  String get entryAddCustomField => 'Add custom field';

  @override
  String get entryAddToFavorites => 'Add to favorites';

  @override
  String get entryAlgorithm => 'Algorithm';

  @override
  String get entryCardDetails => 'Card details';

  @override
  String get entryCardNumber => 'Card number';

  @override
  String get entryCardNumberCopied => 'Card number copied to clipboard';

  @override
  String get entryCardholder => 'Cardholder';

  @override
  String get entryCardholderName => 'Cardholder name';

  @override
  String get entryCardholderNameCopied => 'Cardholder name copied';

  @override
  String get entryChangeIcon => 'Change icon';

  @override
  String get entryChooseIcon => 'Choose Icon';

  @override
  String get entryChooseIconSubtitle => 'Select an icon for this entry';

  @override
  String get entryConfigured => 'Configured';

  @override
  String get entryCopy2FaCode => 'Copy 2FA code';

  @override
  String get entryCopyCardNumber => 'Copy card number';

  @override
  String get entryCopyCardholder => 'Copy cardholder';

  @override
  String get entryCopyFullNote => 'Copy full note';

  @override
  String get entryCopyPassword => 'Copy password';

  @override
  String get entryCopyUrl => 'Copy URL';

  @override
  String get entryCopyUsername => 'Copy username';

  @override
  String get entryCopyValue => 'Copy value';

  @override
  String get entryCopyWebsiteUrl => 'Copy website URL';

  @override
  String get entryCreated => 'Entry created in vault.';

  @override
  String get entryCredentialId => 'Credential ID';

  @override
  String get entryCredentials => 'Credentials';

  @override
  String get entryCustomFields => 'Custom fields';

  @override
  String get entryCustomFieldsHint =>
      'Add extra text, hidden, or URL fields to this entry.';

  @override
  String get entryDecryptedNote => 'Decrypted note:';

  @override
  String get entryDeleteBody => 'This item will be moved to the trash.';

  @override
  String get entryDeleteEntry => 'Delete entry';

  @override
  String entryDeleteTitle(String title) {
    return 'Delete $title?';
  }

  @override
  String get entryDiscardBody => 'Your edits to this entry will be lost.';

  @override
  String get entryDiscardConfirm => 'Discard';

  @override
  String get entryDiscardTitle => 'Discard changes?';

  @override
  String get entryDiscoverable => 'Discoverable';

  @override
  String get entryEditCard => 'Edit card';

  @override
  String get entryEditEntry => 'Edit entry';

  @override
  String get entryEditLogin => 'Edit login';

  @override
  String get entryEditNote => 'Edit note';

  @override
  String get entryEditPasskey => 'Edit passkey';

  @override
  String entryEditTitle(String kind) {
    return 'Edit $kind';
  }

  @override
  String get entryEncryptedContent => 'Encrypted content';

  @override
  String get entryEncryptedHint =>
      'Secrets stay encrypted with Argon2id & ChaCha20-Poly1305.';

  @override
  String get entryEncryptedProtected => 'Encrypted & Protected';

  @override
  String get entryEnterManually => 'Enter Manually';

  @override
  String get entryEnterPassword => 'Enter secure password';

  @override
  String get entryExpires => 'Expires';

  @override
  String get entryExpiry => 'Expiry';

  @override
  String get entryFavoriteRemoved => 'Favorite removed';

  @override
  String get entryField => 'Field';

  @override
  String get entryFieldActions => 'Field actions';

  @override
  String entryFieldCopied(String label, String hint) {
    return '$label copied$hint';
  }

  @override
  String get entryFieldLabel => 'Label';

  @override
  String get entryFieldTypeHidden => 'Hidden field';

  @override
  String get entryFieldTypeHiddenShort => 'Hidden';

  @override
  String get entryFieldTypeText => 'Text field';

  @override
  String get entryFieldTypeTextShort => 'Text';

  @override
  String get entryFieldTypeUrl => 'URL field';

  @override
  String get entryFieldTypeUrlShort => 'URL';

  @override
  String get entryFolder => 'Folder';

  @override
  String get entryGeneratePasswordTooltip => 'Generate password';

  @override
  String get entryGenerateSecurePassword => 'Generate secure password';

  @override
  String get entryGoBack => 'Go back';

  @override
  String get entryHiddenValueKept =>
      'Existing hidden value will be kept unless you enter a new one.';

  @override
  String get entryHideContent => 'Hide content';

  @override
  String get entryHideNumber => 'Hide number';

  @override
  String get entryHidePassword => 'Hide password';

  @override
  String get entryHideValue => 'Hide value';

  @override
  String get entryHistory => 'History';

  @override
  String get entryIconCategoryAll => 'All';

  @override
  String get entryIconCategoryBrands => 'Brands';

  @override
  String get entryIconCategoryCrypto => 'Crypto';

  @override
  String get entryIconCategoryFinance => 'Finance';

  @override
  String get entryIconCategoryLife => 'Life & Utilities';

  @override
  String get entryIconCategoryMedia => 'Media';

  @override
  String get entryIconCategorySecurity => 'Security';

  @override
  String get entryIconCategorySocial => 'Social';

  @override
  String get entryIconCategoryTech => 'Tech & Dev';

  @override
  String get entryIconCategoryWork => 'Work';

  @override
  String get entryIconSearchHint => 'Search icons (e.g. GitHub, Bank, Mail)...';

  @override
  String get entryInvalidTotpSecret =>
      'That key or link is not a valid TOTP secret.';

  @override
  String get entryInvalidWebsite => 'Invalid website address';

  @override
  String get entryItemNotFound => 'Item not found';

  @override
  String get entryKindCard => 'Card';

  @override
  String get entryKindLogin => 'Login';

  @override
  String get entryKindNote => 'Note';

  @override
  String get entryKindPasskey => 'Passkey';

  @override
  String get entryLoading => 'Loading entry…';

  @override
  String get entryLoadingCode => 'Loading code…';

  @override
  String get entryMasterCredentials => 'Master credentials';

  @override
  String entryMissingMessage(String entryId) {
    return 'No entry with ID \"$entryId\" exists.';
  }

  @override
  String get entryMoveDown => 'Move down';

  @override
  String get entryMoveUp => 'Move up';

  @override
  String entryMovedToTrash(String title) {
    return '$title moved to trash';
  }

  @override
  String entryNewTitle(String kind) {
    return 'New $kind';
  }

  @override
  String get entryNo => 'No';

  @override
  String get entryNoFolder => 'No folder';

  @override
  String get entryNoMatchingIcons => 'No matching icons';

  @override
  String get entryNoteCopied => 'Note copied';

  @override
  String get entryNotes => 'Notes';

  @override
  String get entryNotesHint => 'Recovery questions, PIN codes, backup seeds...';

  @override
  String get entryNothingToCopy => 'Nothing to copy';

  @override
  String get entryOpenUrl => 'Open URL';

  @override
  String get entryOpenWebsite => 'Open website';

  @override
  String get entryPasskeyInfo =>
      'Passkeys are created and used through secure sign-in prompts. Credential details are managed automatically and can\'t be edited here yet.';

  @override
  String get entryPasskeyUser => 'User';

  @override
  String entryPasswordCopied(String hint) {
    return 'Password copied$hint';
  }

  @override
  String get entryPasswordGenerationFailed =>
      'Could not generate a password right now.';

  @override
  String entryPasswordHealth(String label, num count) {
    return '$label password ($count chars)';
  }

  @override
  String get entryPasswordHistorySoon =>
      'Password history arrives with encrypted storage.';

  @override
  String entryPasswordScore(num score) {
    return 'Score: $score%';
  }

  @override
  String get entryPinToQuickAccess => 'Pin this entry to quick access';

  @override
  String entryPinned(String title) {
    return '$title pinned to favorites';
  }

  @override
  String get entryQrScanUnavailable =>
      'Camera scanning arrives in a later update. Enter the key manually for now.';

  @override
  String get entryRefreshesAutomatically => 'Refreshes automatically';

  @override
  String get entryRelyingParty => 'Relying party';

  @override
  String get entryRemoveFavorite => 'Remove favorite';

  @override
  String get entryReplaceKey => 'Replace Key';

  @override
  String get entryRevealNote => 'Reveal note';

  @override
  String get entryRevealNumber => 'Reveal number';

  @override
  String get entryRevealPassword => 'Reveal password';

  @override
  String get entryRevealValue => 'Reveal value';

  @override
  String get entrySaveEntry => 'Save entry';

  @override
  String get entrySavedSecurelyHint => 'Saved securely (leave blank to keep)';

  @override
  String get entryScanQrCode => 'Scan QR Code';

  @override
  String entrySecondsRemaining(num seconds) {
    return '${seconds}s';
  }

  @override
  String get entrySecureNote => 'Secure note';

  @override
  String get entrySecureNoteContent => 'Secure note content';

  @override
  String get entrySecureNotes => 'Secure notes';

  @override
  String get entrySecurityCodeCvv => 'Security code (CVV)';

  @override
  String get entrySetupKeyOrLink => 'Setup key or link';

  @override
  String get entrySheetBarrier => 'Sheet';

  @override
  String get entryShowPassword => 'Show password';

  @override
  String get entrySignCount => 'Sign count';

  @override
  String entryStrengthEntropy(String entropyLabel) {
    return 'Entropy: $entropyLabel';
  }

  @override
  String entryStrengthSummary(String label, num bits, String descriptor) {
    return '$label ($bits bits) - $descriptor';
  }

  @override
  String get entrySuggestion => 'Suggestion:';

  @override
  String get entryTitleFieldHint => 'Service or app name';

  @override
  String get entryTitleFieldLabel => 'Title';

  @override
  String get entryTitleRequired => 'Give this entry a title first.';

  @override
  String get entryTotpConfiguredHint =>
      'A rotating code is stored for this entry. Enter a new key to replace it.';

  @override
  String get entryTotpHint =>
      'Generate integrated 30-second rotating security codes directly inside Keyel.';

  @override
  String get entryTotpKeyRequired => 'Enter the setup key from your provider.';

  @override
  String get entryTotpReady =>
      'Two-factor key ready. Save the entry to store it.';

  @override
  String get entryTotpSetupBody =>
      'Paste the setup key (base32) or the otpauth:// link from your provider.';

  @override
  String get entryTotpSetupTitle => 'Set up two-factor';

  @override
  String get entryTransports => 'Transports';

  @override
  String get entryTwoFactorAuth => 'Two-factor authentication';

  @override
  String get entryTwoFactorCode => 'Two-factor code';

  @override
  String get entryUpdated => 'Entry updated.';

  @override
  String get entryUseSuggestedEmail => 'Use suggested email';

  @override
  String get entryUsernameCopied => 'Username copied to clipboard';

  @override
  String get entryUsernameOrEmail => 'Username or email';

  @override
  String get entryValue => 'Value';

  @override
  String entryValueCopied(String label) {
    return '$label copied';
  }

  @override
  String get entryValueSecret => 'Value (secret)';

  @override
  String get entryWebVaultMatcher => 'Web Vault Matcher';

  @override
  String get entryWebsiteOpenFailed => 'Could not open website';

  @override
  String get entryWebsiteUrl => 'Website URL';

  @override
  String get entryWebsiteUrlCopied => 'Website URL copied to clipboard';

  @override
  String get entryYes => 'Yes';

  @override
  String get fldCreating => 'Creating…';

  @override
  String get fldDeleteConfirmBody =>
      'Entries in this folder are kept and move to \"No folder\".';

  @override
  String fldDeleteConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get fldDeleteFolder => 'Delete folder';

  @override
  String get fldDeleted => 'Folder deleted';

  @override
  String get fldEmptyMessage =>
      'Folders keep logins, cards and notes in tidy groups. Use the button below to create the first one.';

  @override
  String get fldFolderNameLabel => 'Folder name';

  @override
  String get fldLoading => 'Loading folders…';

  @override
  String get fldMoveToFolder => 'Move to folder';

  @override
  String get fldNewFolder => 'New folder';

  @override
  String get fldNoFolder => 'No folder';

  @override
  String get fldRenameFolder => 'Rename folder';

  @override
  String get genCapitalizeExample => 'e.g., Apple-Tree-House';

  @override
  String get genCapitalizeFirst => 'Capitalize first letter';

  @override
  String get genCharacterTypeError =>
      'Keep at least one character type switched on.';

  @override
  String get genCharacterTypes => 'Character types';

  @override
  String genCharsShort(num count) {
    return '$count chars';
  }

  @override
  String genCopied(String mode, String clearHint) {
    return '$mode copied to clipboard$clearHint';
  }

  @override
  String genCopyMode(String mode) {
    return 'Copy $mode';
  }

  @override
  String get genError => 'Error';

  @override
  String get genExcludeAmbiguous => 'Exclude ambiguous';

  @override
  String get genExcludeAmbiguousSubtitle => 'Avoids 0, O, 1, l and I confusion';

  @override
  String get genGeneratedLocally => 'Generated locally on device';

  @override
  String get genHistoryMessage =>
      'Generation history arrives with encrypted storage.';

  @override
  String get genIncludeNumber => 'Include a number';

  @override
  String get genIncludeNumberSubtitle => 'Adds two random digits at the end';

  @override
  String genLengthValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '$count character',
    );
    return '$_temp0';
  }

  @override
  String get genLowercase => 'Lowercase letters';

  @override
  String get genNumbers => 'Numbers';

  @override
  String get genPassphrase => 'Passphrase';

  @override
  String get genPassphraseError => 'Could not generate passphrase.';

  @override
  String get genPassphraseOptions => 'Passphrase options';

  @override
  String get genPassphraseTip =>
      'Passphrases trade symbols for memorable words. Use at least eight words for a vault master passphrase.';

  @override
  String get genPassword => 'Password';

  @override
  String get genPasswordError =>
      'Could not generate password. Check constraints.';

  @override
  String get genPasswordLength => 'Password length';

  @override
  String get genPasswordLengthSubtitle => 'Recommended 16+ characters';

  @override
  String get genRegenerate => 'Regenerate';

  @override
  String get genSeparatorSpace => 'Space';

  @override
  String get genSymbols => 'Symbols';

  @override
  String get genUppercase => 'Uppercase letters';

  @override
  String get genUsePassphrase => 'Use this passphrase';

  @override
  String get genUsePassword => 'Use this password';

  @override
  String get genWordCount => 'Word count';

  @override
  String get genWordCountSubtitle => 'Each word adds about 10 bits of entropy';

  @override
  String genWordCountValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get genWordSeparator => 'Word separator';

  @override
  String get imexAddedLabel => 'Added';

  @override
  String get imexAlreadyPresentLabel => 'Already present';

  @override
  String get imexBackupCreated => 'Backup created';

  @override
  String get imexBackupHint =>
      'The backup is a full, encrypted copy of your vault. Keep it somewhere safe.';

  @override
  String get imexBackupPasswordLabel => 'Backup password';

  @override
  String get imexBackupReady => 'Your encrypted backup is ready to share.';

  @override
  String get imexCardsLabel => 'Cards';

  @override
  String get imexConfirmPasswordLabel => 'Confirm password';

  @override
  String get imexCsvExportBody =>
      'Every password in your vault will be written to a plain text file that anyone can read. Only do this if you know what you are doing.';

  @override
  String get imexCsvExportConfirm => 'Export unencrypted';

  @override
  String get imexCsvExportTitle => 'Export unencrypted CSV?';

  @override
  String get imexCsvExported => 'CSV exported';

  @override
  String imexCsvImportSheetTitle(String format) {
    return 'Import $format CSV';
  }

  @override
  String get imexCsvImportSubtitle => 'Bitwarden or Chrome password exports';

  @override
  String get imexCsvMergeHint =>
      'Entries that look the same as ones you already have are skipped.';

  @override
  String get imexCsvReady => 'Your unencrypted export is ready to share.';

  @override
  String get imexEncryptBackupSubtitle =>
      'Choose a password for this backup file. It can be different from your master password and is never stored.';

  @override
  String get imexEncryptBackupTitle => 'Encrypt backup';

  @override
  String get imexEncryptedBackupSection => 'Encrypted backup';

  @override
  String get imexExportBackupAction => 'Export backup';

  @override
  String get imexExportEncryptedSubtitle =>
      'Save an encrypted copy of your vault';

  @override
  String get imexExportEncryptedTitle => 'Export encrypted backup';

  @override
  String get imexExportPlainCsvSubtitle =>
      'Unencrypted — for moving to another app';

  @override
  String get imexExportPlainCsvTitle => 'Export as plain CSV';

  @override
  String get imexFailedRowsLabel => 'Failed rows';

  @override
  String get imexFailureListTitle => 'Rows that could not be imported';

  @override
  String get imexFoldersCreatedLabel => 'Folders created';

  @override
  String get imexHidePassword => 'Hide password';

  @override
  String get imexHubIntro =>
      'Move your vault in and out safely. Encrypted backups use their own password; CSV exports are plain text.';

  @override
  String get imexImportComplete => 'Import complete';

  @override
  String imexImportCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '$count entry',
    );
    return 'Import $_temp0';
  }

  @override
  String get imexImportFromCsvTitle => 'Import from CSV';

  @override
  String get imexLoginsLabel => 'Logins';

  @override
  String get imexMergeHint => 'Entries already in your vault are kept.';

  @override
  String get imexMergeSubtitle => 'Add what is missing, keep the rest';

  @override
  String get imexMergeTitle => 'Merge';

  @override
  String imexMoreFailures(num count) {
    return '…and $count more';
  }

  @override
  String get imexPasswordsMismatch => 'Passwords do not match';

  @override
  String get imexPickBackup => 'Choose a backup file to restore';

  @override
  String get imexPickCsv => 'Choose a CSV export to import';

  @override
  String get imexReplaceHint =>
      'Everything currently in your vault is replaced.';

  @override
  String get imexReplaceSubtitle =>
      'Delete the current vault and use only this file';

  @override
  String get imexReplaceTitle => 'Replace';

  @override
  String get imexReportSubtitle => 'Here is what changed in your vault.';

  @override
  String get imexRestoreAction => 'Restore';

  @override
  String get imexRestoreBackupTitle => 'Restore backup';

  @override
  String get imexRestoreComplete => 'Restore complete';

  @override
  String get imexRestoreFromBackupSubtitle =>
      'Merge or replace your vault from a backup';

  @override
  String get imexRestoreFromBackupTitle => 'Restore from backup';

  @override
  String imexRowFailure(num row, String reason) {
    return 'Row $row: $reason';
  }

  @override
  String get imexSecureNotesLabel => 'Secure notes';

  @override
  String get imexShowPassword => 'Show password';

  @override
  String get imexSkippedRowsLabel => 'Skipped rows';

  @override
  String get imexUnencryptedWarning =>
      'This file is not encrypted. Delete it as soon as you are done.';

  @override
  String get imexVaultSaved => 'Your vault has been saved.';

  @override
  String get otaAndroidOnly => 'Package installer is only supported on Android';

  @override
  String get otaAutoCheckSubtitle =>
      'Checks on launch and when you return, on the selected channel.';

  @override
  String get otaAutoCheckTitle => 'Check for updates automatically';

  @override
  String otaAvailableSubtitle(String version, String channel) {
    return 'Keyel v$version • $channel channel';
  }

  @override
  String otaBannerSemantics(String version) {
    return 'Update available: Keyel $version. Open software update.';
  }

  @override
  String get otaChannelBetaDescription =>
      'Pre-release previews with latest features';

  @override
  String get otaChannelStableDescription => 'Official verified releases';

  @override
  String otaCheckFailedHttp(String status) {
    return 'Failed to check for updates: HTTP $status';
  }

  @override
  String get otaCheckFailedTitle => 'Update check failed';

  @override
  String get otaCheckForUpdates => 'Check for Updates';

  @override
  String get otaChecking => 'Checking...';

  @override
  String get otaCheckingUpdates => 'Checking for updates...';

  @override
  String otaChecksumMismatch(String expected, String computed) {
    return 'Checksum mismatch: expected $expected but got $computed';
  }

  @override
  String get otaChecksumNotVerified => 'Update checksum could not be verified';

  @override
  String get otaConnectingServer => 'Connecting to release server';

  @override
  String get otaCouldNotConnect => 'Could not connect to release server';

  @override
  String otaCouldNotInstallApk(String error) {
    return 'Could not install APK: $error';
  }

  @override
  String get otaDismissBanner => 'Dismiss update banner';

  @override
  String get otaDownloadCancelled => 'Download cancelled by user';

  @override
  String otaDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String otaDownloadFailedHttp(String status) {
    return 'Download failed with HTTP $status';
  }

  @override
  String otaDownloadVersion(String version, String size) {
    return 'Download v$version ($size)';
  }

  @override
  String otaDownloadedVerified(String version) {
    return 'Keyel v$version downloaded & verified';
  }

  @override
  String get otaDownloadingApk => 'Downloading APK';

  @override
  String otaDownloadingDetail(String percent, String size) {
    return '$percent% • $size';
  }

  @override
  String get otaDownloadingUpdate => 'Downloading update...';

  @override
  String get otaEnableNotifications => 'Enable update notifications';

  @override
  String get otaGrantInstallPermission =>
      'Please grant permission to install unknown apps when prompted.';

  @override
  String get otaHandingToInstaller => 'Handing off to system installer';

  @override
  String get otaInstallLocal => 'Install update from local APK file';

  @override
  String get otaInstallNow => 'Install Update Now';

  @override
  String otaInstallationError(String error) {
    return 'Installation error: $error';
  }

  @override
  String otaInstalledVersion(String version) {
    return 'Installed Version: $version';
  }

  @override
  String get otaInstallerUnavailable => 'Package installer could not be opened';

  @override
  String get otaInstallingUpdate => 'Installing update...';

  @override
  String otaLastChecked(String time) {
    return 'Last checked: $time';
  }

  @override
  String otaLatestInstalled(String version) {
    return 'Version $version • Latest release installed';
  }

  @override
  String otaNoBetaRelease(String version) {
    return 'No beta release yet • Version $version installed';
  }

  @override
  String get otaNoReleaseNotes =>
      'No detailed release notes provided for this version.';

  @override
  String get otaNotificationsOn => 'Update notifications are on';

  @override
  String otaPercent(String percent) {
    return '$percent%';
  }

  @override
  String get otaPreferencesTitle => 'Update Preferences';

  @override
  String get otaPrivacyNotice =>
      'Privacy guarantee: automatic checks read the public channel manifest only, on launch and while the app is open. Your vault database, passwords, keys, and biometrics never leave this device.';

  @override
  String get otaReadyToInstall => 'Ready to Install';

  @override
  String get otaRefuseUnverifiedDownload =>
      'Refusing to download an update without a valid SHA-256 checksum';

  @override
  String get otaInsecureUrl => 'Update downloads require an HTTPS URL';

  @override
  String get otaLocalInstallWarning =>
      'Local APKs are not checksum-verified by Keyel. Only install a file you trust.';

  @override
  String get otaReverifyFailed =>
      'The downloaded update failed its final checksum check and was removed';

  @override
  String get otaReleaseChannel => 'Release Channel';

  @override
  String get otaSelectApkTitle => 'Select Keyel Update APK';

  @override
  String get otaTapCheckNow => 'Tap \"Check now\" to look for new releases';

  @override
  String get otaUpToDate => 'Keyel is up to date';

  @override
  String get otaUpdateAvailableTitle => 'Update available';

  @override
  String get otaUpdateFileNotFound => 'Update file not found on device';

  @override
  String otaWhatsNew(String version) {
    return 'What’s New in v$version';
  }

  @override
  String get passCreateBody =>
      'The passkey will be encrypted and stored in your local Keyel vault. Your private key never leaves this device.';

  @override
  String get passCreateQuestion => 'Create a passkey for this account?';

  @override
  String get passFindingPasskeys => 'Finding passkeys…';

  @override
  String get passLabelAccount => 'Account';

  @override
  String get passLabelDisplayName => 'Display name';

  @override
  String get passLabelDomain => 'Domain';

  @override
  String get passLabelSite => 'Site';

  @override
  String get passMissingRp =>
      'Missing relying party information for this request.';

  @override
  String get passNoMatches => 'No passkeys available';

  @override
  String passNoMatchesAvailable(String rpId) {
    return 'No passkeys are saved for $rpId.';
  }

  @override
  String passNoMatchesForRp(String rpId) {
    return 'No passkeys found for $rpId.';
  }

  @override
  String passOrigin(String origin) {
    return 'Origin: $origin';
  }

  @override
  String get passSavePasskey => 'Save passkey';

  @override
  String get passSaving => 'Saving…';

  @override
  String passSignInTo(String rpId) {
    return 'Sign in to $rpId';
  }

  @override
  String get passThisSite => 'this site';

  @override
  String get passUnknownAccount => 'Unknown account';

  @override
  String get passUnknownSite => 'Unknown site';

  @override
  String get passUsePasskey => 'Use passkey';

  @override
  String get prefAllowScreenshotsBody =>
      'Anything on screen, including a revealed secret, could be captured or appear in your Recents preview. The lock and unlock screens stay protected.';

  @override
  String get prefAllowScreenshotsConfirm => 'Allow screenshots';

  @override
  String get prefAllowScreenshotsTitle => 'Allow screenshots?';

  @override
  String get prefAppearanceChangesInstant =>
      'Changes apply instantly across Keyel.';

  @override
  String get prefAppearanceColorsTitle => 'Appearance & colors';

  @override
  String get prefAskToSaveSubtitle =>
      'Offer to save new credentials after a login';

  @override
  String get prefAskToSaveTitle => 'Ask to save';

  @override
  String prefAutoLockAfterMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return 'After $_temp0';
  }

  @override
  String prefAutoLockAfterSeconds(num count) {
    return 'After $count seconds';
  }

  @override
  String get prefAutoLockDialogTitle => 'Auto-lock after';

  @override
  String get prefAutoLockImmediately => 'Immediately';

  @override
  String get prefAutoLockSubtitle =>
      'Lock the vault after time in the background';

  @override
  String get prefAutofillDisabledSubtitle =>
      'Tap to enable Keyel as your autofill provider';

  @override
  String get prefAutofillEnabledSubtitle => 'Keyel is your autofill provider';

  @override
  String get prefAutofillPasskeysSection => 'Autofill & Passkeys';

  @override
  String get prefAutofillServiceTitle => 'Autofill service';

  @override
  String get prefBackToSecurity => 'Back to Security';

  @override
  String get prefBackupImportSubtitle =>
      'Encrypted backups and CSV import or export';

  @override
  String get prefBackupImportTitle => 'Backup & import';

  @override
  String get prefBiometricDisabledSnack => 'Biometric unlock disabled.';

  @override
  String get prefBiometricEnabledSnack => 'Biometric unlock enabled';

  @override
  String get prefBiometricUnlockSubtitle =>
      'Fingerprint or face to open the vault';

  @override
  String get prefBiometricUnlockTitle => 'Biometric unlock';

  @override
  String prefBiometricUpdateError(String error) {
    return 'Could not update biometric settings: $error';
  }

  @override
  String get prefBiometricsUnavailable =>
      'Biometrics are not available on this device.';

  @override
  String get prefBridgeDiagnosticsSubtitle =>
      'Raw FRB bridge operations and diagnostics';

  @override
  String get prefBridgeDiagnosticsTitle => 'Bridge diagnostics & test suite';

  @override
  String get prefChangeMasterPasswordRow => 'Change master password';

  @override
  String get prefChangeMasterSubtitle =>
      'Re-encrypt the vault keyslot with a new master';

  @override
  String get prefChangeMasterTitle => 'Change Master Password';

  @override
  String get prefChangePasswordAction => 'Change Password';

  @override
  String get prefCheckingDeviceSupport => 'Checking device support…';

  @override
  String get prefCheckingStatus => 'Checking…';

  @override
  String get prefClipboardDialogBody =>
      'Locking the vault or leaving the app always clears it right away. This setting controls the timer while Keyel stays open.';

  @override
  String get prefClipboardDialogTitle => 'Clear clipboard after';

  @override
  String prefClipboardMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String get prefClipboardNever => 'Never';

  @override
  String prefClipboardSeconds(num count) {
    return '$count seconds';
  }

  @override
  String get prefClipboardSubtitle => 'Wipe copied secrets from the clipboard';

  @override
  String get prefConfirmMasterTitle => 'Confirm master password';

  @override
  String get prefConfirmNewMasterPassword => 'Confirm New Master Password';

  @override
  String get prefCopyPasswordLabel => 'Copy password';

  @override
  String get prefCrossDeviceSyncSubtitle =>
      'Optional E2EE sync through a folder you choose';

  @override
  String get prefCrossDeviceSyncTitle => 'Cross-device sync';

  @override
  String get prefCurrentMasterPassword => 'Current Master Password';

  @override
  String prefDeviceCurrently(String device) {
    return 'Device is currently $device';
  }

  @override
  String get prefDeviceDarkValue => 'dark';

  @override
  String get prefDeviceLightValue => 'light';

  @override
  String prefDiagnosticsSubject(String version) {
    return 'Keyel diagnostics ($version)';
  }

  @override
  String get prefExampleLogin => 'Example login';

  @override
  String get prefFactoryResetBody =>
      'This will permanently delete your vault file and all stored credentials. This action cannot be undone.';

  @override
  String get prefFactoryResetConfirm => 'Delete Everything';

  @override
  String prefFactoryResetError(String error) {
    return 'Factory reset failed: $error';
  }

  @override
  String get prefFactoryResetSnack => 'Vault permanently deleted. Resetting...';

  @override
  String get prefFactoryResetTitle => 'Factory Reset?';

  @override
  String get prefFactoryResetVaultSubtitle =>
      'Permanently delete vault file and reset app state';

  @override
  String get prefFactoryResetVaultTitle => 'Factory reset vault';

  @override
  String get prefFoldersSubtitle => 'Create, rename and delete vault folders';

  @override
  String get prefHelpAutoLockBody =>
      'The vault locks itself after the delay set in Security. Copied secrets are wiped on lock and when you leave the app, even if the timed clipboard wipe is set to “Never”.';

  @override
  String get prefHelpAutoLockTitle => 'Auto-lock and clipboard';

  @override
  String get prefHelpKeyboardBody =>
      'Ctrl/⌘ + K opens quick actions. Ctrl/⌘ + F jumps to vault search. Ctrl/⌘ + N starts a new entry. On Android, Back asks before discarding unsaved edits.';

  @override
  String get prefHelpKeyboardTitle => 'Keyboard shortcuts';

  @override
  String get prefHelpRecoveryBody =>
      'Your one-time recovery key is the only way back in if you forget the master password. Store it offline; Keyel cannot reset it.';

  @override
  String get prefHelpRecoveryTitle => 'Recovery';

  @override
  String get prefHelpSheetTitle => 'Keyel help';

  @override
  String get prefHelpSupportTooltip => 'Help & support';

  @override
  String get prefHelpVaultLocalBody =>
      'Entries are encrypted on this device. Keyel has no account and sends nothing anywhere unless you explicitly turn on the opt-in breach check or sync.';

  @override
  String get prefHelpVaultLocalTitle => 'Your vault stays local';

  @override
  String get prefIncorrectPassword => 'Incorrect password';

  @override
  String get prefLivePreview => 'Live preview';

  @override
  String get prefLocalEncryptedVault => 'Local Encrypted Vault';

  @override
  String get prefLockVaultNow => 'Lock vault now';

  @override
  String get prefLockVaultSubtitle =>
      'Wipe decryption key from memory immediately';

  @override
  String get prefLoginBadge => 'LOGIN';

  @override
  String get prefMasterChangedSuccess => 'Master password changed successfully';

  @override
  String get prefMasterPasswordLabel => 'Master password';

  @override
  String get prefMatchModeDomain => 'Domain (includes subdomains)';

  @override
  String get prefMatchModeExact => 'Exact host only';

  @override
  String get prefMatchModeTitle => 'Match mode';

  @override
  String get prefNewBadge => 'NEW';

  @override
  String get prefNewMasterPassword => 'New Master Password';

  @override
  String get prefNewPasswordEmpty => 'New password cannot be empty.';

  @override
  String get prefNewPasswordsMismatch => 'New passwords do not match.';

  @override
  String get prefNoVaultBadge => 'No Vault';

  @override
  String get prefOpenSourceLicensesSubtitle =>
      'Libraries bundled with this build';

  @override
  String get prefOpenSourceLicensesTitle => 'Open source licenses';

  @override
  String get prefPasskeyProviderTitle => 'Passkey provider';

  @override
  String get prefPasskeySupportedSubtitle =>
      'Manage Keyel as a passkey provider in system settings';

  @override
  String get prefPasskeyUnsupportedSubtitle =>
      'Not supported on this device or Android version';

  @override
  String get prefPasswordRequired => 'Password required';

  @override
  String prefReportProblemError(String error) {
    return 'Could not prepare the report: $error';
  }

  @override
  String get prefReportProblemSubtitle =>
      'Share a redacted diagnostics file (no secrets)';

  @override
  String get prefScreenshotOffSnack => 'Screenshots allowed while unlocked';

  @override
  String get prefScreenshotOnSnack => 'Screenshot protection on';

  @override
  String get prefScreenshotSubtitle =>
      'Block screenshots and Recents previews while the vault is open. Lock screens stay protected either way.';

  @override
  String get prefSecurityAccessSection => 'Security & Access';

  @override
  String get prefSecuritySubtitle =>
      'Security tuned for this device, kept local.';

  @override
  String get prefSoftwareUpdateRowTitle => 'Software update';

  @override
  String get prefStorageDiagnosticsSection => 'Storage & Diagnostics';

  @override
  String get prefStorageNotInitialized => 'Storage not initialized';

  @override
  String get prefThemeDarkDescription =>
      'Stays dark even when your device uses light mode.';

  @override
  String get prefThemeLightDescription =>
      'Stays light even when your device uses dark mode.';

  @override
  String get prefThemeModeSemantics => 'Theme mode';

  @override
  String prefThemePreviewSemantics(String palette, String mode) {
    return 'Theme preview: $palette, $mode mode.';
  }

  @override
  String prefThemeSemanticLabel(String label, String description) {
    return '$label theme. $description';
  }

  @override
  String prefThemeSemanticWithDevice(
    String label,
    String description,
    String device,
  ) {
    return '$label theme. $description Device is currently $device.';
  }

  @override
  String get prefThemeSystemDescription =>
      'Follows your device appearance and changes along with it.';

  @override
  String get prefTrashSubtitle =>
      'Restore deleted entries or remove them forever';

  @override
  String prefUpdateAvailable(String version) {
    return 'Update available (v$version)';
  }

  @override
  String get prefVaultLockedBadge => 'Locked';

  @override
  String get prefVaultLockedSnack => 'Vault locked';

  @override
  String get prefVaultUnlockedBadge => 'Unlocked';

  @override
  String get prefVerificationFailed => 'Verification failed';

  @override
  String prefVersionUpToDate(String version) {
    return 'Version $version • Up to date';
  }

  @override
  String get prefYourVault => 'Your vault';

  @override
  String get secAddCodes => 'Add codes';

  @override
  String get secAllClear => 'All clear';

  @override
  String get secAllHealthyDetail =>
      'No weak, reused or old passwords, and every login has 2FA.';

  @override
  String get secAllSitesHttps => 'All sites use HTTPS';

  @override
  String secAutoLockSemantics(String label) {
    return 'Auto-lock: $label. Always active.';
  }

  @override
  String get secBadgeChecking => 'Checking';

  @override
  String get secBiometricTip =>
      'Enable biometric lock for instantaneous vault unmasking using your device secure enclave.';

  @override
  String get secBreachActiveSemantics =>
      'Breach check: enabled. Nothing is sent until you tap Check now.';

  @override
  String get secBreachCheck => 'Breach check';

  @override
  String get secBreachCheckFailed => 'Breach check failed.';

  @override
  String get secBreachDisabledNotice =>
      'Optional: check saved passwords against known breaches. Nothing is sent unless you turn this on and tap Check now.';

  @override
  String get secBreachEnabledNotice =>
      'Only the first 5 characters of a SHA-1 hash are sent over HTTPS when you tap Check now. Passwords and vault data never leave this device.';

  @override
  String get secBreachInactiveSemantics =>
      'Breach check: off. No password data is sent.';

  @override
  String get secCheckNow => 'Check now';

  @override
  String secCheckedSummary(String passwords, String prefixes) {
    return 'Checked $passwords across $prefixes.';
  }

  @override
  String get secChecking => 'Checking…';

  @override
  String secClipboardActiveSemantics(String value) {
    return 'Clipboard wipe: $value while the app is open. Locking always clears it.';
  }

  @override
  String get secClipboardInactiveSemantics =>
      'Clipboard wipe: only on lock or when leaving the app.';

  @override
  String get secClipboardWipe => 'Clipboard wipe';

  @override
  String get secCredentialsPlainText => 'Credentials sent in plain text';

  @override
  String get secEnableBreachCheck => 'Enable breach check';

  @override
  String get secEnabled => 'Enabled';

  @override
  String get secError => 'Error';

  @override
  String get secEverythingHealthy => 'Everything looks healthy';

  @override
  String secExposureCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exposures',
      one: '$count exposure',
    );
    return '$_temp0';
  }

  @override
  String secExposures(String title, String exposures) {
    return '$title · $exposures';
  }

  @override
  String get secFix => 'Fix';

  @override
  String get secFixNow => 'Fix now';

  @override
  String secFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count found',
      one: '$count found',
    );
    return '$_temp0';
  }

  @override
  String get secHighCompromiseRisk => 'High compromise risk';

  @override
  String get secInsecureSitesHttp => 'Insecure websites (HTTP)';

  @override
  String get secInsecureWebsites => 'Insecure websites';

  @override
  String secIssuesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issues',
      one: '$count issue',
    );
    return '$_temp0';
  }

  @override
  String secIssuesNeedAttention(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need',
      one: '$count item needs',
    );
    return '$_temp0 your attention';
  }

  @override
  String get secMissingTwoFactor => 'Missing 2FA';

  @override
  String secMoreMatches(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '$count more',
    );
    return '+ $_temp0';
  }

  @override
  String get secMoreThanOneYearOld => 'More than 1 year old';

  @override
  String get secNoExposedPasswords => 'No exposed passwords found.';

  @override
  String get secNoIssuesFound =>
      'No issues found. Your vault is in great shape.';

  @override
  String get secNothingToFix => 'Nothing to fix here.';

  @override
  String get secOff => 'Off';

  @override
  String get secOldPasswords => 'Old passwords';

  @override
  String get secOnLockOnly => 'On lock only';

  @override
  String secPasswordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passwords',
      one: '$count password',
    );
    return '$_temp0';
  }

  @override
  String secPrefixCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prefixes',
      one: '$count prefix',
    );
    return '$_temp0';
  }

  @override
  String get secReady => 'Ready';

  @override
  String get secReusedPasswords => 'Reused passwords';

  @override
  String get secReview => 'Review';

  @override
  String get secReviewIssues => 'Review issues';

  @override
  String get secReviewSettings => 'Review settings';

  @override
  String secSavedPasswordsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved passwords found in breaches:',
      one: '$count saved password found in breaches:',
    );
    return '$_temp0';
  }

  @override
  String get secScoreAtRisk => 'At risk';

  @override
  String get secScoreExcellent => 'Excellent';

  @override
  String get secScoreFair => 'Fair';

  @override
  String get secScoreGood => 'Good';

  @override
  String get secScreenshotActiveSemantics =>
      'Screenshot blocking: enabled while the vault is unlocked. Lock screens are always protected.';

  @override
  String get secScreenshotBlocking => 'Screenshot blocking';

  @override
  String get secScreenshotInactiveSemantics =>
      'Screenshot blocking: off. Lock and unlock screens are still protected.';

  @override
  String get secSendHashDialogBody =>
      'Keyel computes a SHA-1 hash of each saved password on this device and sends only the first 5 characters to Have I Been Pwned over HTTPS. Your passwords, usernames and vault are never sent. Checks run only when you tap Check now, and you can turn this off anytime.';

  @override
  String get secSendHashDialogTitle => 'Send hash prefixes to HIBP?';

  @override
  String get secSentOverPlainHttp => 'Sent over plain HTTP';

  @override
  String get secSharedAcrossServices => 'Shared across services';

  @override
  String get secStatusAtRisk => 'AT RISK';

  @override
  String get secStatusReview => 'REVIEW';

  @override
  String get secStatusSecure => 'SECURE';

  @override
  String get secTotpSupported => 'TOTP supported';

  @override
  String get secTurnOff => 'Turn off';

  @override
  String get secTurnOn => 'Turn on';

  @override
  String get secUnlockToCheck => 'Unlock the vault to check.';

  @override
  String get secUpdate => 'Update';

  @override
  String secVaultHealthLabel(String label) {
    return 'Vault health: $label';
  }

  @override
  String get secVaultLocked => 'Vault locked';

  @override
  String get secVaultPosture => 'Vault posture';

  @override
  String secVaultPostureSemantics(String active, String total) {
    return 'Vault posture: $active of $total protections active.';
  }

  @override
  String get secVaultPostureSubtitle =>
      'How Keyel protects this vault right now';

  @override
  String get secVulnerabilityAudit => 'Vulnerability audit';

  @override
  String get secVulnerabilitySummary => 'Vulnerability summary';

  @override
  String get secWeakPasswords => 'Weak passwords';

  @override
  String get synActionsLabel => 'Actions';

  @override
  String get synDiscoveryUnavailable =>
      'Local network discovery is unavailable; enter the pairing code manually.';

  @override
  String get synFindNearbySubtitle =>
      'Detect Keyel devices on the same local network before pairing.';

  @override
  String get synFindNearbyTitle => 'Find nearby devices';

  @override
  String get synFindingNearby => 'Scanning the local network…';

  @override
  String get synNearbyNone =>
      'No nearby devices found. You can still pair with a code.';

  @override
  String get synNearbyNote =>
      'Being on the same network is not identity verification. Exchange the pairing code out of band.';

  @override
  String synNearbyPeer(String name, String address) {
    return '$name · $address';
  }

  @override
  String get synNearbySelected => 'Selected nearby device';

  @override
  String get synChooseFolder => 'Choose a sync folder';

  @override
  String get synChooseFolderFirst => 'Choose a sync folder first.';

  @override
  String synCodeCopied(String hint) {
    return 'Pairing code copied$hint';
  }

  @override
  String get synCodeStoredCheckbox => 'I stored this code somewhere safe';

  @override
  String synComplete(num added, num updated, String conflicts) {
    return 'Sync complete: $added added, $updated updated$conflicts.';
  }

  @override
  String synConflictCopies(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflict copies',
      one: '$count conflict copy',
    );
    return ', $_temp0';
  }

  @override
  String get synCreateGroupSubtitle =>
      'Pick a folder and get a one-time pairing code.';

  @override
  String get synCreateGroupTitle => 'Create a sync group';

  @override
  String get synDisableBody =>
      'Local sync stops. Remote files are left untouched and can be restored by joining again with the pairing code.';

  @override
  String get synDisableConfirm => 'Disable sync';

  @override
  String get synDisableSubtitle =>
      'Stop syncing on this device; keep remote files.';

  @override
  String get synDisableTitle => 'Disable sync?';

  @override
  String get synDisabled => 'Sync disabled on this device.';

  @override
  String get synEnabledShareCode =>
      'Sync enabled. Share the code with your other device only once.';

  @override
  String get synEnabledStatus => 'Sync enabled';

  @override
  String get synEnterCodeFirst => 'Enter the pairing code first.';

  @override
  String get synFolderLabel => 'Folder';

  @override
  String get synFooterNote =>
      'Sync is foreground-only and requires an unlocked vault. Data is encrypted with a random key that never leaves Keyel; losing the pairing code means starting a new sync group. Keep an encrypted backup as well.';

  @override
  String get synGetStartedLabel => 'Get started';

  @override
  String get synHeadline => 'Sync across your devices';

  @override
  String get synJoinBody =>
      'Remote vault data will be merged with this vault on the next manual sync. Conflicting items become separate copies; nothing is silently overwritten or deleted.';

  @override
  String get synJoinGroup => 'Join group';

  @override
  String get synJoinTitle => 'Join this sync group?';

  @override
  String get synJoined => 'Joined the sync group.';

  @override
  String synLastSync(String date) {
    return 'Last sync: $date';
  }

  @override
  String get synLoadingStatus => 'Reading sync state…';

  @override
  String get synLocalOnlyStatus => 'Your vault stays on this device only.';

  @override
  String get synNever => 'Never';

  @override
  String get synNoFolder =>
      'Sync has no folder set. Disable and enable it again.';

  @override
  String get synNotSet => 'Not set';

  @override
  String get synOffStatus => 'Sync is off';

  @override
  String get synOrJoin => 'Or join an existing group';

  @override
  String get synPairingCodeLabel => 'Pairing code';

  @override
  String get synSaveCodeBody =>
      'This code is a bearer secret: anyone who has it can read the synced vault. Store it offline and enter it on your other device once. It will not be shown again after this dialog.';

  @override
  String get synSaveCodeTitle => 'Save this pairing code';

  @override
  String get synShowCodeSubtitle => 'Pair another device with this sync group.';

  @override
  String get synShowCodeTitle => 'Show pairing code';

  @override
  String get synStatusLabel => 'Status';

  @override
  String get synSubtitle =>
      'Optional, manual and end-to-end encrypted. Keyel never runs a sync server: your own sync tool moves the encrypted files between devices.';

  @override
  String get synSyncNowSubtitle =>
      'Pull remote changes, merge and push this device.';

  @override
  String get synSyncNowTitle => 'Sync now';

  @override
  String get synThisDevice => 'This device';

  @override
  String get synUnknown => 'Unknown';

  @override
  String trashAutoDelete(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Auto-deletes in $_temp0';
  }

  @override
  String get trashBannerMessage =>
      'Deleted items stay here for 30 days, then disappear automatically.';

  @override
  String get trashDeleteForever => 'Delete forever';

  @override
  String trashDeleteForeverBody(String title) {
    return '\"$title\" cannot be recovered after this.';
  }

  @override
  String get trashDeleteForeverTitle => 'Delete forever?';

  @override
  String get trashDeleted => 'Deleted';

  @override
  String get trashEmptied => 'Trash emptied';

  @override
  String get trashEmptyAction => 'Empty trash';

  @override
  String trashEmptyConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trashed entries',
      one: '$count trashed entry',
    );
    return 'All $_temp0 will be deleted forever.';
  }

  @override
  String get trashEmptyConfirmTitle => 'Empty trash?';

  @override
  String get trashEmptyMessage =>
      'Deleted entries appear here for 30 days before they are removed permanently.';

  @override
  String get trashLoading => 'Loading deleted items…';

  @override
  String get trashPermanentlyDeleted => 'Entry permanently deleted';

  @override
  String trashRestored(String title) {
    return '\"$title\" restored';
  }

  @override
  String get vaultAddFirstItem => 'Add your first item';

  @override
  String get vaultAddToFavorites => 'Add to favorites';

  @override
  String get vaultAllFolders => 'All folders';

  @override
  String get vaultAlreadyHaveVault => 'I already have a vault';

  @override
  String get vaultBackToUnlock => 'Back to unlock';

  @override
  String get vaultBiometricOptionalHint =>
      'Optional — open the vault with your fingerprint or face.';

  @override
  String get vaultChooseMasterPassword => 'Please choose a master password.';

  @override
  String get vaultClearSelection => 'Clear selection';

  @override
  String get vaultConfirmMasterPassword => 'Confirm Master Password';

  @override
  String get vaultConfirmNewPassword => 'Confirm new password';

  @override
  String get vaultConfirmPassword => 'Confirm password';

  @override
  String get vaultCopied => 'Copied!';

  @override
  String get vaultCopiedCardNumber => 'Card number copied to clipboard';

  @override
  String get vaultCopiedPassword => 'Password copied';

  @override
  String get vaultCopiedRecoveryKey => 'Recovery key copied to clipboard';

  @override
  String get vaultCopiedUsername => 'Username copied to clipboard';

  @override
  String get vaultCopyCard => 'Copy card';

  @override
  String get vaultCopyCredential => 'Copy credential';

  @override
  String get vaultCopyKey => 'Copy Key';

  @override
  String get vaultCopyRecoveryKey => 'Copy key';

  @override
  String get vaultCreateEncryptedVault => 'Create Encrypted Vault';

  @override
  String get vaultCreateIntro =>
      'Create your encrypted offline vault. Only you have the key to your credentials.';

  @override
  String get vaultCreateMasterPasswordSubtitle =>
      'This is the only key to your vault. We cannot reset it for you.';

  @override
  String get vaultCreateMasterPasswordTitle => 'Create your master password';

  @override
  String get vaultCreatingVault => 'Creating vault…';

  @override
  String vaultDeleteItemsTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return 'Delete $_temp0?';
  }

  @override
  String get vaultDeleteManyItemsBody =>
      'These items will be moved to the trash.';

  @override
  String get vaultDeleteOneItemBody => 'This item will be moved to the trash.';

  @override
  String get vaultEmpty => 'Your vault is empty';

  @override
  String get vaultEmptyHint =>
      'Start adding passwords, payment cards, or secure notes. Everything is stored locally with zero-knowledge encryption.';

  @override
  String get vaultEmptySearchHint => 'Try a different search term or filter.';

  @override
  String vaultEntriesSavedOffline(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '$count entry',
    );
    return '$_temp0 saved offline';
  }

  @override
  String vaultEntryPinnedToFavorites(String title) {
    return '$title pinned to favorites';
  }

  @override
  String vaultEntryRemovedFromFavorites(String title) {
    return '$title removed from favorites';
  }

  @override
  String get vaultExitSelection => 'Exit selection';

  @override
  String get vaultFavorite => 'Favorite';

  @override
  String get vaultFilterAll => 'All';

  @override
  String get vaultFilterCards => 'Cards';

  @override
  String get vaultFilterFavorites => 'Favorites';

  @override
  String get vaultFilterLogins => 'Logins';

  @override
  String get vaultFilterNotes => 'Notes';

  @override
  String get vaultFilterTwoFactor => '2FA';

  @override
  String get vaultFolder => 'folder';

  @override
  String get vaultForgotPassword => 'Forgot password?';

  @override
  String get vaultGetStarted => 'Get Started';

  @override
  String get vaultHidePassword => 'Hide password';

  @override
  String vaultItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsMovedToTrash(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0 moved to trash';
  }

  @override
  String vaultItemsPinnedToFavorites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items pinned to favorites',
      one: '$count item pinned to favorites',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsRemovedFromFavorites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items removed from favorites',
      one: '$count item removed from favorites',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0 selected';
  }

  @override
  String get vaultKindCard => 'Payment card';

  @override
  String get vaultKindLogin => 'Login';

  @override
  String get vaultKindNote => 'Secure note';

  @override
  String get vaultKindPasskey => 'Passkey';

  @override
  String get vaultLoadingList => 'Loading your vault…';

  @override
  String get vaultLocked => 'Vault locked';

  @override
  String get vaultMasterPasswordCapitalized => 'Master Password';

  @override
  String get vaultMasterPasswordChanged =>
      'Your master password changed. Set up quick unlock again.';

  @override
  String get vaultMasterPasswordLabel => 'Master password';

  @override
  String get vaultMoveToFolder => 'Move to folder';

  @override
  String vaultMovedItemsToFolder(num count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return 'Moved $_temp0 to $folder';
  }

  @override
  String get vaultNewItem => 'New Item';

  @override
  String get vaultNewMasterPassword => 'New master password';

  @override
  String get vaultNoExistingVault =>
      'No existing vault was found on this device.';

  @override
  String get vaultNoFolder => 'No folder';

  @override
  String get vaultNoItemSelected => 'No item selected';

  @override
  String get vaultNoMatchesFound => 'No matches found';

  @override
  String get vaultNothingToCopy => 'Nothing to copy';

  @override
  String vaultOpenEntry(String title) {
    return 'Open $title';
  }

  @override
  String get vaultOpenMyVault => 'Open my vault';

  @override
  String get vaultOr => 'OR';

  @override
  String get vaultPasswordsMismatch => 'Passwords do not match.';

  @override
  String get vaultQuickUnlockLater =>
      'You can enable biometric quick unlock later in Settings.';

  @override
  String get vaultQuickUnlockOn =>
      'Quick unlock is on. You can turn it off any time in Settings.';

  @override
  String get vaultQuickUnlockSetupAgain =>
      'Quick unlock needs to be set up again.';

  @override
  String get vaultReadySubtitle =>
      'Keyel locks itself after one minute in the background. You can change this in Settings later.';

  @override
  String get vaultReadyTitle => 'Your vault is ready';

  @override
  String get vaultRecentSearches => 'Recent searches';

  @override
  String vaultRecoveryExportError(String error) {
    return 'Could not export the recovery key ($error).';
  }

  @override
  String vaultRecoveryFileText(String key) {
    return 'Keyel vault recovery key\n==========================\n\nThis file contains the recovery key for your Keyel vault.\n\nWARNING: anyone who has this key can unlock your vault. Keep it\noffline and private, and treat it like the master password itself.\n\nIf you forget your master password, this key is the only way back\ninto your vault. Keyel has no accounts and no cloud backup.\n\nYour recovery key:\n\n$key\n';
  }

  @override
  String get vaultRecoveryKeyLabel => 'Recovery key';

  @override
  String get vaultRecoveryKeyTitle => 'Recovery Key';

  @override
  String get vaultRecoveryKeyWarning =>
      'Write down or securely store this recovery key offline. If you forget your master password, this is the ONLY way to regain access to your vault.';

  @override
  String get vaultRemoveFromFavorites => 'Remove from favorites';

  @override
  String get vaultResetMasterPasswordHint =>
      'Enter your recovery key to set a new master password and unlock your vault.';

  @override
  String get vaultResetMasterPasswordTitle => 'Reset your master password';

  @override
  String get vaultResetPassword => 'Reset password';

  @override
  String get vaultResetting => 'Resetting…';

  @override
  String get vaultResults => 'Results';

  @override
  String get vaultSaveFile => 'Save file';

  @override
  String get vaultSaveRecoveryKeySubtitle =>
      'If you forget the master password, this key is the only way back into your vault. It is shown once.';

  @override
  String get vaultSaveRecoveryKeyTitle => 'Save your recovery key';

  @override
  String get vaultSavedRecoveryKey => 'I Have Saved It';

  @override
  String get vaultSearchHint => 'Search items, tags or notes...';

  @override
  String get vaultSelectAll => 'Select all';

  @override
  String vaultSelectEntry(String title) {
    return 'Select $title';
  }

  @override
  String get vaultSelectItemHint =>
      'Select an item from the list to view and manage its details.';

  @override
  String get vaultShowPassword => 'Show password';

  @override
  String get vaultStoredKeyConfirmation => 'I stored this key somewhere safe';

  @override
  String get vaultToggleFavorite => 'Toggle favorite';

  @override
  String vaultTooManyAttempts(num seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get vaultTopBarTitle => 'Keyel Vault';

  @override
  String get vaultUndo => 'Undo';

  @override
  String get vaultUnfavorite => 'Unfavorite';

  @override
  String get vaultUnlockHint =>
      'Enter your master password to unlock your vault.';

  @override
  String get vaultUnlockWithBiometrics => 'Unlock with biometrics';

  @override
  String get vaultUnlocking => 'Unlocking…';

  @override
  String get vaultViewNote => 'View note';

  @override
  String get vaultViewPasskey => 'View passkey';

  @override
  String get vaultWelcomeBack => 'Welcome back';

  @override
  String get vaultWelcomeSubtitle =>
      'Your passwords stay encrypted on this device. There is no account, no cloud, and no telemetry.';

  @override
  String get vaultWelcomeToKeyel => 'Welcome to Keyel';

  @override
  String get wearClearAll => 'Remove all from watch';

  @override
  String get wearClearMessage =>
      'The seeds are deleted from this watch. You can send them again from the phone. Your vault is not changed.';

  @override
  String get wearClearTitle => 'Remove all codes from the watch?';

  @override
  String get wearCleared => 'All codes removed from the watch';

  @override
  String get wearEmpty =>
      'None of your entries has a one-time password configured.';

  @override
  String get wearFailed => 'Could not reach the watch';

  @override
  String get wearInfo =>
      'Send a TOTP seed to a paired Wear OS watch. The seed is stored only on the watch, encrypted with its device key. Sending requires an unlocked vault. Codes are hidden when you leave the watch app and are never copied to the clipboard.';

  @override
  String get wearSend => 'Send';

  @override
  String get wearSent => 'Seed sent to the watch';

  @override
  String get wearTitle => 'Watch codes';

  @override
  String get wearUnavailable =>
      'No paired Wear OS watch is reachable. Open Keyel on your phone with the watch nearby, then try again.';

  @override
  String get actionReset => 'Reset';

  @override
  String get quickActionOpenEntry => 'Open an entry';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickActionsHint => 'Search entries or choose an action';

  @override
  String get quickActionsNoResults => 'No matching entries';

  @override
  String get quickActionsTooltip => 'Quick actions (Ctrl/⌘ + K)';

  @override
  String get quickActionsKeyboardHint =>
      '↑/↓ to move, Enter to open, Esc to close';

  @override
  String get paneResizeLabel => 'Resize the list pane';
}
