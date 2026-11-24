// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Keyel';

  @override
  String get navVault => 'Coffre';

  @override
  String get navGenerator => 'Générateur';

  @override
  String get navSecurity => 'Sécurité';

  @override
  String get navSettings => 'Réglages';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionLockVault => 'Verrouiller le coffre';

  @override
  String get actionUnlock => 'Déverrouiller';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionRestore => 'Restaurer';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle =>
      'Choisissez la langue utilisée par Keyel';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get securityTitle => 'Santé de la sécurité';

  @override
  String get generatorTitle => 'Générateur';

  @override
  String get vaultTitle => 'Coffre';

  @override
  String get softwareUpdate => 'Mise à jour logicielle';

  @override
  String get foldersTitle => 'Dossiers';

  @override
  String get trashTitle => 'Corbeille';

  @override
  String get importExportTitle => 'Importer et exporter';

  @override
  String get syncTitle => 'Synchronisation';

  @override
  String get reportProblem => 'Signaler un problème';

  @override
  String get searchHint => 'Rechercher';

  @override
  String get checkForUpdates => 'Rechercher des mises à jour';

  @override
  String get aboutGeneration => 'À propos de la génération';

  @override
  String get generationHistory => 'Historique de génération';

  @override
  String get aboutGenerationMessage =>
      'Keyel génère toujours les mots de passe localement sur votre appareil.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get themeModeTitle => 'Thème';

  @override
  String get paletteTitle => 'Couleur d\'accent';

  @override
  String get amoledTitle => 'Noir pur (AMOLED)';

  @override
  String get animationsTitle => 'Animations';

  @override
  String get hapticsTitle => 'Retours tactiles';

  @override
  String get screenshotTitle => 'Protection contre les captures';

  @override
  String get clipboardTitle => 'Effacer le presse-papiers';

  @override
  String get autoLockTitle => 'Verrouillage automatique';

  @override
  String get healthLoading => 'Vérification de la santé de votre coffre…';

  @override
  String get healthErrorTitle => 'Impossible de vérifier la santé du coffre';

  @override
  String get folderEmpty => 'Aucun dossier pour l\'instant';

  @override
  String get trashEmpty => 'La corbeille est vide';

  @override
  String get currentVersion => 'Version actuelle';

  @override
  String get appearanceHeadline => 'Personnalisez Keyel';

  @override
  String get appearanceSubtitle =>
      'Choisissez votre thème, votre palette de couleurs et vos préférences d\'interaction. Les indicateurs de sécurité restent cohérents.';

  @override
  String paletteColors(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count couleurs',
      one: '$count couleur',
    );
    return '$_temp0';
  }

  @override
  String get darkModeTitle => 'Mode sombre';

  @override
  String get interactionTitle => 'Interaction';

  @override
  String get amoledSubtitle =>
      'Utilisez un noir pur en mode sombre pour réduire la luminosité OLED et économiser l\'énergie sur les écrans compatibles.';

  @override
  String get animationsSubtitle =>
      'Activez les animations et les transitions dans l\'application. Les réglages système de réduction des animations sont toujours respectés.';

  @override
  String get hapticsSubtitle =>
      'Activez les retours tactiles lors des interactions pris en charge par votre appareil.';

  @override
  String get languageFollowSystem => 'Suivre le système';

  @override
  String get autofillFillTitle => 'Remplir avec Keyel';

  @override
  String autofillFilling(String target) {
    return 'Remplissage de $target';
  }

  @override
  String get autofillTargetThisApp => 'cette application';

  @override
  String get autofillSearchVault => 'Rechercher dans le coffre';

  @override
  String get autofillCreateNewLogin => 'Créer un nouvel identifiant';

  @override
  String get autofillNeverForSite => 'Jamais pour ce site';

  @override
  String get autofillSaveTitle => 'Enregistrer l\'identifiant ?';

  @override
  String get autofillSaveLogin => 'Enregistrer l\'identifiant';

  @override
  String get autofillNotNow => 'Pas maintenant';

  @override
  String get autofillNewLogin => 'Nouvel identifiant';

  @override
  String get autofillNameRequired =>
      'Donnez d\'abord un nom à cet identifiant.';

  @override
  String get autofillFindingMatches =>
      'Recherche des identifiants correspondants…';

  @override
  String get autofillNoMatches => 'Aucun identifiant correspondant';

  @override
  String get autofillNoMatchesBody =>
      'Créez un identifiant pour cette application ou ce site.';

  @override
  String get autofillDisabledTitle =>
      'La saisie automatique est désactivée pour ce site';

  @override
  String get autofillDisabledBody =>
      'Vous avez choisi de ne jamais remplir ici. Retirez ce choix des réglages de saisie automatique de Keyel pour la réactiver.';

  @override
  String autofillStoreCredentials(String target) {
    return 'Enregistrer ces identifiants pour $target';
  }

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldUsername => 'Nom d\'utilisateur';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String autofillMismatchBody(String target) {
    return 'Certains résultats sont uniquement des correspondances de texte. Vérifiez que l\'identifiant appartient vraiment à $target avant de remplir.';
  }

  @override
  String get autofillVaultLocked => 'Coffre verrouillé';

  @override
  String get autofillUnlockToFill =>
      'Déverrouillez Keyel pour remplir ce formulaire.';

  @override
  String get autofillLoadError => 'Impossible de charger les correspondances';

  @override
  String get autofillNeverTitle => 'Jamais pour ces sites';

  @override
  String get autofillNeverSubtitle =>
      'Emplacements où Keyel ne proposera ni remplissage ni enregistrement';

  @override
  String get autofillNeverEmpty => 'Aucun site bloqué';

  @override
  String autofillNeverCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites bloqués',
      one: '$count site bloqué',
    );
    return '$_temp0';
  }

  @override
  String get actionManage => 'Gérer';

  @override
  String get autofillVerifiedTitle => 'Sites vérifiés uniquement';

  @override
  String get autofillVerifiedSubtitle =>
      'Uniquement les correspondances exactes de paquet ou d\'hôte (substitut hors ligne des Digital Asset Links)';

  @override
  String get coreAutofillAppTitle => 'Saisie automatique Keyel';

  @override
  String get coreBiometricEnableReason =>
      'Confirmez votre identité pour l\'activer';

  @override
  String get coreBreachCheckActive =>
      'Une vérification des fuites est déjà en cours.';

  @override
  String get coreBreachCheckFailed =>
      'La vérification des fuites a échoué. Veuillez réessayer.';

  @override
  String get coreBreachInvalidResponse =>
      'Le service de vérification des fuites a renvoyé une réponse inattendue.';

  @override
  String get coreBreachInvalidToken =>
      'Cette vérification des fuites a expiré.';

  @override
  String get coreBreachUnreachable =>
      'Impossible de contacter le service de vérification des fuites.';

  @override
  String get coreEmptyImport =>
      'Ce fichier ne contient aucune entrée à importer.';

  @override
  String get coreEntryNotFound => 'Entrée introuvable.';

  @override
  String get coreInternalError => 'Erreur interne.';

  @override
  String get coreInvalidEntryId => 'Identifiant d\'entrée non valide.';

  @override
  String get coreInvalidKdfParams =>
      'Paramètres de dérivation de clé non valides.';

  @override
  String get coreInvalidRecoveryKey =>
      'Cette clé de récupération n\'est pas valide.';

  @override
  String get coreMalformedImport =>
      'Ce fichier n\'est pas un export CSV valide.';

  @override
  String get corePaletteAmber => 'Ambre';

  @override
  String get corePaletteAmberDesc => 'Tons dorés chaleureux';

  @override
  String get corePaletteForest => 'Forêt';

  @override
  String get corePaletteForestDesc => 'Tons verts profonds';

  @override
  String get corePaletteGraphite => 'Graphite';

  @override
  String get corePaletteGraphiteDesc => 'Tons monochrome neutres';

  @override
  String get corePaletteIndigo => 'Indigo';

  @override
  String get corePaletteIndigoDesc => 'Couleurs classiques de la marque Keyel';

  @override
  String get corePaletteOcean => 'Océan';

  @override
  String get corePaletteOceanDesc => 'Tons bleus apaisants';

  @override
  String get corePaletteRose => 'Rose';

  @override
  String get corePaletteRoseDesc => 'Tons doux de rouge et de rose';

  @override
  String get corePaletteTeal => 'Bleu-vert';

  @override
  String get corePaletteTealDesc => 'Tons bleu-vert équilibrés';

  @override
  String get corePaletteViolet => 'Violet';

  @override
  String get corePaletteVioletDesc => 'Tons violets intenses';

  @override
  String get corePasskeyAppTitle => 'Clés d\'accès Keyel';

  @override
  String get corePasskeyRequestUnreadable =>
      'Impossible de lire la demande de clé d\'accès. Veuillez réessayer.';

  @override
  String get corePasskeyRequestUnsupported =>
      'Cette demande de clé d\'accès n\'est pas prise en charge.';

  @override
  String get corePasskeyUnavailable => 'Clé d\'accès indisponible';

  @override
  String get coreRequiredFields => 'Veuillez remplir les champs obligatoires.';

  @override
  String get coreStorageError =>
      'Impossible de lire ou d\'écrire le fichier du coffre.';

  @override
  String get coreThemeDark => 'Sombre';

  @override
  String get coreThemeLight => 'Clair';

  @override
  String get coreThemeSystem => 'Système';

  @override
  String coreThrottled(String seconds) {
    return 'Trop de tentatives. Réessayez dans $seconds s.';
  }

  @override
  String get coreUnsupportedCsvFormat =>
      'Ce format CSV n\'est pas pris en charge. Utilisez un export Bitwarden ou Chrome.';

  @override
  String get coreVaultCorrupted => 'Le fichier du coffre est endommagé.';

  @override
  String get coreVaultExists => 'Un coffre existe déjà.';

  @override
  String get coreVaultInvalidPath => 'Le chemin du coffre n\'est pas valide.';

  @override
  String get coreVaultLocked => 'Déverrouillez d\'abord le coffre.';

  @override
  String get coreVaultMissing => 'Aucun fichier de coffre n\'a été trouvé.';

  @override
  String get coreVaultNotInitialized =>
      'Le stockage du coffre n\'est pas initialisé.';

  @override
  String get coreVaultUnsupportedVersion =>
      'Ce coffre a été créé par une version plus récente de Keyel.';

  @override
  String get coreWrongPassword => 'Mot de passe incorrect ou coffre endommagé.';

  @override
  String get entry2FaCodeCopied => 'Code 2FA copié dans le presse-papiers';

  @override
  String get entry2FaEnabled => '2FA activée';

  @override
  String get entryAddCustomField => 'Ajouter un champ personnalisé';

  @override
  String get entryAddToFavorites => 'Ajouter aux favoris';

  @override
  String get entryAlgorithm => 'Algorithme';

  @override
  String get entryCardDetails => 'Détails de la carte';

  @override
  String get entryCardNumber => 'Numéro de carte';

  @override
  String get entryCardNumberCopied =>
      'Numéro de carte copié dans le presse-papiers';

  @override
  String get entryCardholder => 'Titulaire';

  @override
  String get entryCardholderName => 'Nom du titulaire';

  @override
  String get entryCardholderNameCopied => 'Nom du titulaire copié';

  @override
  String get entryChangeIcon => 'Changer l\'icône';

  @override
  String get entryChooseIcon => 'Choisir une icône';

  @override
  String get entryChooseIconSubtitle =>
      'Sélectionnez une icône pour cette entrée';

  @override
  String get entryConfigured => 'Configuré';

  @override
  String get entryCopy2FaCode => 'Copier le code 2FA';

  @override
  String get entryCopyCardNumber => 'Copier le numéro de carte';

  @override
  String get entryCopyCardholder => 'Copier le nom du titulaire';

  @override
  String get entryCopyFullNote => 'Copier la note complète';

  @override
  String get entryCopyPassword => 'Copier le mot de passe';

  @override
  String get entryCopyUrl => 'Copier l\'URL';

  @override
  String get entryCopyUsername => 'Copier le nom d\'utilisateur';

  @override
  String get entryCopyValue => 'Copier la valeur';

  @override
  String get entryCopyWebsiteUrl => 'Copier l\'URL du site';

  @override
  String get entryCreated => 'Entrée créée dans le coffre.';

  @override
  String get entryCredentialId => 'ID d\'identification';

  @override
  String get entryCredentials => 'Identifiants';

  @override
  String get entryCustomFields => 'Champs personnalisés';

  @override
  String get entryCustomFieldsHint =>
      'Ajoutez des champs texte, masqués ou URL à cette entrée.';

  @override
  String get entryDecryptedNote => 'Note déchiffrée :';

  @override
  String get entryDeleteBody => 'Cet élément sera déplacé dans la corbeille.';

  @override
  String get entryDeleteEntry => 'Supprimer l\'entrée';

  @override
  String entryDeleteTitle(String title) {
    return 'Supprimer $title ?';
  }

  @override
  String get entryDiscardBody =>
      'Vos modifications de cette entrée seront perdues.';

  @override
  String get entryDiscardConfirm => 'Abandonner';

  @override
  String get entryDiscardTitle => 'Abandonner les modifications ?';

  @override
  String get entryDiscoverable => 'Découvrable';

  @override
  String get entryEditCard => 'Modifier la carte';

  @override
  String get entryEditEntry => 'Modifier l\'entrée';

  @override
  String get entryEditLogin => 'Modifier la connexion';

  @override
  String get entryEditNote => 'Modifier la note';

  @override
  String get entryEditPasskey => 'Modifier la clé d\'accès';

  @override
  String entryEditTitle(String kind) {
    return 'Modifier $kind';
  }

  @override
  String get entryEncryptedContent => 'Contenu chiffré';

  @override
  String get entryEncryptedHint =>
      'Les secrets restent chiffrés avec Argon2id et ChaCha20-Poly1305.';

  @override
  String get entryEncryptedProtected => 'Chiffré et protégé';

  @override
  String get entryEnterManually => 'Saisir manuellement';

  @override
  String get entryEnterPassword => 'Saisir un mot de passe sécurisé';

  @override
  String get entryExpires => 'Expiration';

  @override
  String get entryExpiry => 'Expiration';

  @override
  String get entryFavoriteRemoved => 'Favori supprimé';

  @override
  String get entryField => 'Champ';

  @override
  String get entryFieldActions => 'Actions du champ';

  @override
  String entryFieldCopied(String label, String hint) {
    return '$label copié$hint';
  }

  @override
  String get entryFieldLabel => 'Libellé';

  @override
  String get entryFieldTypeHidden => 'Champ masqué';

  @override
  String get entryFieldTypeHiddenShort => 'Masqué';

  @override
  String get entryFieldTypeText => 'Champ texte';

  @override
  String get entryFieldTypeTextShort => 'Texte';

  @override
  String get entryFieldTypeUrl => 'Champ URL';

  @override
  String get entryFieldTypeUrlShort => 'URL';

  @override
  String get entryFolder => 'Dossier';

  @override
  String get entryGeneratePasswordTooltip => 'Générer un mot de passe';

  @override
  String get entryGenerateSecurePassword => 'Générer un mot de passe sécurisé';

  @override
  String get entryGoBack => 'Retour';

  @override
  String get entryHiddenValueKept =>
      'La valeur masquée existante sera conservée, sauf si vous en saisissez une nouvelle.';

  @override
  String get entryHideContent => 'Masquer le contenu';

  @override
  String get entryHideNumber => 'Masquer le numéro';

  @override
  String get entryHidePassword => 'Masquer le mot de passe';

  @override
  String get entryHideValue => 'Masquer la valeur';

  @override
  String get entryHistory => 'Historique';

  @override
  String get entryIconCategoryAll => 'Tous';

  @override
  String get entryIconCategoryBrands => 'Marques';

  @override
  String get entryIconCategoryCrypto => 'Crypto';

  @override
  String get entryIconCategoryFinance => 'Finance';

  @override
  String get entryIconCategoryLife => 'Vie et utilitaires';

  @override
  String get entryIconCategoryMedia => 'Médias';

  @override
  String get entryIconCategorySecurity => 'Sécurité';

  @override
  String get entryIconCategorySocial => 'Réseaux sociaux';

  @override
  String get entryIconCategoryTech => 'Tech et dev';

  @override
  String get entryIconCategoryWork => 'Travail';

  @override
  String get entryIconSearchHint =>
      'Rechercher des icônes (ex. GitHub, Banque, Mail)...';

  @override
  String get entryInvalidTotpSecret =>
      'Cette clé ou ce lien n\'est pas un secret TOTP valide.';

  @override
  String get entryInvalidWebsite => 'Adresse du site invalide';

  @override
  String get entryItemNotFound => 'Élément introuvable';

  @override
  String get entryKindCard => 'Carte';

  @override
  String get entryKindLogin => 'Connexion';

  @override
  String get entryKindNote => 'Note';

  @override
  String get entryKindPasskey => 'Clé d\'accès';

  @override
  String get entryLoading => 'Chargement de l\'entrée…';

  @override
  String get entryLoadingCode => 'Chargement du code…';

  @override
  String get entryMasterCredentials => 'Identifiants principaux';

  @override
  String entryMissingMessage(String entryId) {
    return 'Aucune entrée avec l\'ID « $entryId » n\'existe.';
  }

  @override
  String get entryMoveDown => 'Déplacer vers le bas';

  @override
  String get entryMoveUp => 'Déplacer vers le haut';

  @override
  String entryMovedToTrash(String title) {
    return '$title déplacé dans la corbeille';
  }

  @override
  String entryNewTitle(String kind) {
    return 'Nouvelle $kind';
  }

  @override
  String get entryNo => 'Non';

  @override
  String get entryNoFolder => 'Aucun dossier';

  @override
  String get entryNoMatchingIcons => 'Aucune icône correspondante';

  @override
  String get entryNoteCopied => 'Note copiée';

  @override
  String get entryNotes => 'Notes';

  @override
  String get entryNotesHint =>
      'Questions de récupération, codes PIN, phrases de récupération...';

  @override
  String get entryNothingToCopy => 'Rien à copier';

  @override
  String get entryOpenUrl => 'Ouvrir l\'URL';

  @override
  String get entryOpenWebsite => 'Ouvrir le site';

  @override
  String get entryPasskeyInfo =>
      'Les clés d\'accès sont créées et utilisées via des invites de connexion sécurisées. Les détails des identifiants sont gérés automatiquement et ne peuvent pas encore être modifiés ici.';

  @override
  String get entryPasskeyUser => 'Utilisateur';

  @override
  String entryPasswordCopied(String hint) {
    return 'Mot de passe copié$hint';
  }

  @override
  String get entryPasswordGenerationFailed =>
      'Impossible de générer un mot de passe pour le moment.';

  @override
  String entryPasswordHealth(String label, num count) {
    return 'Mot de passe $label ($count caractères)';
  }

  @override
  String get entryPasswordHistorySoon =>
      'L\'historique des mots de passe arrivera avec le stockage chiffré.';

  @override
  String entryPasswordScore(num score) {
    return 'Score : $score %';
  }

  @override
  String get entryPinToQuickAccess => 'Épingler cette entrée à l\'accès rapide';

  @override
  String entryPinned(String title) {
    return '$title épinglé aux favoris';
  }

  @override
  String get entryQrScanUnavailable =>
      'La numérisation par caméra arrivera dans une prochaine mise à jour. Saisissez la clé manuellement pour l\'instant.';

  @override
  String get entryRefreshesAutomatically => 'Actualisation automatique';

  @override
  String get entryRelyingParty => 'Partie de confiance';

  @override
  String get entryRemoveFavorite => 'Retirer des favoris';

  @override
  String get entryReplaceKey => 'Remplacer la clé';

  @override
  String get entryRevealNote => 'Afficher la note';

  @override
  String get entryRevealNumber => 'Afficher le numéro';

  @override
  String get entryRevealPassword => 'Afficher le mot de passe';

  @override
  String get entryRevealValue => 'Afficher la valeur';

  @override
  String get entrySaveEntry => 'Enregistrer l\'entrée';

  @override
  String get entrySavedSecurelyHint =>
      'Enregistré de façon sécurisée (laissez vide pour conserver)';

  @override
  String get entryScanQrCode => 'Scanner le code QR';

  @override
  String entrySecondsRemaining(num seconds) {
    return '${seconds}s';
  }

  @override
  String get entrySecureNote => 'Note sécurisée';

  @override
  String get entrySecureNoteContent => 'Contenu de la note sécurisée';

  @override
  String get entrySecureNotes => 'Notes sécurisées';

  @override
  String get entrySecurityCodeCvv => 'Code de sécurité (CVV)';

  @override
  String get entrySetupKeyOrLink => 'Clé de configuration ou lien';

  @override
  String get entrySheetBarrier => 'Feuille';

  @override
  String get entryShowPassword => 'Afficher le mot de passe';

  @override
  String get entrySignCount => 'Nombre de signatures';

  @override
  String entryStrengthEntropy(String entropyLabel) {
    return 'Entropie : $entropyLabel';
  }

  @override
  String entryStrengthSummary(String label, num bits, String descriptor) {
    return '$label ($bits bits) - $descriptor';
  }

  @override
  String get entrySuggestion => 'Suggestion :';

  @override
  String get entryTitleFieldHint => 'Nom du service ou de l\'application';

  @override
  String get entryTitleFieldLabel => 'Titre';

  @override
  String get entryTitleRequired => 'Donnez d\'abord un titre à cette entrée.';

  @override
  String get entryTotpConfiguredHint =>
      'Un code rotatif est enregistré pour cette entrée. Saisissez une nouvelle clé pour le remplacer.';

  @override
  String get entryTotpHint =>
      'Générez des codes de sécurité rotatifs de 30 secondes directement dans Keyel.';

  @override
  String get entryTotpKeyRequired =>
      'Saisissez la clé de configuration fournie par votre service.';

  @override
  String get entryTotpReady =>
      'Clé 2FA prête. Enregistrez l\'entrée pour la stocker.';

  @override
  String get entryTotpSetupBody =>
      'Collez la clé de configuration (base32) ou le lien otpauth:// fourni par votre service.';

  @override
  String get entryTotpSetupTitle => 'Configurer la double authentification';

  @override
  String get entryTransports => 'Transports';

  @override
  String get entryTwoFactorAuth => 'Authentification à deux facteurs';

  @override
  String get entryTwoFactorCode => 'Code à deux facteurs';

  @override
  String get entryUpdated => 'Entrée mise à jour.';

  @override
  String get entryUseSuggestedEmail => 'Utiliser l\'e-mail suggéré';

  @override
  String get entryUsernameCopied =>
      'Nom d\'utilisateur copié dans le presse-papiers';

  @override
  String get entryUsernameOrEmail => 'Nom d\'utilisateur ou e-mail';

  @override
  String get entryValue => 'Valeur';

  @override
  String entryValueCopied(String label) {
    return '$label copié';
  }

  @override
  String get entryValueSecret => 'Valeur (secrète)';

  @override
  String get entryWebVaultMatcher => 'Correspondance avec le coffre Web';

  @override
  String get entryWebsiteOpenFailed => 'Impossible d\'ouvrir le site';

  @override
  String get entryWebsiteUrl => 'URL du site';

  @override
  String get entryWebsiteUrlCopied =>
      'URL du site copiée dans le presse-papiers';

  @override
  String get entryYes => 'Oui';

  @override
  String get fldCreating => 'Création…';

  @override
  String get fldDeleteConfirmBody =>
      'Les entrées de ce dossier sont conservées et déplacées dans « Aucun dossier ».';

  @override
  String fldDeleteConfirmTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get fldDeleteFolder => 'Supprimer le dossier';

  @override
  String get fldDeleted => 'Dossier supprimé';

  @override
  String get fldEmptyMessage =>
      'Les dossiers regroupent vos identifiants, cartes et notes. Utilisez le bouton ci-dessous pour créer le premier.';

  @override
  String get fldFolderNameLabel => 'Nom du dossier';

  @override
  String get fldLoading => 'Chargement des dossiers…';

  @override
  String get fldMoveToFolder => 'Déplacer vers un dossier';

  @override
  String get fldNewFolder => 'Nouveau dossier';

  @override
  String get fldNoFolder => 'Aucun dossier';

  @override
  String get fldRenameFolder => 'Renommer le dossier';

  @override
  String get genCapitalizeExample => 'p. ex. Apple-Tree-House';

  @override
  String get genCapitalizeFirst => 'Mettre la première lettre en majuscule';

  @override
  String get genCharacterTypeError =>
      'Gardez au moins un type de caractère activé.';

  @override
  String get genCharacterTypes => 'Types de caractères';

  @override
  String genCharsShort(num count) {
    return '$count car.';
  }

  @override
  String genCopied(String mode, String clearHint) {
    return 'Copié dans le presse-papiers : $mode$clearHint';
  }

  @override
  String genCopyMode(String mode) {
    return 'Copier $mode';
  }

  @override
  String get genError => 'Erreur';

  @override
  String get genExcludeAmbiguous => 'Exclure les caractères ambigus';

  @override
  String get genExcludeAmbiguousSubtitle =>
      'Évite la confusion entre 0, O, 1, l et I';

  @override
  String get genGeneratedLocally => 'Généré localement sur l\'appareil';

  @override
  String get genHistoryMessage =>
      'L\'historique de génération sera disponible avec le stockage chiffré.';

  @override
  String get genIncludeNumber => 'Inclure un chiffre';

  @override
  String get genIncludeNumberSubtitle =>
      'Ajoute deux chiffres aléatoires à la fin';

  @override
  String genLengthValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caractères',
      one: '$count caractère',
    );
    return '$_temp0';
  }

  @override
  String get genLowercase => 'Lettres minuscules';

  @override
  String get genNumbers => 'Chiffres';

  @override
  String get genPassphrase => 'Phrase secrète';

  @override
  String get genPassphraseError => 'Impossible de générer la phrase secrète.';

  @override
  String get genPassphraseOptions => 'Options de la phrase secrète';

  @override
  String get genPassphraseTip =>
      'Les phrases secrètes remplacent les symboles par des mots mémorables. Utilisez au moins huit mots pour la phrase secrète maîtresse du coffre.';

  @override
  String get genPassword => 'Mot de passe';

  @override
  String get genPasswordError =>
      'Impossible de générer le mot de passe. Vérifiez les contraintes.';

  @override
  String get genPasswordLength => 'Longueur du mot de passe';

  @override
  String get genPasswordLengthSubtitle => '16 caractères ou plus recommandés';

  @override
  String get genRegenerate => 'Régénérer';

  @override
  String get genSeparatorSpace => 'Espace';

  @override
  String get genSymbols => 'Symboles';

  @override
  String get genUppercase => 'Lettres majuscules';

  @override
  String get genUsePassphrase => 'Utiliser cette phrase secrète';

  @override
  String get genUsePassword => 'Utiliser ce mot de passe';

  @override
  String get genWordCount => 'Nombre de mots';

  @override
  String get genWordCountSubtitle =>
      'Chaque mot ajoute environ 10 bits d\'entropie';

  @override
  String genWordCountValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '$count mot',
    );
    return '$_temp0';
  }

  @override
  String get genWordSeparator => 'Séparateur de mots';

  @override
  String get imexAddedLabel => 'Ajoutés';

  @override
  String get imexAlreadyPresentLabel => 'Déjà présents';

  @override
  String get imexBackupCreated => 'Sauvegarde créée';

  @override
  String get imexBackupHint =>
      'La sauvegarde est une copie complète et chiffrée de votre coffre. Conservez-la en lieu sûr.';

  @override
  String get imexBackupPasswordLabel => 'Mot de passe de la sauvegarde';

  @override
  String get imexBackupReady =>
      'Votre sauvegarde chiffrée est prête à être partagée.';

  @override
  String get imexCardsLabel => 'Cartes';

  @override
  String get imexConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get imexCsvExportBody =>
      'Tous les mots de passe de votre coffre seront écrits dans un fichier texte brut que tout le monde peut lire. Ne faites ceci que si vous savez ce que vous faites.';

  @override
  String get imexCsvExportConfirm => 'Exporter sans chiffrement';

  @override
  String get imexCsvExportTitle => 'Exporter un CSV non chiffré ?';

  @override
  String get imexCsvExported => 'CSV exporté';

  @override
  String imexCsvImportSheetTitle(String format) {
    return 'Importer un CSV $format';
  }

  @override
  String get imexCsvImportSubtitle =>
      'Exports de mots de passe Bitwarden ou Chrome';

  @override
  String get imexCsvMergeHint =>
      'Les entrées qui semblent identiques à celles que vous possédez déjà sont ignorées.';

  @override
  String get imexCsvReady =>
      'Votre export non chiffré est prêt à être partagé.';

  @override
  String get imexEncryptBackupSubtitle =>
      'Choisissez un mot de passe pour ce fichier de sauvegarde. Il peut être différent de votre mot de passe maître et n\'est jamais enregistré.';

  @override
  String get imexEncryptBackupTitle => 'Chiffrer la sauvegarde';

  @override
  String get imexEncryptedBackupSection => 'Sauvegarde chiffrée';

  @override
  String get imexExportBackupAction => 'Exporter la sauvegarde';

  @override
  String get imexExportEncryptedSubtitle =>
      'Enregistrer une copie chiffrée de votre coffre';

  @override
  String get imexExportEncryptedTitle => 'Exporter la sauvegarde chiffrée';

  @override
  String get imexExportPlainCsvSubtitle =>
      'Non chiffré — pour migrer vers une autre application';

  @override
  String get imexExportPlainCsvTitle => 'Exporter en CSV brut';

  @override
  String get imexFailedRowsLabel => 'Lignes en échec';

  @override
  String get imexFailureListTitle => 'Lignes qui n\'ont pas pu être importées';

  @override
  String get imexFoldersCreatedLabel => 'Dossiers créés';

  @override
  String get imexHidePassword => 'Masquer le mot de passe';

  @override
  String get imexHubIntro =>
      'Déplacez votre coffre en toute sécurité. Les sauvegardes chiffrées utilisent leur propre mot de passe ; les exports CSV sont en texte brut.';

  @override
  String get imexImportComplete => 'Import terminé';

  @override
  String imexImportCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '$count entrée',
    );
    return 'Importer $_temp0';
  }

  @override
  String get imexImportFromCsvTitle => 'Importer depuis un CSV';

  @override
  String get imexLoginsLabel => 'Connexions';

  @override
  String get imexMergeHint =>
      'Les entrées déjà présentes dans votre coffre sont conservées.';

  @override
  String get imexMergeSubtitle => 'Ajouter ce qui manque, conserver le reste';

  @override
  String get imexMergeTitle => 'Fusionner';

  @override
  String imexMoreFailures(num count) {
    return '…et $count de plus';
  }

  @override
  String get imexPasswordsMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get imexPickBackup => 'Choisir une sauvegarde à restaurer';

  @override
  String get imexPickCsv => 'Choisir un export CSV à importer';

  @override
  String get imexReplaceHint =>
      'Tout le contenu actuel de votre coffre est remplacé.';

  @override
  String get imexReplaceSubtitle =>
      'Supprimer le coffre actuel et n\'utiliser que ce fichier';

  @override
  String get imexReplaceTitle => 'Remplacer';

  @override
  String get imexReportSubtitle => 'Voici ce qui a changé dans votre coffre.';

  @override
  String get imexRestoreAction => 'Restaurer';

  @override
  String get imexRestoreBackupTitle => 'Restaurer la sauvegarde';

  @override
  String get imexRestoreComplete => 'Restauration terminée';

  @override
  String get imexRestoreFromBackupSubtitle =>
      'Fusionner ou remplacer votre coffre à partir d\'une sauvegarde';

  @override
  String get imexRestoreFromBackupTitle => 'Restaurer depuis une sauvegarde';

  @override
  String imexRowFailure(num row, String reason) {
    return 'Ligne $row : $reason';
  }

  @override
  String get imexSecureNotesLabel => 'Notes sécurisées';

  @override
  String get imexShowPassword => 'Afficher le mot de passe';

  @override
  String get imexSkippedRowsLabel => 'Lignes ignorées';

  @override
  String get imexUnencryptedWarning =>
      'Ce fichier n\'est pas chiffré. Supprimez-le dès que vous avez terminé.';

  @override
  String get imexVaultSaved => 'Votre coffre a été enregistré.';

  @override
  String get otaAndroidOnly =>
      'Le programme d\'installation de paquets n\'est pris en charge que sur Android';

  @override
  String get otaAutoCheckSubtitle =>
      'Vérification au lancement et à votre retour, sur le canal sélectionné.';

  @override
  String get otaAutoCheckTitle => 'Vérifier les mises à jour automatiquement';

  @override
  String otaAvailableSubtitle(String version, String channel) {
    return 'Keyel v$version • canal $channel';
  }

  @override
  String otaBannerSemantics(String version) {
    return 'Mise à jour disponible : Keyel $version. Ouvrir la mise à jour logicielle.';
  }

  @override
  String get otaChannelBetaDescription =>
      'Aperçus des préversions avec les dernières fonctionnalités';

  @override
  String get otaChannelStableDescription => 'Versions officielles vérifiées';

  @override
  String otaCheckFailedHttp(String status) {
    return 'Échec de la vérification des mises à jour : HTTP $status';
  }

  @override
  String get otaCheckFailedTitle => 'Échec de la vérification des mises à jour';

  @override
  String get otaCheckForUpdates => 'Vérifier les mises à jour';

  @override
  String get otaChecking => 'Vérification...';

  @override
  String get otaCheckingUpdates => 'Vérification des mises à jour...';

  @override
  String otaChecksumMismatch(String expected, String computed) {
    return 'Somme de contrôle incohérente : attendu $expected, obtenu $computed';
  }

  @override
  String get otaChecksumNotVerified =>
      'La somme de contrôle de la mise à jour n\'a pas pu être vérifiée';

  @override
  String get otaConnectingServer => 'Connexion au serveur de versions';

  @override
  String get otaCouldNotConnect =>
      'Impossible de se connecter au serveur de versions';

  @override
  String otaCouldNotInstallApk(String error) {
    return 'Impossible d\'installer l\'APK : $error';
  }

  @override
  String get otaDismissBanner => 'Masquer la bannière de mise à jour';

  @override
  String get otaDownloadCancelled => 'Téléchargement annulé par l\'utilisateur';

  @override
  String otaDownloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String otaDownloadFailedHttp(String status) {
    return 'Échec du téléchargement : HTTP $status';
  }

  @override
  String otaDownloadVersion(String version, String size) {
    return 'Télécharger la v$version ($size)';
  }

  @override
  String otaDownloadedVerified(String version) {
    return 'Keyel v$version téléchargé et vérifié';
  }

  @override
  String get otaDownloadingApk => 'Téléchargement de l\'APK';

  @override
  String otaDownloadingDetail(String percent, String size) {
    return '$percent % • $size';
  }

  @override
  String get otaDownloadingUpdate => 'Téléchargement de la mise à jour...';

  @override
  String get otaEnableNotifications =>
      'Activer les notifications de mise à jour';

  @override
  String get otaGrantInstallPermission =>
      'Veuillez autoriser l\'installation d\'applications inconnues lorsque le système vous le demandera.';

  @override
  String get otaHandingToInstaller =>
      'Transfert vers le programme d\'installation système';

  @override
  String get otaInstallLocal =>
      'Installer une mise à jour depuis un fichier APK local';

  @override
  String get otaInstallNow => 'Installer la mise à jour maintenant';

  @override
  String otaInstallationError(String error) {
    return 'Erreur d\'installation : $error';
  }

  @override
  String otaInstalledVersion(String version) {
    return 'Version installée : $version';
  }

  @override
  String get otaInstallerUnavailable =>
      'Impossible d\'ouvrir le programme d\'installation de paquets';

  @override
  String get otaInstallingUpdate => 'Installation de la mise à jour...';

  @override
  String otaLastChecked(String time) {
    return 'Dernière vérification : $time';
  }

  @override
  String otaLatestInstalled(String version) {
    return 'Version $version • Dernière version installée';
  }

  @override
  String otaNoBetaRelease(String version) {
    return 'Aucune version bêta pour le moment • Version $version installée';
  }

  @override
  String get otaNoReleaseNotes =>
      'Aucune note de version détaillée fournie pour cette version.';

  @override
  String get otaNotificationsOn =>
      'Les notifications de mise à jour sont activées';

  @override
  String otaPercent(String percent) {
    return '$percent %';
  }

  @override
  String get otaPreferencesTitle => 'Préférences de mise à jour';

  @override
  String get otaPrivacyNotice =>
      'Garantie de confidentialité : les vérifications automatiques lisent uniquement le manifeste public du canal, au lancement et pendant que l\'application est ouverte. Votre base de données du coffre, vos mots de passe, vos clés et vos données biométriques ne quittent jamais cet appareil.';

  @override
  String get otaReadyToInstall => 'Prêt à installer';

  @override
  String get otaRefuseUnverifiedDownload =>
      'Refus de télécharger une mise à jour sans somme de contrôle SHA-256 valide';

  @override
  String get otaInsecureUrl =>
      'Le téléchargement des mises à jour nécessite une URL HTTPS';

  @override
  String get otaLocalInstallWarning =>
      'Les APK locaux ne sont pas vérifiés par somme de contrôle. N\'installez qu\'un fichier de confiance.';

  @override
  String get otaReverifyFailed =>
      'La mise à jour téléchargée a échoué la vérification finale et a été supprimée';

  @override
  String get otaReleaseChannel => 'Canal de version';

  @override
  String get otaSelectApkTitle => 'Sélectionner l\'APK de mise à jour Keyel';

  @override
  String get otaTapCheckNow =>
      'Appuyez sur « Vérifier maintenant » pour rechercher de nouvelles versions';

  @override
  String get otaUpToDate => 'Keyel est à jour';

  @override
  String get otaUpdateAvailableTitle => 'Mise à jour disponible';

  @override
  String get otaUpdateFileNotFound =>
      'Fichier de mise à jour introuvable sur l\'appareil';

  @override
  String otaWhatsNew(String version) {
    return 'Nouveautés de la v$version';
  }

  @override
  String get passCreateBody =>
      'La clé d\'accès sera chiffrée et stockée dans votre coffre Keyel local. Votre clé privée ne quitte jamais cet appareil.';

  @override
  String get passCreateQuestion => 'Créer une clé d\'accès pour ce compte ?';

  @override
  String get passFindingPasskeys => 'Recherche de clés d\'accès…';

  @override
  String get passLabelAccount => 'Compte';

  @override
  String get passLabelDisplayName => 'Nom affiché';

  @override
  String get passLabelDomain => 'Domaine';

  @override
  String get passLabelSite => 'Site';

  @override
  String get passMissingRp =>
      'Informations sur la partie de confiance manquantes pour cette requête.';

  @override
  String get passNoMatches => 'Aucune clé d\'accès disponible';

  @override
  String passNoMatchesAvailable(String rpId) {
    return 'Aucune clé d\'accès n\'est enregistrée pour $rpId.';
  }

  @override
  String passNoMatchesForRp(String rpId) {
    return 'Aucune clé d\'accès trouvée pour $rpId.';
  }

  @override
  String passOrigin(String origin) {
    return 'Origine : $origin';
  }

  @override
  String get passSavePasskey => 'Enregistrer la clé d\'accès';

  @override
  String get passSaving => 'Enregistrement…';

  @override
  String passSignInTo(String rpId) {
    return 'Se connecter à $rpId';
  }

  @override
  String get passThisSite => 'ce site';

  @override
  String get passUnknownAccount => 'Compte inconnu';

  @override
  String get passUnknownSite => 'Site inconnu';

  @override
  String get passUsePasskey => 'Utiliser une clé d\'accès';

  @override
  String get prefAllowScreenshotsBody =>
      'Tout ce qui s\'affiche à l\'écran, y compris un secret révélé, peut être capturé ou apparaître dans l\'aperçu des applications récentes. Les écrans de verrouillage et de déverrouillage restent protégés.';

  @override
  String get prefAllowScreenshotsConfirm => 'Autoriser les captures d\'écran';

  @override
  String get prefAllowScreenshotsTitle => 'Autoriser les captures d\'écran ?';

  @override
  String get prefAppearanceChangesInstant =>
      'Les modifications s\'appliquent immédiatement dans Keyel.';

  @override
  String get prefAppearanceColorsTitle => 'Apparence et couleurs';

  @override
  String get prefAskToSaveSubtitle =>
      'Proposer d\'enregistrer de nouveaux identifiants après une connexion';

  @override
  String get prefAskToSaveTitle => 'Demander l\'enregistrement';

  @override
  String prefAutoLockAfterMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return 'Après $_temp0';
  }

  @override
  String prefAutoLockAfterSeconds(num count) {
    return 'Après $count secondes';
  }

  @override
  String get prefAutoLockDialogTitle => 'Verrouillage automatique après';

  @override
  String get prefAutoLockImmediately => 'Immédiatement';

  @override
  String get prefAutoLockSubtitle =>
      'Verrouiller le coffre après un certain temps en arrière-plan';

  @override
  String get prefAutofillDisabledSubtitle =>
      'Appuyez pour activer Keyel comme fournisseur de saisie automatique';

  @override
  String get prefAutofillEnabledSubtitle =>
      'Keyel est votre fournisseur de saisie automatique';

  @override
  String get prefAutofillPasskeysSection =>
      'Saisie automatique et clés d\'accès';

  @override
  String get prefAutofillServiceTitle => 'Service de saisie automatique';

  @override
  String get prefBackToSecurity => 'Retour à Sécurité';

  @override
  String get prefBackupImportSubtitle =>
      'Sauvegardes chiffrées et import/export CSV';

  @override
  String get prefBackupImportTitle => 'Sauvegarde et import';

  @override
  String get prefBiometricDisabledSnack =>
      'Déverrouillage biométrique désactivé.';

  @override
  String get prefBiometricEnabledSnack => 'Déverrouillage biométrique activé';

  @override
  String get prefBiometricUnlockSubtitle =>
      'Empreinte ou visage pour ouvrir le coffre';

  @override
  String get prefBiometricUnlockTitle => 'Déverrouillage biométrique';

  @override
  String prefBiometricUpdateError(String error) {
    return 'Impossible de mettre à jour les paramètres biométriques : $error';
  }

  @override
  String get prefBiometricsUnavailable =>
      'La biométrie n\'est pas disponible sur cet appareil.';

  @override
  String get prefBridgeDiagnosticsSubtitle =>
      'Opérations et diagnostics bruts du pont FRB';

  @override
  String get prefBridgeDiagnosticsTitle =>
      'Diagnostics du pont et suite de tests';

  @override
  String get prefChangeMasterPasswordRow => 'Modifier le mot de passe maître';

  @override
  String get prefChangeMasterSubtitle =>
      'Rechiffrer l\'emplacement de clé du coffre avec un nouveau mot de passe maître';

  @override
  String get prefChangeMasterTitle => 'Modifier le mot de passe maître';

  @override
  String get prefChangePasswordAction => 'Modifier le mot de passe';

  @override
  String get prefCheckingDeviceSupport =>
      'Vérification de la prise en charge par l\'appareil…';

  @override
  String get prefCheckingStatus => 'Vérification…';

  @override
  String get prefClipboardDialogBody =>
      'Le verrouillage du coffre ou la fermeture de l’application efface toujours le presse-papiers immédiatement. Ce réglage contrôle le délai pendant lequel Keyel reste ouvert.';

  @override
  String get prefClipboardDialogTitle => 'Effacer le presse-papiers après';

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
  String get prefClipboardNever => 'Jamais';

  @override
  String prefClipboardSeconds(num count) {
    return '$count secondes';
  }

  @override
  String get prefClipboardSubtitle =>
      'Effacer les secrets copiés du presse-papiers';

  @override
  String get prefConfirmMasterTitle => 'Confirmer le mot de passe maître';

  @override
  String get prefConfirmNewMasterPassword =>
      'Confirmer le nouveau mot de passe maître';

  @override
  String get prefCopyPasswordLabel => 'Copier le mot de passe';

  @override
  String get prefCrossDeviceSyncSubtitle =>
      'Synchronisation E2EE facultative via un dossier de votre choix';

  @override
  String get prefCrossDeviceSyncTitle => 'Synchronisation entre appareils';

  @override
  String get prefCurrentMasterPassword => 'Mot de passe maître actuel';

  @override
  String prefDeviceCurrently(String device) {
    return 'L\'appareil est actuellement en mode $device';
  }

  @override
  String get prefDeviceDarkValue => 'sombre';

  @override
  String get prefDeviceLightValue => 'clair';

  @override
  String prefDiagnosticsSubject(String version) {
    return 'Diagnostics Keyel ($version)';
  }

  @override
  String get prefExampleLogin => 'Exemple de connexion';

  @override
  String get prefFactoryResetBody =>
      'Cela supprimera définitivement le fichier du coffre et tous les identifiants enregistrés. Cette action est irréversible.';

  @override
  String get prefFactoryResetConfirm => 'Tout supprimer';

  @override
  String prefFactoryResetError(String error) {
    return 'Échec de la réinitialisation : $error';
  }

  @override
  String get prefFactoryResetSnack =>
      'Coffre supprimé définitivement. Réinitialisation...';

  @override
  String get prefFactoryResetTitle => 'Réinitialisation complète ?';

  @override
  String get prefFactoryResetVaultSubtitle =>
      'Supprimer définitivement le fichier du coffre et réinitialiser l\'application';

  @override
  String get prefFactoryResetVaultTitle => 'Réinitialiser le coffre';

  @override
  String get prefFoldersSubtitle =>
      'Créer, renommer et supprimer des dossiers du coffre';

  @override
  String get prefHelpAutoLockBody =>
      'Le coffre se verrouille après le délai défini dans Sécurité. Les secrets copiés sont effacés lors du verrouillage et à la fermeture de l\'application, même si l\'effacement temporisé du presse-papiers est réglé sur « Jamais ».';

  @override
  String get prefHelpAutoLockTitle =>
      'Verrouillage automatique et presse-papiers';

  @override
  String get prefHelpKeyboardBody =>
      'Ctrl/⌘ + K ouvre les actions rapides. Ctrl/⌘ + F ouvre la recherche du coffre. Ctrl/⌘ + N crée une nouvelle entrée. Sur Android, le bouton Retour demande confirmation avant d\'ignorer les modifications non enregistrées.';

  @override
  String get prefHelpKeyboardTitle => 'Raccourcis clavier';

  @override
  String get prefHelpRecoveryBody =>
      'Votre clé de récupération à usage unique est le seul moyen de retrouver l\'accès si vous oubliez le mot de passe maître. Conservez-la hors ligne ; Keyel ne peut pas la réinitialiser.';

  @override
  String get prefHelpRecoveryTitle => 'Récupération';

  @override
  String get prefHelpSheetTitle => 'Aide Keyel';

  @override
  String get prefHelpSupportTooltip => 'Aide et assistance';

  @override
  String get prefHelpVaultLocalBody =>
      'Les entrées sont chiffrées sur cet appareil. Keyel n\'utilise aucun compte et n\'envoie rien nulle part, sauf si vous activez explicitement la vérification des fuites ou la synchronisation.';

  @override
  String get prefHelpVaultLocalTitle => 'Votre coffre reste local';

  @override
  String get prefIncorrectPassword => 'Mot de passe incorrect';

  @override
  String get prefLivePreview => 'Aperçu en direct';

  @override
  String get prefLocalEncryptedVault => 'Coffre chiffré local';

  @override
  String get prefLockVaultNow => 'Verrouiller le coffre maintenant';

  @override
  String get prefLockVaultSubtitle =>
      'Effacer immédiatement la clé de déchiffrement de la mémoire';

  @override
  String get prefLoginBadge => 'CONNEXION';

  @override
  String get prefMasterChangedSuccess =>
      'Mot de passe maître modifié avec succès';

  @override
  String get prefMasterPasswordLabel => 'Mot de passe maître';

  @override
  String get prefMatchModeDomain => 'Domaine (y compris les sous-domaines)';

  @override
  String get prefMatchModeExact => 'Hôte exact uniquement';

  @override
  String get prefMatchModeTitle => 'Mode de correspondance';

  @override
  String get prefNewBadge => 'NOUVEAU';

  @override
  String get prefNewMasterPassword => 'Nouveau mot de passe maître';

  @override
  String get prefNewPasswordEmpty =>
      'Le nouveau mot de passe ne peut pas être vide.';

  @override
  String get prefNewPasswordsMismatch =>
      'Les nouveaux mots de passe ne correspondent pas.';

  @override
  String get prefNoVaultBadge => 'Aucun coffre';

  @override
  String get prefOpenSourceLicensesSubtitle =>
      'Bibliothèques incluses dans cette version';

  @override
  String get prefOpenSourceLicensesTitle => 'Licences open source';

  @override
  String get prefPasskeyProviderTitle => 'Fournisseur de clés d\'accès';

  @override
  String get prefPasskeySupportedSubtitle =>
      'Gérer Keyel comme fournisseur de clés d\'accès dans les paramètres système';

  @override
  String get prefPasskeyUnsupportedSubtitle =>
      'Non pris en charge sur cet appareil ou cette version d\'Android';

  @override
  String get prefPasswordRequired => 'Mot de passe requis';

  @override
  String prefReportProblemError(String error) {
    return 'Impossible de préparer le rapport : $error';
  }

  @override
  String get prefReportProblemSubtitle =>
      'Partager un fichier de diagnostic anonymisé (sans secrets)';

  @override
  String get prefScreenshotOffSnack =>
      'Captures d\'écran autorisées pendant le déverrouillage';

  @override
  String get prefScreenshotOnSnack =>
      'Protection contre les captures d\'écran activée';

  @override
  String get prefScreenshotSubtitle =>
      'Bloquer les captures d\'écran et les aperçus des applications récentes lorsque le coffre est ouvert. Les écrans de verrouillage restent protégés dans tous les cas.';

  @override
  String get prefSecurityAccessSection => 'Sécurité et accès';

  @override
  String get prefSecuritySubtitle =>
      'Sécurité adaptée à cet appareil, conservée localement.';

  @override
  String get prefSoftwareUpdateRowTitle => 'Mise à jour logicielle';

  @override
  String get prefStorageDiagnosticsSection => 'Stockage et diagnostics';

  @override
  String get prefStorageNotInitialized => 'Stockage non initialisé';

  @override
  String get prefThemeDarkDescription =>
      'Reste sombre même lorsque votre appareil utilise le mode clair.';

  @override
  String get prefThemeLightDescription =>
      'Reste clair même lorsque votre appareil utilise le mode sombre.';

  @override
  String get prefThemeModeSemantics => 'Mode de thème';

  @override
  String prefThemePreviewSemantics(String palette, String mode) {
    return 'Aperçu du thème : $palette, mode $mode.';
  }

  @override
  String prefThemeSemanticLabel(String label, String description) {
    return 'Thème $label. $description';
  }

  @override
  String prefThemeSemanticWithDevice(
    String label,
    String description,
    String device,
  ) {
    return 'Thème $label. $description L\'appareil est actuellement en mode $device.';
  }

  @override
  String get prefThemeSystemDescription =>
      'Suit l\'apparence de votre appareil et change avec elle.';

  @override
  String get prefTrashSubtitle =>
      'Restaurer les entrées supprimées ou les supprimer définitivement';

  @override
  String prefUpdateAvailable(String version) {
    return 'Mise à jour disponible (v$version)';
  }

  @override
  String get prefVaultLockedBadge => 'Verrouillé';

  @override
  String get prefVaultLockedSnack => 'Coffre verrouillé';

  @override
  String get prefVaultUnlockedBadge => 'Déverrouillé';

  @override
  String get prefVerificationFailed => 'Échec de la vérification';

  @override
  String prefVersionUpToDate(String version) {
    return 'Version $version • À jour';
  }

  @override
  String get prefYourVault => 'Votre coffre';

  @override
  String get secAddCodes => 'Ajouter des codes';

  @override
  String get secAllClear => 'Tout est clair';

  @override
  String get secAllHealthyDetail =>
      'Aucun mot de passe faible, réutilisé ou ancien, et chaque connexion dispose d\'une 2FA.';

  @override
  String get secAllSitesHttps => 'Tous les sites utilisent HTTPS';

  @override
  String secAutoLockSemantics(String label) {
    return 'Verrouillage automatique : $label. Toujours actif.';
  }

  @override
  String get secBadgeChecking => 'Vérification';

  @override
  String get secBiometricTip =>
      'Activez le verrouillage biométrique pour déverrouiller instantanément le coffre à l\'aide de l\'enclave sécurisée de votre appareil.';

  @override
  String get secBreachActiveSemantics =>
      'Vérification des fuites : activée. Rien n\'est envoyé avant que vous appuyiez sur « Vérifier maintenant ».';

  @override
  String get secBreachCheck => 'Vérification des fuites';

  @override
  String get secBreachCheckFailed => 'La vérification des fuites a échoué.';

  @override
  String get secBreachDisabledNotice =>
      'Facultatif : vérifiez les mots de passe enregistrés par rapport aux fuites connues. Rien n\'est envoyé, sauf si vous activez cette option et appuyez sur Vérifier maintenant.';

  @override
  String get secBreachEnabledNotice =>
      'Seuls les 5 premiers caractères d\'un hachage SHA-1 sont envoyés par HTTPS lorsque vous appuyez sur Vérifier maintenant. Les mots de passe et les données du coffre ne quittent jamais cet appareil.';

  @override
  String get secBreachInactiveSemantics =>
      'Vérification des fuites : désactivée. Aucune donnée de mot de passe n\'est envoyée.';

  @override
  String get secCheckNow => 'Vérifier maintenant';

  @override
  String secCheckedSummary(String passwords, String prefixes) {
    return 'Vérification de $passwords sur $prefixes.';
  }

  @override
  String get secChecking => 'Vérification…';

  @override
  String secClipboardActiveSemantics(String value) {
    return 'Effacement du presse-papiers : $value tant que l\'application est ouverte. Le verrouillage l\'efface toujours.';
  }

  @override
  String get secClipboardInactiveSemantics =>
      'Effacement du presse-papiers : uniquement au verrouillage ou à la fermeture de l\'application.';

  @override
  String get secClipboardWipe => 'Effacement du presse-papiers';

  @override
  String get secCredentialsPlainText => 'Identifiants envoyés en texte brut';

  @override
  String get secEnableBreachCheck => 'Activer la vérification des fuites';

  @override
  String get secEnabled => 'Activé';

  @override
  String get secError => 'Erreur';

  @override
  String get secEverythingHealthy => 'Tout semble sain';

  @override
  String secExposureCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expositions',
      one: '$count exposition',
    );
    return '$_temp0';
  }

  @override
  String secExposures(String title, String exposures) {
    return '$title · $exposures';
  }

  @override
  String get secFix => 'Corriger';

  @override
  String get secFixNow => 'Corriger maintenant';

  @override
  String secFoundCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trouvés',
      one: '$count trouvé',
    );
    return '$_temp0';
  }

  @override
  String get secHighCompromiseRisk => 'Risque de compromission élevé';

  @override
  String get secInsecureSitesHttp => 'Sites non sécurisés (HTTP)';

  @override
  String get secInsecureWebsites => 'Sites non sécurisés';

  @override
  String secIssuesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes',
      one: '$count problème',
    );
    return '$_temp0';
  }

  @override
  String secIssuesNeedAttention(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments nécessitent',
      one: '$count élément nécessite',
    );
    return '$_temp0 votre attention';
  }

  @override
  String get secMissingTwoFactor => '2FA absente';

  @override
  String secMoreMatches(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres',
      one: '$count autre',
    );
    return '+ $_temp0';
  }

  @override
  String get secMoreThanOneYearOld => 'Plus d\'un an';

  @override
  String get secNoExposedPasswords => 'Aucun mot de passe exposé trouvé.';

  @override
  String get secNoIssuesFound =>
      'Aucun problème trouvé. Votre coffre est en excellent état.';

  @override
  String get secNothingToFix => 'Rien à corriger ici.';

  @override
  String get secOff => 'Désactivé';

  @override
  String get secOldPasswords => 'Anciens mots de passe';

  @override
  String get secOnLockOnly => 'Uniquement au verrouillage';

  @override
  String secPasswordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe',
      one: '$count mot de passe',
    );
    return '$_temp0';
  }

  @override
  String secPrefixCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count préfixes',
      one: '$count préfixe',
    );
    return '$_temp0';
  }

  @override
  String get secReady => 'Prêt';

  @override
  String get secReusedPasswords => 'Mots de passe réutilisés';

  @override
  String get secReview => 'Examiner';

  @override
  String get secReviewIssues => 'Examiner les problèmes';

  @override
  String get secReviewSettings => 'Vérifier les réglages';

  @override
  String secSavedPasswordsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe enregistrés trouvés dans des fuites :',
      one: '$count mot de passe enregistré trouvé dans des fuites :',
    );
    return '$_temp0';
  }

  @override
  String get secScoreAtRisk => 'À risque';

  @override
  String get secScoreExcellent => 'Excellent';

  @override
  String get secScoreFair => 'Moyen';

  @override
  String get secScoreGood => 'Bon';

  @override
  String get secScreenshotActiveSemantics =>
      'Blocage des captures d\'écran : activé tant que le coffre est déverrouillé. Les écrans de verrouillage sont toujours protégés.';

  @override
  String get secScreenshotBlocking => 'Blocage des captures d\'écran';

  @override
  String get secScreenshotInactiveSemantics =>
      'Blocage des captures d\'écran : désactivé. Les écrans de verrouillage et de déverrouillage restent protégés.';

  @override
  String get secSendHashDialogBody =>
      'Keyel calcule un hachage SHA-1 de chaque mot de passe enregistré sur cet appareil et n\'envoie que les 5 premiers caractères à Have I Been Pwned via HTTPS. Vos mots de passe, identifiants et votre coffre ne sont jamais envoyés. Les vérifications ont lieu uniquement lorsque vous appuyez sur Vérifier maintenant, et vous pouvez désactiver cette option à tout moment.';

  @override
  String get secSendHashDialogTitle =>
      'Envoyer les préfixes de hachage à HIBP ?';

  @override
  String get secSentOverPlainHttp => 'Envoyés en HTTP simple';

  @override
  String get secSharedAcrossServices => 'Partagés entre plusieurs services';

  @override
  String get secStatusAtRisk => 'EN DANGER';

  @override
  String get secStatusReview => 'À VÉRIFIER';

  @override
  String get secStatusSecure => 'SÉCURISÉ';

  @override
  String get secTotpSupported => 'TOTP pris en charge';

  @override
  String get secTurnOff => 'Désactiver';

  @override
  String get secTurnOn => 'Activer';

  @override
  String get secUnlockToCheck => 'Déverrouillez le coffre pour vérifier.';

  @override
  String get secUpdate => 'Mettre à jour';

  @override
  String secVaultHealthLabel(String label) {
    return 'Santé du coffre : $label';
  }

  @override
  String get secVaultLocked => 'Coffre verrouillé';

  @override
  String get secVaultPosture => 'Protection du coffre';

  @override
  String secVaultPostureSemantics(String active, String total) {
    return 'Protection du coffre : $active protections actives sur $total.';
  }

  @override
  String get secVaultPostureSubtitle =>
      'Comment Keyel protège ce coffre en ce moment';

  @override
  String get secVulnerabilityAudit => 'Audit des vulnérabilités';

  @override
  String get secVulnerabilitySummary => 'Résumé des vulnérabilités';

  @override
  String get secWeakPasswords => 'Mots de passe faibles';

  @override
  String get synActionsLabel => 'Actions';

  @override
  String get synChooseFolder => 'Choisir un dossier de synchronisation';

  @override
  String get synChooseFolderFirst =>
      'Choisissez d\'abord un dossier de synchronisation.';

  @override
  String synCodeCopied(String hint) {
    return 'Code d\'appariement copié$hint';
  }

  @override
  String get synCodeStoredCheckbox => 'J’ai enregistré ce code en lieu sûr';

  @override
  String synComplete(num added, num updated, String conflicts) {
    return 'Synchronisation terminée : $added ajoutées, $updated mises à jour$conflicts.';
  }

  @override
  String synConflictCopies(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count copies de conflit',
      one: '$count copie de conflit',
    );
    return ', $_temp0';
  }

  @override
  String get synCreateGroupSubtitle =>
      'Choisissez un dossier et obtenez un code d\'appariement à usage unique.';

  @override
  String get synCreateGroupTitle => 'Créer un groupe de synchronisation';

  @override
  String get synDisableBody =>
      'La synchronisation locale s\'arrête. Les fichiers distants ne sont pas modifiés et peuvent être restaurés en rejoignant à nouveau le groupe avec le code d\'appariement.';

  @override
  String get synDisableConfirm => 'Désactiver la synchronisation';

  @override
  String get synDisableSubtitle =>
      'Arrêter la synchronisation sur cet appareil ; conserver les fichiers distants.';

  @override
  String get synDisableTitle => 'Désactiver la synchronisation ?';

  @override
  String get synDisabled => 'Synchronisation désactivée sur cet appareil.';

  @override
  String get synEnabledShareCode =>
      'Synchronisation activée. Ne partagez le code qu\'une seule fois avec votre autre appareil.';

  @override
  String get synEnabledStatus => 'Synchronisation activée';

  @override
  String get synEnterCodeFirst => 'Saisissez d\'abord le code d\'appariement.';

  @override
  String get synFolderLabel => 'Dossier';

  @override
  String get synFooterNote =>
      'La synchronisation fonctionne uniquement au premier plan et nécessite un coffre déverrouillé. Les données sont chiffrées avec une clé aléatoire qui ne quitte jamais Keyel ; perdre le code d\'appariement implique de créer un nouveau groupe de synchronisation. Conservez également une sauvegarde chiffrée.';

  @override
  String get synGetStartedLabel => 'Commencer';

  @override
  String get synHeadline => 'Synchronisez vos appareils';

  @override
  String get synJoinBody =>
      'Les données distantes du coffre seront fusionnées avec ce coffre lors de la prochaine synchronisation manuelle. Les éléments conflictuels deviennent des copies distinctes ; rien n\'est écrasé ni supprimé silencieusement.';

  @override
  String get synJoinGroup => 'Rejoindre le groupe';

  @override
  String get synJoinTitle => 'Rejoindre ce groupe de synchronisation ?';

  @override
  String get synJoined => 'Vous avez rejoint le groupe de synchronisation.';

  @override
  String synLastSync(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get synLoadingStatus => 'Lecture de l\'état de synchronisation…';

  @override
  String get synLocalOnlyStatus =>
      'Votre coffre reste uniquement sur cet appareil.';

  @override
  String get synNever => 'Jamais';

  @override
  String get synNoFolder =>
      'Aucun dossier n\'est défini pour la synchronisation. Désactivez-la puis réactivez-la.';

  @override
  String get synNotSet => 'Non défini';

  @override
  String get synOffStatus => 'Synchronisation désactivée';

  @override
  String get synOrJoin => 'Ou rejoignez un groupe existant';

  @override
  String get synPairingCodeLabel => 'Code d\'appariement';

  @override
  String get synSaveCodeBody =>
      'Ce code est un secret au porteur : toute personne le connaissant peut lire le coffre synchronisé. Conservez-le hors ligne et saisissez-le une seule fois sur votre autre appareil. Il ne sera plus affiché après cette fenêtre.';

  @override
  String get synSaveCodeTitle => 'Enregistrez ce code d’appariement';

  @override
  String get synShowCodeSubtitle =>
      'Appairez un autre appareil avec ce groupe de synchronisation.';

  @override
  String get synShowCodeTitle => 'Afficher le code d\'appariement';

  @override
  String get synStatusLabel => 'État';

  @override
  String get synSubtitle =>
      'Facultative, manuelle et chiffrée de bout en bout. Keyel n\'héberge aucun serveur de synchronisation : votre propre outil déplace les fichiers chiffrés entre les appareils.';

  @override
  String get synSyncNowSubtitle =>
      'Récupérer les modifications distantes, fusionner et envoyer celles de cet appareil.';

  @override
  String get synSyncNowTitle => 'Synchroniser maintenant';

  @override
  String get synThisDevice => 'Cet appareil';

  @override
  String get synUnknown => 'Inconnu';

  @override
  String trashAutoDelete(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'Suppression automatique dans $_temp0';
  }

  @override
  String get trashBannerMessage =>
      'Les éléments supprimés restent ici pendant 30 jours, puis disparaissent automatiquement.';

  @override
  String get trashDeleteForever => 'Supprimer définitivement';

  @override
  String trashDeleteForeverBody(String title) {
    return '« $title » ne pourra pas être récupéré après cette action.';
  }

  @override
  String get trashDeleteForeverTitle => 'Supprimer définitivement ?';

  @override
  String get trashDeleted => 'Supprimé';

  @override
  String get trashEmptied => 'Corbeille vidée';

  @override
  String get trashEmptyAction => 'Vider la corbeille';

  @override
  String trashEmptyConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées de la corbeille seront supprimées définitivement.',
      one: '$count entrée de la corbeille sera supprimée définitivement.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyConfirmTitle => 'Vider la corbeille ?';

  @override
  String get trashEmptyMessage =>
      'Les entrées supprimées apparaissent ici pendant 30 jours avant d\'être définitivement effacées.';

  @override
  String get trashLoading => 'Chargement des éléments supprimés…';

  @override
  String get trashPermanentlyDeleted => 'Entrée supprimée définitivement';

  @override
  String trashRestored(String title) {
    return '« $title » restauré';
  }

  @override
  String get vaultAddFirstItem => 'Ajouter votre premier élément';

  @override
  String get vaultAddToFavorites => 'Ajouter aux favoris';

  @override
  String get vaultAllFolders => 'Tous les dossiers';

  @override
  String get vaultAlreadyHaveVault => 'J\'ai déjà un coffre';

  @override
  String get vaultBackToUnlock => 'Retour au déverrouillage';

  @override
  String get vaultBiometricOptionalHint =>
      'Facultatif — ouvrez le coffre avec votre empreinte ou votre visage.';

  @override
  String get vaultChooseMasterPassword =>
      'Veuillez choisir un mot de passe principal.';

  @override
  String get vaultClearSelection => 'Effacer la sélection';

  @override
  String get vaultConfirmMasterPassword =>
      'Confirmer le mot de passe principal';

  @override
  String get vaultConfirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get vaultConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get vaultCopied => 'Copié !';

  @override
  String get vaultCopiedCardNumber =>
      'Numéro de carte copié dans le presse-papiers';

  @override
  String get vaultCopiedPassword => 'Mot de passe copié';

  @override
  String get vaultCopiedRecoveryKey =>
      'Clé de récupération copiée dans le presse-papiers';

  @override
  String get vaultCopiedUsername =>
      'Nom d\'utilisateur copié dans le presse-papiers';

  @override
  String get vaultCopyCard => 'Copier la carte';

  @override
  String get vaultCopyCredential => 'Copier l\'identifiant';

  @override
  String get vaultCopyKey => 'Copier la clé';

  @override
  String get vaultCopyRecoveryKey => 'Copier la clé';

  @override
  String get vaultCreateEncryptedVault => 'Créer le coffre chiffré';

  @override
  String get vaultCreateIntro =>
      'Créez votre coffre chiffré hors ligne. Vous seul détenez la clé de vos identifiants.';

  @override
  String get vaultCreateMasterPasswordSubtitle =>
      'C\'est la seule clé de votre coffre. Nous ne pouvons pas la réinitialiser pour vous.';

  @override
  String get vaultCreateMasterPasswordTitle =>
      'Créez votre mot de passe principal';

  @override
  String get vaultCreatingVault => 'Création du coffre…';

  @override
  String vaultDeleteItemsTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
    );
    return 'Supprimer $_temp0 ?';
  }

  @override
  String get vaultDeleteManyItemsBody =>
      'Ces éléments seront déplacés dans la corbeille.';

  @override
  String get vaultDeleteOneItemBody =>
      'Cet élément sera déplacé dans la corbeille.';

  @override
  String get vaultEmpty => 'Votre coffre est vide';

  @override
  String get vaultEmptyHint =>
      'Commencez à ajouter des mots de passe, des cartes bancaires ou des notes sécurisées. Tout est stocké localement avec un chiffrement à connaissance nulle.';

  @override
  String get vaultEmptySearchHint =>
      'Essayez un autre terme de recherche ou un autre filtre.';

  @override
  String vaultEntriesSavedOffline(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments enregistrés',
      one: '$count élément enregistré',
    );
    return '$_temp0 hors ligne';
  }

  @override
  String vaultEntryPinnedToFavorites(String title) {
    return '$title ajouté aux favoris';
  }

  @override
  String vaultEntryRemovedFromFavorites(String title) {
    return '$title retiré des favoris';
  }

  @override
  String get vaultExitSelection => 'Quitter la sélection';

  @override
  String get vaultFavorite => 'Ajouter aux favoris';

  @override
  String get vaultFilterAll => 'Tout';

  @override
  String get vaultFilterCards => 'Cartes';

  @override
  String get vaultFilterFavorites => 'Favoris';

  @override
  String get vaultFilterLogins => 'Connexions';

  @override
  String get vaultFilterNotes => 'Notes';

  @override
  String get vaultFilterTwoFactor => '2FA';

  @override
  String get vaultFolder => 'dossier';

  @override
  String get vaultForgotPassword => 'Mot de passe oublié ?';

  @override
  String get vaultGetStarted => 'Commencer';

  @override
  String get vaultHidePassword => 'Masquer le mot de passe';

  @override
  String vaultItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsMovedToTrash(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments déplacés',
      one: '$count élément déplacé',
    );
    return '$_temp0 dans la corbeille';
  }

  @override
  String vaultItemsPinnedToFavorites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés aux favoris',
      one: '$count élément ajouté aux favoris',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsRemovedFromFavorites(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments retirés des favoris',
      one: '$count élément retiré des favoris',
    );
    return '$_temp0';
  }

  @override
  String vaultItemsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments sélectionnés',
      one: '$count élément sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get vaultKindCard => 'Carte bancaire';

  @override
  String get vaultKindLogin => 'Connexion';

  @override
  String get vaultKindNote => 'Note sécurisée';

  @override
  String get vaultKindPasskey => 'Clé d\'accès';

  @override
  String get vaultLoadingList => 'Ouverture de votre coffre…';

  @override
  String get vaultLocked => 'Coffre verrouillé';

  @override
  String get vaultMasterPasswordCapitalized => 'Mot de passe principal';

  @override
  String get vaultMasterPasswordChanged =>
      'Votre mot de passe principal a changé. Reconfigurez le déverrouillage rapide.';

  @override
  String get vaultMasterPasswordLabel => 'Mot de passe principal';

  @override
  String get vaultMoveToFolder => 'Déplacer vers un dossier';

  @override
  String vaultMovedItemsToFolder(num count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments déplacés',
      one: '$count élément déplacé',
    );
    return '$_temp0 vers $folder';
  }

  @override
  String get vaultNewItem => 'Nouvel élément';

  @override
  String get vaultNewMasterPassword => 'Nouveau mot de passe principal';

  @override
  String get vaultNoExistingVault =>
      'Aucun coffre existant n\'a été trouvé sur cet appareil.';

  @override
  String get vaultNoFolder => 'Aucun dossier';

  @override
  String get vaultNoItemSelected => 'Aucun élément sélectionné';

  @override
  String get vaultNoMatchesFound => 'Aucun résultat';

  @override
  String get vaultNothingToCopy => 'Rien à copier';

  @override
  String vaultOpenEntry(String title) {
    return 'Ouvrir $title';
  }

  @override
  String get vaultOpenMyVault => 'Ouvrir mon coffre';

  @override
  String get vaultOr => 'OU';

  @override
  String get vaultPasswordsMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get vaultQuickUnlockLater =>
      'Vous pouvez activer le déverrouillage rapide biométrique plus tard dans les paramètres.';

  @override
  String get vaultQuickUnlockOn =>
      'Le déverrouillage rapide est activé. Vous pouvez le désactiver à tout moment dans les paramètres.';

  @override
  String get vaultQuickUnlockSetupAgain =>
      'Le déverrouillage rapide doit être reconfiguré.';

  @override
  String get vaultReadySubtitle =>
      'Keyel se verrouille automatiquement après une minute en arrière-plan. Vous pouvez modifier ce réglage plus tard dans les paramètres.';

  @override
  String get vaultReadyTitle => 'Votre coffre est prêt';

  @override
  String get vaultRecentSearches => 'Recherches récentes';

  @override
  String vaultRecoveryExportError(String error) {
    return 'Impossible d\'exporter la clé de récupération ($error).';
  }

  @override
  String vaultRecoveryFileText(String key) {
    return 'Clé de récupération du coffre Keyel\n==========================\n\nCe fichier contient la clé de récupération de votre coffre Keyel.\n\nATTENTION : toute personne disposant de cette clé peut ouvrir votre coffre. Conservez-la\nhors ligne et privée, et traitez-la comme le mot de passe principal lui-même.\n\nSi vous oubliez votre mot de passe principal, cette clé est le seul moyen de\nretrouver l\'accès à votre coffre. Keyel n\'a pas de compte et pas de sauvegarde cloud.\n\nVotre clé de récupération :\n\n$key\n';
  }

  @override
  String get vaultRecoveryKeyLabel => 'Clé de récupération';

  @override
  String get vaultRecoveryKeyTitle => 'Clé de récupération';

  @override
  String get vaultRecoveryKeyWarning =>
      'Notez ou conservez cette clé de récupération hors ligne en toute sécurité. Si vous oubliez votre mot de passe principal, c\'est la SEULE façon de retrouver l\'accès à votre coffre.';

  @override
  String get vaultRemoveFromFavorites => 'Retirer des favoris';

  @override
  String get vaultResetMasterPasswordHint =>
      'Saisissez votre clé de récupération pour définir un nouveau mot de passe principal et ouvrir votre coffre.';

  @override
  String get vaultResetMasterPasswordTitle =>
      'Réinitialisez votre mot de passe principal';

  @override
  String get vaultResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get vaultResetting => 'Réinitialisation…';

  @override
  String get vaultResults => 'Résultats';

  @override
  String get vaultSaveFile => 'Enregistrer le fichier';

  @override
  String get vaultSaveRecoveryKeySubtitle =>
      'Si vous oubliez le mot de passe principal, cette clé est le seul moyen de retrouver l\'accès à votre coffre. Elle n\'est affichée qu\'une seule fois.';

  @override
  String get vaultSaveRecoveryKeyTitle =>
      'Enregistrez votre clé de récupération';

  @override
  String get vaultSavedRecoveryKey => 'Je l\'ai enregistrée';

  @override
  String get vaultSearchHint =>
      'Rechercher des éléments, des étiquettes ou des notes...';

  @override
  String get vaultSelectAll => 'Tout sélectionner';

  @override
  String vaultSelectEntry(String title) {
    return 'Sélectionner $title';
  }

  @override
  String get vaultSelectItemHint =>
      'Sélectionnez un élément dans la liste pour voir et gérer ses détails.';

  @override
  String get vaultShowPassword => 'Afficher le mot de passe';

  @override
  String get vaultStoredKeyConfirmation =>
      'J\'ai enregistré cette clé en lieu sûr';

  @override
  String get vaultToggleFavorite => 'Ajouter/retirer des favoris';

  @override
  String vaultTooManyAttempts(num seconds) {
    return 'Trop de tentatives. Réessayez dans $seconds s.';
  }

  @override
  String get vaultTopBarTitle => 'Coffre Keyel';

  @override
  String get vaultUndo => 'Annuler';

  @override
  String get vaultUnfavorite => 'Retirer des favoris';

  @override
  String get vaultUnlockHint =>
      'Saisissez votre mot de passe principal pour ouvrir votre coffre.';

  @override
  String get vaultUnlockWithBiometrics => 'Déverrouiller avec la biométrie';

  @override
  String get vaultUnlocking => 'Ouverture…';

  @override
  String get vaultViewNote => 'Voir la note';

  @override
  String get vaultViewPasskey => 'Voir la clé d\'accès';

  @override
  String get vaultWelcomeBack => 'Bon retour';

  @override
  String get vaultWelcomeSubtitle =>
      'Vos mots de passe restent chiffrés sur cet appareil. Il n\'y a ni compte, ni cloud, ni télémétrie.';

  @override
  String get vaultWelcomeToKeyel => 'Bienvenue sur Keyel';

  @override
  String get wearClearAll => 'Tout supprimer de la montre';

  @override
  String get wearClearMessage =>
      'Les secrets sont supprimés de cette montre. Vous pouvez les renvoyer depuis le téléphone. Votre coffre n\'est pas modifié.';

  @override
  String get wearClearTitle => 'Supprimer tous les codes de la montre ?';

  @override
  String get wearCleared => 'Tous les codes ont été supprimés de la montre';

  @override
  String get wearEmpty =>
      'Aucune de vos entrées ne contient de mot de passe à usage unique.';

  @override
  String get wearFailed => 'Impossible de joindre la montre';

  @override
  String get wearInfo =>
      'Envoyez un secret TOTP à une montre Wear OS associée. Le secret n\'est stocké que sur la montre, chiffré avec la clé de l\'appareil. L\'envoi nécessite un coffre déverrouillé. Les codes sont masqués quand vous quittez l\'application montre et ne sont jamais copiés dans le presse-papiers.';

  @override
  String get wearSend => 'Envoyer';

  @override
  String get wearSent => 'Secret envoyé à la montre';

  @override
  String get wearTitle => 'Codes montre';

  @override
  String get wearUnavailable =>
      'Aucune montre Wear OS associée n\'est accessible. Ouvrez Keyel sur votre téléphone avec la montre à proximité, puis réessayez.';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get quickActionOpenEntry => 'Ouvrir une entrée';

  @override
  String get quickActionsTitle => 'Actions rapides';

  @override
  String get quickActionsHint => 'Rechercher une entrée ou choisir une action';

  @override
  String get quickActionsNoResults => 'Aucune entrée correspondante';

  @override
  String get quickActionsTooltip => 'Actions rapides (Ctrl/⌘ + K)';

  @override
  String get paneResizeLabel => 'Redimensionner le volet de liste';
}
