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
  static const supportListTitle = 'Mes demandes';
  static const supportNewTitle = 'Signaler un problème';
  static const supportDetailTitle = 'Ticket support';
  static const supportEmpty = 'Vous n’avez pas encore de demande.';
  static const supportListLoadError =
      'Impossible de charger vos demandes de support.';
  static const supportDetailLoadError =
      'Impossible de charger ce ticket.';
  static const supportBodyLabel = 'Description du problème';
  static const supportBodyHint =
      'Veuillez décrire le problème rencontré en détail. Ne partagez pas de mots de passe.';
  static const supportBodyInvalid =
      'Le message doit contenir entre 1 et 4 000 caractères.';
  static const supportSend = 'Envoyer le signalement';
  static const supportSending = 'Envoi en cours…';
  static const supportReplySend = 'Envoyer';
  static const supportReplyHint = 'Écrire un message…';
  static const supportReplyClosed =
      'Ce ticket est clôturé. Vous ne pouvez plus y répondre.';
  static const supportOrderLinked = 'Commande liée';
  static const supportOrderOptional =
      'La commande liée est celle depuis laquelle vous avez ouvert le formulaire.';
  static const supportOrderLinkedFallback = 'Commande liée';
  static const supportOrderLinkedLoading = 'Chargement de la commande…';
  static const supportCreateUncertain =
      'L’envoi n’a pas été confirmé. Votre texte est conservé. Consultez Mes demandes avant de renvoyer.';
  static const supportReplyUncertain =
      'L’envoi du message n’a pas été confirmé. Votre brouillon est conservé. Actualisez avant de renvoyer.';
  static const supportMutationUncertain =
      'Le serveur n’a pas confirmé l’opération. Aucun renvoi automatique.';
  static const supportCheckList = 'Voir Mes demandes';
  static const supportRefresh = 'Actualiser';
  static const supportNewRequest = 'Nouvelle demande';
  static const supportStatusOpen = 'Ouvert';
  static const supportStatusInProgress = 'En cours';
  static const supportStatusWaitingCustomer = 'En attente de votre réponse';
  static const supportStatusResolved = 'Résolu';
  static const supportStatusClosed = 'Fermé';
  static const supportStatusUnknown = 'Statut inconnu';
  static const supportPriorityLabel = 'Priorité';
  static const supportPriorityLow = 'Basse';
  static const supportPriorityNormal = 'Normale';
  static const supportPriorityHigh = 'Haute';
  static const supportPriorityUnknown = 'Priorité inconnue';
  static const supportYou = 'Vous';
  static const supportAgent = 'SpeedyGo Support';
  static const supportMessageConfirmed = 'Message confirmé';
  static const supportNoCancelHint =
      'Cette demande n’annule pas une commande et ne déclenche pas de remboursement.';
  static const supportReportProblem = 'Signaler un problème';
  static const supportLoadMore = 'Voir plus';
  static const supportLoadingMore = 'Chargement…';
  static const supportCentreAide = 'Centre d’aide';
  static const supportTicketsLabel = 'Mes demandes';
  static const ratingTitle = 'Noter ma commande';
  static const ratingWriteTitle = 'Rédiger un avis';
  static const ratingMerchantPrompt = 'Comment était votre repas ?';
  static const ratingDriverPrompt = 'Comment s’est passée la livraison ?';
  static const ratingDriverLabel = 'Votre livreur SpeedyGo';
  static const ratingWriteDetailed = 'Rédiger un avis détaillé';
  static const ratingSendScores = 'Envoyer les notes';
  static const ratingSkip = 'Passer';
  static const ratingPublish = 'Envoyer l’avis';
  static const ratingCommentLabel = 'Votre expérience';
  static const ratingCommentHint =
      'Décrivez votre expérience. Ne partagez pas de coordonnées personnelles.';
  static const ratingPrivacyNote =
      'Pour votre sécurité, ne partagez pas vos coordonnées personnelles (téléphone, adresse exacte) dans votre avis.';
  static const ratingScoreRequired = 'Choisissez une note de 1 à 5 étoiles.';
  static const ratingCommentInvalid =
      'Le commentaire ne peut pas dépasser 2 000 caractères.';
  static const ratingOrderIneligible =
      'Seules les commandes terminées peuvent être notées.';
  static const ratingAlreadyDone = 'Vous avez déjà noté cette commande.';
  static const ratingSuccess = 'Merci, votre note a été enregistrée.';
  static const ratingSubmitUncertain =
      'L’envoi n’a pas été confirmé. Votre brouillon est conservé. Actualisez avant de renvoyer.';
  static const ratingDriverUncertainPartial =
      'La note commerce est enregistrée. La note livreur n’est pas confirmée — actualisez avant de renvoyer uniquement le livreur.';
  static const ratingDriverFailedPartial =
      'La note commerce est enregistrée. La note livreur a échoué — vous pouvez réessayer le livreur.';
  static const ratingMutationUncertain =
      'Le serveur n’a pas confirmé la note. Aucun renvoi automatique.';
  static const ratingLoadError = 'Impossible de charger l’état de notation.';
  static const ratingSending = 'Envoi en cours…';
  static const ratingEntry = 'Noter la commande';
  static const ratingReviewsTitle = 'Avis';
  static String ratingReviewsHeading(String merchantName) =>
      'Avis — $merchantName';
  static const ratingReviewsUnsupported =
      'Les avis individuels ne sont pas disponibles. Voici la note moyenne confirmée par SpeedyGo.';
  static const ratingReviewsUnsupportedEmpty =
      'Les avis individuels ne sont pas disponibles.';
  static const ratingNoPublicFeedEmpty =
      'Les commentaires restent privés. Aucune moyenne n’est affichée tant que le commerce n’a pas de notes.';
  static const ratingReviewsEmpty = 'Aucune note pour ce commerce pour le moment.';
  static const ratingReviewsLoadError =
      'Impossible de charger la note de ce commerce.';
  static const ratingAverageLabel = 'Note moyenne';
  static const ratingCountLabel = 'avis';
  static const ratingNoPublicFeed =
      'Les commentaires restent privés. Seuls le total et la moyenne du commerce sont affichés.';
  static const ratingDistributionUnavailable =
      'Répartition détaillée non fournie par le serveur.';
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

  static const welcomeWordmark = 'SPEEDYGO';
  static const welcomeDiscoverEyebrow = 'DÉCOUVREZ';
  static const welcomeDiscoverTitle = 'Vos envies,\nà portée de main.';
  static const welcomeDiscoverBody =
      'Explorez les commerces et trouvez\nce qui vous fait plaisir.';
  static const welcomeOrderEyebrow = 'COMMANDEZ';
  static const welcomeOrderTitle = 'Un coup de cœur,\nquelques clics.';
  static const welcomeOrderBody =
      'Choisissez vos produits et préparez\nvotre commande en toute simplicité.';
  static const welcomeTrackEyebrow = 'SUIVEZ';
  static const welcomeTrackTitle = 'Votre commande,\nà chaque étape.';
  static const welcomeTrackBody =
      'De la préparation à la livraison,\nsuivez son avancement dans l’application.';
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
  static const profileConsentPrefix = 'En continuant, vous acceptez nos ';
  static const profileTermsLink = 'Conditions Générales';
  static const profileConsentMid = ' et confirmez avoir lu notre ';
  static const profilePrivacyLink = 'Politique de Confidentialité';
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
    return '$hello, $first \u{1F44B}';
  }

  static const languageTitle = 'Choisissez votre langue';
  static const languageSubtitle =
      'Vous pourrez changer la langue plus tard depuis votre profil.';
  static const languageFrench = 'Français';
  static const languageFrenchHint = 'De gauche à droite';
  static const languageFrenchHintSettings = 'Couramment utilisée en Algérie';
  static const languageArabic = 'العربية';
  static const languageArabicLabel = 'Arabe (العربية)';
  static const languageArabicHint = 'من اليمين إلى اليسار';
  static const languageArabicHintSettings = 'Langue nationale et officielle';
  static const languageArabicUnavailable =
      'Indisponible pour le moment. L’application reste en français.';
  static const languageArabicDisabled = 'Bientôt disponible';
  static const languageSettingsSubtitle =
      'Choisissez votre langue de préférence pour l’application SpeedyGo.';
  static const languageDirectionHeading = 'Aperçu de la direction';
  static const languageDirectionLtr = 'LTR (Gauche à Droite)';
  static const languageDirectionRtl = 'RTL';
  static const languageDirectionPreviewTitle = 'Accueil';
  static const languageDirectionPreviewSubtitle = 'Navigation actuelle';
  static const languageSessionNote =
      'Vos données et votre session actuelle seront conservées. Seul le français est disponible pour le moment ; aucun redémarrage n’est requis.';
  static const languageSave = 'Enregistrer les modifications';
  static const previewUnavailable =
      'Cet aperçu n’est pas disponible dans la navigation normale.';
  static const previewBanner =
      'Aperçu développement — pas la navigation produit.';
  static const previewEnableTitle = 'Aperçu de navigation';
  static const previewEnableBody =
      'Répertoire des écrans placeholder. Aucune donnée métier. Désactivé en release.';
  static const previewEnableAction = 'Ouvrir l’aperçu';
  static const ordersEmpty = 'Aucune commande pour le moment.';
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
  static const searchHint = 'Rechercher un commerce ou produit';
  static const categories = 'Catégories';
  static const seeAll = 'Tout voir';
  static const allCategoriesTitle = 'Toutes les catégories';
  static const categoriesSearchHint = 'Rechercher une catégorie...';
  static const categoriesExploreHeading = 'Explorer par rayon';
  static const categoriesEmpty = 'Aucune catégorie active.';
  static const categoriesSearchEmpty =
      'Aucune catégorie ne correspond à votre recherche.';
  static const categoriesLoadError =
      'Impossible de charger les catégories.';
  static const coverLoadError = 'Image indisponible';
  static const nearbyMerchants = 'Commerçants à proximité';
  static const storefrontsTitle = 'Commerces';
  static const storefrontsEmpty = 'Aucun commerce visible.';
  static const storefrontsOpenNow = 'Ouverts maintenant';
  static const storefrontsOpenNowEmpty =
      'Aucun commerce ouvert pour le moment.';
  static const storefrontsShowAll = 'Afficher tous les commerces';
  static const hoursOpen = 'Ouvert';
  static const hoursOpenUntil = 'Ouvert jusqu’à';
  static const hoursClosed = 'Fermé';
  static const hoursUnconfigured = 'Horaires non renseignés';
  static const hoursClosesAt = 'Ferme à';
  static const hoursOpensAt = 'Ouvre à';
  static const allProducts = 'Tous';
  static const productsEmpty = 'Aucun produit disponible dans cette catégorie.';
  static const productsEmptyUnfiltered =
      'Aucun produit disponible pour le moment.';
  static const searchEmpty = 'Aucun résultat pour cette recherche.';
  static const searchNeedTwoChars = 'Saisissez au moins 2 caractères.';
  static const searchStorefronts = 'Commerces';
  static const searchProducts = 'Produits';
  static const storefrontInfo = 'Infos';
  static const storefrontInfoScreenTitle = 'Infos sur le marchand';
  static const storefrontAddressSection = 'Adresse';
  static const storefrontMenu = 'Menu';
  static const weeklyHours = 'Horaires';
  static const openingHoursSection = 'Horaires d’ouverture';
  static const hoursTodaySuffix = '(Aujourd’hui)';
  static const cartUnavailable =
      'Le panier n’est pas encore disponible. Aucun article n’a été ajouté.';
  static const addToCart = 'Ajouter au panier';
  static const customizeProduct = 'Personnaliser';
  static const customizeTitle = 'Personnaliser';
  static const cartTitle = 'Panier';
  static const cartEmpty = 'Votre panier est vide.';
  static const cartEmptyHint =
      'Ajoutez un produit depuis un commerce pour commencer.';
  static const cartLoadError = 'Impossible de charger le panier.';
  static const cartMerchandiseSubtotal = 'Sous-total marchandises';
  static const cartOrderSummary = 'Résumé';
  static const cartSubtotalHint =
      'La livraison et les remises sont calculées à la vérification.';
  static const checkoutUnavailable =
      'Le paiement n’est pas encore disponible. Aucune commande n’a été créée.';
  static const checkoutAction = 'Vérifier ma commande';
  static const checkoutReviewHint =
      'Aucune commande n’est créée à cette étape.';
  static const checkoutReviewTitle = 'Révision de la commande';
  static const checkoutVerifying = 'Vérification de la commande…';
  static const checkoutNeedAddress =
      'Choisissez une adresse de livraison pour vérifier la commande.';
  static const checkoutChooseAddress = 'Choisir une adresse';
  static const checkoutChangeAddress = 'Modifier l’adresse';
  static const checkoutDeliveryAddress = 'Adresse de livraison';
  static const checkoutMerchandise = 'Sous-total marchandises';
  static const checkoutDeliveryFee = 'Frais de livraison';
  static const checkoutDiscount = 'Remise';
  static const checkoutPayable = 'Total à payer';
  static const checkoutPromoLabel = 'Code promo';
  static const checkoutPromoHint = 'Saisir un code';
  static const checkoutPromoApply = 'Appliquer';
  static const checkoutPromoRemove = 'Retirer';
  static const checkoutPromoEmpty = 'Saisissez un code promo.';
  static const checkoutPromoCopiedHint =
      'Un code copié n’est pas appliqué tant que la vérification ne le confirme pas.';
  static String checkoutPromoApplied(String code) => 'Code $code appliqué';
  static const checkoutPriceChanged =
      'Le prix d’un article a changé. Les montants ci-dessous sont à jour.';
  static const checkoutPlaceOrder = 'Commander';
  static const checkoutPlaceOrderUnavailable =
      'Choisissez un mode de paiement et vérifiez la commande.';
  static const checkoutSubmitting = 'Envoi de la commande…';
  static const checkoutReconfirmRequired =
      'Les montants ont changé. Vérifiez les totaux, puis confirmez à nouveau.';
  static const checkoutPaymentTitle = 'Mode de paiement';
  static const checkoutPaymentChoose = 'Choisissez comment payer';
  static const checkoutPaymentHint =
      'Le mode de paiement est choisi au moment de la commande. Il n’est pas envoyé à la vérification et ne change pas les totaux.';
  static const checkoutPaymentCod = 'Paiement à la livraison';
  static const checkoutPaymentCodBody =
      'Payez le montant exact au livreur à l’arrivée.';
  static const checkoutPaymentElectronic = 'Paiement électronique';
  static const checkoutPaymentElectronicSoon = 'Bientôt disponible';
  static const checkoutPaymentElectronicHint =
      'Vous serez redirigé vers le prestataire après l’envoi de la commande. Un retour navigateur ne confirme pas le paiement.';
  static const checkoutPaymentElectronicUnavailable =
      'Indisponible pour le moment. Seul le paiement à la livraison est proposé.';
  static const checkoutPaymentMethodUnavailable =
      'Ce mode de paiement n’est pas disponible. Choisissez un mode disponible (paiement à la livraison). Votre sélection n’a pas été modifiée automatiquement.';
  static const checkoutPaymentLater =
      'Disponible à la commande, pas à cette étape.';
  static const checkoutPaymentSelected = 'Sélectionné';
  static const checkoutPaymentSecurityNote =
      'Le paiement électronique n’est proposé que lorsqu’il est activé. Aucune donnée bancaire n’est saisie dans SpeedyGo.';
  static const checkoutBackToReview = 'Retour à la révision';
  static const checkoutContinue = 'Continuer';
  static const checkoutPlaceOrderElectronic =
      'Envoyer la commande puis payer';
  static const paymentTitle = 'Paiement';
  static const paymentRedirectTitle = 'Redirection vers le paiement';
  static const paymentReadyTitle = 'Paiement à effectuer';
  static const paymentReadyBody =
      'Votre commande est enregistrée. Démarrez le paiement auprès du prestataire. Le statut serveur fait seule autorité.';
  static const paymentPendingTitle = 'Paiement en cours';
  static const paymentPendingBody =
      'Le prestataire traite votre paiement. Un retour navigateur ou une URL ne signifie pas que le paiement est confirmé.';
  static const paymentSucceededTitle = 'Paiement confirmé';
  static const paymentSucceededBody =
      'Le serveur a confirmé le paiement. Cela ne signifie pas que le commerce a accepté la commande ni qu’un livreur est assigné.';
  static const paymentFailedTitle = 'Paiement non abouti';
  static const paymentFailedBody =
      'Le paiement n’a pas abouti. Vous pouvez réessayer sur la même commande sans en créer une nouvelle.';
  static const paymentCancelledTitle = 'Paiement annulé';
  static const paymentCancelledBody =
      'L’intention de paiement est annulée côté SpeedyGo.';
  static const paymentPayNow = 'Payer maintenant';
  static const paymentInitiating = 'Ouverture du paiement…';
  static const paymentCheckStatus = 'Vérifier le statut';
  static const paymentRefresh = 'Actualiser';
  static const paymentGoConfirmation = 'Voir la confirmation';
  static const paymentAmountLabel = 'Montant';
  static const paymentStatusLabel = 'Statut du paiement';
  static const paymentAttemptLabel = 'Tentative';
  static const paymentProviderLabel = 'Prestataire';
  static const paymentStatusPending = 'En attente';
  static const paymentStatusProcessing = 'En cours';
  static const paymentStatusSucceeded = 'Confirmé';
  static const paymentStatusFailed = 'Échoué';
  static const paymentStatusCancelled = 'Annulé';
  static const paymentStatusUnknown = 'Inconnu';
  static const paymentBrowserReturnHint =
      'Retour détecté. Le paiement n’est pas considéré comme réussi tant que le serveur ne l’a pas confirmé.';
  static const paymentTestCheckoutHint =
      'Le prestataire de test a renvoyé une URL non ouvrable dans le navigateur. Aucun webhook n’est forgé. Vérifiez le statut serveur ou configurez Chargily sandbox.';
  static const paymentCheckoutMissing =
      'Aucune URL de paiement utilisable n’a été renvoyée.';
  static const paymentCheckoutRejectedHttp =
      'L’URL de paiement HTTP a été refusée. Seul HTTPS sur un hôte prestataire approuvé est ouvert.';
  static const paymentCheckoutRejectedHost =
      'L’URL de paiement n’appartient pas à un hôte prestataire approuvé.';
  static const paymentCheckoutRejectedTest =
      'Les URL de test ne sont pas utilisées en mode Client normal.';
  static const paymentInitiateDisabled =
      'Le paiement électronique n’est pas activé sur cette application. Le statut actuel est affiché sans nouvelle tentative.';
  static const paymentInitiateUncertain =
      'L’initiation n’a pas été confirmée. La commande n’est pas recréée. Vérifiez le statut du paiement.';
  static const paymentPollingPaused =
      'La vérification automatique est en pause. Actualisez pour recharger le statut serveur.';
  static const paymentLoadError = 'Impossible de charger le paiement.';
  static const paymentNotElectronic =
      'Cette commande n’utilise pas le paiement électronique.';
  static const paymentContinue = 'Continuer le paiement';
  static const paymentSuccessDistinctHint =
      'Le succès du paiement est distinct de l’acceptation du commerce et de la livraison.';
  static const orderReconfirmationRequired =
      'Les montants ont changé depuis votre dernière vérification. Confirmez les nouveaux totaux.';
  static const orderSubmissionPendingVerification =
      'Nous n’avons pas pu confirmer l’envoi de la commande.';
  static const orderSubmissionPendingHint =
      'Votre connexion a peut-être été interrompue. Consultez vos commandes avant de renvoyer une commande.';
  static const orderSubmissionServerUncertain =
      'Le serveur n’a pas confirmé la commande. Vérifiez vos commandes avant de réessayer.';
  static const orderSubmissionViewOrders = 'Voir mes commandes';
  static const orderSubmissionCheckAgain = 'Vérifier à nouveau';
  static const orderConfirmationTitle = 'Commande envoyée';
  static const orderConfirmationSent =
      'Votre commande a bien été transmise au commerce.';
  static const orderConfirmationAwaitingMerchant =
      'Elle est en attente de confirmation par le commerce. Aucun livreur n’est assigné pour le moment.';
  static const orderConfirmationAwaitingMerchantShort =
      'En attente de confirmation du commerce';
  static const orderConfirmationPaymentPending =
      'Non confirmé par le serveur';
  static const orderConfirmationPaymentSucceeded =
      'Confirmé par le serveur';
  static const orderConfirmationPaymentFailed = 'Paiement échoué';
  static const orderConfirmationPaymentCancelled = 'Paiement annulé';
  static const orderConfirmationNoPaymentCollected =
      'À encaisser à la livraison';
  static const orderConfirmationAmountPaid = 'Montant payé';
  static const orderConfirmationAmountCod = 'À régler à la livraison';
  static const orderConfirmationAmountDue = 'Montant';
  static const orderConfirmationViewDetail = 'Voir le détail';
  static const orderConfirmationBackHome = 'Retour à l’accueil';
  static const orderDetailTitle = 'Ma commande';
  static const orderReferenceLabel = 'Référence';
  static const orderStatusLabel = 'Statut';
  static const orderPaymentMethodLabel = 'Paiement';
  static const orderPaymentDetailsTitle = 'Détails du paiement';
  static const orderDeliveryAddressLabel = 'Adresse de livraison';
  static const orderDeliveryPlaceLabel = 'Lieu de livraison';
  static const orderItemsLabel = 'Articles';
  static const orderItemsOrderedLabel = 'Articles commandés';
  static const orderUnitPriceLabel = 'par unité';
  static const orderLoadError = 'Impossible de charger cette commande.';
  static const ordersLoadError = 'Impossible de charger vos commandes.';
  static const ordersTabInProgress = 'En cours';
  static const ordersTabCompleted = 'Terminées';
  static const ordersTabCancelled = 'Annulées';
  static const ordersEmptyFiltered = 'Aucune commande dans cette catégorie.';
  static const ordersOlderHint =
      'Des commandes plus anciennes peuvent exister. Chargez la page suivante.';
  static const accountPaymentMethodsTitle = 'Méthodes de paiement';
  static const accountPaymentMethodsBody =
      'Aucune carte n’est enregistrée. Le mode de paiement se choisit au moment de la commande. Le paiement à la livraison est disponible. Le paiement électronique n’est proposé que lorsqu’il est activé sur cette application.';
  static const accountDeleteTitle = 'Supprimer mon compte';
  static const accountDeleteBody =
      'La suppression de compte n’est pas disponible. SpeedyGo n’utilise pas de mot de passe : la connexion se fait par code SMS. Cette action n’est pas envoyée au serveur.';
  static const accountDeleteAction = 'Supprimer définitivement';
  static const accountNotificationsSettingsTitle = 'Notifications';
  static const accountNotificationsSettingsBody =
      'Les alertes de commande s’affichent dans l’onglet Alertes. Aucune préférence de notification n’est enregistrée sur le serveur, et les notifications système ne sont pas demandées ici.';
  static const accountNotificationsOpenInbox = 'Voir les alertes';
  static const legalUnavailableBody =
      'Le texte officiel n’est pas encore servi par une API publique. Aucune politique n’est inventée ici.';
  static const legalPrivacyTitle = 'Politique de confidentialité';
  static const legalTermsTitle = 'Conditions d’utilisation';
  static const accountSectionAccount = 'Compte';
  static const accountSectionPreferences = 'Préférences';
  static const accountSectionSupport = 'Support';
  static const accountSectionLegal = 'Légal & Sécurité';
  static const accountAddressesLabel = 'Adresses enregistrées';
  static const accountLanguageLabel = 'Langue';
  static const accountSecurityLabel = 'Sécurité';
  static const checkoutNotesTitle = 'Instructions spéciales';
  static const checkoutNotesUnavailable =
      'Les instructions spéciales ne sont pas acceptées à la commande. Aucun champ n’est envoyé au serveur.';
  static const pspStatusUnconfirmed = 'Statut PSP non confirmé';
  static const orderPaymentCod = 'Paiement à la livraison';
  static const orderPaymentElectronic = 'Paiement électronique';
  static const orderStatusCancelled = 'Annulée';
  static const orderStatusCompleted = 'Livrée';
  static const orderCancelTitle = 'Annuler la commande';
  static const orderCancelEligibleTitle = 'Éligible à l’annulation';
  static const orderCancelEligibleBody =
      'Statut : Attente de confirmation du commerce';
  static const orderCancelNotEligible =
      'Cette commande ne peut plus être annulée.';
  static const orderCancelReasonLabel = 'Raison de l’annulation';
  static const orderCancelReasonOptionalHint =
      'Facultatif. La raison n’est pas obligatoire pour confirmer.';
  static const orderCancelReasonChangeOfMind = 'Changement d’avis';
  static const orderCancelReasonWaitTooLong = 'Temps d’attente trop long';
  static const orderCancelReasonOrderError = 'Erreur dans la commande';
  static const orderCancelIrreversible =
      'Cette action est irréversible.';
  static const orderCancelConfirmAction = 'Confirmer l’annulation';
  static const orderCancelKeepOrder = 'Garder ma commande';
  static const orderCancelEntry = 'Annuler la commande';
  static const orderCancelAccepted = 'Votre commande a été annulée.';
  static const orderCancelRejected =
      'L’annulation a été refusée. La commande n’a pas été annulée.';
  static const orderCancelPendingVerification =
      'Nous n’avons pas pu confirmer l’annulation.';
  static const orderCancelPendingHint =
      'Vérifiez l’état de la commande avant de réessayer. L’annulation n’est pas renvoyée automatiquement.';
  static const orderCancelCheckAgain = 'Vérifier l’état';
  static const orderCancelCodNoRefund =
      'Aucun paiement électronique n’avait été prélevé. Aucun remboursement n’est dû.';
  static const orderCancelElectronicRefundIntent =
      'Un remboursement peut être nécessaire. Cela ne signifie pas que l’argent a déjà été recrédité.';
  static const orderCancelElectronicRefundBankHint =
      'Pour les paiements électroniques, un remboursement peut prendre du temps une fois confirmé par SpeedyGo.';
  static const orderRefundsTitle = 'Remboursement';
  static const orderRefundsEmpty =
      'Aucun remboursement n’est enregistré pour cette commande.';
  static const orderRefundStatusRequested = 'Demande enregistrée';
  static const orderRefundStatusUnderReview = 'En examen';
  static const orderRefundStatusApproved = 'Approuvé';
  static const orderRefundStatusProcessing = 'En traitement';
  static const orderRefundStatusRefunded = 'Remboursé';
  static const orderRefundStatusRejected = 'Refusé';
  static const orderRefundStatusFailed = 'Échoué';
  static const orderRefundNotCompletedHint =
      'Ce statut décrit le dossier de remboursement, pas un remboursement déjà effectué sur votre compte.';
  static const orderRefundCompletedHint =
      'Le remboursement a été confirmé côté SpeedyGo.';
  static const orderRefundsLoadError =
      'Impossible de charger les informations de remboursement.';
  static const trackingTitle = 'Suivi de commande';
  static const trackingStatusDetailsTitle = 'Détails de l’état';
  static const trackingAwaitingMerchantTitle = 'En attente de confirmation';
  static const trackingAwaitingMerchantBody =
      'Le commerce vérifie la disponibilité de vos articles avant de valider votre commande.';
  static const trackingAcceptedBody =
      'Le commerce a accepté votre commande.';
  static const trackingPreparingBody =
      'Le commerce prépare votre commande.';
  static const trackingReadyBody =
      'Votre commande est prête. La recherche d’un livreur n’a pas encore commencé.';
  static const trackingSearchingBody =
      'SpeedyGo recherche un livreur pour votre commande.';
  static const trackingAssignedBody =
      'Un livreur est assigné. La livraison n’est pas encore terminée.';
  static const trackingInTransitBody =
      'Votre commande est en chemin.';
  static const trackingNearbyTitle = 'Votre livreur est presque arrivé';
  static const trackingNearbyBody =
      'Le livreur a signalé son arrivée près de votre adresse.';
  static const trackingCompletedTitle = 'Commande livrée';
  static const trackingCompletedBody =
      'La livraison est terminée.';
  static const trackingCancelledBody =
      'Cette commande est annulée. Aucune livraison n’est en cours.';
  static const trackingFailedTitle = 'Livraison interrompue';
  static const trackingFailedBody =
      'Cette livraison n’a pas pu être terminée.';
  static const trackingUnknownTitle = 'État en cours de mise à jour';
  static const trackingUnknownBody =
      'L’état actuel n’est pas encore affiché. Actualisez pour recharger les données serveur.';
  static const trackingProgression = 'Progression';
  static const trackingTimelineSent = 'Envoyée';
  static const trackingTimelineMerchant = 'Confirmation';
  static const trackingTimelinePrep = 'Préparation';
  static const trackingTimelineDelivery = 'Livraison';
  static const trackingTimelineDone = 'Terminée';
  static const trackingOpenDetail = 'Voir le détail';
  static const trackingRefresh = 'Actualiser le suivi';
  static const trackingOffline =
      'Connexion interrompue. L’état affiché peut ne plus être à jour.';
  static const trackingStaleHint =
      'La position du livreur n’est plus fraîche. Aucun déplacement inventé.';
  static const trackingLive = 'Position à jour';
  static const trackingStale = 'Position ancienne';
  static const trackingUnavailable = 'Position indisponible';
  static const trackingNoDriver = 'Aucun livreur assigné pour le suivi';
  static const trackingDriverIdLabel = 'Identifiant livreur';
  static const trackingLocationLabel = 'Dernière position connue';
  static const trackingRecordedAtLabel = 'Enregistrée à';
  static const trackingMapUnavailable =
      'Aucune carte n’est configurée dans l’application. Le suivi d’état reste disponible.';
  static const trackingNoCustomerGps =
      'SpeedyGo n’utilise pas votre GPS pour consulter cette livraison.';
  static const trackingDeliveryCodeUnavailable =
      'Aucun code de livraison n’est fourni par le serveur pour le moment.';
  static const trackingPickupLabel = 'Retrait';
  static const trackingDropoffLabel = 'Livraison';
  static const trackingOrderStatusLabel = 'Commande';
  static const trackingFulfillmentLabel = 'Préparation';
  static const trackingDeliveryStatusLabel = 'Livraison';
  static const trackingLoadError = 'Impossible de charger le suivi.';
  static const trackingEntry = 'Suivre la commande';
  static const checkoutDeliveryZone = 'Zone de livraison';
  static const checkoutRetryPreview = 'Revérifier';
  static const checkoutOpenCart = 'Retour au panier';
  static const removeFromCart = 'Retirer';
  static const clearCart = 'Vider le panier';
  static const clearCartConfirmTitle = 'Vider le panier ?';
  static const clearCartConfirmBody =
      'Tous les articles de ce commerce seront retirés.';
  static const addAnotherItem = 'Ajouter un autre article';
  static const cartAdded = 'Ajouté au panier';
  static const viewCart = 'Voir le panier';
  static const optionRequired = 'Obligatoire';
  static const optionOptional = 'Optionnel';
  static String optionSelectCount(int min, int max) {
    if (min == max) {
      return min == 1 ? 'Sélectionnez 1 option' : 'Sélectionnez $min options';
    }
    return 'Sélectionnez $min–$max options';
  }

  static const cartBranchConflict =
      'Votre panier appartient déjà à un autre commerce. Videz-le pour commander ici.';
  static const cartGoToExisting = 'Ouvrir le panier';
  static const cartKeepExisting = 'Conserver';
  static const quantityLabel = 'Quantité';
  static const cartItemUnavailable = 'Cet article n’est plus disponible.';
  static const cartNotReady =
      'Certains articles du panier ne sont plus valides.';
  static const addingToCart = 'Ajout au panier…';
  static const cartReconciling = 'Vérification du panier…';
  static const cartAddUnconfirmed =
      'L’ajout n’a pas pu être confirmé. Votre sélection a été conservée.';
  static const cartClearing = 'Vidage du panier…';
  static const perPortion = 'Par portion';
  static const productDescriptionHeading = 'Description';
  static const customizeProductHint = 'Suppléments, options, extras…';
  static const customizeProductCardTitle = 'Personnaliser votre produit';
  static const orderFrom = 'Commande chez';
  static const productUnavailable = 'Ce produit n’est pas disponible.';
  static const storefrontUnavailable = 'Ce commerce n’est pas disponible.';
  static const searchQueryInvalid = 'Cette recherche n’est pas valide.';
  static const catalogLoadError = 'Impossible de charger le catalogue.';
  static const loadMore = 'Charger plus';
  static const optionUnavailable = 'Indisponible';
  static const closedBrowseHint =
      'Commerce fermé. Vous pouvez consulter le menu.';
  static const weekdayMonday = 'Lundi';
  static const weekdayTuesday = 'Mardi';
  static const weekdayWednesday = 'Mercredi';
  static const weekdayThursday = 'Jeudi';
  static const weekdayFriday = 'Vendredi';
  static const weekdaySaturday = 'Samedi';
  static const weekdaySunday = 'Dimanche';
  static const closedAllDay = 'Fermé';
  static const specialOffer = 'Offre spéciale';
  static const promoHeadline = '150 DZD offerts';
  static const promoCondition = 'Sur toute commande dès 1,500 DZD';
  static const promoCode = 'SPEEDY150';
  static const promoMerchandiseCondition =
      'S’applique aux produits. Vérifiée au paiement.';
  static const promoCodeCopied = 'Code copié';
  static const copyPromoCode = 'Copier le code';
  static String promoFixedHeadline(String formattedAmount) =>
      'Jusqu’à $formattedAmount de réduction';
  static String promoRateHeadline(String percent) => '$percent de réduction';
  static const categoryRestaurants = 'Restaurants';
  static const categoryBakeries = 'Boulangeries';
  static const categoryGroceries = 'Épiceries';
  static const categoryPharmacies = 'Pharmacies';
  static const categoryDesserts = 'Desserts';
  static const activeOrder = 'Commande en cours';
  static const orderStatusPendingAcceptance = 'En attente du commerce';
  static const orderStatusAccepted = 'Commande acceptée';
  static const orderStatusPreparing = 'En préparation';
  static const orderStatusReady = 'Prête pour le livreur';
  static const orderStatusSearchingDriver = 'Recherche d’un livreur';
  static const orderStatusDriverAssigned = 'Livreur assigné';
  static const orderStatusToPickup = 'Le livreur se rend au commerce';
  static const orderStatusAtPickup = 'Le livreur est au commerce';
  static const orderStatusPickedUp = 'Commande récupérée';
  static const orderStatusInTransit = 'En chemin vers vous';
  static const orderStatusArrived = 'Le livreur est arrivé';
  static const homeDesignPreviewTitle = 'Accueil — composition design';
  static const homeDesignPreviewHint =
      'Composition visuelle Stitch. Données d’aperçu locales, hors API.';
  static const previewAddress = 'Domicile — Sidi Djillali';
  static const previewCustomerName = 'Amel';
  static const previewMerchantName = 'Dar El Bahia';
  static const previewMerchantCuisine = 'Cuisine Algérienne & Traditionnelle';
  static const previewPopular = 'Populaire';
  static const previewEta = '25–35 min';
  static const previewDeliveryFee = '200 DZD';
  static const previewRating = '4.7';
  static const previewOrderNumber = '#SG-260803-1842';
  static const previewOrderStatus = 'En chemin vers vous';
  static const navPreview = 'Aperçu de navigation';
  static const closeLabel = 'Fermer';
  static const saveUnavailable = 'Enregistrement non branché.';
  static const submitUnavailable = 'Soumission non branchée.';
  static const deleteUnavailable =
      'Aucune route de suppression de compte. Le compte n’a pas été modifié.';
  static const favoritesUnavailable =
      'Aucun favori n’existe côté serveur. Rien n’a été ajouté.';
  static const promotionsTitle = 'Promotions et offres';
  static const promotionsEmpty = 'Aucune offre publiée pour le moment.';
  static const promotionsCheckoutHint =
      'Le code s’applique à la vérification. L’éligibilité est calculée par le serveur.';
  static const promotionsUnavailable =
      'Cette offre n’a pas été appliquée. Utilisez le code à la vérification.';
  static const notificationPrefsUnavailable =
      'Aucun stockage de préférences de notification. Rien n’a été enregistré.';
  static const notificationsTitle = 'Alertes';
  static const notificationsEmpty =
      'Aucune notification pour le moment.';
  static const notificationsLoadError =
      'Impossible de charger les notifications.';
  static const notificationsMarkAll = 'Tout marquer lu';
  static const notificationsLoadMore = 'Voir plus';
  static const notificationsLoadingMore = 'Chargement…';
  static const notificationsDestinationUnavailable =
      'Cette notification ne peut pas être ouverte ici.';
  static const notificationsUnknownType =
      'Type de notification non pris en charge.';
  static const notificationsMarkReadError =
      'Impossible de mettre à jour l’état de lecture.';
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
  static const logoutNoteOrders =
      'Vos commandes en cours resteront liées à votre compte.';
  static const logoutNoteReconnect =
      'Vous devrez vous reconnecter pour suivre vos livraisons.';
  static const logoutNoteSafe =
      'Votre panier et vos adresses enregistrées sont en sécurité.';
  static const logoutConfirmAction = 'Se déconnecter';
  static const cancel = 'Annuler';
  static const logoutLocalOnly =
      'Vous êtes déconnecté sur cet appareil. La révocation serveur n’a pas pu être confirmée.';

  static const addressesTitle = 'Adresses enregistrées';
  static const addressesEmpty =
      'Aucune adresse enregistrée. Vous pouvez parcourir SpeedyGo sans en ajouter.';
  static const addressesLoadError = 'Impossible de charger les adresses.';
  static const addressesDefaultSection = 'Adresse par défaut';
  static const addressesOtherSection = 'Autres adresses';
  static const addAddress = 'Ajouter une adresse';
  static const addAddressShort = 'Ajouter';
  static const addAddressNew = 'Ajouter une nouvelle adresse';
  static const editAddress = 'Modifier l’adresse';
  static const saveAddress = 'Enregistrer l’adresse';
  static const addressTypeLabel = 'Type d’adresse';
  static const addressLabelField = 'Libellé';
  static const addressLabelHint = 'Ex: Domicile';
  static const addressTextField = 'Adresse détaillée';
  static const addressTextHint = 'Ex: Cité 1500 Logements, Bloc 12';
  static const addressLatitudeField = 'Latitude';
  static const addressLongitudeField = 'Longitude';
  static const addressCoordsHint =
      'La livraison est confirmée au paiement, pas sur cet écran.';
  static const addressLabelRequired = 'Saisissez un libellé.';
  static const addressLabelTooLong =
      'Le libellé ne peut pas dépasser 64 caractères.';
  static const addressTextRequired = 'Saisissez l’adresse détaillée.';
  static const addressTextTooLong =
      'L’adresse ne peut pas dépasser 500 caractères.';
  static const addressLatitudeInvalid =
      'Saisissez une latitude entre -90 et 90.';
  static const addressLongitudeInvalid =
      'Saisissez une longitude entre -180 et 180.';
  static const addressCoordsRequired =
      'Latitude et longitude sont obligatoires.';
  static const addressFirstDefaultHint =
      'La première adresse enregistrée devient l’adresse par défaut du compte.';
  static const addressDefaultHint =
      'Pour changer l’adresse par défaut, utilisez « Définir par défaut » dans la liste des adresses.';
  static const useMyLocation = 'Utiliser ma position';
  static const setAsDefault = 'Définir par défaut';
  static const defaultAddressBadge = 'Par défaut';
  static const selectedAddressBadge = 'Sélectionnée';
  static const deleteAddress = 'Supprimer';
  static const deleteAddressTitle = 'Supprimer cette adresse ?';
  static const deleteAddressBody =
      'Elle sera retirée de votre carnet. Les commandes déjà passées ne sont pas modifiées.';
  static const confirmDelete = 'Supprimer';
  static const addressPickerTitle = 'Adresse de livraison';
  static const addressPickerEmpty =
      'Aucune adresse enregistrée. Ajoutez-en une pour la sélectionner.';
  static const chooseThisAddress = 'Choisir cette adresse';
  static const addressSelectionHint =
      'Cette sélection s’affiche à l’accueil. Elle ne change pas l’adresse par défaut du compte.';
  static const addressNotFound = 'Cette adresse est introuvable.';
  static const addressInvalid = 'Cette adresse n’est pas valide.';
  static const addressDefaultConflict =
      'Impossible de définir cette adresse par défaut pour le moment.';
  static const addressSaving = 'Enregistrement…';
  static const addressReconciling = 'Vérification de l’adresse…';
  /// Confirmed create/update only — never use for uncertain save results.
  static const addressSaved = 'Adresse enregistrée';
  static const addressSaveUnconfirmed =
      'L’enregistrement n’a pas pu être confirmé. Vos saisies ont été conservées.';
  static const locationPermissionTitle = 'Activez votre localisation';
  static const locationPermissionBody =
      'SpeedyGo peut préremplir la latitude et la longitude de cette adresse. Le catalogue n’est pas filtré par position. La livraison n’est confirmée qu’au paiement.';
  static const locationBenefitCoordsTitle = 'Coordonnées précises';
  static const locationBenefitCoordsBody =
      'Préremplit latitude et longitude pour enregistrer l’adresse plus rapidement.';
  static const locationBenefitDeliveryTitle = 'Livraison au paiement';
  static const locationBenefitDeliveryBody =
      'L’éligibilité de livraison reste vérifiée au moment du paiement, pas ici.';
  static const locationPrivacyNote =
      'Votre localisation n’est utilisée que pour préremplir les coordonnées. Vous pouvez saisir l’adresse manuellement.';
  static const allowLocation = 'Autoriser la localisation';
  static const enterAddressManually = 'Saisir une adresse manuellement';
  static const locationDenied =
      'La localisation a été refusée. Saisissez les coordonnées manuellement ou autorisez-la dans les réglages.';
  static const locationDeniedForever =
      'La localisation est bloquée pour SpeedyGo. Autorisez-la dans les réglages de l’appareil, ou saisissez les coordonnées manuellement.';
  static const locationServicesDisabled =
      'Les services de localisation sont désactivés. Activez-les, ou saisissez les coordonnées manuellement.';
  static const locationUnavailable =
      'La position n’est pas disponible pour le moment. Saisissez les coordonnées manuellement.';
  static const confirmLocationTitle = 'Confirmer l’emplacement';
  static const confirmLocationBody =
      'Vérifiez ces coordonnées. Elles ne sont pas enregistrées tant que vous n’enregistrez pas l’adresse, et elles ne prouvent pas l’éligibilité de livraison.';
  static const confirmLocationAction = 'Confirmer la position';
  static const locationNotAMap =
      'Aucune carte n’est configurée. Seules les coordonnées GPS de l’appareil sont affichées.';
  static const confirmLocationPrecisionNote =
      'Précision de l’adresse requise';
  static String confirmLocationClientLabel(String name) => 'Client : $name';
  static const confirmLocationCoordsFallback = 'Position GPS';
  static const addressLabelHome = 'Domicile';
  static const addressLabelWork = 'Travail';
  static const addressLabelOther = 'Autre';

  static const offline = 'Vérifiez votre connexion, puis réessayez.';
  static const retry = 'Réessayer';
  static const refresh = 'Actualiser';
  static const unexpected = 'Une erreur s’est produite. Réessayez.';
  static const sessionExpired = 'Votre session a expiré. Connectez-vous.';
  static const reauthRequired =
      'Reconnectez-vous pour continuer. L’ancienne session n’est plus utilisable ici.';
  static const securityTitle = 'Sécurité';
  static const securitySessionsHeading = 'Sessions actives';
  static const securityAccountHeading = 'Informations de compte';
  static const securityVerifiedPhone = 'Numéro vérifié';
  static const securityCurrentBadge = 'Cet appareil';
  static const securityCurrentPill = 'COURANT';
  static const securityEmpty = 'Aucune session active.';
  static const securityLoadError =
      'Impossible de charger les sessions.';
  static const securityRevoke = 'Révoquer';
  static const securityRevokeTitle = 'Révoquer cette session ?';
  static const securityRevokeBody =
      'Cet appareil devra se reconnecter. Votre session actuelle reste active.';
  static const securityRevokeCurrentTitle =
      'Révoquer la session de cet appareil ?';
  static const securityRevokeCurrentBody =
      'Vous serez déconnecté immédiatement sur cet appareil.';
  static const securityRevokeConfirm = 'Révoquer';
  static const securityLogoutAll = 'Déconnecter tous les appareils';
  static const securityLogoutAllTitle =
      'Déconnecter tous les appareils ?';
  static const securityLogoutAllBody =
      'Toutes les sessions seront révoquées, y compris celle-ci. Vous serez déconnecté immédiatement et devrez vous reconnecter.';
  static const securityOtpGuidanceTitle = 'Conseils de sécurité';
  static const securityOtpGuidance =
      'La connexion SpeedyGo utilise un code SMS à usage unique. Il n’existe pas de double authentification séparée. Ne partagez jamais ce code.';
  static const securityLogoutAllConfirm = 'Tout déconnecter';
  static const securityReportSuspicious = 'Signaler une activité suspecte';
  static const securityRevokeUncertain =
      'La révocation n’est pas confirmée. Actualisation en cours…';
  static const securityRevokedOk = 'Session révoquée.';
  static const notificationsBrand = 'SPEEDYGO';
  static const notificationsEmptyHint =
      'Les alertes de commande apparaîtront ici dès qu’elles seront disponibles.';
  static const notificationsPermissionLink = 'Autorisations';
  static const notificationsPrefsLink = 'Préférences';
  static const otpServerUnavailable =
      'Le service d’authentification est temporairement indisponible. Réessayez plus tard.';
  static const otpCooldownHint = 'Patientez avant une nouvelle demande.';

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
      case 'INTERNAL_ERROR':
        return otpServerUnavailable;
      case 'OTP_NOT_ACCEPTED':
        return otpServerUnavailable;
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
      case 'CUSTOMER_ADDRESS_NOT_FOUND':
        return addressNotFound;
      case 'CUSTOMER_ADDRESS_INVALID':
        return addressInvalid;
      case 'CUSTOMER_DEFAULT_ADDRESS_INVALID':
        return addressDefaultConflict;
      case 'ADDRESS_MUTATION_UNCERTAIN':
        return addressSaveUnconfirmed;
      case 'CUSTOMER_STOREFRONT_NOT_FOUND':
        return storefrontUnavailable;
      case 'CUSTOMER_PRODUCT_NOT_FOUND':
        return productUnavailable;
      case 'CUSTOMER_SEARCH_QUERY_INVALID':
        return searchQueryInvalid;
      case 'CUSTOMER_CATALOG_INVALID_PAGINATION':
        return 'Cette page de catalogue n’est pas valide.';
      case 'CART_ITEM_NOT_FOUND':
        return 'Cet article n’est plus dans le panier.';
      case 'CART_BRANCH_MISMATCH':
        return cartBranchConflict;
      case 'CART_PRODUCT_NOT_AVAILABLE':
        return 'Ce produit n’est pas disponible pour le panier.';
      case 'CART_OPTION_NOT_AVAILABLE':
        return 'Cette option n’est plus disponible.';
      case 'CART_OPTION_INVALID':
        return 'Cette combinaison d’options n’est pas valide.';
      case 'CART_REQUIRED_OPTION_MISSING':
        return 'Sélectionnez les options obligatoires.';
      case 'CART_INVALID_QUANTITY':
        return 'La quantité doit être comprise entre 1 et 99.';
      case 'CART_MUTATION_UNCERTAIN':
        return cartAddUnconfirmed;
      case 'CHECKOUT_CART_REQUIRED':
        return 'Votre panier est vide ou n’existe plus.';
      case 'CHECKOUT_CART_NOT_READY':
        return cartNotReady;
      case 'CHECKOUT_ADDRESS_NOT_FOUND':
        return 'Cette adresse n’est plus disponible.';
      case 'CHECKOUT_ADDRESS_COORDINATES_REQUIRED':
        return 'Cette adresse n’a pas de coordonnées utilisables.';
      case 'CHECKOUT_ADDRESS_OUTSIDE_ZONE':
        return 'Cette adresse n’est pas dans une zone de livraison.';
      case 'CHECKOUT_DELIVERY_ZONE_AMBIGUOUS':
        return 'La zone de livraison de cette adresse n’est pas déterminée. Choisissez une autre adresse.';
      case 'CHECKOUT_PRICING_RULE_NOT_FOUND':
        return 'Les frais de livraison ne sont pas disponibles pour cette adresse.';
      case 'CHECKOUT_PRICING_CONFIGURATION_INVALID':
        return 'La tarification de livraison n’est pas disponible pour le moment.';
      case 'CHECKOUT_MERCHANT_NOT_OPERATIONAL':
        return 'Ce commerce n’accepte pas de commande pour le moment.';
      case 'CHECKOUT_BRANCH_NOT_OPERATIONAL':
        return 'Ce point de vente n’accepte pas de commande pour le moment.';
      case 'CHECKOUT_BRANCH_CLOSED':
        return 'Ce commerce est fermé pour le moment.';
      case 'CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED':
        return 'Les horaires de ce commerce ne sont pas disponibles.';
      case 'PROMOTION_CODE_INVALID':
        return 'Ce code promo n’est pas valide.';
      case 'PROMOTION_NOT_FOUND':
        return 'Ce code promo est introuvable.';
      case 'PROMOTION_INACTIVE':
        return 'Ce code promo n’est pas actif.';
      case 'PROMOTION_NOT_YET_ACTIVE':
        return 'Ce code promo n’est pas encore actif.';
      case 'PROMOTION_EXPIRED':
        return 'Ce code promo a expiré.';
      case 'PROMOTION_CONFIGURATION_INVALID':
        return 'Cette promotion n’est pas applicable.';
      case 'PROMOTION_STACKING_UNSUPPORTED':
        return 'Cette promotion ne peut pas être combinée.';
      case 'PROMOTION_REDEMPTION_CONFLICT':
        return 'Cette promotion n’est plus utilisable.';
      case 'PROMOTION_ZERO_PAYABLE_UNSUPPORTED':
        return 'Cette promotion n’est pas applicable à cette commande.';
      case 'ORDER_CART_REQUIRED':
        return 'Votre panier est vide ou n’existe plus.';
      case 'ORDER_CART_NOT_READY':
        return cartNotReady;
      case 'ORDER_ADDRESS_NOT_FOUND':
        return 'Cette adresse n’est plus disponible.';
      case 'ORDER_ADDRESS_COORDINATES_REQUIRED':
        return 'Cette adresse n’a pas de coordonnées utilisables.';
      case 'ORDER_ADDRESS_OUTSIDE_ZONE':
        return 'Cette adresse n’est pas dans une zone de livraison.';
      case 'ORDER_DELIVERY_ZONE_AMBIGUOUS':
        return 'La zone de livraison de cette adresse n’est pas déterminée.';
      case 'ORDER_PRICING_RULE_NOT_FOUND':
        return 'Les frais de livraison ne sont pas disponibles pour cette adresse.';
      case 'ORDER_PRICING_CONFIGURATION_INVALID':
        return 'La tarification de livraison n’est pas disponible pour le moment.';
      case 'ORDER_MERCHANT_NOT_OPERATIONAL':
        return 'Ce commerce n’accepte pas de commande pour le moment.';
      case 'ORDER_BRANCH_NOT_OPERATIONAL':
        return 'Ce point de vente n’accepte pas de commande pour le moment.';
      case 'ORDER_BRANCH_CLOSED':
        return 'Ce commerce est fermé pour le moment.';
      case 'ORDER_BRANCH_HOURS_NOT_CONFIGURED':
        return 'Les horaires de ce commerce ne sont pas disponibles.';
      case 'ORDER_ALREADY_CREATED':
        return 'Une commande a déjà été créée depuis ce panier.';
      case 'ORDER_NOT_FOUND':
        return 'Cette commande est introuvable.';
      case 'DELIVERY_NOT_FOUND':
      case 'TRACKING_DELIVERY_NOT_FOUND':
        return 'Aucune livraison n’est encore associée à cette commande.';
      case 'TRACKING_UNAUTHORIZED':
        return 'Le suivi n’est pas disponible pour cette commande.';
      case 'ORDER_PAYMENT_METHOD_INVALID':
        return 'Ce mode de paiement n’est pas disponible.';
      case 'PAYMENT_NOT_FOUND':
        return 'Le paiement de cette commande est introuvable.';
      case 'PAYMENT_METHOD_NOT_ELECTRONIC':
        return paymentNotElectronic;
      case 'PAYMENT_ALREADY_SUCCEEDED':
        return paymentSucceededTitle;
      case 'PAYMENT_NOT_INITIABLE':
        return 'Ce paiement ne peut plus être initié.';
      case 'PAYMENT_AMOUNT_MISMATCH':
      case 'PAYMENT_CURRENCY_MISMATCH':
      case 'PAYMENT_INVALID_STATE':
        return 'Le paiement n’est pas cohérent avec la commande.';
      case 'PAYMENT_PROVIDER_UNAVAILABLE':
        return 'Le prestataire de paiement est indisponible.';
      case 'PAYMENT_PROVIDER_CONFIGURATION_INVALID':
        return 'Le prestataire de paiement n’est pas configuré.';
      case 'PAYMENT_INITIATE_SERVER_UNCERTAIN':
        return paymentInitiateUncertain;
      case 'ORDER_RECONFIRMATION_REQUIRED':
        return orderReconfirmationRequired;
      case 'ORDER_FINANCIAL_CONFIGURATION_INVALID':
      case 'ORDER_EXPECTED_AMOUNTS_INVALID':
        return 'Les montants de la commande ne sont plus valides.';
      case 'ORDER_CANCELLATION_NOT_ALLOWED':
      case 'ORDER_CANCELLATION_FULFILLMENT_ACTIVE':
      case 'ORDER_CANCELLATION_COD_COLLECTED':
      case 'ORDER_CANCELLATION_REFUND_REQUIRED':
      case 'ORDER_CANCELLATION_CONFLICT':
        return orderCancelNotEligible;
      case 'ORDER_CANCELLATION_REASON_INVALID':
        return 'Cette raison d’annulation n’est pas valide.';
      case 'ORDER_CANCELLATION_SERVER_UNCERTAIN':
        return orderCancelPendingVerification;
      case 'SUPPORT_NOT_FOUND':
        return 'Ce ticket est introuvable.';
      case 'SUPPORT_FORBIDDEN':
        return 'Le support n’est pas disponible pour ce compte.';
      case 'SUPPORT_INVALID_STATE':
        return supportReplyClosed;
      case 'SUPPORT_INVALID_INPUT':
        return supportBodyInvalid;
      case 'SUPPORT_RESOURCE_FORBIDDEN':
        return 'Cette commande ne peut pas être associée à la demande.';
      case 'SUPPORT_CREATE_UNCERTAIN':
        return supportCreateUncertain;
      case 'SUPPORT_REPLY_UNCERTAIN':
        return supportReplyUncertain;
      case 'RATING_NOT_FOUND':
        return 'Cette note est introuvable.';
      case 'RATING_FORBIDDEN':
        return 'La notation n’est pas disponible pour ce compte.';
      case 'RATING_INVALID_STATE':
        return ratingOrderIneligible;
      case 'RATING_INVALID_INPUT':
        return ratingScoreRequired;
      case 'RATING_ALREADY_EXISTS':
        return ratingAlreadyDone;
      case 'RATING_SELF_NOT_ALLOWED':
        return 'Vous ne pouvez pas noter cette cible.';
      case 'RATING_INTEGRITY':
        return 'La notation livreur n’est pas disponible pour cette commande.';
      case 'RATING_MERCHANT_UNCERTAIN':
      case 'RATING_DRIVER_UNCERTAIN':
        return ratingSubmitUncertain;
      case 'VALIDATION_ERROR':
        return 'Certaines informations sont invalides.';
      default:
        return unexpected;
    }
  }
}
