/// French product copy for the auth/session slice.
class AppStrings {
  AppStrings._();

  static const appName = 'SpeedyGo';
  static const splashLoading = 'Chargement de SpeedyGo…';

  static const phoneTitle = 'Entrez votre numéro de téléphone';
  static const phoneSubtitle =
      'Nous vous enverrons un code de confirmation par SMS.';
  static const phoneHint = '555 12 34 56';
  static const phonePrefix = '+213';
  static const phoneSmsNote = 'Les frais de SMS standard peuvent s’appliquer.';
  static const phoneInvalid = 'Saisissez un numéro algérien valide.';
  static const continueLabel = 'Continuer';
  static const needHelp = 'Besoin d’aide ?';
  static const helpUnavailable =
      'L’assistance sera disponible dans une prochaine version.';
  static const back = 'Retour';

  static const otpTitle = 'Vérification du code';
  static String otpSentTo(String masked) => 'Code envoyé au $masked';
  static const editNumber = 'Modifier';
  static const verify = 'Vérifier';
  static const otpIncomplete = 'Saisissez les 6 chiffres du code.';
  static String resendIn(String clock) => 'Renvoyer le code dans $clock';
  static const resend = 'Renvoyer le code';

  static const restoreTitle = 'Session restaurée';
  static const restoreLoading = 'Restauration de votre session…';
  static const restoreOfflineTitle = 'Connexion indisponible';
  static const restoreOffline =
      'Votre session n’a pas été annulée. Réessayez lorsque le réseau est de retour.';
  static const restoreRetry = 'Réessayer';
  static const restoreOtherAccount = 'Se connecter avec un autre compte';
  static const restoreContinue = 'Continuer';

  static const welcomeDiscoverTitle = 'Découvrez';
  static const welcomeDiscoverBody =
      'Explorez les meilleurs restaurants et commerces de votre quartier. Boulangeries, pharmacies et plus encore, à portée de main.';
  static const welcomeOrderTitle = 'Commandez';
  static const welcomeOrderBody =
      'Des prix transparents, des frais de livraison réduits et un paiement sécurisé. Payez en espèces ou par CIB/EDAHABIA.';
  static const welcomeTrackTitle = 'Suivez';
  static const welcomeTrackBody =
      'Suivez votre commande en temps réel, de la préparation en cuisine jusqu’à votre porte avec notre suivi en direct sur carte.';
  static const welcomeTrackLiveTitle = 'Le livreur arrive';
  static const welcomeTrackLiveEta = 'Arrivée prévue dans 8 min';
  static const skip = 'Passer';
  static const next = 'Suivant';
  static const start = 'Commencer';

  static const profileTitle = 'Profil';
  static const profileStep = 'Étape 2 sur 2';
  static const fullNameLabel = 'Nom complet';
  static const fullNameHint = 'Ex: Amel Benali';
  static const fullNameRequired = 'Le nom complet est obligatoire.';
  static const profileConsent =
      'En continuant, vous acceptez nos Conditions Générales et confirmez avoir lu notre Politique de Confidentialité.';
  static const profileSaving = 'Traitement…';
  static const profilePhotoUnavailable =
      'La photo de profil n’est pas encore prise en charge.';

  static const landingTitle = 'Intégration SpeedyGo';
  static const landingBody =
      'La connexion fonctionne. Le catalogue, le panier et le suivi seront branchés dans une prochaine étape. Cet écran n’est pas l’accueil définitif.';
  static String landingHello(String name) => 'Bonjour, $name';

  static String homeGreeting(String name, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    final hello = hour >= 18 || hour < 6 ? 'Bonsoir' : 'Bonjour';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return '$hello, $first 👋';
  }

  static const languageTitle = 'Choisissez votre langue';
  static const languageSubtitle =
      'Vous pourrez changer la langue plus tard depuis votre profil.';
  static const languageFrench = 'Français';
  static const languageFrenchHint = 'De gauche à droite';
  static const languageArabic = 'العربية';
  static const languageArabicHint = 'من اليمين إلى اليسار';
  static const languageArabicUnavailable =
      'Indisponible pour le moment. L’application reste en français.';
  static const languageArabicDisabled = 'Bientôt disponible';
  static const previewUnavailable =
      'Cet aperçu n’est pas disponible dans la navigation normale.';
  static const previewBanner =
      'Aperçu développement — pas la navigation produit.';
  static const previewEnableTitle = 'Aperçu de navigation';
  static const previewEnableBody =
      'Répertoire des écrans placeholder. Aucune donnée métier. Désactivé en release.';
  static const previewEnableAction = 'Ouvrir l’aperçu';
  static const ordersEmpty =
      'Aucune commande à afficher. L’historique n’est pas encore chargé.';
  static const nearbyEmpty =
      'Aucun commerçant à proximité n’est chargé pour le moment.';
  static const languageTermsPrefix = 'En continuant, vous acceptez nos ';
  static const languageTermsLink = 'Conditions d’utilisation';

  static const tabHome = 'Accueil';
  static const tabSearch = 'Recherche';
  static const tabOrders = 'Commandes';
  static const tabAlerts = 'Alertes';
  static const tabProfile = 'Profil';

