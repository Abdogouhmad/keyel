import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// User-facing copy: appTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Keyel'**
  String get appTitle;

  /// User-facing copy: navVault (en template).
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get navVault;

  /// User-facing copy: navGenerator (en template).
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get navGenerator;

  /// User-facing copy: navSecurity (en template).
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get navSecurity;

  /// User-facing copy: navSettings (en template).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// User-facing copy: actionBack (en template).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// User-facing copy: actionClose (en template).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// User-facing copy: actionCancel (en template).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// User-facing copy: actionSave (en template).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// User-facing copy: actionRetry (en template).
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// User-facing copy: actionDelete (en template).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// User-facing copy: actionEdit (en template).
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// User-facing copy: actionCopy (en template).
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// User-facing copy: actionShare (en template).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// User-facing copy: actionDone (en template).
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// User-facing copy: actionAdd (en template).
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// User-facing copy: actionOpen (en template).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// User-facing copy: actionRefresh (en template).
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// User-facing copy: actionLockVault (en template).
  ///
  /// In en, this message translates to:
  /// **'Lock vault'**
  String get actionLockVault;

  /// User-facing copy: actionUnlock (en template).
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// User-facing copy: actionClear (en template).
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// User-facing copy: actionRemove (en template).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// User-facing copy: actionRestore (en template).
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// User-facing copy: actionContinue (en template).
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// User-facing copy: languageSystem (en template).
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// User-facing copy: languageEnglish (en template).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// User-facing copy: languageFrench (en template).
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// User-facing copy: settingsLanguageTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// User-facing copy: settingsLanguageSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by Keyel'**
  String get settingsLanguageSubtitle;

  /// User-facing copy: appearanceTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// User-facing copy: settingsTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// User-facing copy: securityTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Security Health'**
  String get securityTitle;

  /// User-facing copy: generatorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get generatorTitle;

  /// User-facing copy: vaultTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultTitle;

  /// User-facing copy: softwareUpdate (en template).
  ///
  /// In en, this message translates to:
  /// **'Software Update'**
  String get softwareUpdate;

  /// User-facing copy: foldersTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersTitle;

  /// User-facing copy: trashTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTitle;

  /// User-facing copy: passkeysTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeysTitle;

  /// User-facing copy: autofillTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Autofill'**
  String get autofillTitle;

  /// User-facing copy: importExportTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Import & export'**
  String get importExportTitle;

  /// User-facing copy: syncTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// User-facing copy: helpTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// User-facing copy: reportProblem (en template).
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// User-facing copy: commonLoading (en template).
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// User-facing copy: commonErrorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// User-facing copy: commonEmpty (en template).
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get commonEmpty;

  /// User-facing copy: searchHint (en template).
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// User-facing copy: stateMissingTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get stateMissingTitle;

  /// User-facing copy: stateMissingMessage (en template).
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get stateMissingMessage;

  /// User-facing copy: checkForUpdates (en template).
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// User-facing copy: aboutGeneration (en template).
  ///
  /// In en, this message translates to:
  /// **'About generation'**
  String get aboutGeneration;

  /// User-facing copy: generationHistory (en template).
  ///
  /// In en, this message translates to:
  /// **'Generation history'**
  String get generationHistory;

  /// User-facing copy: aboutGenerationMessage (en template).
  ///
  /// In en, this message translates to:
  /// **'Keyel always generates locally on your device.'**
  String get aboutGenerationMessage;

  /// User-facing copy: clearFilters (en template).
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// User-facing copy: addItem (en template).
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// User-facing copy: themeModeTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeModeTitle;

  /// User-facing copy: paletteTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get paletteTitle;

  /// User-facing copy: amoledTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Pure black (AMOLED)'**
  String get amoledTitle;

  /// User-facing copy: animationsTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animationsTitle;

  /// User-facing copy: hapticsTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get hapticsTitle;

  /// User-facing copy: screenshotTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection'**
  String get screenshotTitle;

  /// User-facing copy: clipboardTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Clear clipboard'**
  String get clipboardTitle;

  /// User-facing copy: autoLockTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get autoLockTitle;

  /// User-facing copy: breachTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Breach monitoring'**
  String get breachTitle;

  /// User-facing copy: otaTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get otaTitle;

  /// User-facing copy: healthLoading (en template).
  ///
  /// In en, this message translates to:
  /// **'Checking your vault health…'**
  String get healthLoading;

  /// User-facing copy: healthErrorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Could not check vault health'**
  String get healthErrorTitle;

  /// User-facing copy: vaultLoading (en template).
  ///
  /// In en, this message translates to:
  /// **'Opening your vault…'**
  String get vaultLoading;

  /// User-facing copy: vaultErrorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Could not open your vault'**
  String get vaultErrorTitle;

  /// User-facing copy: folderEmpty (en template).
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get folderEmpty;

  /// User-facing copy: trashEmpty (en template).
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// User-facing copy: folderErrorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Could not load folders'**
  String get folderErrorTitle;

  /// User-facing copy: trashErrorTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Could not load trash'**
  String get trashErrorTitle;

  /// User-facing copy: versionLabel (en template).
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// User-facing copy: currentVersion (en template).
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersion;

  /// User-facing copy: installedVersion (en template).
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedVersion;

  /// User-facing copy: appearanceHeadline (en template).
  ///
  /// In en, this message translates to:
  /// **'Personalize Keyel'**
  String get appearanceHeadline;

  /// User-facing copy: appearanceSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Choose your theme, accent palette, and interaction preferences. Security indicators stay consistent.'**
  String get appearanceSubtitle;

  /// User-facing copy: paletteColors (en template).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} color} other{{count} colors}}'**
  String paletteColors(num count);

  /// User-facing copy: darkModeTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeTitle;

  /// User-facing copy: interactionTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Interaction'**
  String get interactionTitle;

  /// User-facing copy: amoledSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Use true black backgrounds in dark mode to reduce OLED glow and save power on supported displays.'**
  String get amoledSubtitle;

  /// User-facing copy: animationsSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Enable motion and transitions throughout the app. System reduced-motion settings are always respected.'**
  String get animationsSubtitle;

  /// User-facing copy: hapticsSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Enable tactile feedback for taps and actions where supported by your device.'**
  String get hapticsSubtitle;

  /// User-facing copy: languageFollowSystem (en template).
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// User-facing copy: autofillFillTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Fill from Keyel'**
  String get autofillFillTitle;

  /// User-facing copy: autofillFilling (en template).
  ///
  /// In en, this message translates to:
  /// **'Filling {target}'**
  String autofillFilling(String target);

  /// User-facing copy: autofillTargetThisApp (en template).
  ///
  /// In en, this message translates to:
  /// **'this app'**
  String get autofillTargetThisApp;

  /// User-facing copy: autofillSearchVault (en template).
  ///
  /// In en, this message translates to:
  /// **'Search vault'**
  String get autofillSearchVault;

  /// User-facing copy: autofillCreateNewLogin (en template).
  ///
  /// In en, this message translates to:
  /// **'Create new login'**
  String get autofillCreateNewLogin;

  /// User-facing copy: autofillNeverForSite (en template).
  ///
  /// In en, this message translates to:
  /// **'Never for this site'**
  String get autofillNeverForSite;

  /// User-facing copy: autofillSaveTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Save login?'**
  String get autofillSaveTitle;

  /// User-facing copy: autofillSaveLogin (en template).
  ///
  /// In en, this message translates to:
  /// **'Save login'**
  String get autofillSaveLogin;

  /// User-facing copy: autofillNotNow (en template).
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get autofillNotNow;

  /// User-facing copy: autofillNewLogin (en template).
  ///
  /// In en, this message translates to:
  /// **'New login'**
  String get autofillNewLogin;

  /// User-facing copy: autofillNameRequired (en template).
  ///
  /// In en, this message translates to:
  /// **'Give this login a name first.'**
  String get autofillNameRequired;

  /// User-facing copy: autofillFindingMatches (en template).
  ///
  /// In en, this message translates to:
  /// **'Finding matching logins…'**
  String get autofillFindingMatches;

  /// User-facing copy: autofillNoMatches (en template).
  ///
  /// In en, this message translates to:
  /// **'No matching logins'**
  String get autofillNoMatches;

  /// User-facing copy: autofillNoMatchesBody (en template).
  ///
  /// In en, this message translates to:
  /// **'Create a new login for this app or site.'**
  String get autofillNoMatchesBody;

  /// User-facing copy: autofillDisabledTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Autofill is off for this site'**
  String get autofillDisabledTitle;

  /// User-facing copy: autofillDisabledBody (en template).
  ///
  /// In en, this message translates to:
  /// **'You chose never to fill here. Remove this choice from Keyel\'s autofill settings to turn it back on.'**
  String get autofillDisabledBody;

  /// User-facing copy: autofillStoreCredentials (en template).
  ///
  /// In en, this message translates to:
  /// **'Store these credentials for {target}'**
  String autofillStoreCredentials(String target);

  /// User-facing copy: fieldName (en template).
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// User-facing copy: fieldUsername (en template).
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// User-facing copy: fieldPassword (en template).
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// User-facing copy: autofillMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'Some results are text matches only. Check that the login really belongs to {target} before filling.'**
  String autofillMismatchBody(String target);

  /// User-facing copy: autofillVaultLocked (en template).
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get autofillVaultLocked;

  /// User-facing copy: autofillUnlockToFill (en template).
  ///
  /// In en, this message translates to:
  /// **'Unlock Keyel to fill this form.'**
  String get autofillUnlockToFill;

  /// User-facing copy: autofillLoadError (en template).
  ///
  /// In en, this message translates to:
  /// **'Could not load matches'**
  String get autofillLoadError;

  /// User-facing copy: autofillNeverTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Never for these sites'**
  String get autofillNeverTitle;

  /// User-facing copy: autofillNeverSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Where Keyel will not offer to fill or save'**
  String get autofillNeverSubtitle;

  /// User-facing copy: autofillNeverEmpty (en template).
  ///
  /// In en, this message translates to:
  /// **'No blocked sites yet'**
  String get autofillNeverEmpty;

  /// User-facing copy: autofillNeverCount (en template).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} blocked site} other{{count} blocked sites}}'**
  String autofillNeverCount(num count);

  /// User-facing copy: actionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get actionManage;

  /// User-facing copy: autofillVerifiedTitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Verified sites only'**
  String get autofillVerifiedTitle;

  /// User-facing copy: autofillVerifiedSubtitle (en template).
  ///
  /// In en, this message translates to:
  /// **'Exact package or host matches only (offline Digital Asset Links substitute)'**
  String get autofillVerifiedSubtitle;

  /// MaterialApp title for the autofill entrypoint.
  ///
  /// In en, this message translates to:
  /// **'Keyel Autofill'**
  String get coreAutofillAppTitle;

  /// Reason shown by the OS biometric prompt when enabling quick unlock.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to enable it'**
  String get coreBiometricEnableReason;

  /// Vault error: a breach check is already running.
  ///
  /// In en, this message translates to:
  /// **'A breach check is already in progress.'**
  String get coreBreachCheckActive;

  /// Generic breach-check failure message.
  ///
  /// In en, this message translates to:
  /// **'Breach check failed. Please try again.'**
  String get coreBreachCheckFailed;

  /// Vault error: breach service returned an unexpected response.
  ///
  /// In en, this message translates to:
  /// **'The breach service returned an unexpected response.'**
  String get coreBreachInvalidResponse;

  /// Vault error: breach-check token expired.
  ///
  /// In en, this message translates to:
  /// **'That breach check has expired.'**
  String get coreBreachInvalidToken;

  /// Error shown when the breach-check network request fails.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the breach service.'**
  String get coreBreachUnreachable;

  /// Vault error: import file has no entries.
  ///
  /// In en, this message translates to:
  /// **'That file has no entries to import.'**
  String get coreEmptyImport;

  /// Vault error: entry does not exist.
  ///
  /// In en, this message translates to:
  /// **'Entry not found.'**
  String get coreEntryNotFound;

  /// Vault error: generic internal failure.
  ///
  /// In en, this message translates to:
  /// **'Internal error.'**
  String get coreInternalError;

  /// Vault error: malformed entry id.
  ///
  /// In en, this message translates to:
  /// **'Invalid entry id.'**
  String get coreInvalidEntryId;

  /// Vault error: invalid key-derivation parameters.
  ///
  /// In en, this message translates to:
  /// **'Invalid key-derivation parameters.'**
  String get coreInvalidKdfParams;

  /// Vault error: recovery key rejected.
  ///
  /// In en, this message translates to:
  /// **'That recovery key is not valid.'**
  String get coreInvalidRecoveryKey;

  /// Vault error: malformed CSV export.
  ///
  /// In en, this message translates to:
  /// **'That file is not a valid CSV export.'**
  String get coreMalformedImport;

  /// Accent palette label: amber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get corePaletteAmber;

  /// Accent palette description: amber.
  ///
  /// In en, this message translates to:
  /// **'Warm golden tones'**
  String get corePaletteAmberDesc;

  /// Accent palette label: forest green.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get corePaletteForest;

  /// Accent palette description: forest green.
  ///
  /// In en, this message translates to:
  /// **'Deep green tones'**
  String get corePaletteForestDesc;

  /// Accent palette label: graphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get corePaletteGraphite;

  /// Accent palette description: graphite.
  ///
  /// In en, this message translates to:
  /// **'Neutral monochrome tones'**
  String get corePaletteGraphiteDesc;

  /// Accent palette label: classic indigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get corePaletteIndigo;

  /// Accent palette description: classic indigo.
  ///
  /// In en, this message translates to:
  /// **'Classic Keyel brand colors'**
  String get corePaletteIndigoDesc;

  /// Accent palette label: ocean blue.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get corePaletteOcean;

  /// Accent palette description: ocean blue.
  ///
  /// In en, this message translates to:
  /// **'Calm blue tones'**
  String get corePaletteOceanDesc;

  /// Accent palette label: rose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get corePaletteRose;

  /// Accent palette description: rose.
  ///
  /// In en, this message translates to:
  /// **'Soft red and pink tones'**
  String get corePaletteRoseDesc;

  /// Accent palette label: teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get corePaletteTeal;

  /// Accent palette description: teal.
  ///
  /// In en, this message translates to:
  /// **'Balanced blue-green tones'**
  String get corePaletteTealDesc;

  /// Accent palette label: violet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get corePaletteViolet;

  /// Accent palette description: violet.
  ///
  /// In en, this message translates to:
  /// **'Rich purple tones'**
  String get corePaletteVioletDesc;

  /// MaterialApp title for the passkey entrypoint.
  ///
  /// In en, this message translates to:
  /// **'Keyel Passkeys'**
  String get corePasskeyAppTitle;

  /// Passkey error: the incoming request could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read the passkey request. Try again.'**
  String get corePasskeyRequestUnreadable;

  /// Passkey error: unsupported request mode.
  ///
  /// In en, this message translates to:
  /// **'This passkey request is not supported.'**
  String get corePasskeyRequestUnsupported;

  /// Title of the passkey error screen.
  ///
  /// In en, this message translates to:
  /// **'Passkey unavailable'**
  String get corePasskeyUnavailable;

  /// Vault error: required fields are empty.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the required fields.'**
  String get coreRequiredFields;

  /// Vault error: file I/O failed.
  ///
  /// In en, this message translates to:
  /// **'Could not read or write the vault file.'**
  String get coreStorageError;

  /// Theme mode label: dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get coreThemeDark;

  /// Theme mode label: light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get coreThemeLight;

  /// Theme mode label: follow system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get coreThemeSystem;

  /// Unlock throttle error shown after too many master-password attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String coreThrottled(String seconds);

  /// Vault error: unsupported CSV layout.
  ///
  /// In en, this message translates to:
  /// **'That CSV format is not supported. Use a Bitwarden or Chrome export.'**
  String get coreUnsupportedCsvFormat;

  /// Vault error: vault file is damaged.
  ///
  /// In en, this message translates to:
  /// **'The vault file is damaged.'**
  String get coreVaultCorrupted;

  /// Vault error: a vault already exists.
  ///
  /// In en, this message translates to:
  /// **'A vault already exists.'**
  String get coreVaultExists;

  /// Vault error: configured path is invalid.
  ///
  /// In en, this message translates to:
  /// **'The vault path is invalid.'**
  String get coreVaultInvalidPath;

  /// Vault error: operation requires an unlocked vault.
  ///
  /// In en, this message translates to:
  /// **'Unlock the vault first.'**
  String get coreVaultLocked;

  /// Vault error: no vault file found.
  ///
  /// In en, this message translates to:
  /// **'No vault file was found.'**
  String get coreVaultMissing;

  /// Vault error: storage is not initialized.
  ///
  /// In en, this message translates to:
  /// **'Vault storage is not initialized.'**
  String get coreVaultNotInitialized;

  /// Vault error: vault format is too new.
  ///
  /// In en, this message translates to:
  /// **'This vault was created by a newer Keyel version.'**
  String get coreVaultUnsupportedVersion;

  /// Vault error: master password rejected or vault damaged.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or damaged vault.'**
  String get coreWrongPassword;

  /// User-facing copy: "2FA code copied to clipboard".
  ///
  /// In en, this message translates to:
  /// **'2FA code copied to clipboard'**
  String get entry2FaCodeCopied;

  /// User-facing copy: "2FA enabled".
  ///
  /// In en, this message translates to:
  /// **'2FA enabled'**
  String get entry2FaEnabled;

  /// User-facing copy: "Add custom field".
  ///
  /// In en, this message translates to:
  /// **'Add custom field'**
  String get entryAddCustomField;

  /// User-facing copy: "Add to favorites".
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get entryAddToFavorites;

  /// User-facing copy: "Algorithm".
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get entryAlgorithm;

  /// User-facing copy: "Card details".
  ///
  /// In en, this message translates to:
  /// **'Card details'**
  String get entryCardDetails;

  /// User-facing copy: "Card number".
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get entryCardNumber;

  /// User-facing copy: "Card number copied to clipboard".
  ///
  /// In en, this message translates to:
  /// **'Card number copied to clipboard'**
  String get entryCardNumberCopied;

  /// User-facing copy: "Cardholder".
  ///
  /// In en, this message translates to:
  /// **'Cardholder'**
  String get entryCardholder;

  /// User-facing copy: "Cardholder name".
  ///
  /// In en, this message translates to:
  /// **'Cardholder name'**
  String get entryCardholderName;

  /// User-facing copy: "Cardholder name copied".
  ///
  /// In en, this message translates to:
  /// **'Cardholder name copied'**
  String get entryCardholderNameCopied;

  /// User-facing copy: "Change icon".
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get entryChangeIcon;

  /// User-facing copy: "Choose Icon".
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get entryChooseIcon;

  /// User-facing copy: "Select an icon for this entry".
  ///
  /// In en, this message translates to:
  /// **'Select an icon for this entry'**
  String get entryChooseIconSubtitle;

  /// User-facing copy: "Configured".
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get entryConfigured;

  /// User-facing copy: "Copy 2FA code".
  ///
  /// In en, this message translates to:
  /// **'Copy 2FA code'**
  String get entryCopy2FaCode;

  /// User-facing copy: "Copy card number".
  ///
  /// In en, this message translates to:
  /// **'Copy card number'**
  String get entryCopyCardNumber;

  /// User-facing copy: "Copy cardholder".
  ///
  /// In en, this message translates to:
  /// **'Copy cardholder'**
  String get entryCopyCardholder;

  /// User-facing copy: "Copy full note".
  ///
  /// In en, this message translates to:
  /// **'Copy full note'**
  String get entryCopyFullNote;

  /// User-facing copy: "Copy password".
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get entryCopyPassword;

  /// User-facing copy: "Copy URL".
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get entryCopyUrl;

  /// User-facing copy: "Copy username".
  ///
  /// In en, this message translates to:
  /// **'Copy username'**
  String get entryCopyUsername;

  /// User-facing copy: "Copy value".
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get entryCopyValue;

  /// User-facing copy: "Copy website URL".
  ///
  /// In en, this message translates to:
  /// **'Copy website URL'**
  String get entryCopyWebsiteUrl;

  /// User-facing copy: "Entry created in vault.".
  ///
  /// In en, this message translates to:
  /// **'Entry created in vault.'**
  String get entryCreated;

  /// User-facing copy: "Credential ID".
  ///
  /// In en, this message translates to:
  /// **'Credential ID'**
  String get entryCredentialId;

  /// User-facing copy: "Credentials".
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get entryCredentials;

  /// User-facing copy: "Custom fields".
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get entryCustomFields;

  /// User-facing copy: "Add extra text, hidden, or URL fields to this entry.".
  ///
  /// In en, this message translates to:
  /// **'Add extra text, hidden, or URL fields to this entry.'**
  String get entryCustomFieldsHint;

  /// User-facing copy: "Decrypted note:".
  ///
  /// In en, this message translates to:
  /// **'Decrypted note:'**
  String get entryDecryptedNote;

  /// User-facing copy: "This item will be moved to the trash.".
  ///
  /// In en, this message translates to:
  /// **'This item will be moved to the trash.'**
  String get entryDeleteBody;

  /// User-facing copy: "Delete entry".
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get entryDeleteEntry;

  /// User-facing copy: "Delete {title}?".
  ///
  /// In en, this message translates to:
  /// **'Delete {title}?'**
  String entryDeleteTitle(String title);

  /// User-facing copy: "Your edits to this entry will be lost.".
  ///
  /// In en, this message translates to:
  /// **'Your edits to this entry will be lost.'**
  String get entryDiscardBody;

  /// User-facing copy: "Discard".
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get entryDiscardConfirm;

  /// User-facing copy: "Discard changes?".
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get entryDiscardTitle;

  /// User-facing copy: "Discoverable".
  ///
  /// In en, this message translates to:
  /// **'Discoverable'**
  String get entryDiscoverable;

  /// User-facing copy: "Edit card".
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get entryEditCard;

  /// User-facing copy: "Edit entry".
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get entryEditEntry;

  /// User-facing copy: "Edit login".
  ///
  /// In en, this message translates to:
  /// **'Edit login'**
  String get entryEditLogin;

  /// User-facing copy: "Edit note".
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get entryEditNote;

  /// User-facing copy: "Edit passkey".
  ///
  /// In en, this message translates to:
  /// **'Edit passkey'**
  String get entryEditPasskey;

  /// User-facing copy: "Edit {kind}".
  ///
  /// In en, this message translates to:
  /// **'Edit {kind}'**
  String entryEditTitle(String kind);

  /// User-facing copy: "Encrypted content".
  ///
  /// In en, this message translates to:
  /// **'Encrypted content'**
  String get entryEncryptedContent;

  /// User-facing copy: "Secrets stay encrypted with Argon2id & ChaCha20-Poly1305.".
  ///
  /// In en, this message translates to:
  /// **'Secrets stay encrypted with Argon2id & ChaCha20-Poly1305.'**
  String get entryEncryptedHint;

  /// User-facing copy: "Encrypted & Protected".
  ///
  /// In en, this message translates to:
  /// **'Encrypted & Protected'**
  String get entryEncryptedProtected;

  /// User-facing copy: "Enter Manually".
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get entryEnterManually;

  /// User-facing copy: "Enter secure password".
  ///
  /// In en, this message translates to:
  /// **'Enter secure password'**
  String get entryEnterPassword;

  /// User-facing copy: "Expires".
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get entryExpires;

  /// User-facing copy: "Expiry".
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get entryExpiry;

  /// User-facing copy: "Favorite removed".
  ///
  /// In en, this message translates to:
  /// **'Favorite removed'**
  String get entryFavoriteRemoved;

  /// User-facing copy: "Field".
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get entryField;

  /// User-facing copy: "Field actions".
  ///
  /// In en, this message translates to:
  /// **'Field actions'**
  String get entryFieldActions;

  /// User-facing copy: "{label} copied{hint}".
  ///
  /// In en, this message translates to:
  /// **'{label} copied{hint}'**
  String entryFieldCopied(String label, String hint);

  /// User-facing copy: "Label".
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get entryFieldLabel;

  /// User-facing copy: "Hidden field".
  ///
  /// In en, this message translates to:
  /// **'Hidden field'**
  String get entryFieldTypeHidden;

  /// User-facing copy: "Hidden".
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get entryFieldTypeHiddenShort;

  /// User-facing copy: "Text field".
  ///
  /// In en, this message translates to:
  /// **'Text field'**
  String get entryFieldTypeText;

  /// User-facing copy: "Text".
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get entryFieldTypeTextShort;

  /// User-facing copy: "URL field".
  ///
  /// In en, this message translates to:
  /// **'URL field'**
  String get entryFieldTypeUrl;

  /// User-facing copy: "URL".
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get entryFieldTypeUrlShort;

  /// User-facing copy: "Folder".
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get entryFolder;

  /// User-facing copy: "Generate password".
  ///
  /// In en, this message translates to:
  /// **'Generate password'**
  String get entryGeneratePasswordTooltip;

  /// User-facing copy: "Generate secure password".
  ///
  /// In en, this message translates to:
  /// **'Generate secure password'**
  String get entryGenerateSecurePassword;

  /// User-facing copy: "Go back".
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get entryGoBack;

  /// User-facing copy: "Existing hidden value will be kept unless you enter a new one.".
  ///
  /// In en, this message translates to:
  /// **'Existing hidden value will be kept unless you enter a new one.'**
  String get entryHiddenValueKept;

  /// User-facing copy: "Hide content".
  ///
  /// In en, this message translates to:
  /// **'Hide content'**
  String get entryHideContent;

  /// User-facing copy: "Hide number".
  ///
  /// In en, this message translates to:
  /// **'Hide number'**
  String get entryHideNumber;

  /// User-facing copy: "Hide password".
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get entryHidePassword;

  /// User-facing copy: "Hide value".
  ///
  /// In en, this message translates to:
  /// **'Hide value'**
  String get entryHideValue;

  /// User-facing copy: "History".
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get entryHistory;

  /// User-facing copy: "All".
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get entryIconCategoryAll;

  /// User-facing copy: "Brands".
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get entryIconCategoryBrands;

  /// User-facing copy: "Crypto".
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get entryIconCategoryCrypto;

  /// User-facing copy: "Finance".
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get entryIconCategoryFinance;

  /// User-facing copy: "Life & Utilities".
  ///
  /// In en, this message translates to:
  /// **'Life & Utilities'**
  String get entryIconCategoryLife;

  /// User-facing copy: "Media".
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get entryIconCategoryMedia;

  /// User-facing copy: "Security".
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get entryIconCategorySecurity;

  /// User-facing copy: "Social".
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get entryIconCategorySocial;

  /// User-facing copy: "Tech & Dev".
  ///
  /// In en, this message translates to:
  /// **'Tech & Dev'**
  String get entryIconCategoryTech;

  /// User-facing copy: "Work".
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get entryIconCategoryWork;

  /// User-facing copy: "Search icons (e.g. GitHub, Bank, Mail)...".
  ///
  /// In en, this message translates to:
  /// **'Search icons (e.g. GitHub, Bank, Mail)...'**
  String get entryIconSearchHint;

  /// User-facing copy: "That key or link is not a valid TOTP secret.".
  ///
  /// In en, this message translates to:
  /// **'That key or link is not a valid TOTP secret.'**
  String get entryInvalidTotpSecret;

  /// User-facing copy: "Invalid website address".
  ///
  /// In en, this message translates to:
  /// **'Invalid website address'**
  String get entryInvalidWebsite;

  /// User-facing copy: "Item not found".
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get entryItemNotFound;

  /// User-facing copy: "Card".
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get entryKindCard;

  /// User-facing copy: "Login".
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get entryKindLogin;

  /// User-facing copy: "Note".
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get entryKindNote;

  /// User-facing copy: "Passkey".
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get entryKindPasskey;

  /// User-facing copy: "Loading entry…".
  ///
  /// In en, this message translates to:
  /// **'Loading entry…'**
  String get entryLoading;

  /// User-facing copy: "Loading code…".
  ///
  /// In en, this message translates to:
  /// **'Loading code…'**
  String get entryLoadingCode;

  /// User-facing copy: "Master credentials".
  ///
  /// In en, this message translates to:
  /// **'Master credentials'**
  String get entryMasterCredentials;

  /// User-facing copy: "No entry with ID "{entryId}" exists.".
  ///
  /// In en, this message translates to:
  /// **'No entry with ID \"{entryId}\" exists.'**
  String entryMissingMessage(String entryId);

  /// User-facing copy: "Move down".
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get entryMoveDown;

  /// User-facing copy: "Move up".
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get entryMoveUp;

  /// User-facing copy: "{title} moved to trash".
  ///
  /// In en, this message translates to:
  /// **'{title} moved to trash'**
  String entryMovedToTrash(String title);

  /// User-facing copy: "New {kind}".
  ///
  /// In en, this message translates to:
  /// **'New {kind}'**
  String entryNewTitle(String kind);

  /// User-facing copy: "No".
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get entryNo;

  /// User-facing copy: "No folder".
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get entryNoFolder;

  /// User-facing copy: "No matching icons".
  ///
  /// In en, this message translates to:
  /// **'No matching icons'**
  String get entryNoMatchingIcons;

  /// User-facing copy: "Note copied".
  ///
  /// In en, this message translates to:
  /// **'Note copied'**
  String get entryNoteCopied;

  /// User-facing copy: "Notes".
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get entryNotes;

  /// User-facing copy: "Recovery questions, PIN codes, backup seeds...".
  ///
  /// In en, this message translates to:
  /// **'Recovery questions, PIN codes, backup seeds...'**
  String get entryNotesHint;

  /// User-facing copy: "Nothing to copy".
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy'**
  String get entryNothingToCopy;

  /// User-facing copy: "Open URL".
  ///
  /// In en, this message translates to:
  /// **'Open URL'**
  String get entryOpenUrl;

  /// User-facing copy: "Open website".
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get entryOpenWebsite;

  /// User-facing copy: "Passkeys are created and used through secure sign-in prompts. Credential details are managed automatically and can't be edited here yet.".
  ///
  /// In en, this message translates to:
  /// **'Passkeys are created and used through secure sign-in prompts. Credential details are managed automatically and can\'t be edited here yet.'**
  String get entryPasskeyInfo;

  /// User-facing copy: "User".
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get entryPasskeyUser;

  /// User-facing copy: "Password copied{hint}".
  ///
  /// In en, this message translates to:
  /// **'Password copied{hint}'**
  String entryPasswordCopied(String hint);

  /// User-facing copy: "Could not generate a password right now.".
  ///
  /// In en, this message translates to:
  /// **'Could not generate a password right now.'**
  String get entryPasswordGenerationFailed;

  /// User-facing copy: "{label} password ({count} chars)".
  ///
  /// In en, this message translates to:
  /// **'{label} password ({count} chars)'**
  String entryPasswordHealth(String label, num count);

  /// User-facing copy: "Password history arrives with encrypted storage.".
  ///
  /// In en, this message translates to:
  /// **'Password history arrives with encrypted storage.'**
  String get entryPasswordHistorySoon;

  /// User-facing copy: "Score: {score}%".
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String entryPasswordScore(num score);

  /// User-facing copy: "Pin this entry to quick access".
  ///
  /// In en, this message translates to:
  /// **'Pin this entry to quick access'**
  String get entryPinToQuickAccess;

  /// User-facing copy: "{title} pinned to favorites".
  ///
  /// In en, this message translates to:
  /// **'{title} pinned to favorites'**
  String entryPinned(String title);

  /// User-facing copy: "Camera scanning arrives in a later update. Enter the key manually for now.".
  ///
  /// In en, this message translates to:
  /// **'Camera scanning arrives in a later update. Enter the key manually for now.'**
  String get entryQrScanUnavailable;

  /// User-facing copy: "Refreshes automatically".
  ///
  /// In en, this message translates to:
  /// **'Refreshes automatically'**
  String get entryRefreshesAutomatically;

  /// User-facing copy: "Relying party".
  ///
  /// In en, this message translates to:
  /// **'Relying party'**
  String get entryRelyingParty;

  /// User-facing copy: "Remove favorite".
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get entryRemoveFavorite;

  /// User-facing copy: "Replace Key".
  ///
  /// In en, this message translates to:
  /// **'Replace Key'**
  String get entryReplaceKey;

  /// User-facing copy: "Reveal note".
  ///
  /// In en, this message translates to:
  /// **'Reveal note'**
  String get entryRevealNote;

  /// User-facing copy: "Reveal number".
  ///
  /// In en, this message translates to:
  /// **'Reveal number'**
  String get entryRevealNumber;

  /// User-facing copy: "Reveal password".
  ///
  /// In en, this message translates to:
  /// **'Reveal password'**
  String get entryRevealPassword;

  /// User-facing copy: "Reveal value".
  ///
  /// In en, this message translates to:
  /// **'Reveal value'**
  String get entryRevealValue;

  /// User-facing copy: "Save entry".
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get entrySaveEntry;

  /// User-facing copy: "Saved securely (leave blank to keep)".
  ///
  /// In en, this message translates to:
  /// **'Saved securely (leave blank to keep)'**
  String get entrySavedSecurelyHint;

  /// User-facing copy: "Scan QR Code".
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get entryScanQrCode;

  /// User-facing copy: "{seconds}s".
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String entrySecondsRemaining(num seconds);

  /// User-facing copy: "Secure note".
  ///
  /// In en, this message translates to:
  /// **'Secure note'**
  String get entrySecureNote;

  /// User-facing copy: "Secure note content".
  ///
  /// In en, this message translates to:
  /// **'Secure note content'**
  String get entrySecureNoteContent;

  /// User-facing copy: "Secure notes".
  ///
  /// In en, this message translates to:
  /// **'Secure notes'**
  String get entrySecureNotes;

  /// User-facing copy: "Security code (CVV)".
  ///
  /// In en, this message translates to:
  /// **'Security code (CVV)'**
  String get entrySecurityCodeCvv;

  /// User-facing copy: "Setup key or link".
  ///
  /// In en, this message translates to:
  /// **'Setup key or link'**
  String get entrySetupKeyOrLink;

  /// User-facing copy: "Sheet".
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get entrySheetBarrier;

  /// User-facing copy: "Show password".
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get entryShowPassword;

  /// User-facing copy: "Sign count".
  ///
  /// In en, this message translates to:
  /// **'Sign count'**
  String get entrySignCount;

  /// User-facing copy: "Entropy: {entropyLabel}".
  ///
  /// In en, this message translates to:
  /// **'Entropy: {entropyLabel}'**
  String entryStrengthEntropy(String entropyLabel);

  /// User-facing copy: "{label} ({bits} bits) - {descriptor}".
  ///
  /// In en, this message translates to:
  /// **'{label} ({bits} bits) - {descriptor}'**
  String entryStrengthSummary(String label, num bits, String descriptor);

  /// User-facing copy: "Suggestion:".
  ///
  /// In en, this message translates to:
  /// **'Suggestion:'**
  String get entrySuggestion;

  /// User-facing copy: "Service or app name".
  ///
  /// In en, this message translates to:
  /// **'Service or app name'**
  String get entryTitleFieldHint;

  /// User-facing copy: "Title".
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get entryTitleFieldLabel;

  /// User-facing copy: "Give this entry a title first.".
  ///
  /// In en, this message translates to:
  /// **'Give this entry a title first.'**
  String get entryTitleRequired;

  /// User-facing copy: "A rotating code is stored for this entry. Enter a new key to replace it.".
  ///
  /// In en, this message translates to:
  /// **'A rotating code is stored for this entry. Enter a new key to replace it.'**
  String get entryTotpConfiguredHint;

  /// User-facing copy: "Generate integrated 30-second rotating security codes directly inside Keyel.".
  ///
  /// In en, this message translates to:
  /// **'Generate integrated 30-second rotating security codes directly inside Keyel.'**
  String get entryTotpHint;

  /// User-facing copy: "Enter the setup key from your provider.".
  ///
  /// In en, this message translates to:
  /// **'Enter the setup key from your provider.'**
  String get entryTotpKeyRequired;

  /// User-facing copy: "Two-factor key ready. Save the entry to store it.".
  ///
  /// In en, this message translates to:
  /// **'Two-factor key ready. Save the entry to store it.'**
  String get entryTotpReady;

  /// User-facing copy: "Paste the setup key (base32) or the otpauth:// link from your provider.".
  ///
  /// In en, this message translates to:
  /// **'Paste the setup key (base32) or the otpauth:// link from your provider.'**
  String get entryTotpSetupBody;

  /// User-facing copy: "Set up two-factor".
  ///
  /// In en, this message translates to:
  /// **'Set up two-factor'**
  String get entryTotpSetupTitle;

  /// User-facing copy: "Transports".
  ///
  /// In en, this message translates to:
  /// **'Transports'**
  String get entryTransports;

  /// User-facing copy: "Two-factor authentication".
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get entryTwoFactorAuth;

  /// User-facing copy: "Two-factor code".
  ///
  /// In en, this message translates to:
  /// **'Two-factor code'**
  String get entryTwoFactorCode;

  /// User-facing copy: "Entry updated.".
  ///
  /// In en, this message translates to:
  /// **'Entry updated.'**
  String get entryUpdated;

  /// User-facing copy: "Use suggested email".
  ///
  /// In en, this message translates to:
  /// **'Use suggested email'**
  String get entryUseSuggestedEmail;

  /// User-facing copy: "Username copied to clipboard".
  ///
  /// In en, this message translates to:
  /// **'Username copied to clipboard'**
  String get entryUsernameCopied;

  /// User-facing copy: "Username or email".
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get entryUsernameOrEmail;

  /// User-facing copy: "Value".
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get entryValue;

  /// User-facing copy: "{label} copied".
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String entryValueCopied(String label);

  /// User-facing copy: "Value (secret)".
  ///
  /// In en, this message translates to:
  /// **'Value (secret)'**
  String get entryValueSecret;

  /// User-facing copy: "Web Vault Matcher".
  ///
  /// In en, this message translates to:
  /// **'Web Vault Matcher'**
  String get entryWebVaultMatcher;

  /// User-facing copy: "Could not open website".
  ///
  /// In en, this message translates to:
  /// **'Could not open website'**
  String get entryWebsiteOpenFailed;

  /// User-facing copy: "Website URL".
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get entryWebsiteUrl;

  /// User-facing copy: "Website URL copied to clipboard".
  ///
  /// In en, this message translates to:
  /// **'Website URL copied to clipboard'**
  String get entryWebsiteUrlCopied;

  /// User-facing copy: "Yes".
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get entryYes;

  /// Busy label of the new folder button in the picker.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get fldCreating;

  /// Confirmation dialog body explaining what happens to entries.
  ///
  /// In en, this message translates to:
  /// **'Entries in this folder are kept and move to \"No folder\".'**
  String get fldDeleteConfirmBody;

  /// Confirmation dialog title for deleting a folder.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String fldDeleteConfirmTitle(String name);

  /// Confirm label and tile tooltip for deleting a folder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get fldDeleteFolder;

  /// Snackbar after a folder is deleted.
  ///
  /// In en, this message translates to:
  /// **'Folder deleted'**
  String get fldDeleted;

  /// Empty state body on the folders screen.
  ///
  /// In en, this message translates to:
  /// **'Folders keep logins, cards and notes in tidy groups. Use the button below to create the first one.'**
  String get fldEmptyMessage;

  /// Text field label in the folder name dialog.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get fldFolderNameLabel;

  /// Loading state message on the folders screen.
  ///
  /// In en, this message translates to:
  /// **'Loading folders…'**
  String get fldLoading;

  /// Title of the folder picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get fldMoveToFolder;

  /// New folder action label and dialog title.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get fldNewFolder;

  /// Picker option for an unfiled entry.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get fldNoFolder;

  /// Rename folder action label and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get fldRenameFolder;

  /// Example subtitle for capitalized passphrases.
  ///
  /// In en, this message translates to:
  /// **'e.g., Apple-Tree-House'**
  String get genCapitalizeExample;

  /// Title of the capitalize switch.
  ///
  /// In en, this message translates to:
  /// **'Capitalize first letter'**
  String get genCapitalizeFirst;

  /// Snackbar when the user tries to disable every character type.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one character type switched on.'**
  String get genCharacterTypeError;

  /// Section label above character type switches.
  ///
  /// In en, this message translates to:
  /// **'Character types'**
  String get genCharacterTypes;

  /// Abbreviated password length slider track labels.
  ///
  /// In en, this message translates to:
  /// **'{count} chars'**
  String genCharsShort(num count);

  /// Snackbar after copying a generated secret; clearHint is the clipboard wipe suffix.
  ///
  /// In en, this message translates to:
  /// **'{mode} copied to clipboard{clearHint}'**
  String genCopied(String mode, String clearHint);

  /// Copy button label including the current mode name.
  ///
  /// In en, this message translates to:
  /// **'Copy {mode}'**
  String genCopyMode(String mode);

  /// Fallback placeholder shown when generation fails.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get genError;

  /// Title of the ambiguous-character switch.
  ///
  /// In en, this message translates to:
  /// **'Exclude ambiguous'**
  String get genExcludeAmbiguous;

  /// Subtitle explaining ambiguous character exclusion.
  ///
  /// In en, this message translates to:
  /// **'Avoids 0, O, 1, l and I confusion'**
  String get genExcludeAmbiguousSubtitle;

  /// Badge on the generated secret card.
  ///
  /// In en, this message translates to:
  /// **'Generated locally on device'**
  String get genGeneratedLocally;

  /// Snackbar shown from the generation history icon.
  ///
  /// In en, this message translates to:
  /// **'Generation history arrives with encrypted storage.'**
  String get genHistoryMessage;

  /// Title of the include-number switch.
  ///
  /// In en, this message translates to:
  /// **'Include a number'**
  String get genIncludeNumber;

  /// Subtitle of the include-number switch.
  ///
  /// In en, this message translates to:
  /// **'Adds two random digits at the end'**
  String get genIncludeNumberSubtitle;

  /// Password length value label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} character} other{{count} characters}}'**
  String genLengthValue(num count);

  /// Title of the lowercase letters switch.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters'**
  String get genLowercase;

  /// Title of the numbers switch.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get genNumbers;

  /// Generator mode label for word-based passphrases.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get genPassphrase;

  /// Snackbar shown when passphrase generation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not generate passphrase.'**
  String get genPassphraseError;

  /// Section label above passphrase switches.
  ///
  /// In en, this message translates to:
  /// **'Passphrase options'**
  String get genPassphraseOptions;

  /// Informational tip about passphrase length.
  ///
  /// In en, this message translates to:
  /// **'Passphrases trade symbols for memorable words. Use at least eight words for a vault master passphrase.'**
  String get genPassphraseTip;

  /// Generator mode label for character passwords.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get genPassword;

  /// Snackbar shown when password generation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not generate password. Check constraints.'**
  String get genPasswordError;

  /// Title of the password length slider card.
  ///
  /// In en, this message translates to:
  /// **'Password length'**
  String get genPasswordLength;

  /// Subtitle of the password length slider card.
  ///
  /// In en, this message translates to:
  /// **'Recommended 16+ characters'**
  String get genPasswordLengthSubtitle;

  /// Tooltip of the regenerate button.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get genRegenerate;

  /// Label for the space separator option.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get genSeparatorSpace;

  /// Title of the symbols switch.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get genSymbols;

  /// Title of the uppercase letters switch.
  ///
  /// In en, this message translates to:
  /// **'Uppercase letters'**
  String get genUppercase;

  /// Primary button label in passphrase mode.
  ///
  /// In en, this message translates to:
  /// **'Use this passphrase'**
  String get genUsePassphrase;

  /// Primary button label in password mode.
  ///
  /// In en, this message translates to:
  /// **'Use this password'**
  String get genUsePassword;

  /// Title of the passphrase word-count slider card.
  ///
  /// In en, this message translates to:
  /// **'Word count'**
  String get genWordCount;

  /// Subtitle of the word-count slider card.
  ///
  /// In en, this message translates to:
  /// **'Each word adds about 10 bits of entropy'**
  String get genWordCountSubtitle;

  /// Word count value label and slider track labels.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} word} other{{count} words}}'**
  String genWordCountValue(num count);

  /// Section label above separator options.
  ///
  /// In en, this message translates to:
  /// **'Word separator'**
  String get genWordSeparator;

  /// Import/export UI copy: added label.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get imexAddedLabel;

  /// Import/export UI copy: already present label.
  ///
  /// In en, this message translates to:
  /// **'Already present'**
  String get imexAlreadyPresentLabel;

  /// Import/export UI copy: backup created.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get imexBackupCreated;

  /// Import/export UI copy: backup hint.
  ///
  /// In en, this message translates to:
  /// **'The backup is a full, encrypted copy of your vault. Keep it somewhere safe.'**
  String get imexBackupHint;

  /// Import/export UI copy: backup password label.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get imexBackupPasswordLabel;

  /// Import/export UI copy: backup ready.
  ///
  /// In en, this message translates to:
  /// **'Your encrypted backup is ready to share.'**
  String get imexBackupReady;

  /// Import/export UI copy: cards label.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get imexCardsLabel;

  /// Import/export UI copy: confirm password label.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get imexConfirmPasswordLabel;

  /// Import/export UI copy: csv export body.
  ///
  /// In en, this message translates to:
  /// **'Every password in your vault will be written to a plain text file that anyone can read. Only do this if you know what you are doing.'**
  String get imexCsvExportBody;

  /// Import/export UI copy: csv export confirm.
  ///
  /// In en, this message translates to:
  /// **'Export unencrypted'**
  String get imexCsvExportConfirm;

  /// Import/export UI copy: csv export title.
  ///
  /// In en, this message translates to:
  /// **'Export unencrypted CSV?'**
  String get imexCsvExportTitle;

  /// Import/export UI copy: csv exported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported'**
  String get imexCsvExported;

  /// Import/export UI copy: csv import sheet title.
  ///
  /// In en, this message translates to:
  /// **'Import {format} CSV'**
  String imexCsvImportSheetTitle(String format);

  /// Import/export UI copy: csv import subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bitwarden or Chrome password exports'**
  String get imexCsvImportSubtitle;

  /// Import/export UI copy: csv merge hint.
  ///
  /// In en, this message translates to:
  /// **'Entries that look the same as ones you already have are skipped.'**
  String get imexCsvMergeHint;

  /// Import/export UI copy: csv ready.
  ///
  /// In en, this message translates to:
  /// **'Your unencrypted export is ready to share.'**
  String get imexCsvReady;

  /// Import/export UI copy: encrypt backup subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password for this backup file. It can be different from your master password and is never stored.'**
  String get imexEncryptBackupSubtitle;

  /// Import/export UI copy: encrypt backup title.
  ///
  /// In en, this message translates to:
  /// **'Encrypt backup'**
  String get imexEncryptBackupTitle;

  /// Import/export UI copy: encrypted backup section.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup'**
  String get imexEncryptedBackupSection;

  /// Import/export UI copy: export backup action.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get imexExportBackupAction;

  /// Import/export UI copy: export encrypted subtitle.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted copy of your vault'**
  String get imexExportEncryptedSubtitle;

  /// Import/export UI copy: export encrypted title.
  ///
  /// In en, this message translates to:
  /// **'Export encrypted backup'**
  String get imexExportEncryptedTitle;

  /// Import/export UI copy: export plain csv subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted — for moving to another app'**
  String get imexExportPlainCsvSubtitle;

  /// Import/export UI copy: export plain csv title.
  ///
  /// In en, this message translates to:
  /// **'Export as plain CSV'**
  String get imexExportPlainCsvTitle;

  /// Import/export UI copy: failed rows label.
  ///
  /// In en, this message translates to:
  /// **'Failed rows'**
  String get imexFailedRowsLabel;

  /// Import/export UI copy: failure list title.
  ///
  /// In en, this message translates to:
  /// **'Rows that could not be imported'**
  String get imexFailureListTitle;

  /// Import/export UI copy: folders created label.
  ///
  /// In en, this message translates to:
  /// **'Folders created'**
  String get imexFoldersCreatedLabel;

  /// Import/export UI copy: hide password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get imexHidePassword;

  /// Import/export UI copy: hub intro.
  ///
  /// In en, this message translates to:
  /// **'Move your vault in and out safely. Encrypted backups use their own password; CSV exports are plain text.'**
  String get imexHubIntro;

  /// Import/export UI copy: import complete.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get imexImportComplete;

  /// Import/export UI copy: import count.
  ///
  /// In en, this message translates to:
  /// **'Import {count, plural, =1{{count} entry} other{{count} entries}}'**
  String imexImportCount(num count);

  /// Import/export UI copy: import from csv title.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get imexImportFromCsvTitle;

  /// Import/export UI copy: logins label.
  ///
  /// In en, this message translates to:
  /// **'Logins'**
  String get imexLoginsLabel;

  /// Import/export UI copy: merge hint.
  ///
  /// In en, this message translates to:
  /// **'Entries already in your vault are kept.'**
  String get imexMergeHint;

  /// Import/export UI copy: merge subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add what is missing, keep the rest'**
  String get imexMergeSubtitle;

  /// Import/export UI copy: merge title.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get imexMergeTitle;

  /// Import/export UI copy: more failures.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String imexMoreFailures(num count);

  /// Import/export UI copy: passwords mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get imexPasswordsMismatch;

  /// Import/export UI copy: pick backup.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file to restore'**
  String get imexPickBackup;

  /// Import/export UI copy: pick csv.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV export to import'**
  String get imexPickCsv;

  /// Import/export UI copy: replace hint.
  ///
  /// In en, this message translates to:
  /// **'Everything currently in your vault is replaced.'**
  String get imexReplaceHint;

  /// Import/export UI copy: replace subtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the current vault and use only this file'**
  String get imexReplaceSubtitle;

  /// Import/export UI copy: replace title.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get imexReplaceTitle;

  /// Import/export UI copy: report subtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is what changed in your vault.'**
  String get imexReportSubtitle;

  /// Import/export UI copy: restore action.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get imexRestoreAction;

  /// Import/export UI copy: restore backup title.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get imexRestoreBackupTitle;

  /// Import/export UI copy: restore complete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get imexRestoreComplete;

  /// Import/export UI copy: restore from backup subtitle.
  ///
  /// In en, this message translates to:
  /// **'Merge or replace your vault from a backup'**
  String get imexRestoreFromBackupSubtitle;

  /// Import/export UI copy: restore from backup title.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get imexRestoreFromBackupTitle;

  /// Import/export UI copy: row failure.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {reason}'**
  String imexRowFailure(num row, String reason);

  /// Import/export UI copy: secure notes label.
  ///
  /// In en, this message translates to:
  /// **'Secure notes'**
  String get imexSecureNotesLabel;

  /// Import/export UI copy: show password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get imexShowPassword;

  /// Import/export UI copy: skipped rows label.
  ///
  /// In en, this message translates to:
  /// **'Skipped rows'**
  String get imexSkippedRowsLabel;

  /// Import/export UI copy: unencrypted warning.
  ///
  /// In en, this message translates to:
  /// **'This file is not encrypted. Delete it as soon as you are done.'**
  String get imexUnencryptedWarning;

  /// Import/export UI copy: vault saved.
  ///
  /// In en, this message translates to:
  /// **'Your vault has been saved.'**
  String get imexVaultSaved;

  /// Platform error on unsupported platforms.
  ///
  /// In en, this message translates to:
  /// **'Package installer is only supported on Android'**
  String get otaAndroidOnly;

  /// Subtitle of the automatic-check switch.
  ///
  /// In en, this message translates to:
  /// **'Checks on launch and when you return, on the selected channel.'**
  String get otaAutoCheckSubtitle;

  /// Title of the automatic-check switch.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get otaAutoCheckTitle;

  /// Subtitle naming the offered version and channel.
  ///
  /// In en, this message translates to:
  /// **'Keyel v{version} • {channel} channel'**
  String otaAvailableSubtitle(String version, String channel);

  /// Screen-reader label of the global update banner.
  ///
  /// In en, this message translates to:
  /// **'Update available: Keyel {version}. Open software update.'**
  String otaBannerSemantics(String version);

  /// Description of the beta release channel.
  ///
  /// In en, this message translates to:
  /// **'Pre-release previews with latest features'**
  String get otaChannelBetaDescription;

  /// Description of the stable release channel.
  ///
  /// In en, this message translates to:
  /// **'Official verified releases'**
  String get otaChannelStableDescription;

  /// Service error when the manifest request returns a non-200 status.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates: HTTP {status}'**
  String otaCheckFailedHttp(String status);

  /// Status banner title after a failed check.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get otaCheckFailedTitle;

  /// Primary action label in the idle state.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get otaCheckForUpdates;

  /// Primary action label while checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get otaChecking;

  /// Status banner title while checking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get otaCheckingUpdates;

  /// Service error when the downloaded APK hash differs.
  ///
  /// In en, this message translates to:
  /// **'Checksum mismatch: expected {expected} but got {computed}'**
  String otaChecksumMismatch(String expected, String computed);

  /// Provider error before installing an unverified update.
  ///
  /// In en, this message translates to:
  /// **'Update checksum could not be verified'**
  String get otaChecksumNotVerified;

  /// Status banner subtitle while checking.
  ///
  /// In en, this message translates to:
  /// **'Connecting to release server'**
  String get otaConnectingServer;

  /// Fallback error subtitle on the status banner.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to release server'**
  String get otaCouldNotConnect;

  /// Provider error when installing a local APK fails.
  ///
  /// In en, this message translates to:
  /// **'Could not install APK: {error}'**
  String otaCouldNotInstallApk(String error);

  /// Tooltip of the banner dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Dismiss update banner'**
  String get otaDismissBanner;

  /// Cancellation exception message for an aborted download.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled by user'**
  String get otaDownloadCancelled;

  /// Provider error when an update download fails.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String otaDownloadFailed(String error);

  /// Service error when the APK download returns a non-200 status.
  ///
  /// In en, this message translates to:
  /// **'Download failed with HTTP {status}'**
  String otaDownloadFailedHttp(String status);

  /// Primary action when an update is available.
  ///
  /// In en, this message translates to:
  /// **'Download v{version} ({size})'**
  String otaDownloadVersion(String version, String size);

  /// Status banner subtitle after verification.
  ///
  /// In en, this message translates to:
  /// **'Keyel v{version} downloaded & verified'**
  String otaDownloadedVerified(String version);

  /// Title of the download progress card.
  ///
  /// In en, this message translates to:
  /// **'Downloading APK'**
  String get otaDownloadingApk;

  /// Status banner subtitle with progress and size.
  ///
  /// In en, this message translates to:
  /// **'{percent}% • {size}'**
  String otaDownloadingDetail(String percent, String size);

  /// Status banner title while downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get otaDownloadingUpdate;

  /// Button requesting notification permission.
  ///
  /// In en, this message translates to:
  /// **'Enable update notifications'**
  String get otaEnableNotifications;

  /// Snack bar asking for install-unknown-apps permission.
  ///
  /// In en, this message translates to:
  /// **'Please grant permission to install unknown apps when prompted.'**
  String get otaGrantInstallPermission;

  /// Status banner subtitle while installing.
  ///
  /// In en, this message translates to:
  /// **'Handing off to system installer'**
  String get otaHandingToInstaller;

  /// Button installing a locally selected APK.
  ///
  /// In en, this message translates to:
  /// **'Install update from local APK file'**
  String get otaInstallLocal;

  /// Primary action once the update is verified.
  ///
  /// In en, this message translates to:
  /// **'Install Update Now'**
  String get otaInstallNow;

  /// Provider error when installation fails.
  ///
  /// In en, this message translates to:
  /// **'Installation error: {error}'**
  String otaInstallationError(String error);

  /// Idle status banner title.
  ///
  /// In en, this message translates to:
  /// **'Installed Version: {version}'**
  String otaInstalledVersion(String version);

  /// Platform error when the Android installer cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Package installer could not be opened'**
  String get otaInstallerUnavailable;

  /// Status banner title while installing.
  ///
  /// In en, this message translates to:
  /// **'Installing update...'**
  String get otaInstallingUpdate;

  /// Idle status banner subtitle with the last check time.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {time}'**
  String otaLastChecked(String time);

  /// Status banner subtitle when the latest release is installed.
  ///
  /// In en, this message translates to:
  /// **'Version {version} • Latest release installed'**
  String otaLatestInstalled(String version);

  /// Status banner subtitle on the beta channel with no new release.
  ///
  /// In en, this message translates to:
  /// **'No beta release yet • Version {version} installed'**
  String otaNoBetaRelease(String version);

  /// Fallback text in the release notes card.
  ///
  /// In en, this message translates to:
  /// **'No detailed release notes provided for this version.'**
  String get otaNoReleaseNotes;

  /// Label shown when update notifications are enabled.
  ///
  /// In en, this message translates to:
  /// **'Update notifications are on'**
  String get otaNotificationsOn;

  /// Percentage label for download progress.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String otaPercent(String percent);

  /// Title of the update preferences card.
  ///
  /// In en, this message translates to:
  /// **'Update Preferences'**
  String get otaPreferencesTitle;

  /// Privacy notice at the bottom of the OTA screen.
  ///
  /// In en, this message translates to:
  /// **'Privacy guarantee: automatic checks read the public channel manifest only, on launch and while the app is open. Your vault database, passwords, keys, and biometrics never leave this device.'**
  String get otaPrivacyNotice;

  /// Status banner title when the APK is verified.
  ///
  /// In en, this message translates to:
  /// **'Ready to Install'**
  String get otaReadyToInstall;

  /// Service error refusing an update without a checksum.
  ///
  /// In en, this message translates to:
  /// **'Refusing to download an update without a valid SHA-256 checksum'**
  String get otaRefuseUnverifiedDownload;

  /// Label of the release channel selector.
  ///
  /// In en, this message translates to:
  /// **'Release Channel'**
  String get otaReleaseChannel;

  /// Title of the local APK file picker.
  ///
  /// In en, this message translates to:
  /// **'Select Keyel Update APK'**
  String get otaSelectApkTitle;

  /// Idle status banner subtitle before the first check.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Check now\" to look for new releases'**
  String get otaTapCheckNow;

  /// Status banner title when already current.
  ///
  /// In en, this message translates to:
  /// **'Keyel is up to date'**
  String get otaUpToDate;

  /// Status banner and global banner title for an available update.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get otaUpdateAvailableTitle;

  /// Provider error when the downloaded file is missing.
  ///
  /// In en, this message translates to:
  /// **'Update file not found on device'**
  String get otaUpdateFileNotFound;

  /// Release notes card title.
  ///
  /// In en, this message translates to:
  /// **'What’s New in v{version}'**
  String otaWhatsNew(String version);

  /// Explanation below the passkey creation headline.
  ///
  /// In en, this message translates to:
  /// **'The passkey will be encrypted and stored in your local Keyel vault. Your private key never leaves this device.'**
  String get passCreateBody;

  /// Headline asking for passkey creation confirmation.
  ///
  /// In en, this message translates to:
  /// **'Create a passkey for this account?'**
  String get passCreateQuestion;

  /// Loading state message on the passkey selection screen.
  ///
  /// In en, this message translates to:
  /// **'Finding passkeys…'**
  String get passFindingPasskeys;

  /// Info row label for the account name.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get passLabelAccount;

  /// Info row label for the account display name.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get passLabelDisplayName;

  /// Info row label for the relying party id.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get passLabelDomain;

  /// Info row label for the relying party name.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get passLabelSite;

  /// Error when a passkey request has no relying party.
  ///
  /// In en, this message translates to:
  /// **'Missing relying party information for this request.'**
  String get passMissingRp;

  /// Empty state title on the passkey selection screen.
  ///
  /// In en, this message translates to:
  /// **'No passkeys available'**
  String get passNoMatches;

  /// Empty state body on the passkey selection screen.
  ///
  /// In en, this message translates to:
  /// **'No passkeys are saved for {rpId}.'**
  String passNoMatchesAvailable(String rpId);

  /// Error when no passkeys exist for a relying party.
  ///
  /// In en, this message translates to:
  /// **'No passkeys found for {rpId}.'**
  String passNoMatchesForRp(String rpId);

  /// Line showing the requesting origin.
  ///
  /// In en, this message translates to:
  /// **'Origin: {origin}'**
  String passOrigin(String origin);

  /// Title and primary button label on the passkey creation screen.
  ///
  /// In en, this message translates to:
  /// **'Save passkey'**
  String get passSavePasskey;

  /// Busy label of the save passkey button.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get passSaving;

  /// Headline naming the site to sign in to.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {rpId}'**
  String passSignInTo(String rpId);

  /// Fallback site name in the sign-in headline.
  ///
  /// In en, this message translates to:
  /// **'this site'**
  String get passThisSite;

  /// Fallback account name in passkey creation.
  ///
  /// In en, this message translates to:
  /// **'Unknown account'**
  String get passUnknownAccount;

  /// Fallback relying party name in passkey creation.
  ///
  /// In en, this message translates to:
  /// **'Unknown site'**
  String get passUnknownSite;

  /// Title of the passkey selection screen.
  ///
  /// In en, this message translates to:
  /// **'Use passkey'**
  String get passUsePasskey;

  /// Settings UI copy: allow screenshots body.
  ///
  /// In en, this message translates to:
  /// **'Anything on screen, including a revealed secret, could be captured or appear in your Recents preview. The lock and unlock screens stay protected.'**
  String get prefAllowScreenshotsBody;

  /// Settings UI copy: allow screenshots confirm.
  ///
  /// In en, this message translates to:
  /// **'Allow screenshots'**
  String get prefAllowScreenshotsConfirm;

  /// Settings UI copy: allow screenshots title.
  ///
  /// In en, this message translates to:
  /// **'Allow screenshots?'**
  String get prefAllowScreenshotsTitle;

  /// Settings UI copy: appearance changes instant.
  ///
  /// In en, this message translates to:
  /// **'Changes apply instantly across Keyel.'**
  String get prefAppearanceChangesInstant;

  /// Settings UI copy: appearance colors title.
  ///
  /// In en, this message translates to:
  /// **'Appearance & colors'**
  String get prefAppearanceColorsTitle;

  /// Settings UI copy: ask to save subtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer to save new credentials after a login'**
  String get prefAskToSaveSubtitle;

  /// Settings UI copy: ask to save title.
  ///
  /// In en, this message translates to:
  /// **'Ask to save'**
  String get prefAskToSaveTitle;

  /// Settings UI copy: auto lock after minutes.
  ///
  /// In en, this message translates to:
  /// **'After {count, plural, =1{{count} minute} other{{count} minutes}}'**
  String prefAutoLockAfterMinutes(num count);

  /// Settings UI copy: auto lock after seconds.
  ///
  /// In en, this message translates to:
  /// **'After {count} seconds'**
  String prefAutoLockAfterSeconds(num count);

  /// Title of the auto-lock delay selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock after'**
  String get prefAutoLockDialogTitle;

  /// Settings UI copy: auto lock immediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get prefAutoLockImmediately;

  /// Settings UI copy: auto lock subtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the vault after time in the background'**
  String get prefAutoLockSubtitle;

  /// Settings UI copy: autofill disabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable Keyel as your autofill provider'**
  String get prefAutofillDisabledSubtitle;

  /// Settings UI copy: autofill enabled subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keyel is your autofill provider'**
  String get prefAutofillEnabledSubtitle;

  /// Settings UI copy: autofill passkeys section.
  ///
  /// In en, this message translates to:
  /// **'Autofill & Passkeys'**
  String get prefAutofillPasskeysSection;

  /// Settings UI copy: autofill service title.
  ///
  /// In en, this message translates to:
  /// **'Autofill service'**
  String get prefAutofillServiceTitle;

  /// Settings UI copy: back to security.
  ///
  /// In en, this message translates to:
  /// **'Back to Security'**
  String get prefBackToSecurity;

  /// Settings UI copy: backup import subtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backups and CSV import or export'**
  String get prefBackupImportSubtitle;

  /// Settings UI copy: backup import title.
  ///
  /// In en, this message translates to:
  /// **'Backup & import'**
  String get prefBackupImportTitle;

  /// Settings UI copy: biometric disabled snack.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock disabled.'**
  String get prefBiometricDisabledSnack;

  /// Settings UI copy: biometric enabled snack.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock enabled'**
  String get prefBiometricEnabledSnack;

  /// Settings UI copy: biometric unlock subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face to open the vault'**
  String get prefBiometricUnlockSubtitle;

  /// Settings UI copy: biometric unlock title.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get prefBiometricUnlockTitle;

  /// Settings UI copy: biometric update error.
  ///
  /// In en, this message translates to:
  /// **'Could not update biometric settings: {error}'**
  String prefBiometricUpdateError(String error);

  /// Settings UI copy: biometrics unavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device.'**
  String get prefBiometricsUnavailable;

  /// Settings UI copy: bridge diagnostics subtitle.
  ///
  /// In en, this message translates to:
  /// **'Raw FRB bridge operations and diagnostics'**
  String get prefBridgeDiagnosticsSubtitle;

  /// Settings UI copy: bridge diagnostics title.
  ///
  /// In en, this message translates to:
  /// **'Bridge diagnostics & test suite'**
  String get prefBridgeDiagnosticsTitle;

  /// Settings UI copy: change master password row.
  ///
  /// In en, this message translates to:
  /// **'Change master password'**
  String get prefChangeMasterPasswordRow;

  /// Settings UI copy: change master subtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypt the vault keyslot with a new master'**
  String get prefChangeMasterSubtitle;

  /// Settings UI copy: change master title.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get prefChangeMasterTitle;

  /// Settings UI copy: change password action.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get prefChangePasswordAction;

  /// Settings UI copy: checking device support.
  ///
  /// In en, this message translates to:
  /// **'Checking device support…'**
  String get prefCheckingDeviceSupport;

  /// Settings UI copy: checking status.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get prefCheckingStatus;

  /// Explains that locking or leaving always clears immediately and that this timer applies only while Keyel stays open.
  ///
  /// In en, this message translates to:
  /// **'Locking the vault or leaving the app always clears it right away. This setting controls the timer while Keyel stays open.'**
  String get prefClipboardDialogBody;

  /// Title of the clipboard clear delay selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear clipboard after'**
  String get prefClipboardDialogTitle;

  /// Settings UI copy: clipboard minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} minute} other{{count} minutes}}'**
  String prefClipboardMinutes(num count);

  /// Settings UI copy: clipboard never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get prefClipboardNever;

  /// Settings UI copy: clipboard seconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String prefClipboardSeconds(num count);

  /// Settings UI copy: clipboard subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe copied secrets from the clipboard'**
  String get prefClipboardSubtitle;

  /// Settings UI copy: confirm master title.
  ///
  /// In en, this message translates to:
  /// **'Confirm master password'**
  String get prefConfirmMasterTitle;

  /// Settings UI copy: confirm new master password.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Master Password'**
  String get prefConfirmNewMasterPassword;

  /// Settings UI copy: copy password label.
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get prefCopyPasswordLabel;

  /// Settings UI copy: cross device sync subtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional E2EE sync through a folder you choose'**
  String get prefCrossDeviceSyncSubtitle;

  /// Settings UI copy: cross device sync title.
  ///
  /// In en, this message translates to:
  /// **'Cross-device sync'**
  String get prefCrossDeviceSyncTitle;

  /// Settings UI copy: current master password.
  ///
  /// In en, this message translates to:
  /// **'Current Master Password'**
  String get prefCurrentMasterPassword;

  /// Settings UI copy: device currently.
  ///
  /// In en, this message translates to:
  /// **'Device is currently {device}'**
  String prefDeviceCurrently(String device);

  /// Settings UI copy: device dark value.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get prefDeviceDarkValue;

  /// Settings UI copy: device light value.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get prefDeviceLightValue;

  /// Settings UI copy: diagnostics subject.
  ///
  /// In en, this message translates to:
  /// **'Keyel diagnostics ({version})'**
  String prefDiagnosticsSubject(String version);

  /// Settings UI copy: example login.
  ///
  /// In en, this message translates to:
  /// **'Example login'**
  String get prefExampleLogin;

  /// Settings UI copy: factory reset body.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your vault file and all stored credentials. This action cannot be undone.'**
  String get prefFactoryResetBody;

  /// Settings UI copy: factory reset confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get prefFactoryResetConfirm;

  /// Settings UI copy: factory reset error.
  ///
  /// In en, this message translates to:
  /// **'Factory reset failed: {error}'**
  String prefFactoryResetError(String error);

  /// Settings UI copy: factory reset snack.
  ///
  /// In en, this message translates to:
  /// **'Vault permanently deleted. Resetting...'**
  String get prefFactoryResetSnack;

  /// Settings UI copy: factory reset title.
  ///
  /// In en, this message translates to:
  /// **'Factory Reset?'**
  String get prefFactoryResetTitle;

  /// Settings UI copy: factory reset vault subtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete vault file and reset app state'**
  String get prefFactoryResetVaultSubtitle;

  /// Settings UI copy: factory reset vault title.
  ///
  /// In en, this message translates to:
  /// **'Factory reset vault'**
  String get prefFactoryResetVaultTitle;

  /// Settings UI copy: folders subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, rename and delete vault folders'**
  String get prefFoldersSubtitle;

  /// Settings UI copy: help auto lock body.
  ///
  /// In en, this message translates to:
  /// **'The vault locks itself after the delay set in Security. Copied secrets are wiped on lock and when you leave the app, even if the timed clipboard wipe is set to “Never”.'**
  String get prefHelpAutoLockBody;

  /// Settings UI copy: help auto lock title.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock and clipboard'**
  String get prefHelpAutoLockTitle;

  /// Settings UI copy: help keyboard body.
  ///
  /// In en, this message translates to:
  /// **'Ctrl/⌘ + F jumps to vault search. Ctrl/⌘ + N starts a new entry. On Android, Back asks before discarding unsaved edits.'**
  String get prefHelpKeyboardBody;

  /// Settings UI copy: help keyboard title.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get prefHelpKeyboardTitle;

  /// Settings UI copy: help recovery body.
  ///
  /// In en, this message translates to:
  /// **'Your one-time recovery key is the only way back in if you forget the master password. Store it offline; Keyel cannot reset it.'**
  String get prefHelpRecoveryBody;

  /// Settings UI copy: help recovery title.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get prefHelpRecoveryTitle;

  /// Settings UI copy: help sheet title.
  ///
  /// In en, this message translates to:
  /// **'Keyel help'**
  String get prefHelpSheetTitle;

  /// Settings UI copy: help support tooltip.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get prefHelpSupportTooltip;

  /// Settings UI copy: help vault local body.
  ///
  /// In en, this message translates to:
  /// **'Entries are encrypted on this device. Keyel has no account and sends nothing anywhere unless you explicitly turn on the opt-in breach check or sync.'**
  String get prefHelpVaultLocalBody;

  /// Settings UI copy: help vault local title.
  ///
  /// In en, this message translates to:
  /// **'Your vault stays local'**
  String get prefHelpVaultLocalTitle;

  /// Settings UI copy: incorrect password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get prefIncorrectPassword;

  /// Settings UI copy: live preview.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get prefLivePreview;

  /// Settings UI copy: local encrypted vault.
  ///
  /// In en, this message translates to:
  /// **'Local Encrypted Vault'**
  String get prefLocalEncryptedVault;

  /// Settings UI copy: lock vault now.
  ///
  /// In en, this message translates to:
  /// **'Lock vault now'**
  String get prefLockVaultNow;

  /// Settings UI copy: lock vault subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe decryption key from memory immediately'**
  String get prefLockVaultSubtitle;

  /// Settings UI copy: login badge.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get prefLoginBadge;

  /// Settings UI copy: master changed success.
  ///
  /// In en, this message translates to:
  /// **'Master password changed successfully'**
  String get prefMasterChangedSuccess;

  /// Settings UI copy: master password label.
  ///
  /// In en, this message translates to:
  /// **'Master password'**
  String get prefMasterPasswordLabel;

  /// Settings UI copy: match mode domain.
  ///
  /// In en, this message translates to:
  /// **'Domain (includes subdomains)'**
  String get prefMatchModeDomain;

  /// Settings UI copy: match mode exact.
  ///
  /// In en, this message translates to:
  /// **'Exact host only'**
  String get prefMatchModeExact;

  /// Settings UI copy: match mode title.
  ///
  /// In en, this message translates to:
  /// **'Match mode'**
  String get prefMatchModeTitle;

  /// Settings UI copy: new badge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get prefNewBadge;

  /// Settings UI copy: new master password.
  ///
  /// In en, this message translates to:
  /// **'New Master Password'**
  String get prefNewMasterPassword;

  /// Settings UI copy: new password empty.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be empty.'**
  String get prefNewPasswordEmpty;

  /// Settings UI copy: new passwords mismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get prefNewPasswordsMismatch;

  /// Settings UI copy: no vault badge.
  ///
  /// In en, this message translates to:
  /// **'No Vault'**
  String get prefNoVaultBadge;

  /// Settings UI copy: offline vault subtitle.
  ///
  /// In en, this message translates to:
  /// **'Zero telemetry, zero cloud synchronisation'**
  String get prefOfflineVaultSubtitle;

  /// Settings UI copy: offline vault title.
  ///
  /// In en, this message translates to:
  /// **'Offline vault mode'**
  String get prefOfflineVaultTitle;

  /// Settings UI copy: open source licenses subtitle.
  ///
  /// In en, this message translates to:
  /// **'Libraries bundled with this build'**
  String get prefOpenSourceLicensesSubtitle;

  /// Settings UI copy: open source licenses title.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get prefOpenSourceLicensesTitle;

  /// Settings UI copy: passkey provider title.
  ///
  /// In en, this message translates to:
  /// **'Passkey provider'**
  String get prefPasskeyProviderTitle;

  /// Settings UI copy: passkey supported subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Keyel as a passkey provider in system settings'**
  String get prefPasskeySupportedSubtitle;

  /// Settings UI copy: passkey unsupported subtitle.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device or Android version'**
  String get prefPasskeyUnsupportedSubtitle;

  /// Settings UI copy: password required.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get prefPasswordRequired;

  /// Settings UI copy: report problem error.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the report: {error}'**
  String prefReportProblemError(String error);

  /// Settings UI copy: report problem subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a redacted diagnostics file (no secrets)'**
  String get prefReportProblemSubtitle;

  /// Settings UI copy: screenshot off snack.
  ///
  /// In en, this message translates to:
  /// **'Screenshots allowed while unlocked'**
  String get prefScreenshotOffSnack;

  /// Settings UI copy: screenshot on snack.
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection on'**
  String get prefScreenshotOnSnack;

  /// Settings UI copy: screenshot subtitle.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots and Recents previews while the vault is open. Lock screens stay protected either way.'**
  String get prefScreenshotSubtitle;

  /// Settings UI copy: security access section.
  ///
  /// In en, this message translates to:
  /// **'Security & Access'**
  String get prefSecurityAccessSection;

  /// Settings UI copy: security subtitle.
  ///
  /// In en, this message translates to:
  /// **'Security tuned for this device, kept local.'**
  String get prefSecuritySubtitle;

  /// Settings UI copy: software update row title.
  ///
  /// In en, this message translates to:
  /// **'Software update'**
  String get prefSoftwareUpdateRowTitle;

  /// Settings UI copy: storage diagnostics section.
  ///
  /// In en, this message translates to:
  /// **'Storage & Diagnostics'**
  String get prefStorageDiagnosticsSection;

  /// Settings UI copy: storage not initialized.
  ///
  /// In en, this message translates to:
  /// **'Storage not initialized'**
  String get prefStorageNotInitialized;

  /// Settings UI copy: theme dark description.
  ///
  /// In en, this message translates to:
  /// **'Stays dark even when your device uses light mode.'**
  String get prefThemeDarkDescription;

  /// Settings UI copy: theme light description.
  ///
  /// In en, this message translates to:
  /// **'Stays light even when your device uses dark mode.'**
  String get prefThemeLightDescription;

  /// Settings UI copy: theme mode semantics.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get prefThemeModeSemantics;

  /// Settings UI copy: theme preview semantics.
  ///
  /// In en, this message translates to:
  /// **'Theme preview: {palette}, {mode} mode.'**
  String prefThemePreviewSemantics(String palette, String mode);

  /// Settings UI copy: theme semantic label.
  ///
  /// In en, this message translates to:
  /// **'{label} theme. {description}'**
  String prefThemeSemanticLabel(String label, String description);

  /// Settings UI copy: theme semantic with device.
  ///
  /// In en, this message translates to:
  /// **'{label} theme. {description} Device is currently {device}.'**
  String prefThemeSemanticWithDevice(
    String label,
    String description,
    String device,
  );

  /// Settings UI copy: theme system description.
  ///
  /// In en, this message translates to:
  /// **'Follows your device appearance and changes along with it.'**
  String get prefThemeSystemDescription;

  /// Settings UI copy: trash subtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore deleted entries or remove them forever'**
  String get prefTrashSubtitle;

  /// Settings UI copy: update available.
  ///
  /// In en, this message translates to:
  /// **'Update available (v{version})'**
  String prefUpdateAvailable(String version);

  /// Settings UI copy: vault locked badge.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get prefVaultLockedBadge;

  /// Settings UI copy: vault locked snack.
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get prefVaultLockedSnack;

  /// Settings UI copy: vault unlocked badge.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get prefVaultUnlockedBadge;

  /// Settings UI copy: verification failed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get prefVerificationFailed;

  /// Settings UI copy: version up to date.
  ///
  /// In en, this message translates to:
  /// **'Version {version} • Up to date'**
  String prefVersionUpToDate(String version);

  /// Settings UI copy: your vault.
  ///
  /// In en, this message translates to:
  /// **'Your vault'**
  String get prefYourVault;

  /// Action on missing-2FA tiles.
  ///
  /// In en, this message translates to:
  /// **'Add codes'**
  String get secAddCodes;

  /// Summary label when no issues remain.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get secAllClear;

  /// Detail of the all-clear card.
  ///
  /// In en, this message translates to:
  /// **'No weak, reused or old passwords, and every login has 2FA.'**
  String get secAllHealthyDetail;

  /// Insecure sites row detail when clean.
  ///
  /// In en, this message translates to:
  /// **'All sites use HTTPS'**
  String get secAllSitesHttps;

  /// Screen-reader description of the auto-lock seal.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock: {label}. Always active.'**
  String secAutoLockSemantics(String label);

  /// Breach-check status badge while running.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get secBadgeChecking;

  /// Tip about biometric unlocking.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric lock for instantaneous vault unmasking using your device secure enclave.'**
  String get secBiometricTip;

  /// Screen-reader description when breach checking is on.
  ///
  /// In en, this message translates to:
  /// **'Breach check: enabled. Nothing is sent until you tap Check now.'**
  String get secBreachActiveSemantics;

  /// Label of the breach-check posture seal and audit row.
  ///
  /// In en, this message translates to:
  /// **'Breach check'**
  String get secBreachCheck;

  /// Fallback error shown when the breach check failed.
  ///
  /// In en, this message translates to:
  /// **'Breach check failed.'**
  String get secBreachCheckFailed;

  /// Explanation shown while breach checking is off.
  ///
  /// In en, this message translates to:
  /// **'Optional: check saved passwords against known breaches. Nothing is sent unless you turn this on and tap Check now.'**
  String get secBreachDisabledNotice;

  /// Disclosure shown while breach checking is enabled.
  ///
  /// In en, this message translates to:
  /// **'Only the first 5 characters of a SHA-1 hash are sent over HTTPS when you tap Check now. Passwords and vault data never leave this device.'**
  String get secBreachEnabledNotice;

  /// Screen-reader description when breach checking is off.
  ///
  /// In en, this message translates to:
  /// **'Breach check: off. No password data is sent.'**
  String get secBreachInactiveSemantics;

  /// Button starting a breach check.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get secCheckNow;

  /// Summary of checked passwords and queried prefixes.
  ///
  /// In en, this message translates to:
  /// **'Checked {passwords} across {prefixes}.'**
  String secCheckedSummary(String passwords, String prefixes);

  /// Breach-check button label while running.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get secChecking;

  /// Screen-reader description of the timed clipboard wipe.
  ///
  /// In en, this message translates to:
  /// **'Clipboard wipe: {value} while the app is open. Locking always clears it.'**
  String secClipboardActiveSemantics(String value);

  /// Screen-reader description of the lock-only clipboard wipe.
  ///
  /// In en, this message translates to:
  /// **'Clipboard wipe: only on lock or when leaving the app.'**
  String get secClipboardInactiveSemantics;

  /// Label of the clipboard-wipe posture seal.
  ///
  /// In en, this message translates to:
  /// **'Clipboard wipe'**
  String get secClipboardWipe;

  /// Insecure sites row detail when issues exist.
  ///
  /// In en, this message translates to:
  /// **'Credentials sent in plain text'**
  String get secCredentialsPlainText;

  /// Label of the breach-check opt-in switch.
  ///
  /// In en, this message translates to:
  /// **'Enable breach check'**
  String get secEnableBreachCheck;

  /// Enabled value shared by posture seals.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get secEnabled;

  /// Breach-check status badge on failure.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get secError;

  /// Title of the all-clear card.
  ///
  /// In en, this message translates to:
  /// **'Everything looks healthy'**
  String get secEverythingHealthy;

  /// Exposure count inserted in a matched-entry row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} exposure} other{{count} exposures}}'**
  String secExposureCount(num count);

  /// One matched entry with its exposure count.
  ///
  /// In en, this message translates to:
  /// **'{title} · {exposures}'**
  String secExposures(String title, String exposures);

  /// Generic fix action on issue tiles and rows.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get secFix;

  /// Action on weak-password tiles.
  ///
  /// In en, this message translates to:
  /// **'Fix now'**
  String get secFixNow;

  /// Breach-check status badge with match count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} found} other{{count} found}}'**
  String secFoundCount(num count);

  /// Subtitle of the weak-password health category.
  ///
  /// In en, this message translates to:
  /// **'High compromise risk'**
  String get secHighCompromiseRisk;

  /// Title of the insecure sites audit row.
  ///
  /// In en, this message translates to:
  /// **'Insecure websites (HTTP)'**
  String get secInsecureSitesHttp;

  /// Title of the insecure-website health category.
  ///
  /// In en, this message translates to:
  /// **'Insecure websites'**
  String get secInsecureWebsites;

  /// Summary label with the total issue count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} issue} other{{count} issues}}'**
  String secIssuesCount(num count);

  /// Score card message with the number of affected items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item needs} other{{count} items need}} your attention'**
  String secIssuesNeedAttention(num count);

  /// Title of the missing-2FA health category.
  ///
  /// In en, this message translates to:
  /// **'Missing 2FA'**
  String get secMissingTwoFactor;

  /// Count of additional breach matches not shown.
  ///
  /// In en, this message translates to:
  /// **'+ {count, plural, =1{{count} more} other{{count} more}}'**
  String secMoreMatches(num count);

  /// Subtitle of the old-password health category.
  ///
  /// In en, this message translates to:
  /// **'More than 1 year old'**
  String get secMoreThanOneYearOld;

  /// Breach-check result when nothing was found.
  ///
  /// In en, this message translates to:
  /// **'No exposed passwords found.'**
  String get secNoExposedPasswords;

  /// Score card message when there are no issues.
  ///
  /// In en, this message translates to:
  /// **'No issues found. Your vault is in great shape.'**
  String get secNoIssuesFound;

  /// Empty state of the health issue sheet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to fix here.'**
  String get secNothingToFix;

  /// Disabled value shared by posture seals and badges.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get secOff;

  /// Title of the old-password health category.
  ///
  /// In en, this message translates to:
  /// **'Old passwords'**
  String get secOldPasswords;

  /// Clipboard-wipe value when no timer is set.
  ///
  /// In en, this message translates to:
  /// **'On lock only'**
  String get secOnLockOnly;

  /// Pluralized password count used in the check summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} password} other{{count} passwords}}'**
  String secPasswordCount(num count);

  /// Pluralized prefix count used in the check summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} prefix} other{{count} prefixes}}'**
  String secPrefixCount(num count);

  /// Breach-check status badge before a check.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get secReady;

  /// Title of the reused-password health category.
  ///
  /// In en, this message translates to:
  /// **'Reused passwords'**
  String get secReusedPasswords;

  /// Action on reused-password tiles.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get secReview;

  /// Score card action opening the issue list.
  ///
  /// In en, this message translates to:
  /// **'Review issues'**
  String get secReviewIssues;

  /// Button opening the security settings.
  ///
  /// In en, this message translates to:
  /// **'Review settings'**
  String get secReviewSettings;

  /// Breach-check result header with match count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} saved password found in breaches:} other{{count} saved passwords found in breaches:}}'**
  String secSavedPasswordsFound(num count);

  /// Vault health label for a low score.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get secScoreAtRisk;

  /// Vault health label for the highest score range.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get secScoreExcellent;

  /// Vault health label for a medium score.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get secScoreFair;

  /// Vault health label for a high score.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get secScoreGood;

  /// Screen-reader description when screenshot blocking is on.
  ///
  /// In en, this message translates to:
  /// **'Screenshot blocking: enabled while the vault is unlocked. Lock screens are always protected.'**
  String get secScreenshotActiveSemantics;

  /// Label of the screenshot-blocking posture seal.
  ///
  /// In en, this message translates to:
  /// **'Screenshot blocking'**
  String get secScreenshotBlocking;

  /// Screen-reader description when screenshot blocking is off.
  ///
  /// In en, this message translates to:
  /// **'Screenshot blocking: off. Lock and unlock screens are still protected.'**
  String get secScreenshotInactiveSemantics;

  /// Body of the breach-check opt-in disclosure dialog.
  ///
  /// In en, this message translates to:
  /// **'Keyel computes a SHA-1 hash of each saved password on this device and sends only the first 5 characters to Have I Been Pwned over HTTPS. Your passwords, usernames and vault are never sent. Checks run only when you tap Check now, and you can turn this off anytime.'**
  String get secSendHashDialogBody;

  /// Title of the breach-check opt-in disclosure dialog.
  ///
  /// In en, this message translates to:
  /// **'Send hash prefixes to HIBP?'**
  String get secSendHashDialogTitle;

  /// Subtitle of the insecure-website health category.
  ///
  /// In en, this message translates to:
  /// **'Sent over plain HTTP'**
  String get secSentOverPlainHttp;

  /// Subtitle of the reused-password health category.
  ///
  /// In en, this message translates to:
  /// **'Shared across services'**
  String get secSharedAcrossServices;

  /// Uppercase status word for a low score.
  ///
  /// In en, this message translates to:
  /// **'AT RISK'**
  String get secStatusAtRisk;

  /// Uppercase status word for a medium score.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get secStatusReview;

  /// Uppercase status word on the score gauge.
  ///
  /// In en, this message translates to:
  /// **'SECURE'**
  String get secStatusSecure;

  /// Subtitle of the missing-2FA health category.
  ///
  /// In en, this message translates to:
  /// **'TOTP supported'**
  String get secTotpSupported;

  /// Button turning breach checking off.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get secTurnOff;

  /// Confirmation button of the breach-check disclosure dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get secTurnOn;

  /// Hint shown when breach checking needs an unlocked vault.
  ///
  /// In en, this message translates to:
  /// **'Unlock the vault to check.'**
  String get secUnlockToCheck;

  /// Action on old-password tiles.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get secUpdate;

  /// Vault health label row under the score gauge.
  ///
  /// In en, this message translates to:
  /// **'Vault health: {label}'**
  String secVaultHealthLabel(String label);

  /// Confirmation after locking the vault.
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get secVaultLocked;

  /// Title of the security-posture card.
  ///
  /// In en, this message translates to:
  /// **'Vault posture'**
  String get secVaultPosture;

  /// Screen-reader summary of active protections.
  ///
  /// In en, this message translates to:
  /// **'Vault posture: {active} of {total} protections active.'**
  String secVaultPostureSemantics(String active, String total);

  /// Subtitle of the security-posture card.
  ///
  /// In en, this message translates to:
  /// **'How Keyel protects this vault right now'**
  String get secVaultPostureSubtitle;

  /// Header of the vulnerability audit section.
  ///
  /// In en, this message translates to:
  /// **'Vulnerability audit'**
  String get secVulnerabilityAudit;

  /// Header of the vulnerability summary section.
  ///
  /// In en, this message translates to:
  /// **'Vulnerability summary'**
  String get secVulnerabilitySummary;

  /// Title of the weak-password health category.
  ///
  /// In en, this message translates to:
  /// **'Weak passwords'**
  String get secWeakPasswords;

  /// Sync UI copy: actions label.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get synActionsLabel;

  /// Sync UI copy: choose folder.
  ///
  /// In en, this message translates to:
  /// **'Choose a sync folder'**
  String get synChooseFolder;

  /// Sync UI copy: choose folder first.
  ///
  /// In en, this message translates to:
  /// **'Choose a sync folder first.'**
  String get synChooseFolderFirst;

  /// Sync UI copy: code copied.
  ///
  /// In en, this message translates to:
  /// **'Pairing code copied{hint}'**
  String synCodeCopied(String hint);

  /// Confirmation checkbox required before closing the pairing-code dialog.
  ///
  /// In en, this message translates to:
  /// **'I stored this code somewhere safe'**
  String get synCodeStoredCheckbox;

  /// Sync UI copy: complete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete: {added} added, {updated} updated{conflicts}.'**
  String synComplete(num added, num updated, String conflicts);

  /// Sync UI copy: conflict copies.
  ///
  /// In en, this message translates to:
  /// **', {count, plural, =1{{count} conflict copy} other{{count} conflict copies}}'**
  String synConflictCopies(num count);

  /// Sync UI copy: create group subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder and get a one-time pairing code.'**
  String get synCreateGroupSubtitle;

  /// Sync UI copy: create group title.
  ///
  /// In en, this message translates to:
  /// **'Create a sync group'**
  String get synCreateGroupTitle;

  /// Sync UI copy: disable body.
  ///
  /// In en, this message translates to:
  /// **'Local sync stops. Remote files are left untouched and can be restored by joining again with the pairing code.'**
  String get synDisableBody;

  /// Sync UI copy: disable confirm.
  ///
  /// In en, this message translates to:
  /// **'Disable sync'**
  String get synDisableConfirm;

  /// Sync UI copy: disable subtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop syncing on this device; keep remote files.'**
  String get synDisableSubtitle;

  /// Sync UI copy: disable title.
  ///
  /// In en, this message translates to:
  /// **'Disable sync?'**
  String get synDisableTitle;

  /// Sync UI copy: disabled.
  ///
  /// In en, this message translates to:
  /// **'Sync disabled on this device.'**
  String get synDisabled;

  /// Sync UI copy: enabled share code.
  ///
  /// In en, this message translates to:
  /// **'Sync enabled. Share the code with your other device only once.'**
  String get synEnabledShareCode;

  /// Sync UI copy: enabled status.
  ///
  /// In en, this message translates to:
  /// **'Sync enabled'**
  String get synEnabledStatus;

  /// Sync UI copy: enter code first.
  ///
  /// In en, this message translates to:
  /// **'Enter the pairing code first.'**
  String get synEnterCodeFirst;

  /// Sync UI copy: folder label.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get synFolderLabel;

  /// Sync UI copy: footer note.
  ///
  /// In en, this message translates to:
  /// **'Sync is foreground-only and requires an unlocked vault. Data is encrypted with a random key that never leaves Keyel; losing the pairing code means starting a new sync group. Keep an encrypted backup as well.'**
  String get synFooterNote;

  /// Sync UI copy: get started label.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get synGetStartedLabel;

  /// Sync UI copy: headline.
  ///
  /// In en, this message translates to:
  /// **'Sync across your devices'**
  String get synHeadline;

  /// Sync UI copy: join body.
  ///
  /// In en, this message translates to:
  /// **'Remote vault data will be merged with this vault on the next manual sync. Conflicting items become separate copies; nothing is silently overwritten or deleted.'**
  String get synJoinBody;

  /// Sync UI copy: join group.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get synJoinGroup;

  /// Sync UI copy: join title.
  ///
  /// In en, this message translates to:
  /// **'Join this sync group?'**
  String get synJoinTitle;

  /// Sync UI copy: joined.
  ///
  /// In en, this message translates to:
  /// **'Joined the sync group.'**
  String get synJoined;

  /// Sync UI copy: last sync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String synLastSync(String date);

  /// Sync UI copy: loading status.
  ///
  /// In en, this message translates to:
  /// **'Reading sync state…'**
  String get synLoadingStatus;

  /// Sync UI copy: local only status.
  ///
  /// In en, this message translates to:
  /// **'Your vault stays on this device only.'**
  String get synLocalOnlyStatus;

  /// Sync UI copy: never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get synNever;

  /// Sync UI copy: no folder.
  ///
  /// In en, this message translates to:
  /// **'Sync has no folder set. Disable and enable it again.'**
  String get synNoFolder;

  /// Sync UI copy: not set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get synNotSet;

  /// Sync UI copy: off status.
  ///
  /// In en, this message translates to:
  /// **'Sync is off'**
  String get synOffStatus;

  /// Sync UI copy: or join.
  ///
  /// In en, this message translates to:
  /// **'Or join an existing group'**
  String get synOrJoin;

  /// Sync UI copy: pairing code label.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get synPairingCodeLabel;

  /// Explains that the pairing code is a bearer secret and will not be shown again.
  ///
  /// In en, this message translates to:
  /// **'This code is a bearer secret: anyone who has it can read the synced vault. Store it offline and enter it on your other device once. It will not be shown again after this dialog.'**
  String get synSaveCodeBody;

  /// Title of the one-time pairing-code dialog.
  ///
  /// In en, this message translates to:
  /// **'Save this pairing code'**
  String get synSaveCodeTitle;

  /// Sync UI copy: show code subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair another device with this sync group.'**
  String get synShowCodeSubtitle;

  /// Sync UI copy: show code title.
  ///
  /// In en, this message translates to:
  /// **'Show pairing code'**
  String get synShowCodeTitle;

  /// Sync UI copy: status label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get synStatusLabel;

  /// Sync UI copy: subtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional, manual and end-to-end encrypted. Keyel never runs a sync server: your own sync tool moves the encrypted files between devices.'**
  String get synSubtitle;

  /// Sync UI copy: sync now subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull remote changes, merge and push this device.'**
  String get synSyncNowSubtitle;

  /// Sync UI copy: sync now title.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get synSyncNowTitle;

  /// Sync UI copy: this device.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get synThisDevice;

  /// Sync UI copy: unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get synUnknown;

  /// Label showing days until automatic deletion.
  ///
  /// In en, this message translates to:
  /// **'Auto-deletes in {count, plural, =1{{count} day} other{{count} days}}'**
  String trashAutoDelete(num count);

  /// Informational banner above the trash list.
  ///
  /// In en, this message translates to:
  /// **'Deleted items stay here for 30 days, then disappear automatically.'**
  String get trashBannerMessage;

  /// Confirm label and tile tooltip for permanent deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get trashDeleteForever;

  /// Confirmation dialog body for permanent deletion.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" cannot be recovered after this.'**
  String trashDeleteForeverBody(String title);

  /// Confirmation dialog title for permanent deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete forever?'**
  String get trashDeleteForeverTitle;

  /// Fallback label when an entry has no deletion date.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get trashDeleted;

  /// Snackbar after the trash is emptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptied;

  /// Confirm label and icon tooltip for emptying the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmptyAction;

  /// Confirmation dialog body naming the number of entries.
  ///
  /// In en, this message translates to:
  /// **'All {count, plural, =1{{count} trashed entry} other{{count} trashed entries}} will be deleted forever.'**
  String trashEmptyConfirmBody(num count);

  /// Confirmation dialog title for emptying the trash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash?'**
  String get trashEmptyConfirmTitle;

  /// Empty state body on the trash screen.
  ///
  /// In en, this message translates to:
  /// **'Deleted entries appear here for 30 days before they are removed permanently.'**
  String get trashEmptyMessage;

  /// Loading state message on the trash screen.
  ///
  /// In en, this message translates to:
  /// **'Loading deleted items…'**
  String get trashLoading;

  /// Snackbar after an entry is purged.
  ///
  /// In en, this message translates to:
  /// **'Entry permanently deleted'**
  String get trashPermanentlyDeleted;

  /// Snackbar after restoring an entry.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" restored'**
  String trashRestored(String title);

  /// Action in the empty-vault state.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get vaultAddFirstItem;

  /// Tooltip for pinning a single row.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get vaultAddToFavorites;

  /// Folder filter chip for all folders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get vaultAllFolders;

  /// Button for opening an existing vault.
  ///
  /// In en, this message translates to:
  /// **'I already have a vault'**
  String get vaultAlreadyHaveVault;

  /// Button returning to the unlock form.
  ///
  /// In en, this message translates to:
  /// **'Back to unlock'**
  String get vaultBackToUnlock;

  /// Subtitle of the optional biometric switch.
  ///
  /// In en, this message translates to:
  /// **'Optional — open the vault with your fingerprint or face.'**
  String get vaultBiometricOptionalHint;

  /// Validation message for an empty master password.
  ///
  /// In en, this message translates to:
  /// **'Please choose a master password.'**
  String get vaultChooseMasterPassword;

  /// Tooltip for clearing all marked rows.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get vaultClearSelection;

  /// Confirmation field label on the create-vault screen.
  ///
  /// In en, this message translates to:
  /// **'Confirm Master Password'**
  String get vaultConfirmMasterPassword;

  /// Confirmation field label in the reset view.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get vaultConfirmNewPassword;

  /// Confirmation field label in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get vaultConfirmPassword;

  /// Temporary copy-button label after copying the recovery key.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get vaultCopied;

  /// Copy confirmation for a card number.
  ///
  /// In en, this message translates to:
  /// **'Card number copied to clipboard'**
  String get vaultCopiedCardNumber;

  /// Copy confirmation prefix; the clipboard clear hint is appended.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get vaultCopiedPassword;

  /// Copy confirmation for the recovery key; the clear hint is appended.
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied to clipboard'**
  String get vaultCopiedRecoveryKey;

  /// Copy confirmation for a username.
  ///
  /// In en, this message translates to:
  /// **'Username copied to clipboard'**
  String get vaultCopiedUsername;

  /// Tooltip for copying a card number.
  ///
  /// In en, this message translates to:
  /// **'Copy card'**
  String get vaultCopyCard;

  /// Tooltip for copying a login credential.
  ///
  /// In en, this message translates to:
  /// **'Copy credential'**
  String get vaultCopyCredential;

  /// Copy button in the recovery-key dialog.
  ///
  /// In en, this message translates to:
  /// **'Copy Key'**
  String get vaultCopyKey;

  /// Copy-button label on the onboarding recovery-key step.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get vaultCopyRecoveryKey;

  /// Create-vault button label.
  ///
  /// In en, this message translates to:
  /// **'Create Encrypted Vault'**
  String get vaultCreateEncryptedVault;

  /// Subtitle of the create-vault screen.
  ///
  /// In en, this message translates to:
  /// **'Create your encrypted offline vault. Only you have the key to your credentials.'**
  String get vaultCreateIntro;

  /// Subtitle of the onboarding master-password step.
  ///
  /// In en, this message translates to:
  /// **'This is the only key to your vault. We cannot reset it for you.'**
  String get vaultCreateMasterPasswordSubtitle;

  /// Title of the onboarding master-password step.
  ///
  /// In en, this message translates to:
  /// **'Create your master password'**
  String get vaultCreateMasterPasswordTitle;

  /// Busy label of the onboarding create button.
  ///
  /// In en, this message translates to:
  /// **'Creating vault…'**
  String get vaultCreatingVault;

  /// Title of the bulk-delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{{count} item} other{{count} items}}?'**
  String vaultDeleteItemsTitle(num count);

  /// Body of the bulk-delete dialog for several items.
  ///
  /// In en, this message translates to:
  /// **'These items will be moved to the trash.'**
  String get vaultDeleteManyItemsBody;

  /// Body of the bulk-delete dialog for one item.
  ///
  /// In en, this message translates to:
  /// **'This item will be moved to the trash.'**
  String get vaultDeleteOneItemBody;

  /// Empty-state title for an empty vault.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty'**
  String get vaultEmpty;

  /// Empty-state body for an empty vault.
  ///
  /// In en, this message translates to:
  /// **'Start adding passwords, payment cards, or secure notes. Everything is stored locally with zero-knowledge encryption.'**
  String get vaultEmptyHint;

  /// Empty-state body for a search with no results.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or filter.'**
  String get vaultEmptySearchHint;

  /// Offline entry count under the vault headline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} entry} other{{count} entries}} saved offline'**
  String vaultEntriesSavedOffline(num count);

  /// Snack-bar confirmation for pinning one entry.
  ///
  /// In en, this message translates to:
  /// **'{title} pinned to favorites'**
  String vaultEntryPinnedToFavorites(String title);

  /// Snack-bar confirmation for unpinning one entry.
  ///
  /// In en, this message translates to:
  /// **'{title} removed from favorites'**
  String vaultEntryRemovedFromFavorites(String title);

  /// Tooltip for leaving selection mode.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get vaultExitSelection;

  /// Label revealed when swiping a row to favorite it.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get vaultFavorite;

  /// Filter chip label for all entries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vaultFilterAll;

  /// Filter chip label for payment cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get vaultFilterCards;

  /// Filter chip label and section title for favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get vaultFilterFavorites;

  /// Filter chip label for login entries.
  ///
  /// In en, this message translates to:
  /// **'Logins'**
  String get vaultFilterLogins;

  /// Filter chip label for secure notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vaultFilterNotes;

  /// Filter chip label and row badge for two-factor entries.
  ///
  /// In en, this message translates to:
  /// **'2FA'**
  String get vaultFilterTwoFactor;

  /// Snack-bar fallback when a folder id cannot be resolved.
  ///
  /// In en, this message translates to:
  /// **'folder'**
  String get vaultFolder;

  /// Link to the recovery-key reset flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get vaultForgotPassword;

  /// Call to action on the onboarding welcome step.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get vaultGetStarted;

  /// Tooltip for obscuring a password field.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get vaultHidePassword;

  /// Item count shown next to a section title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item} other{{count} items}}'**
  String vaultItemCount(num count);

  /// Snack-bar confirmation for bulk deletion.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item} other{{count} items}} moved to trash'**
  String vaultItemsMovedToTrash(num count);

  /// Snack-bar confirmation for bulk pinning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item pinned to favorites} other{{count} items pinned to favorites}}'**
  String vaultItemsPinnedToFavorites(num count);

  /// Snack-bar confirmation for bulk unpinning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item removed from favorites} other{{count} items removed from favorites}}'**
  String vaultItemsRemovedFromFavorites(num count);

  /// Selection toolbar count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item} other{{count} items}} selected'**
  String vaultItemsSelected(num count);

  /// Fallback subtitle for payment-card rows.
  ///
  /// In en, this message translates to:
  /// **'Payment card'**
  String get vaultKindCard;

  /// Fallback subtitle for login rows.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get vaultKindLogin;

  /// Fallback subtitle for secure-note rows.
  ///
  /// In en, this message translates to:
  /// **'Secure note'**
  String get vaultKindNote;

  /// Fallback subtitle for passkey rows.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get vaultKindPasskey;

  /// Message shown while the vault list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading your vault…'**
  String get vaultLoadingList;

  /// Snack-bar confirmation after locking the vault.
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get vaultLocked;

  /// Master-password field label on the create-vault screen.
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get vaultMasterPasswordCapitalized;

  /// Biometric reset message after a password change.
  ///
  /// In en, this message translates to:
  /// **'Your master password changed. Set up quick unlock again.'**
  String get vaultMasterPasswordChanged;

  /// Master-password field label on unlock and onboarding forms.
  ///
  /// In en, this message translates to:
  /// **'Master password'**
  String get vaultMasterPasswordLabel;

  /// Tooltip for the bulk move action.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get vaultMoveToFolder;

  /// Snack-bar confirmation for moving entries to a folder.
  ///
  /// In en, this message translates to:
  /// **'Moved {count, plural, =1{{count} item} other{{count} items}} to {folder}'**
  String vaultMovedItemsToFolder(num count, String folder);

  /// Label of the new-item button and FAB.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get vaultNewItem;

  /// New-password field label in the reset view.
  ///
  /// In en, this message translates to:
  /// **'New master password'**
  String get vaultNewMasterPassword;

  /// Message shown when no vault file exists.
  ///
  /// In en, this message translates to:
  /// **'No existing vault was found on this device.'**
  String get vaultNoExistingVault;

  /// Folder filter chip and snack-bar fallback for unfiled entries.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get vaultNoFolder;

  /// Title of the wide-layout detail placeholder.
  ///
  /// In en, this message translates to:
  /// **'No item selected'**
  String get vaultNoItemSelected;

  /// Empty-state title for a search with no results.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get vaultNoMatchesFound;

  /// Feedback when an entry has no secret to copy.
  ///
  /// In en, this message translates to:
  /// **'Nothing to copy'**
  String get vaultNothingToCopy;

  /// Semantics label for opening a row.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String vaultOpenEntry(String title);

  /// Final onboarding button.
  ///
  /// In en, this message translates to:
  /// **'Open my vault'**
  String get vaultOpenMyVault;

  /// Separator between unlock methods.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get vaultOr;

  /// Validation message for mismatched passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get vaultPasswordsMismatch;

  /// Info card copy when biometric quick unlock is disabled.
  ///
  /// In en, this message translates to:
  /// **'You can enable biometric quick unlock later in Settings.'**
  String get vaultQuickUnlockLater;

  /// Info card copy when biometric quick unlock is enabled.
  ///
  /// In en, this message translates to:
  /// **'Quick unlock is on. You can turn it off any time in Settings.'**
  String get vaultQuickUnlockOn;

  /// Biometric reset message when credentials are missing.
  ///
  /// In en, this message translates to:
  /// **'Quick unlock needs to be set up again.'**
  String get vaultQuickUnlockSetupAgain;

  /// Subtitle of the final onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Keyel locks itself after one minute in the background. You can change this in Settings later.'**
  String get vaultReadySubtitle;

  /// Headline of the final onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Your vault is ready'**
  String get vaultReadyTitle;

  /// Heading above remembered search chips.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get vaultRecentSearches;

  /// Error message when exporting the recovery key fails.
  ///
  /// In en, this message translates to:
  /// **'Could not export the recovery key ({error}).'**
  String vaultRecoveryExportError(String error);

  /// Plain-text recovery-key document written to the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Keyel vault recovery key\n==========================\n\nThis file contains the recovery key for your Keyel vault.\n\nWARNING: anyone who has this key can unlock your vault. Keep it\noffline and private, and treat it like the master password itself.\n\nIf you forget your master password, this key is the only way back\ninto your vault. Keyel has no accounts and no cloud backup.\n\nYour recovery key:\n\n{key}\n'**
  String vaultRecoveryFileText(String key);

  /// Recovery-key field label in the reset view.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get vaultRecoveryKeyLabel;

  /// Title of the recovery-key dialog.
  ///
  /// In en, this message translates to:
  /// **'Recovery Key'**
  String get vaultRecoveryKeyTitle;

  /// Warning body of the recovery-key dialog.
  ///
  /// In en, this message translates to:
  /// **'Write down or securely store this recovery key offline. If you forget your master password, this is the ONLY way to regain access to your vault.'**
  String get vaultRecoveryKeyWarning;

  /// Tooltip for unpinning a single row.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get vaultRemoveFromFavorites;

  /// Subtitle of the recovery reset view.
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery key to set a new master password and unlock your vault.'**
  String get vaultResetMasterPasswordHint;

  /// Headline of the recovery reset view.
  ///
  /// In en, this message translates to:
  /// **'Reset your master password'**
  String get vaultResetMasterPasswordTitle;

  /// Label of the reset-password button.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get vaultResetPassword;

  /// Busy label of the reset-password button.
  ///
  /// In en, this message translates to:
  /// **'Resetting…'**
  String get vaultResetting;

  /// Section title for search results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get vaultResults;

  /// Button for saving the recovery key as a file.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get vaultSaveFile;

  /// Subtitle of the onboarding recovery-key step.
  ///
  /// In en, this message translates to:
  /// **'If you forget the master password, this key is the only way back into your vault. It is shown once.'**
  String get vaultSaveRecoveryKeySubtitle;

  /// Title of the onboarding recovery-key step.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery key'**
  String get vaultSaveRecoveryKeyTitle;

  /// Dismiss button in the recovery-key dialog.
  ///
  /// In en, this message translates to:
  /// **'I Have Saved It'**
  String get vaultSavedRecoveryKey;

  /// Hint text of the vault search field.
  ///
  /// In en, this message translates to:
  /// **'Search items, tags or notes...'**
  String get vaultSearchHint;

  /// Tooltip for selecting all visible rows.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get vaultSelectAll;

  /// Semantics label for a row in selection mode.
  ///
  /// In en, this message translates to:
  /// **'Select {title}'**
  String vaultSelectEntry(String title);

  /// Body of the wide-layout detail placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select an item from the list to view and manage its details.'**
  String get vaultSelectItemHint;

  /// Tooltip for revealing a password field.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get vaultShowPassword;

  /// Checkbox label confirming the recovery key was stored.
  ///
  /// In en, this message translates to:
  /// **'I stored this key somewhere safe'**
  String get vaultStoredKeyConfirmation;

  /// Tooltip for the bulk favorite action.
  ///
  /// In en, this message translates to:
  /// **'Toggle favorite'**
  String get vaultToggleFavorite;

  /// Inline cooldown message on the unlock form.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String vaultTooManyAttempts(num seconds);

  /// Vault list top bar title.
  ///
  /// In en, this message translates to:
  /// **'Keyel Vault'**
  String get vaultTopBarTitle;

  /// Undo action on the favorite snack bar.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get vaultUndo;

  /// Label revealed when swiping a row to unpin it.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get vaultUnfavorite;

  /// Subtitle of the unlock form.
  ///
  /// In en, this message translates to:
  /// **'Enter your master password to unlock your vault.'**
  String get vaultUnlockHint;

  /// Biometric unlock button and onboarding switch label.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get vaultUnlockWithBiometrics;

  /// Busy label of the unlock button.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get vaultUnlocking;

  /// Tooltip for opening a secure note.
  ///
  /// In en, this message translates to:
  /// **'View note'**
  String get vaultViewNote;

  /// Tooltip for opening a passkey.
  ///
  /// In en, this message translates to:
  /// **'View passkey'**
  String get vaultViewPasskey;

  /// Headline of the unlock form.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get vaultWelcomeBack;

  /// Subtitle of the onboarding welcome step.
  ///
  /// In en, this message translates to:
  /// **'Your passwords stay encrypted on this device. There is no account, no cloud, and no telemetry.'**
  String get vaultWelcomeSubtitle;

  /// Welcome headline on the create-vault and onboarding screens.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Keyel'**
  String get vaultWelcomeToKeyel;

  /// Button that clears every seed from the watch
  ///
  /// In en, this message translates to:
  /// **'Remove all from watch'**
  String get wearClearAll;

  /// Confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'The seeds are deleted from this watch. You can send them again from the phone. Your vault is not changed.'**
  String get wearClearMessage;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove all codes from the watch?'**
  String get wearClearTitle;

  /// Confirmation after clearing the watch
  ///
  /// In en, this message translates to:
  /// **'All codes removed from the watch'**
  String get wearCleared;

  /// Empty state for watch code transfer
  ///
  /// In en, this message translates to:
  /// **'None of your entries has a one-time password configured.'**
  String get wearEmpty;

  /// Failure message for a watch transfer
  ///
  /// In en, this message translates to:
  /// **'Could not reach the watch'**
  String get wearFailed;

  /// Explanation of the watch code transfer
  ///
  /// In en, this message translates to:
  /// **'Send a TOTP seed to a paired Wear OS watch. The seed is stored only on the watch, encrypted with its device key. Sending requires an unlocked vault. Codes are hidden when you leave the watch app and are never copied to the clipboard.'**
  String get wearInfo;

  /// Button that pushes one seed to the watch
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get wearSend;

  /// Confirmation after a successful push
  ///
  /// In en, this message translates to:
  /// **'Seed sent to the watch'**
  String get wearSent;

  /// Title of the Wear OS TOTP settings screen
  ///
  /// In en, this message translates to:
  /// **'Watch codes'**
  String get wearTitle;

  /// Shown when no watch is connected
  ///
  /// In en, this message translates to:
  /// **'No paired Wear OS watch is reachable. Open Keyel on your phone with the watch nearby, then try again.'**
  String get wearUnavailable;

  /// Button that clears the current selection.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