  static const navOnlyBadge = 'Navigation seule';
  static const unsupportedBadge = 'API absente';
  static const productDecisionBadge = 'Décision produit';
  static const liveAuthBadge = 'Auth réelle';
  static const navFixtureNote =
      'Identifiant de navigation uniquement. Aucune opération métier n’est exécutée.';
  static const navBlocked =
      'Cette action n’est pas branchée. Aucune opération n’a été effectuée.';
  static const navUnsupported =
      'Cette fonction n’existe pas côté serveur. Aucune opération n’a été effectuée.';
  static const navProductDecision =
      'Contrat incomplet. Aucune opération n’a été effectuée.';
  static const allScreens = 'Tous les écrans';
  static const allScreensHint =
      'Références Customer. Les actions métier restent non branchées.';
  static const deliverTo = 'Livrer à';
  static const deliverToUnset = 'Adresse non définie';
  static const deliverToSaved = 'Adresse enregistrée';
  static const searchHint = 'Rechercher un restaurant ou un produit';
  static const categories = 'Catégories';
  static const seeAll = 'Tout voir';
  static const nearbyMerchants = 'Commerçants à proximité';
  static const specialOffer = 'Offre spéciale';
  static const promoHeadline = '150 DZD offerts';
  static const promoCondition = 'Sur toute commande dès 1,500 DZD';
  static const promoCode = 'SPEEDY150';
  static const categoryRestaurants = 'Restaurants';
  static const categoryBakeries = 'Boulangeries';
  static const categoryGroceries = 'Épiceries';
  static const categoryPharmacies = 'Pharmacies';
  static const categoryDesserts = 'Desserts';
  static const activeOrder = 'Commande en cours';
  static const navPreview = 'Aperçu de navigation';
  static const closeLabel = 'Fermer';
  static const saveUnavailable = 'Enregistrement non branché.';
  static const submitUnavailable = 'Soumission non branchée.';
  static const deleteUnavailable =
      'Aucune route de suppression de compte. Le compte n’a pas été modifié.';
  static const favoritesUnavailable =
      'Aucun favori n’existe côté serveur. Rien n’a été ajouté.';
  static const promotionsUnavailable =
      'Aucune liste de promotions Customer. Le code n’a pas été appliqué.';
  static const notificationPrefsUnavailable =
      'Aucun stockage de préférences de notification. Rien n’a été enregistré.';
  static const catalogUnwired =
      'Catalogue, photos et éligibilité livraison ne sont pas branchés.';
  static const openPreview = 'Ouvrir l’écran (aperçu)';
  static const arabicRtlPending = 'RTL arabe non implémenté';
  static const logout = 'Déconnexion';
  static const logoutConfirmTitle =
      'Voulez-vous vous déconnecter de SpeedyGo ?';
  static const logoutConfirmBody =
      'Vous allez quitter cette session sur cet appareil.';
  static const logoutSessionActive = 'Session active sur cet appareil';
  static const logoutNoteLocal = 'La session de cet appareil sera fermée.';
  static const logoutNoteReconnect =
      'Vous devrez vous reconnecter pour utiliser SpeedyGo sur cet appareil.';
  static const logoutConfirmAction = 'Se déconnecter';
  static const cancel = 'Annuler';
  static const logoutLocalOnly =
      'Vous êtes déconnecté sur cet appareil. La révocation serveur n’a pas pu être confirmée.';

  static const offline = 'Vérifiez votre connexion, puis réessayez.';
  static const retry = 'Réessayer';
  static const unexpected = 'Une erreur s’est produite. Réessayez.';
  static const sessionExpired = 'Votre session a expiré. Connectez-vous.';
  static const reauthRequired =
      'Reconnectez-vous pour continuer. L’ancienne session n’est plus utilisable ici.';

  static String errorForCode(String? code) {
    switch (code) {
      case 'AUTH_INVALID_IDENTIFIER':
        return 'Ce numéro n’est pas valide.';
      case 'AUTH_INVALID_OTP':
        return 'Code incorrect. Réessayez.';
      case 'AUTH_OTP_EXPIRED':
        return 'Ce code a expiré. Demandez-en un nouveau.';
      case 'AUTH_OTP_ATTEMPTS_EXCEEDED':
        return 'Trop de tentatives. Demandez un nouveau code.';
      case 'AUTH_RATE_LIMITED':
        return 'Veuillez patienter avant de renvoyer un code.';
      case 'AUTH_INVALID_TOKEN':
      case 'AUTH_SESSION_REVOKED':
      case 'AUTH_SESSION_EXPIRED':
        return sessionExpired;
      case 'AUTH_ACCOUNT_SUSPENDED':
      case 'AUTH_ACCOUNT_DISABLED':
        return 'Ce compte ne peut pas se connecter.';
      case 'CUSTOMER_PROFILE_ALREADY_EXISTS':
        return 'Votre profil existe déjà.';
      case 'CUSTOMER_PROFILE_NOT_FOUND':
        return 'Profil introuvable. Réessayez.';
      case 'VALIDATION_ERROR':
        return 'Certaines informations sont invalides.';
      default:
        return unexpected;
    }
  }
}
