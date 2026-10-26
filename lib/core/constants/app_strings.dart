/// Customer UI copy — French (fallback) and Arabic on one shared code path.
/// Bind via [bind] when locale changes.
class AppStrings {
  AppStrings._();

  static String _code = 'fr';

  static void bind(String languageCode) {
    _code = languageCode == 'ar' ? 'ar' : 'fr';
  }

  static bool get isArabic => _code == 'ar';
  static String get languageCode => _code;

  static String get appName => isArabic ? 'SpeedyGo' : 'SpeedyGo';

  static String get splashLoading => isArabic ? 'جاري تحميل SpeedyGo…' : 'Chargement de SpeedyGo…';

  static String get phoneTitle => isArabic ? 'أدخل رقم هاتفك' : 'Entrez votre numéro de téléphone';

  static String get phoneSubtitle => isArabic ? 'سنرسل إليك رمز تأكيد عبر رسالة قصيرة.' : 'Nous vous enverrons un code de confirmation par SMS.';

  static String get phoneHint => isArabic ? '555 12 34 56' : '555 12 34 56';

  static String get phonePrefix => isArabic ? '+213' : '+213';

  static String get phoneSmsNote => isArabic ? 'قد تُطبَّق رسوم الرسائل القصيرة المعتادة.' : 'Les frais de SMS standard peuvent s’appliquer.';

  static String get phoneInvalid => isArabic ? 'أدخل رقمًا جزائريًا صالحًا.' : 'Saisissez un numéro algérien valide.';

  static String get continueLabel => isArabic ? 'متابعة' : 'Continuer';

  static String get needHelp => isArabic ? 'هل تحتاج مساعدة؟' : 'Besoin d’aide ?';

  static String get helpUnavailable => isArabic ? 'ستتوفر المساعدة في إصدار لاحق.' : 'L’assistance sera disponible dans une prochaine version.';

  static String get supportListTitle => isArabic ? 'طلباتي' : 'Mes demandes';

  static String get supportNewTitle => isArabic ? 'الإبلاغ عن مشكلة' : 'Signaler un problème';

  static String get supportDetailTitle => isArabic ? 'تذكرة الدعم' : 'Ticket support';

  static String get supportEmpty => isArabic ? 'ليس لديك أي طلب بعد.' : 'Vous n’avez pas encore de demande.';

  static String get supportListLoadError => isArabic ? 'تعذّر تحميل طلبات الدعم.' : 'Impossible de charger vos demandes de support.';

  static String get supportDetailLoadError => isArabic ? 'تعذّر تحميل هذه التذكرة.' : 'Impossible de charger ce ticket.';

  static String get supportBodyLabel => isArabic ? 'وصف المشكلة' : 'Description du problème';

  static String get supportBodyHint => isArabic ? 'يرجى وصف المشكلة بالتفصيل. لا تشارك كلمات المرور.' : 'Veuillez décrire le problème rencontré en détail. Ne partagez pas de mots de passe.';

  static String get supportBodyInvalid => isArabic ? 'يجب أن تحتوي الرسالة على ما بين 1 و 4 000 حرف.' : 'Le message doit contenir entre 1 et 4 000 caractères.';

  static String get supportSend => isArabic ? 'إرسال البلاغ' : 'Envoyer le signalement';

  static String get supportSending => isArabic ? 'جاري الإرسال…' : 'Envoi en cours…';

  static String get supportReplySend => isArabic ? 'إرسال' : 'Envoyer';

  static String get supportReplyHint => isArabic ? 'اكتب رسالة…' : 'Écrire un message…';

  static String get supportReplyClosed => isArabic ? 'هذه التذكرة مغلقة. لم يعد بإمكانك الرد عليها.' : 'Ce ticket est clôturé. Vous ne pouvez plus y répondre.';

  static String get supportOrderLinked => isArabic ? 'طلب مرتبط' : 'Commande liée';

  static String get supportOrderOptional => isArabic ? 'الطلب المرتبط هو الطلب الذي فتحت منه النموذج.' : 'La commande liée est celle depuis laquelle vous avez ouvert le formulaire.';

  static String get supportOrderLinkedFallback => isArabic ? 'طلب مرتبط' : 'Commande liée';

  static String get supportOrderLinkedLoading => isArabic ? 'جاري تحميل الطلب…' : 'Chargement de la commande…';

  static String get supportCreateUncertain => isArabic ? 'لم يُؤكَّد الإرسال. تم الاحتفاظ بنصك. راجع طلباتي قبل إعادة الإرسال.' : 'L’envoi n’a pas été confirmé. Votre texte est conservé. Consultez Mes demandes avant de renvoyer.';

  static String get supportReplyUncertain => isArabic ? 'لم يُؤكَّد إرسال الرسالة. تم الاحتفاظ بمسودتك. حدّث قبل إعادة الإرسال.' : 'L’envoi du message n’a pas été confirmé. Votre brouillon est conservé. Actualisez avant de renvoyer.';

  static String get supportMutationUncertain => isArabic ? 'لم يؤكّد الخادم العملية. لا إعادة إرسال تلقائية.' : 'Le serveur n’a pas confirmé l’opération. Aucun renvoi automatique.';

  static String get supportCheckList => isArabic ? 'عرض طلباتي' : 'Voir Mes demandes';

  static String get supportRefresh => isArabic ? 'تحديث' : 'Actualiser';

  static String get supportNewRequest => isArabic ? 'طلب جديد' : 'Nouvelle demande';

  static String get supportStatusOpen => isArabic ? 'مفتوح' : 'Ouvert';

  static String get supportStatusInProgress => isArabic ? 'قيد المعالجة' : 'En cours';

  static String get supportStatusWaitingCustomer => isArabic ? 'في انتظار ردك' : 'En attente de votre réponse';

  static String get supportStatusResolved => isArabic ? 'تم الحل' : 'Résolu';

  static String get supportStatusClosed => isArabic ? 'مغلق' : 'Fermé';

  static String get supportStatusUnknown => isArabic ? 'حالة غير معروفة' : 'Statut inconnu';

  static String get supportPriorityLabel => isArabic ? 'الأولوية' : 'Priorité';

  static String get supportPriorityLow => isArabic ? 'منخفضة' : 'Basse';

  static String get supportPriorityNormal => isArabic ? 'عادية' : 'Normale';

  static String get supportPriorityHigh => isArabic ? 'عالية' : 'Haute';

  static String get supportPriorityUnknown => isArabic ? 'أولوية غير معروفة' : 'Priorité inconnue';

  static String get supportYou => isArabic ? 'أنت' : 'Vous';

  static String get supportAgent => isArabic ? 'دعم SpeedyGo' : 'SpeedyGo Support';

  static String get supportMessageConfirmed => isArabic ? 'تم تأكيد الرسالة' : 'Message confirmé';

  static String get supportNoCancelHint => isArabic ? 'هذا الطلب لا يلغي طلبية ولا يبدأ استردادًا.' : 'Cette demande n’annule pas une commande et ne déclenche pas de remboursement.';

  static String get supportReportProblem => isArabic ? 'الإبلاغ عن مشكلة' : 'Signaler un problème';

  static String get supportLoadMore => isArabic ? 'عرض المزيد' : 'Voir plus';

  static String get supportLoadingMore => isArabic ? 'جاري التحميل…' : 'Chargement…';

  static String get supportCentreAide => isArabic ? 'مركز المساعدة' : 'Centre d’aide';

  static String get supportTicketsLabel => isArabic ? 'طلباتي' : 'Mes demandes';

  static String get ratingTitle => isArabic ? 'تقييم طلبي' : 'Noter ma commande';

  static String get ratingWriteTitle => isArabic ? 'كتابة تقييم' : 'Rédiger un avis';

  static String get ratingMerchantPrompt => isArabic ? 'كيف كانت وجبتك؟' : 'Comment était votre repas ?';

  static String get ratingDriverPrompt => isArabic ? 'كيف كانت تجربة التوصيل؟' : 'Comment s’est passée la livraison ?';

  static String get ratingDriverLabel => isArabic ? 'مندوب توصيل SpeedyGo' : 'Votre livreur SpeedyGo';

  static String get ratingWriteDetailed => isArabic ? 'كتابة تقييم مفصّل' : 'Rédiger un avis détaillé';

  static String get ratingSendScores => isArabic ? 'إرسال التقييمات' : 'Envoyer les notes';

  static String get ratingSkip => isArabic ? 'تخطي' : 'Passer';

  static String get ratingPublish => isArabic ? 'إرسال التقييم' : 'Envoyer l’avis';

  static String get ratingCommentLabel => isArabic ? 'تجربتك' : 'Votre expérience';

  static String get ratingCommentHint => isArabic ? 'صف تجربتك. لا تشارك بيانات التواصل الشخصية.' : 'Décrivez votre expérience. Ne partagez pas de coordonnées personnelles.';

  static String get ratingPrivacyNote => isArabic ? 'لسلامتك، لا تشارك بياناتك الشخصية (الهاتف، العنوان الدقيق) في تقييمك.' : 'Pour votre sécurité, ne partagez pas vos coordonnées personnelles (téléphone, adresse exacte) dans votre avis.';

  static String get ratingScoreRequired => isArabic ? 'اختر تقييمًا من 1 إلى 5 نجوم.' : 'Choisissez une note de 1 à 5 étoiles.';

  static String get ratingCommentInvalid => isArabic ? 'لا يمكن أن يتجاوز التعليق 2 000 حرف.' : 'Le commentaire ne peut pas dépasser 2 000 caractères.';

  static String get ratingOrderIneligible => isArabic ? 'يمكن تقييم الطلبات المكتملة فقط.' : 'Seules les commandes terminées peuvent être notées.';

  static String get ratingAlreadyDone => isArabic ? 'لقد قيّمت هذا الطلب مسبقًا.' : 'Vous avez déjà noté cette commande.';

  static String get ratingSuccess => isArabic ? 'شكرًا، تم تسجيل تقييمك.' : 'Merci, votre note a été enregistrée.';

  static String get ratingSubmitUncertain => isArabic ? 'لم يُؤكَّد الإرسال. تم الاحتفاظ بمسودتك. حدّث قبل إعادة الإرسال.' : 'L’envoi n’a pas été confirmé. Votre brouillon est conservé. Actualisez avant de renvoyer.';

  static String get ratingDriverUncertainPartial => isArabic ? 'تم تسجيل تقييم المتجر. لم يُؤكَّد تقييم المندوب — حدّث قبل إعادة إرسال تقييم المندوب فقط.' : 'La note commerce est enregistrée. La note livreur n’est pas confirmée — actualisez avant de renvoyer uniquement le livreur.';

  static String get ratingDriverFailedPartial => isArabic ? 'تم تسجيل تقييم المتجر. فشل تقييم المندوب — يمكنك إعادة محاولة تقييم المندوب.' : 'La note commerce est enregistrée. La note livreur a échoué — vous pouvez réessayer le livreur.';

  static String get ratingMutationUncertain => isArabic ? 'لم يؤكّد الخادم التقييم. لا إعادة إرسال تلقائية.' : 'Le serveur n’a pas confirmé la note. Aucun renvoi automatique.';

  static String get ratingLoadError => isArabic ? 'تعذّر تحميل حالة التقييم.' : 'Impossible de charger l’état de notation.';

  static String get ratingSending => isArabic ? 'جاري الإرسال…' : 'Envoi en cours…';

  static String get ratingEntry => isArabic ? 'تقييم الطلب' : 'Noter la commande';

  static String get ratingReviewsTitle => isArabic ? 'التقييمات' : 'Avis';

  static String get ratingReviewsUnsupported => isArabic ? 'التقييمات الفردية غير متاحة. إليك المعدل المؤكد من SpeedyGo.' : 'Les avis individuels ne sont pas disponibles. Voici la note moyenne confirmée par SpeedyGo.';

  static String get ratingReviewsUnsupportedEmpty => isArabic ? 'التقييمات الفردية غير متاحة.' : 'Les avis individuels ne sont pas disponibles.';

  static String get ratingNoPublicFeedEmpty => isArabic ? 'تبقى التعليقات خاصة. لا يُعرض معدل حتى يحصل المتجر على تقييمات.' : 'Les commentaires restent privés. Aucune moyenne n’est affichée tant que le commerce n’a pas de notes.';

  static String get ratingReviewsEmpty => isArabic ? 'لا توجد تقييمات لهذا المتجر حاليًا.' : 'Aucune note pour ce commerce pour le moment.';

  static String get ratingReviewsLoadError => isArabic ? 'تعذّر تحميل تقييم هذا المتجر.' : 'Impossible de charger la note de ce commerce.';

  static String get ratingAverageLabel => isArabic ? 'المعدل' : 'Note moyenne';

  static String get ratingCountLabel => isArabic ? 'تقييم' : 'avis';

  static String get ratingNoPublicFeed => isArabic ? 'تبقى التعليقات خاصة. يُعرض فقط العدد والمعدل للمتجر.' : 'Les commentaires restent privés. Seuls le total et la moyenne du commerce sont affichés.';

  static String get ratingDistributionUnavailable => isArabic ? 'التوزيع التفصيلي غير مُقدَّم من الخادم.' : 'Répartition détaillée non fournie par le serveur.';

  static String get back => isArabic ? 'رجوع' : 'Retour';

  static String get otpTitle => isArabic ? 'التحقق من الرمز' : 'Vérification du code';

  static String get editNumber => isArabic ? 'تعديل' : 'Modifier';

  static String get verify => isArabic ? 'تحقق' : 'Vérifier';

  static String get otpIncomplete => isArabic ? 'أدخل الأرقام الستة للرمز.' : 'Saisissez les 6 chiffres du code.';

  static String get resend => isArabic ? 'إعادة إرسال الرمز' : 'Renvoyer le code';

  static String get restoreTitle => isArabic ? 'تم استعادة الجلسة' : 'Session restaurée';

  static String get restoreLoading => isArabic ? 'جاري استعادة جلستك…' : 'Restauration de votre session…';

  static String get restoreOfflineTitle => isArabic ? 'الاتصال غير متاح' : 'Connexion indisponible';

  static String get restoreOffline => isArabic ? 'لم تُلغَ جلستك. أعد المحاولة عند عودة الشبكة.' : 'Votre session n’a pas été annulée. Réessayez lorsque le réseau est de retour.';

  static String get restoreRetry => isArabic ? 'إعادة المحاولة' : 'Réessayer';

  static String get restoreOtherAccount => isArabic ? 'تسجيل الدخول بحساب آخر' : 'Se connecter avec un autre compte';

  static String get restoreContinue => isArabic ? 'متابعة' : 'Continuer';

  static String get welcomeWordmark => isArabic ? 'SPEEDYGO' : 'SPEEDYGO';

  static String get welcomeDiscoverEyebrow => isArabic ? 'اكتشف' : 'DÉCOUVREZ';

  static String get welcomeDiscoverTitle => isArabic ? 'ما تشتهيه،\nفي متناول يدك.' : 'Vos envies,\nà portée de main.';

  static String get welcomeDiscoverBody => isArabic ? 'استكشف المتاجر واعثر على\nما يسعدك.' : 'Explorez les commerces et trouvez\nce qui vous fait plaisir.';

  static String get welcomeOrderEyebrow => isArabic ? 'اطلب' : 'COMMANDEZ';

  static String get welcomeOrderTitle => isArabic ? 'ما يعجبك،\nببضع نقرات.' : 'Un coup de cœur,\nquelques clics.';

  static String get welcomeOrderBody => isArabic ? 'اختر منتجاتك وجهّز\nطلبك بكل سهولة.' : 'Choisissez vos produits et préparez\nvotre commande en toute simplicité.';

  static String get welcomeTrackEyebrow => isArabic ? 'تابع' : 'SUIVEZ';

  static String get welcomeTrackTitle => isArabic ? 'طلبك،\nفي كل مرحلة.' : 'Votre commande,\nà chaque étape.';

  static String get welcomeTrackBody => isArabic ? 'من التحضير إلى التوصيل،\nتابع تقدّمه في التطبيق.' : 'De la préparation à la livraison,\nsuivez son avancement dans l’application.';

  static String get welcomeTrackLiveTitle => isArabic ? 'المندوب في الطريق' : 'Le livreur arrive';

  static String get welcomeTrackLiveEta => isArabic ? 'الوصول المتوقع خلال 8 دقائق' : 'Arrivée prévue dans 8 min';

  static String get skip => isArabic ? 'تخطي' : 'Passer';

  static String get next => isArabic ? 'التالي' : 'Suivant';

  static String get start => isArabic ? 'ابدأ' : 'Commencer';

  static String get profileTitle => isArabic ? 'الملف الشخصي' : 'Profil';

  static String get profileStep => isArabic ? 'الخطوة 2 من 2' : 'Étape 2 sur 2';

  static String get fullNameLabel => isArabic ? 'الاسم الكامل' : 'Nom complet';

  static String get fullNameHint => isArabic ? 'مثال: Amel Benali' : 'Ex: Amel Benali';

  static String get fullNameRequired => isArabic ? 'الاسم الكامل إلزامي.' : 'Le nom complet est obligatoire.';

  static String get profileConsentPrefix => isArabic ? 'بالمتابعة، فإنك توافق على ' : 'En continuant, vous acceptez nos ';

  static String get profileTermsLink => isArabic ? 'الشروط العامة' : 'Conditions Générales';

  static String get profileConsentMid => isArabic ? ' وتؤكد أنك اطّلعت على ' : ' et confirmez avoir lu notre ';

  static String get profilePrivacyLink => isArabic ? 'سياسة الخصوصية' : 'Politique de Confidentialité';

  static String get profileConsent => isArabic ? 'بالمتابعة، فإنك توافق على الشروط العامة وتؤكد أنك اطّلعت على سياسة الخصوصية.' : 'En continuant, vous acceptez nos Conditions Générales et confirmez avoir lu notre Politique de Confidentialité.';

  static String get profileSaving => isArabic ? 'جاري المعالجة…' : 'Traitement…';

  static String get profilePhotoUnavailable => isArabic ? 'صورة الملف الشخصي غير مدعومة بعد.' : 'La photo de profil n’est pas encore prise en charge.';

  static String get landingTitle => isArabic ? 'دمج SpeedyGo' : 'Intégration SpeedyGo';

  static String get landingBody => isArabic ? 'الاتصال يعمل. سيتم ربط الكتالوج والسلة والتتبّع في مرحلة لاحقة. هذه الشاشة ليست الصفحة الرئيسية النهائية.' : 'La connexion fonctionne. Le catalogue, le panier et le suivi seront branchés dans une prochaine étape. Cet écran n’est pas l’accueil définitif.';

  static String get languageTitle => isArabic ? 'اختر لغتك' : 'Choisissez votre langue';

  static String get languageSubtitle => isArabic ? 'يمكنك تغيير اللغة لاحقًا من ملفك الشخصي.' : 'Vous pourrez changer la langue plus tard depuis votre profil.';

  static String get languageFrench => isArabic ? 'Français' : 'Français';

  static String get languageFrenchHint => isArabic ? 'من اليسار إلى اليمين' : 'De gauche à droite';

  static String get languageFrenchHintSettings => isArabic ? 'شائعة الاستخدام في الجزائر' : 'Couramment utilisée en Algérie';

  static String get languageArabic => isArabic ? 'العربية' : 'العربية';

  static String get languageArabicLabel => isArabic ? 'العربية' : 'Arabe (العربية)';

  static String get languageArabicHint => isArabic ? 'من اليمين إلى اليسار' : 'من اليمين إلى اليسار';

  static String get languageArabicHintSettings => isArabic ? 'لغة وطنية ورسمية' : 'Langue nationale et officielle';

  static String get languageArabicUnavailable => isArabic ? 'غير متاح حاليًا. يبقى التطبيق بالفرنسية.' : 'Indisponible pour le moment. L’application reste en français.';

  static String get languageArabicDisabled => isArabic ? 'قريبًا' : 'Bientôt disponible';

  static String get languageSettingsSubtitle => isArabic ? 'اختر لغة الواجهة المفضّلة لتطبيق SpeedyGo.' : 'Choisissez votre langue de préférence pour l’application SpeedyGo.';

  static String get languageDirectionHeading => isArabic ? 'معاينة الاتجاه' : 'Aperçu de la direction';

  static String get languageDirectionLtr => isArabic ? 'LTR (من اليسار إلى اليمين)' : 'LTR (Gauche à Droite)';

  static String get languageDirectionRtl => isArabic ? 'RTL' : 'RTL';

  static String get languageDirectionPreviewTitle => isArabic ? 'الرئيسية' : 'Accueil';

  static String get languageDirectionPreviewSubtitle => isArabic ? 'التنقّل الحالي' : 'Navigation actuelle';

  static String get languageSessionNote => isArabic ? 'سيتم الاحتفاظ ببياناتك وجلستك الحالية. الفرنسية والعربية متاحتان؛ لا حاجة لإعادة التشغيل.' : 'Vos données et votre session actuelle seront conservées. Le français et l’arabe sont disponibles ; aucun redémarrage n’est requis.';

  static String get languageSave => isArabic ? 'حفظ التعديلات' : 'Enregistrer les modifications';

  static String get previewUnavailable => isArabic ? 'هذه المعاينة غير متاحة في التنقّل العادي.' : 'Cet aperçu n’est pas disponible dans la navigation normale.';

  static String get previewBanner => isArabic ? 'معاينة تطوير — ليست تنقّل المنتج.' : 'Aperçu développement — pas la navigation produit.';

  static String get previewEnableTitle => isArabic ? 'معاينة التنقّل' : 'Aperçu de navigation';

  static String get previewEnableBody => isArabic ? 'دليل شاشات مؤقتة. لا بيانات تشغيلية. معطّل في الإصدار النهائي.' : 'Répertoire des écrans placeholder. Aucune donnée métier. Désactivé en release.';

  static String get previewEnableAction => isArabic ? 'فتح المعاينة' : 'Ouvrir l’aperçu';

  static String get ordersEmpty => isArabic ? 'لا توجد طلبات حاليًا.' : 'Aucune commande pour le moment.';

  static String get nearbyEmpty => isArabic ? 'لم يُحمَّل أي تاجر قريب حاليًا.' : 'Aucun commerçant à proximité n’est chargé pour le moment.';

  static String get languageTermsPrefix => isArabic ? 'بالمتابعة، فإنك توافق على ' : 'En continuant, vous acceptez nos ';

  static String get languageTermsLink => isArabic ? 'شروط الاستخدام' : 'Conditions d’utilisation';

  static String get tabHome => isArabic ? 'الرئيسية' : 'Accueil';

  static String get tabSearch => isArabic ? 'بحث' : 'Recherche';

  static String get tabOrders => isArabic ? 'الطلبات' : 'Commandes';

  static String get tabAlerts => isArabic ? 'التنبيهات' : 'Alertes';

  static String get tabProfile => isArabic ? 'الملف الشخصي' : 'Profil';

  static String get navOnlyBadge => isArabic ? 'تنقّل فقط' : 'Navigation seule';

  static String get unsupportedBadge => isArabic ? 'واجهة API غائبة' : 'API absente';

  static String get productDecisionBadge => isArabic ? 'قرار المنتج' : 'Décision produit';

  static String get liveAuthBadge => isArabic ? 'مصادقة حقيقية' : 'Auth réelle';

  static String get navFixtureNote => isArabic ? 'معرّف تنقّل فقط. لا تُنفَّذ أي عملية تشغيلية.' : 'Identifiant de navigation uniquement. Aucune opération métier n’est exécutée.';

  static String get navBlocked => isArabic ? 'هذا الإجراء غير مربوط. لم تُنفَّذ أي عملية.' : 'Cette action n’est pas branchée. Aucune opération n’a été effectuée.';

  static String get navUnsupported => isArabic ? 'هذه الوظيفة غير موجودة على الخادم. لم تُنفَّذ أي عملية.' : 'Cette fonction n’existe pas côté serveur. Aucune opération n’a été effectuée.';

  static String get navProductDecision => isArabic ? 'العقد غير مكتمل. لم تُنفَّذ أي عملية.' : 'Contrat incomplet. Aucune opération n’a été effectuée.';

  static String get allScreens => isArabic ? 'كل الشاشات' : 'Tous les écrans';

  static String get allScreensHint => isArabic ? 'مراجع العميل. تبقى الإجراءات التشغيلية غير مربوطة.' : 'Références Customer. Les actions métier restent non branchées.';

  static String get deliverTo => isArabic ? 'التوصيل إلى' : 'Livrer à';

  static String get deliverToUnset => isArabic ? 'العنوان غير محدّد' : 'Adresse non définie';

  static String get deliverToSaved => isArabic ? 'عنوان محفوظ' : 'Adresse enregistrée';

  static String get searchHint => isArabic ? 'ابحث عن متجر أو منتج' : 'Rechercher un commerce ou produit';

  static String get categories => isArabic ? 'الفئات' : 'Catégories';

  static String get seeAll => isArabic ? 'عرض الكل' : 'Tout voir';

  static String get allCategoriesTitle => isArabic ? 'كل الفئات' : 'Toutes les catégories';

  static String get categoriesSearchHint => isArabic ? 'ابحث عن فئة...' : 'Rechercher une catégorie...';

  static String get categoriesExploreHeading => isArabic ? 'استكشف حسب القسم' : 'Explorer par rayon';

  static String get categoriesEmpty => isArabic ? 'لا توجد فئة نشطة.' : 'Aucune catégorie active.';

  static String get categoriesSearchEmpty => isArabic ? 'لا توجد فئة تطابق بحثك.' : 'Aucune catégorie ne correspond à votre recherche.';

  static String get categoriesLoadError => isArabic ? 'تعذّر تحميل الفئات.' : 'Impossible de charger les catégories.';

  static String get coverLoadError => isArabic ? 'الصورة غير متاحة' : 'Image indisponible';

  static String get nearbyMerchants => isArabic ? 'تجار قريبون' : 'Commerçants à proximité';

  static String get storefrontsTitle => isArabic ? 'المتاجر' : 'Commerces';

  static String get storefrontsEmpty => isArabic ? 'لا يوجد متجر ظاهر.' : 'Aucun commerce visible.';

  static String get storefrontsOpenNow => isArabic ? 'مفتوحة الآن' : 'Ouverts maintenant';

  static String get storefrontsOpenNowEmpty => isArabic ? 'لا يوجد متجر مفتوح حاليًا.' : 'Aucun commerce ouvert pour le moment.';

  static String get storefrontsShowAll => isArabic ? 'عرض كل المتاجر' : 'Afficher tous les commerces';

  static String get hoursOpen => isArabic ? 'مفتوح' : 'Ouvert';

  static String get hoursOpenUntil => isArabic ? 'مفتوح حتى' : 'Ouvert jusqu’à';

  static String get hoursClosed => isArabic ? 'مغلق' : 'Fermé';

  static String get hoursUnconfigured => isArabic ? 'أوقات العمل غير مذكورة' : 'Horaires non renseignés';

  static String get hoursClosesAt => isArabic ? 'يغلق عند' : 'Ferme à';

  static String get hoursOpensAt => isArabic ? 'يفتح عند' : 'Ouvre à';

  static String get allProducts => isArabic ? 'الكل' : 'Tous';

  static String get productsEmpty => isArabic ? 'لا يوجد منتج متاح في هذه الفئة.' : 'Aucun produit disponible dans cette catégorie.';

  static String get productsEmptyUnfiltered => isArabic ? 'لا يوجد منتج متاح حاليًا.' : 'Aucun produit disponible pour le moment.';

  static String get searchEmpty => isArabic ? 'لا توجد نتائج لهذا البحث.' : 'Aucun résultat pour cette recherche.';

  static String get searchNeedTwoChars => isArabic ? 'أدخل حرفين على الأقل.' : 'Saisissez au moins 2 caractères.';

  static String get searchStorefronts => isArabic ? 'المتاجر' : 'Commerces';

  static String get searchProducts => isArabic ? 'المنتجات' : 'Produits';

  static String get storefrontInfo => isArabic ? 'معلومات' : 'Infos';

  static String get storefrontInfoScreenTitle => isArabic ? 'معلومات عن التاجر' : 'Infos sur le marchand';

  static String get storefrontAddressSection => isArabic ? 'العنوان' : 'Adresse';

  static String get storefrontMenu => isArabic ? 'القائمة' : 'Menu';

  static String get weeklyHours => isArabic ? 'أوقات العمل' : 'Horaires';

  static String get openingHoursSection => isArabic ? 'ساعات العمل' : 'Horaires d’ouverture';

  static String get hoursTodaySuffix => isArabic ? '(اليوم)' : '(Aujourd’hui)';

  static String get cartUnavailable => isArabic ? 'السلة غير متاحة بعد. لم تُضَف أي سلعة.' : 'Le panier n’est pas encore disponible. Aucun article n’a été ajouté.';

  static String get addToCart => isArabic ? 'أضف إلى السلة' : 'Ajouter au panier';

  static String get customizeProduct => isArabic ? 'تخصيص' : 'Personnaliser';

  static String get customizeTitle => isArabic ? 'تخصيص' : 'Personnaliser';

  static String get cartTitle => isArabic ? 'السلة' : 'Panier';

  static String get cartEmpty => isArabic ? 'سلتك فارغة.' : 'Votre panier est vide.';

  static String get cartEmptyHint => isArabic ? 'أضف منتجًا من متجر للبدء.' : 'Ajoutez un produit depuis un commerce pour commencer.';

  static String get cartLoadError => isArabic ? 'تعذّر تحميل السلة.' : 'Impossible de charger le panier.';

  static String get cartMerchandiseSubtotal => isArabic ? 'مجموع المنتجات' : 'Sous-total marchandises';

  static String get cartOrderSummary => isArabic ? 'الملخص' : 'Résumé';

  static String get cartSubtotalHint => isArabic ? 'يُحسب التوصيل والخصومات عند المراجعة.' : 'La livraison et les remises sont calculées à la vérification.';

  static String get checkoutUnavailable => isArabic ? 'الدفع غير متاح بعد. لم يُنشأ أي طلب.' : 'Le paiement n’est pas encore disponible. Aucune commande n’a été créée.';

  static String get checkoutAction => isArabic ? 'مراجعة طلبي' : 'Vérifier ma commande';

  static String get checkoutReviewHint => isArabic ? 'لا يُنشأ طلب في هذه المرحلة.' : 'Aucune commande n’est créée à cette étape.';

  static String get checkoutReviewTitle => isArabic ? 'مراجعة الطلب' : 'Révision de la commande';

  static String get checkoutVerifying => isArabic ? 'جاري التحقق من الطلب…' : 'Vérification de la commande…';

  static String get checkoutNeedAddress => isArabic ? 'اختر عنوان توصيل للتحقق من الطلب.' : 'Choisissez une adresse de livraison pour vérifier la commande.';

  static String get checkoutChooseAddress => isArabic ? 'اختيار عنوان' : 'Choisir une adresse';

  static String get checkoutChangeAddress => isArabic ? 'تعديل العنوان' : 'Modifier l’adresse';

  static String get checkoutDeliveryAddress => isArabic ? 'عنوان التوصيل' : 'Adresse de livraison';

  static String get checkoutMerchandise => isArabic ? 'مجموع المنتجات' : 'Sous-total marchandises';

  static String get checkoutDeliveryFee => isArabic ? 'رسوم التوصيل' : 'Frais de livraison';

  static String get checkoutDiscount => isArabic ? 'خصم' : 'Remise';

  static String get checkoutPayable => isArabic ? 'الإجمالي المستحق' : 'Total à payer';

  static String get checkoutPromoLabel => isArabic ? 'رمز ترويجي' : 'Code promo';

  static String get checkoutPromoHint => isArabic ? 'أدخل رمزًا' : 'Saisir un code';

  static String get checkoutPromoApply => isArabic ? 'تطبيق' : 'Appliquer';

  static String get checkoutPromoRemove => isArabic ? 'إزالة' : 'Retirer';

  static String get checkoutPromoEmpty => isArabic ? 'أدخل رمزًا ترويجيًا.' : 'Saisissez un code promo.';

  static String get checkoutPromoCopiedHint => isArabic ? 'لا يُطبَّق الرمز المنسوخ ما لم تؤكّده المراجعة.' : 'Un code copié n’est pas appliqué tant que la vérification ne le confirme pas.';

  static String get checkoutPriceChanged => isArabic ? 'تغيّر سعر سلعة. المبالغ أدناه محدَّثة.' : 'Le prix d’un article a changé. Les montants ci-dessous sont à jour.';

  static String get checkoutPlaceOrder => isArabic ? 'اطلب' : 'Commander';

  static String get checkoutPlaceOrderUnavailable => isArabic ? 'اختر طريقة دفع وتحقّق من الطلب.' : 'Choisissez un mode de paiement et vérifiez la commande.';

  static String get checkoutSubmitting => isArabic ? 'جاري إرسال الطلب…' : 'Envoi de la commande…';

  static String get checkoutReconfirmRequired => isArabic ? 'تغيّرت المبالغ. راجع الإجماليات ثم أكّد مجددًا.' : 'Les montants ont changé. Vérifiez les totaux, puis confirmez à nouveau.';

  static String get checkoutPaymentTitle => isArabic ? 'طريقة الدفع' : 'Mode de paiement';

  static String get checkoutPaymentChoose => isArabic ? 'اختر كيف تدفع' : 'Choisissez comment payer';

  static String get checkoutPaymentHint => isArabic ? 'تُختار طريقة الدفع عند إرسال الطلب. لا تُرسل عند المراجعة ولا تغيّر الإجماليات.' : 'Le mode de paiement est choisi au moment de la commande. Il n’est pas envoyé à la vérification et ne change pas les totaux.';

  static String get checkoutPaymentCod => isArabic ? 'الدفع عند الاستلام' : 'Paiement à la livraison';

  static String get checkoutPaymentCodBody => isArabic ? 'ادفع المبلغ المحدد لمندوب التوصيل عند الوصول.' : 'Payez le montant exact au livreur à l’arrivée.';

  static String get checkoutPaymentElectronic => isArabic ? 'الدفع الإلكتروني' : 'Paiement électronique';

  static String get checkoutPaymentElectronicSoon => isArabic ? 'قريبًا' : 'Bientôt disponible';

  static String get checkoutPaymentElectronicHint => isArabic ? 'سيتم توجيهك إلى مقدّم الخدمة بعد إرسال الطلب. العودة من المتصفح لا تؤكّد الدفع.' : 'Vous serez redirigé vers le prestataire après l’envoi de la commande. Un retour navigateur ne confirme pas le paiement.';

  static String get checkoutPaymentElectronicUnavailable => isArabic ? 'غير متاح حاليًا. يُعرض الدفع عند الاستلام فقط.' : 'Indisponible pour le moment. Seul le paiement à la livraison est proposé.';

  static String get checkoutPaymentMethodUnavailable => isArabic ? 'طريقة الدفع هذه غير متاحة. اختر طريقة متاحة (الدفع عند الاستلام). لم يُغيَّر اختيارك تلقائيًا.' : 'Ce mode de paiement n’est pas disponible. Choisissez un mode disponible (paiement à la livraison). Votre sélection n’a pas été modifiée automatiquement.';

  static String get checkoutPaymentLater => isArabic ? 'متاح عند الطلب، وليس في هذه المرحلة.' : 'Disponible à la commande, pas à cette étape.';

  static String get checkoutPaymentSelected => isArabic ? 'محدَّد' : 'Sélectionné';

  static String get checkoutPaymentSecurityNote => isArabic ? 'يُعرض الدفع الإلكتروني فقط عند تفعيله. لا تُدخل أي بيانات بنكية في SpeedyGo.' : 'Le paiement électronique n’est proposé que lorsqu’il est activé. Aucune donnée bancaire n’est saisie dans SpeedyGo.';

  static String get checkoutBackToReview => isArabic ? 'العودة إلى المراجعة' : 'Retour à la révision';

  static String get checkoutContinue => isArabic ? 'متابعة' : 'Continuer';

  static String get checkoutPlaceOrderElectronic => isArabic ? 'إرسال الطلب ثم الدفع' : 'Envoyer la commande puis payer';

  static String get paymentTitle => isArabic ? 'الدفع' : 'Paiement';

  static String get paymentRedirectTitle => isArabic ? 'التوجيه إلى الدفع' : 'Redirection vers le paiement';

  static String get paymentReadyTitle => isArabic ? 'دفع مطلوب' : 'Paiement à effectuer';

  static String get paymentReadyBody => isArabic ? 'تم تسجيل طلبك. ابدأ الدفع لدى مقدّم الخدمة. حالة الخادم وحدها هي المرجع.' : 'Votre commande est enregistrée. Démarrez le paiement auprès du prestataire. Le statut serveur fait seule autorité.';

  static String get paymentPendingTitle => isArabic ? 'الدفع قيد المعالجة' : 'Paiement en cours';

  static String get paymentPendingBody => isArabic ? 'يعالج مقدّم الخدمة دفعتك. العودة من المتصفح أو عنوان URL لا يعني أن الدفع مؤكد.' : 'Le prestataire traite votre paiement. Un retour navigateur ou une URL ne signifie pas que le paiement est confirmé.';

  static String get paymentSucceededTitle => isArabic ? 'تم تأكيد الدفع' : 'Paiement confirmé';

  static String get paymentSucceededBody => isArabic ? 'أكّد الخادم الدفع. هذا لا يعني أن المتجر قبل الطلب ولا أن مندوب توصيل قد عُيّن.' : 'Le serveur a confirmé le paiement. Cela ne signifie pas que le commerce a accepté la commande ni qu’un livreur est assigné.';

  static String get paymentFailedTitle => isArabic ? 'لم يكتمل الدفع' : 'Paiement non abouti';

  static String get paymentFailedBody => isArabic ? 'لم يكتمل الدفع. يمكنك إعادة المحاولة على نفس الطلب دون إنشاء طلب جديد.' : 'Le paiement n’a pas abouti. Vous pouvez réessayer sur la même commande sans en créer une nouvelle.';

  static String get paymentCancelledTitle => isArabic ? 'تم إلغاء الدفع' : 'Paiement annulé';

  static String get paymentCancelledBody => isArabic ? 'أُلغيت نية الدفع لدى SpeedyGo.' : 'L’intention de paiement est annulée côté SpeedyGo.';

  static String get paymentPayNow => isArabic ? 'ادفع الآن' : 'Payer maintenant';

  static String get paymentInitiating => isArabic ? 'جاري فتح الدفع…' : 'Ouverture du paiement…';

  static String get paymentCheckStatus => isArabic ? 'التحقق من الحالة' : 'Vérifier le statut';

  static String get paymentRefresh => isArabic ? 'تحديث' : 'Actualiser';

  static String get paymentGoConfirmation => isArabic ? 'عرض التأكيد' : 'Voir la confirmation';

  static String get paymentAmountLabel => isArabic ? 'المبلغ' : 'Montant';

  static String get paymentStatusLabel => isArabic ? 'حالة الدفع' : 'Statut du paiement';

  static String get paymentAttemptLabel => isArabic ? 'محاولة' : 'Tentative';

  static String get paymentProviderLabel => isArabic ? 'مقدّم الخدمة' : 'Prestataire';

  static String get paymentStatusPending => isArabic ? 'قيد الانتظار' : 'En attente';

  static String get paymentStatusProcessing => isArabic ? 'قيد المعالجة' : 'En cours';

  static String get paymentStatusSucceeded => isArabic ? 'مؤكد' : 'Confirmé';

  static String get paymentStatusFailed => isArabic ? 'فشل' : 'Échoué';

  static String get paymentStatusCancelled => isArabic ? 'ملغى' : 'Annulé';

  static String get paymentStatusUnknown => isArabic ? 'غير معروف' : 'Inconnu';

  static String get paymentBrowserReturnHint => isArabic ? 'تم رصد العودة. لا يُعدّ الدفع ناجحًا ما لم يؤكّده الخادم.' : 'Retour détecté. Le paiement n’est pas considéré comme réussi tant que le serveur ne l’a pas confirmé.';

  static String get paymentTestCheckoutHint => isArabic ? 'أعاد مقدّم الاختبار عنوان URL غير قابل للفتح في المتصفح. لا يُنشأ webhook. تحقّق من حالة الخادم أو اضبط Chargily sandbox.' : 'Le prestataire de test a renvoyé une URL non ouvrable dans le navigateur. Aucun webhook n’est forgé. Vérifiez le statut serveur ou configurez Chargily sandbox.';

  static String get paymentCheckoutMissing => isArabic ? 'لم يُرجع أي عنوان URL صالح للدفع.' : 'Aucune URL de paiement utilisable n’a été renvoyée.';

  static String get paymentCheckoutRejectedHttp => isArabic ? 'رُفض عنوان URL للدفع عبر HTTP. يُفتح HTTPS فقط على مضيف مقدّم خدمة معتمد.' : 'L’URL de paiement HTTP a été refusée. Seul HTTPS sur un hôte prestataire approuvé est ouvert.';

  static String get paymentCheckoutRejectedHost => isArabic ? 'عنوان URL للدفع لا ينتمي إلى مضيف مقدّم خدمة معتمد.' : 'L’URL de paiement n’appartient pas à un hôte prestataire approuvé.';

  static String get paymentCheckoutRejectedTest => isArabic ? 'لا تُستخدم عناوين URL الاختبارية في وضع العميل العادي.' : 'Les URL de test ne sont pas utilisées en mode Client normal.';

  static String get paymentInitiateDisabled => isArabic ? 'الدفع الإلكتروني غير مفعّل على هذا التطبيق. تُعرض الحالة الحالية دون محاولة جديدة.' : 'Le paiement électronique n’est pas activé sur cette application. Le statut actuel est affiché sans nouvelle tentative.';

  static String get paymentInitiateUncertain => isArabic ? 'لم يُؤكَّد بدء الدفع. لا يُعاد إنشاء الطلب. تحقّق من حالة الدفع.' : 'L’initiation n’a pas été confirmée. La commande n’est pas recréée. Vérifiez le statut du paiement.';

  static String get paymentPollingPaused => isArabic ? 'التحقق التلقائي متوقف مؤقتًا. حدّث لإعادة تحميل حالة الخادم.' : 'La vérification automatique est en pause. Actualisez pour recharger le statut serveur.';

  static String get paymentLoadError => isArabic ? 'تعذّر تحميل الدفع.' : 'Impossible de charger le paiement.';

  static String get paymentNotElectronic => isArabic ? 'هذا الطلب لا يستخدم الدفع الإلكتروني.' : 'Cette commande n’utilise pas le paiement électronique.';

  static String get paymentContinue => isArabic ? 'متابعة الدفع' : 'Continuer le paiement';

  static String get paymentSuccessDistinctHint => isArabic ? 'نجاح الدفع منفصل عن قبول المتجر وعن التوصيل.' : 'Le succès du paiement est distinct de l’acceptation du commerce et de la livraison.';

  static String get orderReconfirmationRequired => isArabic ? 'تغيّرت المبالغ منذ آخر تحقق. أكّد الإجماليات الجديدة.' : 'Les montants ont changé depuis votre dernière vérification. Confirmez les nouveaux totaux.';

  static String get orderSubmissionPendingVerification => isArabic ? 'تعذّر تأكيد إرسال الطلب.' : 'Nous n’avons pas pu confirmer l’envoi de la commande.';

  static String get orderSubmissionPendingHint => isArabic ? 'ربما انقطع اتصالك. راجع طلباتك قبل إعادة إرسال طلب.' : 'Votre connexion a peut-être été interrompue. Consultez vos commandes avant de renvoyer une commande.';

  static String get orderSubmissionServerUncertain => isArabic ? 'لم يؤكّد الخادم الطلب. راجع طلباتك قبل إعادة المحاولة.' : 'Le serveur n’a pas confirmé la commande. Vérifiez vos commandes avant de réessayer.';

  static String get orderSubmissionViewOrders => isArabic ? 'عرض طلباتي' : 'Voir mes commandes';

  static String get orderSubmissionCheckAgain => isArabic ? 'التحقق مجددًا' : 'Vérifier à nouveau';

  static String get orderConfirmationTitle => isArabic ? 'تم إرسال الطلب' : 'Commande envoyée';

  static String get orderConfirmationSent => isArabic ? 'تم إرسال طلبك إلى المتجر.' : 'Votre commande a bien été transmise au commerce.';

  static String get orderConfirmationAwaitingMerchant => isArabic ? 'بانتظار تأكيد المتجر. لم يُعيَّن مندوب توصيل بعد.' : 'Elle est en attente de confirmation par le commerce. Aucun livreur n’est assigné pour le moment.';

  static String get orderConfirmationAwaitingMerchantShort => isArabic ? 'بانتظار تأكيد المتجر' : 'En attente de confirmation du commerce';

  static String get orderConfirmationPaymentPending => isArabic ? 'غير مؤكد من الخادم' : 'Non confirmé par le serveur';

  static String get orderConfirmationPaymentSucceeded => isArabic ? 'مؤكد من الخادم' : 'Confirmé par le serveur';

  static String get orderConfirmationPaymentFailed => isArabic ? 'فشل الدفع' : 'Paiement échoué';

  static String get orderConfirmationPaymentCancelled => isArabic ? 'تم إلغاء الدفع' : 'Paiement annulé';

  static String get orderConfirmationNoPaymentCollected => isArabic ? 'يُحصَّل عند التوصيل' : 'À encaisser à la livraison';

  static String get orderConfirmationAmountPaid => isArabic ? 'المبلغ المدفوع' : 'Montant payé';

  static String get orderConfirmationAmountCod => isArabic ? 'يُسدَّد عند الاستلام' : 'À régler à la livraison';

  static String get orderConfirmationAmountDue => isArabic ? 'المبلغ' : 'Montant';

  static String get orderConfirmationViewDetail => isArabic ? 'عرض التفاصيل' : 'Voir le détail';

  static String get orderConfirmationBackHome => isArabic ? 'العودة إلى الرئيسية' : 'Retour à l’accueil';

  static String get orderDetailTitle => isArabic ? 'طلبي' : 'Ma commande';

  static String get orderReferenceLabel => isArabic ? 'المرجع' : 'Référence';

  static String get orderStatusLabel => isArabic ? 'الحالة' : 'Statut';

  static String get orderPaymentMethodLabel => isArabic ? 'الدفع' : 'Paiement';

  static String get orderPaymentDetailsTitle => isArabic ? 'تفاصيل الدفع' : 'Détails du paiement';

  static String get orderDeliveryAddressLabel => isArabic ? 'عنوان التوصيل' : 'Adresse de livraison';

  static String get orderDeliveryPlaceLabel => isArabic ? 'مكان التوصيل' : 'Lieu de livraison';

  static String get orderItemsLabel => isArabic ? 'السلع' : 'Articles';

  static String get orderItemsOrderedLabel => isArabic ? 'السلع المطلوبة' : 'Articles commandés';

  static String get orderUnitPriceLabel => isArabic ? 'للوحدة' : 'par unité';

  static String get orderLoadError => isArabic ? 'تعذّر تحميل هذا الطلب.' : 'Impossible de charger cette commande.';

  static String get ordersLoadError => isArabic ? 'تعذّر تحميل طلباتك.' : 'Impossible de charger vos commandes.';

  static String get ordersTabInProgress => isArabic ? 'قيد التنفيذ' : 'En cours';

  static String get ordersTabCompleted => isArabic ? 'مكتملة' : 'Terminées';

  static String get ordersTabCancelled => isArabic ? 'ملغاة' : 'Annulées';

  static String get ordersEmptyFiltered => isArabic ? 'لا توجد طلبات في هذه الفئة.' : 'Aucune commande dans cette catégorie.';

  static String get ordersOlderHint => isArabic ? 'قد توجد طلبات أقدم. حمّل الصفحة التالية.' : 'Des commandes plus anciennes peuvent exister. Chargez la page suivante.';

  static String get accountPaymentMethodsTitle => isArabic ? 'طرق الدفع' : 'Méthodes de paiement';

  static String get accountPaymentMethodsBody => isArabic ? 'لا توجد بطاقة محفوظة. تُختار طريقة الدفع عند إرسال الطلب. الدفع عند الاستلام متاح. يُعرض الدفع الإلكتروني فقط عند تفعيله على هذا التطبيق.' : 'Aucune carte n’est enregistrée. Le mode de paiement se choisit au moment de la commande. Le paiement à la livraison est disponible. Le paiement électronique n’est proposé que lorsqu’il est activé sur cette application.';

  static String get accountDeleteTitle => isArabic ? 'حذف حسابي' : 'Supprimer mon compte';

  static String get accountDeleteBody => isArabic ? 'حذف الحساب غير متاح. SpeedyGo لا يستخدم كلمة مرور: يتم الدخول برمز SMS. لا يُرسل هذا الإجراء إلى الخادم.' : 'La suppression de compte n’est pas disponible. SpeedyGo n’utilise pas de mot de passe : la connexion se fait par code SMS. Cette action n’est pas envoyée au serveur.';

  static String get accountDeleteAction => isArabic ? 'حذف نهائي' : 'Supprimer définitivement';

  static String get accountNotificationsSettingsTitle => isArabic ? 'الإشعارات' : 'Notifications';

  static String get accountNotificationsSettingsBody => isArabic ? 'تظهر تنبيهات الطلب في تبويب التنبيهات. لا تُحفظ أي تفضيلات إشعار على الخادم، ولا تُطلب إشعارات النظام هنا.' : 'Les alertes de commande s’affichent dans l’onglet Alertes. Aucune préférence de notification n’est enregistrée sur le serveur, et les notifications système ne sont pas demandées ici.';

  static String get accountNotificationsOpenInbox => isArabic ? 'عرض التنبيهات' : 'Voir les alertes';

  static String get legalUnavailableBody => isArabic ? 'النص الرسمي غير مقدَّم بعد عبر واجهة API عامة. لا تُخترع أي سياسة هنا.' : 'Le texte officiel n’est pas encore servi par une API publique. Aucune politique n’est inventée ici.';

  static String get legalPrivacyTitle => isArabic ? 'سياسة الخصوصية' : 'Politique de confidentialité';

  static String get legalTermsTitle => isArabic ? 'شروط الاستخدام' : 'Conditions d’utilisation';

  static String get accountSectionAccount => isArabic ? 'الحساب' : 'Compte';

  static String get accountSectionPreferences => isArabic ? 'التفضيلات' : 'Préférences';

  static String get accountSectionSupport => isArabic ? 'الدعم' : 'Support';

  static String get accountSectionLegal => isArabic ? 'القانون والأمان' : 'Légal & Sécurité';

  static String get accountAddressesLabel => isArabic ? 'العناوين المحفوظة' : 'Adresses enregistrées';

  static String get accountLanguageLabel => isArabic ? 'اللغة' : 'Langue';

  static String get accountSecurityLabel => isArabic ? 'الأمان' : 'Sécurité';

  static String get checkoutNotesTitle => isArabic ? 'تعليمات خاصة' : 'Instructions spéciales';

  static String get checkoutNotesUnavailable => isArabic ? 'لا تُقبل التعليمات الخاصة عند الطلب. لا يُرسل أي حقل إلى الخادم.' : 'Les instructions spéciales ne sont pas acceptées à la commande. Aucun champ n’est envoyé au serveur.';

  static String get pspStatusUnconfirmed => isArabic ? 'حالة PSP غير مؤكدة' : 'Statut PSP non confirmé';

  static String get orderPaymentCod => isArabic ? 'الدفع عند الاستلام' : 'Paiement à la livraison';

  static String get orderPaymentElectronic => isArabic ? 'الدفع الإلكتروني' : 'Paiement électronique';

  static String get orderStatusCancelled => isArabic ? 'ملغاة' : 'Annulée';

  static String get orderStatusCompleted => isArabic ? 'تم التوصيل' : 'Livrée';

  static String get orderCancelTitle => isArabic ? 'إلغاء الطلب' : 'Annuler la commande';

  static String get orderCancelEligibleTitle => isArabic ? 'قابل للإلغاء' : 'Éligible à l’annulation';

  static String get orderCancelEligibleBody => isArabic ? 'الحالة: بانتظار تأكيد المتجر' : 'Statut : Attente de confirmation du commerce';

  static String get orderCancelNotEligible => isArabic ? 'لم يعد بالإمكان إلغاء هذا الطلب.' : 'Cette commande ne peut plus être annulée.';

  static String get orderCancelReasonLabel => isArabic ? 'سبب الإلغاء' : 'Raison de l’annulation';

  static String get orderCancelReasonOptionalHint => isArabic ? 'اختياري. السبب غير إلزامي للتأكيد.' : 'Facultatif. La raison n’est pas obligatoire pour confirmer.';

  static String get orderCancelReasonChangeOfMind => isArabic ? 'تغيير الرأي' : 'Changement d’avis';

  static String get orderCancelReasonWaitTooLong => isArabic ? 'وقت الانتظار طويل جدًا' : 'Temps d’attente trop long';

  static String get orderCancelReasonOrderError => isArabic ? 'خطأ في الطلب' : 'Erreur dans la commande';

  static String get orderCancelIrreversible => isArabic ? 'هذا الإجراء لا يمكن التراجع عنه.' : 'Cette action est irréversible.';

  static String get orderCancelConfirmAction => isArabic ? 'تأكيد الإلغاء' : 'Confirmer l’annulation';

  static String get orderCancelKeepOrder => isArabic ? 'الإبقاء على طلبي' : 'Garder ma commande';

  static String get orderCancelEntry => isArabic ? 'إلغاء الطلب' : 'Annuler la commande';

  static String get orderCancelAccepted => isArabic ? 'تم إلغاء طلبك.' : 'Votre commande a été annulée.';

  static String get orderCancelRejected => isArabic ? 'رُفض الإلغاء. لم يُلغَ الطلب.' : 'L’annulation a été refusée. La commande n’a pas été annulée.';

  static String get orderCancelPendingVerification => isArabic ? 'تعذّر تأكيد الإلغاء.' : 'Nous n’avons pas pu confirmer l’annulation.';

  static String get orderCancelPendingHint => isArabic ? 'تحقّق من حالة الطلب قبل إعادة المحاولة. لا يُعاد إرسال الإلغاء تلقائيًا.' : 'Vérifiez l’état de la commande avant de réessayer. L’annulation n’est pas renvoyée automatiquement.';

  static String get orderCancelCheckAgain => isArabic ? 'التحقق من الحالة' : 'Vérifier l’état';

  static String get orderCancelCodNoRefund => isArabic ? 'لم يُحصَّل أي دفع إلكتروني. لا يُستحق أي استرداد.' : 'Aucun paiement électronique n’avait été prélevé. Aucun remboursement n’est dû.';

  static String get orderCancelElectronicRefundIntent => isArabic ? 'قد يلزم استرداد. هذا لا يعني أن المبلغ قد أُعيد إلى حسابك.' : 'Un remboursement peut être nécessaire. Cela ne signifie pas que l’argent a déjà été recrédité.';

  static String get orderCancelElectronicRefundBankHint => isArabic ? 'بالنسبة للدفع الإلكتروني، قد يستغرق الاسترداد وقتًا بعد تأكيده من SpeedyGo.' : 'Pour les paiements électroniques, un remboursement peut prendre du temps une fois confirmé par SpeedyGo.';

  static String get orderRefundsTitle => isArabic ? 'الاسترداد' : 'Remboursement';

  static String get orderRefundsEmpty => isArabic ? 'لا يوجد استرداد مسجَّل لهذا الطلب.' : 'Aucun remboursement n’est enregistré pour cette commande.';

  static String get orderRefundStatusRequested => isArabic ? 'تم تسجيل الطلب' : 'Demande enregistrée';

  static String get orderRefundStatusUnderReview => isArabic ? 'قيد المراجعة' : 'En examen';

  static String get orderRefundStatusApproved => isArabic ? 'موافق عليه' : 'Approuvé';

  static String get orderRefundStatusProcessing => isArabic ? 'قيد المعالجة' : 'En traitement';

  static String get orderRefundStatusRefunded => isArabic ? 'تم الاسترداد' : 'Remboursé';

  static String get orderRefundStatusRejected => isArabic ? 'مرفوض' : 'Refusé';

  static String get orderRefundStatusFailed => isArabic ? 'فشل' : 'Échoué';

  static String get orderRefundNotCompletedHint => isArabic ? 'تصف هذه الحالة ملف الاسترداد، وليس استردادًا مكتملًا في حسابك.' : 'Ce statut décrit le dossier de remboursement, pas un remboursement déjà effectué sur votre compte.';

  static String get orderRefundCompletedHint => isArabic ? 'تم تأكيد الاسترداد لدى SpeedyGo.' : 'Le remboursement a été confirmé côté SpeedyGo.';

  static String get orderRefundsLoadError => isArabic ? 'تعذّر تحميل معلومات الاسترداد.' : 'Impossible de charger les informations de remboursement.';

  static String get trackingTitle => isArabic ? 'تتبّع الطلب' : 'Suivi de commande';

  static String get trackingStatusDetailsTitle => isArabic ? 'تفاصيل الحالة' : 'Détails de l’état';

  static String get trackingAwaitingMerchantTitle => isArabic ? 'بانتظار التأكيد' : 'En attente de confirmation';

  static String get trackingAwaitingMerchantBody => isArabic ? 'يتحقق المتجر من توفّر سلعك قبل تأكيد طلبك.' : 'Le commerce vérifie la disponibilité de vos articles avant de valider votre commande.';

  static String get trackingAcceptedBody => isArabic ? 'قبل المتجر طلبك.' : 'Le commerce a accepté votre commande.';

  static String get trackingPreparingBody => isArabic ? 'يحضّر المتجر طلبك.' : 'Le commerce prépare votre commande.';

  static String get trackingReadyBody => isArabic ? 'طلبك جاهز. لم يبدأ البحث عن مندوب توصيل بعد.' : 'Votre commande est prête. La recherche d’un livreur n’a pas encore commencé.';

  static String get trackingSearchingBody => isArabic ? 'تبحث SpeedyGo عن مندوب توصيل لطلبك.' : 'SpeedyGo recherche un livreur pour votre commande.';

  static String get trackingAssignedBody => isArabic ? 'تم تعيين مندوب توصيل. لم يكتمل التوصيل بعد.' : 'Un livreur est assigné. La livraison n’est pas encore terminée.';

  static String get trackingInTransitBody => isArabic ? 'طلبك في الطريق.' : 'Votre commande est en chemin.';

  static String get trackingNearbyTitle => isArabic ? 'مندوب التوصيل على وشك الوصول' : 'Votre livreur est presque arrivé';

  static String get trackingNearbyBody => isArabic ? 'أبلغ المندوب بوصوله قرب عنوانك.' : 'Le livreur a signalé son arrivée près de votre adresse.';

  static String get trackingCompletedTitle => isArabic ? 'تم توصيل الطلب' : 'Commande livrée';

  static String get trackingCompletedBody => isArabic ? 'اكتمل التوصيل.' : 'La livraison est terminée.';

  static String get trackingCancelledBody => isArabic ? 'هذا الطلب ملغى. لا يوجد توصيل جارٍ.' : 'Cette commande est annulée. Aucune livraison n’est en cours.';

  static String get trackingFailedTitle => isArabic ? 'توقّف التوصيل' : 'Livraison interrompue';

  static String get trackingFailedBody => isArabic ? 'تعذّر إكمال هذا التوصيل.' : 'Cette livraison n’a pas pu être terminée.';

  static String get trackingUnknownTitle => isArabic ? 'الحالة قيد التحديث' : 'État en cours de mise à jour';

  static String get trackingUnknownBody => isArabic ? 'الحالة الحالية غير معروضة بعد. حدّث لإعادة تحميل بيانات الخادم.' : 'L’état actuel n’est pas encore affiché. Actualisez pour recharger les données serveur.';

  static String get trackingProgression => isArabic ? 'التقدّم' : 'Progression';

  static String get trackingTimelineSent => isArabic ? 'أُرسل' : 'Envoyée';

  static String get trackingTimelineMerchant => isArabic ? 'التأكيد' : 'Confirmation';

  static String get trackingTimelinePrep => isArabic ? 'التحضير' : 'Préparation';

  static String get trackingTimelineDelivery => isArabic ? 'التوصيل' : 'Livraison';

  static String get trackingTimelineDone => isArabic ? 'مكتمل' : 'Terminée';

  static String get trackingOpenDetail => isArabic ? 'عرض التفاصيل' : 'Voir le détail';

  static String get trackingRefresh => isArabic ? 'تحديث التتبّع' : 'Actualiser le suivi';

  static String get trackingOffline => isArabic ? 'انقطع الاتصال. قد لا تكون الحالة المعروضة محدَّثة.' : 'Connexion interrompue. L’état affiché peut ne plus être à jour.';

  static String get trackingStaleHint => isArabic ? 'موقع المندوب لم يعد حديثًا. لا يُختلق أي تنقّل.' : 'La position du livreur n’est plus fraîche. Aucun déplacement inventé.';

  static String get trackingLive => isArabic ? 'موقع محدَّث' : 'Position à jour';

  static String get trackingStale => isArabic ? 'موقع قديم' : 'Position ancienne';

  static String get trackingUnavailable => isArabic ? 'الموقع غير متاح' : 'Position indisponible';

  static String get trackingNoDriver => isArabic ? 'لم يُعيَّن مندوب توصيل للتتبّع' : 'Aucun livreur assigné pour le suivi';

  static String get trackingDriverIdLabel => isArabic ? 'معرّف المندوب' : 'Identifiant livreur';

  static String get trackingLocationLabel => isArabic ? 'آخر موقع معروف' : 'Dernière position connue';

  static String get trackingRecordedAtLabel => isArabic ? 'سُجّل في' : 'Enregistrée à';

  static String get trackingMapUnavailable => isArabic ? 'لا توجد خريطة مُعدّة في التطبيق. يبقى تتبّع الحالة متاحًا.' : 'Aucune carte n’est configurée dans l’application. Le suivi d’état reste disponible.';

  static String get trackingNoCustomerGps => isArabic ? 'لا يستخدم SpeedyGo جهاز GPS لديك لعرض هذا التوصيل.' : 'SpeedyGo n’utilise pas votre GPS pour consulter cette livraison.';

  static String get trackingDeliveryCodeUnavailable => isArabic ? 'لا يوفّر الخادم رمز توصيل حاليًا.' : 'Aucun code de livraison n’est fourni par le serveur pour le moment.';

  static String get trackingPickupLabel => isArabic ? 'الاستلام' : 'Retrait';

  static String get trackingDropoffLabel => isArabic ? 'التوصيل' : 'Livraison';

  static String get trackingOrderStatusLabel => isArabic ? 'الطلب' : 'Commande';

  static String get trackingFulfillmentLabel => isArabic ? 'التحضير' : 'Préparation';

  static String get trackingDeliveryStatusLabel => isArabic ? 'التوصيل' : 'Livraison';

  static String get trackingLoadError => isArabic ? 'تعذّر تحميل التتبّع.' : 'Impossible de charger le suivi.';

  static String get trackingEntry => isArabic ? 'تتبّع الطلب' : 'Suivre la commande';

  static String get checkoutDeliveryZone => isArabic ? 'منطقة التوصيل' : 'Zone de livraison';

  static String get checkoutRetryPreview => isArabic ? 'إعادة التحقق' : 'Revérifier';

  static String get checkoutOpenCart => isArabic ? 'العودة إلى السلة' : 'Retour au panier';

  static String get removeFromCart => isArabic ? 'إزالة' : 'Retirer';

  static String get clearCart => isArabic ? 'إفراغ السلة' : 'Vider le panier';

  static String get clearCartConfirmTitle => isArabic ? 'إفراغ السلة؟' : 'Vider le panier ?';

  static String get clearCartConfirmBody => isArabic ? 'ستُزال كل سلع هذا المتجر.' : 'Tous les articles de ce commerce seront retirés.';

  static String get addAnotherItem => isArabic ? 'إضافة سلعة أخرى' : 'Ajouter un autre article';

  static String get cartAdded => isArabic ? 'أُضيف إلى السلة' : 'Ajouté au panier';

  static String get viewCart => isArabic ? 'عرض السلة' : 'Voir le panier';

  static String get optionRequired => isArabic ? 'إلزامي' : 'Obligatoire';

  static String get optionOptional => isArabic ? 'اختياري' : 'Optionnel';

  static String get cartBranchConflict => isArabic ? 'سلتك تخص متجرًا آخر. أفرغها للطلب من هنا.' : 'Votre panier appartient déjà à un autre commerce. Videz-le pour commander ici.';

  static String get cartGoToExisting => isArabic ? 'فتح السلة' : 'Ouvrir le panier';

  static String get cartKeepExisting => isArabic ? 'الاحتفاظ' : 'Conserver';

  static String get quantityLabel => isArabic ? 'الكمية' : 'Quantité';

  static String get cartItemUnavailable => isArabic ? 'هذه السلعة لم تعد متاحة.' : 'Cet article n’est plus disponible.';

  static String get cartNotReady => isArabic ? 'بعض سلع السلة لم تعد صالحة.' : 'Certains articles du panier ne sont plus valides.';

  static String get addingToCart => isArabic ? 'جاري الإضافة إلى السلة…' : 'Ajout au panier…';

  static String get cartReconciling => isArabic ? 'جاري التحقق من السلة…' : 'Vérification du panier…';

  static String get cartAddUnconfirmed => isArabic ? 'تعذّر تأكيد الإضافة. تم الاحتفاظ باختيارك.' : 'L’ajout n’a pas pu être confirmé. Votre sélection a été conservée.';

  static String get cartClearing => isArabic ? 'جاري إفراغ السلة…' : 'Vidage du panier…';

  static String get perPortion => isArabic ? 'للحصة' : 'Par portion';

  static String get productDescriptionHeading => isArabic ? 'الوصف' : 'Description';

  static String get customizeProductHint => isArabic ? 'إضافات، خيارات، إضافات إضافية…' : 'Suppléments, options, extras…';

  static String get customizeProductCardTitle => isArabic ? 'خصّص منتجك' : 'Personnaliser votre produit';

  static String get orderFrom => isArabic ? 'طلب من' : 'Commande chez';

  static String get productUnavailable => isArabic ? 'هذا المنتج غير متاح.' : 'Ce produit n’est pas disponible.';

  static String get storefrontUnavailable => isArabic ? 'هذا المتجر غير متاح.' : 'Ce commerce n’est pas disponible.';

  static String get searchQueryInvalid => isArabic ? 'هذا البحث غير صالح.' : 'Cette recherche n’est pas valide.';

  static String get catalogLoadError => isArabic ? 'تعذّر تحميل الكتالوج.' : 'Impossible de charger le catalogue.';

  static String get loadMore => isArabic ? 'تحميل المزيد' : 'Charger plus';

  static String get optionUnavailable => isArabic ? 'غير متاح' : 'Indisponible';

  static String get closedBrowseHint => isArabic ? 'المتجر مغلق. يمكنك تصفّح القائمة.' : 'Commerce fermé. Vous pouvez consulter le menu.';

  static String get weekdayMonday => isArabic ? 'الاثنين' : 'Lundi';

  static String get weekdayTuesday => isArabic ? 'الثلاثاء' : 'Mardi';

  static String get weekdayWednesday => isArabic ? 'الأربعاء' : 'Mercredi';

  static String get weekdayThursday => isArabic ? 'الخميس' : 'Jeudi';

  static String get weekdayFriday => isArabic ? 'الجمعة' : 'Vendredi';

  static String get weekdaySaturday => isArabic ? 'السبت' : 'Samedi';

  static String get weekdaySunday => isArabic ? 'الأحد' : 'Dimanche';

  static String get closedAllDay => isArabic ? 'مغلق' : 'Fermé';

  static String get specialOffer => isArabic ? 'عرض خاص' : 'Offre spéciale';

  static String get promoHeadline => isArabic ? '150 DZD هدية' : '150 DZD offerts';

  static String get promoCondition => isArabic ? 'على كل طلب ابتداءً من 1,500 DZD' : 'Sur toute commande dès 1,500 DZD';

  static String get promoCode => isArabic ? 'SPEEDY150' : 'SPEEDY150';

  static String get promoMerchandiseCondition => isArabic ? 'يُطبَّق على المنتجات. يُتحقق منه عند الدفع.' : 'S’applique aux produits. Vérifiée au paiement.';

  static String get promoCodeCopied => isArabic ? 'تم نسخ الرمز' : 'Code copié';

  static String get copyPromoCode => isArabic ? 'نسخ الرمز' : 'Copier le code';

  static String get categoryRestaurants => isArabic ? 'مطاعم' : 'Restaurants';

  static String get categoryBakeries => isArabic ? 'مخابز' : 'Boulangeries';

  static String get categoryGroceries => isArabic ? 'بقالات' : 'Épiceries';

  static String get categoryPharmacies => isArabic ? 'صيدليات' : 'Pharmacies';

  static String get categoryDesserts => isArabic ? 'حلويات' : 'Desserts';

  static String get categoryRestaurantsSubtitle => isArabic ? 'برغر، بيتزا، تقليدي...' : 'Burgers, Pizzas, Traditionnel...';

  static String get categoryDessertsSubtitle => isArabic ? 'حلويات وكعك' : 'Gâteaux, Desserts';

  static String get categoryBakeriesSubtitle => isArabic ? 'خبز ومعجنات' : 'Pain, Viennoiseries';

  static String get categoryGroceriesSubtitle => isArabic ? 'منتجات محلية' : 'Produits locaux';

  static String get categoryPharmaciesSubtitle => isArabic ? 'صحة وعناية' : 'Santé, Soins';

  static String get activeOrder => isArabic ? 'طلب قيد التنفيذ' : 'Commande en cours';

  static String get orderStatusPendingAcceptance => isArabic ? 'بانتظار المتجر' : 'En attente du commerce';

  static String get orderStatusAccepted => isArabic ? 'تم قبول الطلب' : 'Commande acceptée';

  static String get orderStatusPreparing => isArabic ? 'قيد التحضير' : 'En préparation';

  static String get orderStatusReady => isArabic ? 'جاهز للمندوب' : 'Prête pour le livreur';

  static String get orderStatusSearchingDriver => isArabic ? 'البحث عن مندوب توصيل' : 'Recherche d’un livreur';

  static String get orderStatusDriverAssigned => isArabic ? 'تم تعيين المندوب' : 'Livreur assigné';

  static String get orderStatusToPickup => isArabic ? 'المندوب متوجه إلى المتجر' : 'Le livreur se rend au commerce';

  static String get orderStatusAtPickup => isArabic ? 'المندوب في المتجر' : 'Le livreur est au commerce';

  static String get orderStatusPickedUp => isArabic ? 'تم استلام الطلب' : 'Commande récupérée';

  static String get orderStatusInTransit => isArabic ? 'في الطريق إليك' : 'En chemin vers vous';

  static String get orderStatusArrived => isArabic ? 'وصل المندوب' : 'Le livreur est arrivé';

  static String get homeDesignPreviewTitle => isArabic ? 'الرئيسية — تكوين التصميم' : 'Accueil — composition design';

  static String get homeDesignPreviewHint => isArabic ? 'تكوين بصري Stitch. بيانات معاينة محلية، خارج واجهة API.' : 'Composition visuelle Stitch. Données d’aperçu locales, hors API.';

  static String get previewAddress => isArabic ? 'المنزل — Sidi Djillali' : 'Domicile — Sidi Djillali';

  static String get previewCustomerName => isArabic ? 'Amel' : 'Amel';

  static String get previewMerchantName => isArabic ? 'Dar El Bahia' : 'Dar El Bahia';

  static String get previewMerchantCuisine => isArabic ? 'مطبخ جزائري وتقليدي' : 'Cuisine Algérienne & Traditionnelle';

  static String get previewPopular => isArabic ? 'شائع' : 'Populaire';

  static String get previewEta => isArabic ? '25–35 min' : '25–35 min';

  static String get previewDeliveryFee => isArabic ? '200 DZD' : '200 DZD';

  static String get previewRating => isArabic ? '4.7' : '4.7';

  static String get previewOrderNumber => isArabic ? '#SG-260803-1842' : '#SG-260803-1842';

  static String get previewOrderStatus => isArabic ? 'في الطريق إليك' : 'En chemin vers vous';

  static String get navPreview => isArabic ? 'معاينة التنقّل' : 'Aperçu de navigation';

  static String get closeLabel => isArabic ? 'إغلاق' : 'Fermer';

  static String get saveUnavailable => isArabic ? 'الحفظ غير مربوط.' : 'Enregistrement non branché.';

  static String get submitUnavailable => isArabic ? 'الإرسال غير مربوط.' : 'Soumission non branchée.';

  static String get deleteUnavailable => isArabic ? 'لا يوجد مسار لحذف الحساب. لم يُعدَّل الحساب.' : 'Aucune route de suppression de compte. Le compte n’a pas été modifié.';

  static String get favoritesUnavailable => isArabic ? 'لا توجد مفضّلات على الخادم. لم يُضَف شيء.' : 'Aucun favori n’existe côté serveur. Rien n’a été ajouté.';

  static String get promotionsTitle => isArabic ? 'العروض والتخفيضات' : 'Promotions et offres';

  static String get promotionsEmpty => isArabic ? 'لا يوجد عرض منشور حاليًا.' : 'Aucune offre publiée pour le moment.';

  static String get promotionsCheckoutHint => isArabic ? 'يُطبَّق الرمز عند المراجعة. يحسب الخادم الأهلية.' : 'Le code s’applique à la vérification. L’éligibilité est calculée par le serveur.';

  static String get promotionsUnavailable => isArabic ? 'لم يُطبَّق هذا العرض. استخدم الرمز عند المراجعة.' : 'Cette offre n’a pas été appliquée. Utilisez le code à la vérification.';

  static String get notificationPrefsUnavailable => isArabic ? 'لا يوجد تخزين لتفضيلات الإشعارات. لم يُحفظ شيء.' : 'Aucun stockage de préférences de notification. Rien n’a été enregistré.';

  static String get notificationsTitle => isArabic ? 'التنبيهات' : 'Alertes';

  static String get notificationsEmpty => isArabic ? 'لا توجد إشعارات حاليًا.' : 'Aucune notification pour le moment.';

  static String get notificationsLoadError => isArabic ? 'تعذّر تحميل الإشعارات.' : 'Impossible de charger les notifications.';

  static String get notificationsMarkAll => isArabic ? 'تعليم الكل كمقروء' : 'Tout marquer lu';

  static String get notificationsLoadMore => isArabic ? 'عرض المزيد' : 'Voir plus';

  static String get notificationsLoadingMore => isArabic ? 'جاري التحميل…' : 'Chargement…';

  static String get notificationsDestinationUnavailable => isArabic ? 'لا يمكن فتح هذا الإشعار هنا.' : 'Cette notification ne peut pas être ouverte ici.';

  static String get notificationsUnknownType => isArabic ? 'نوع الإشعار غير مدعوم.' : 'Type de notification non pris en charge.';

  static String get notificationsMarkReadError => isArabic ? 'تعذّر تحديث حالة القراءة.' : 'Impossible de mettre à jour l’état de lecture.';

  static String get notificationsJustNow => isArabic ? 'الآن' : 'À l’instant';

  static String notificationsMinutesAgo(int count) =>
      isArabic ? 'منذ $count د' : 'Il y a $count min';

  static String notificationsHoursAgo(int count) =>
      isArabic ? 'منذ $count س' : 'Il y a $count h';

  static String notificationsDaysAgo(int count) =>
      isArabic ? 'منذ $count ي' : 'Il y a $count j';

  static String get notifTitleOrderAccepted =>
      isArabic ? 'تم قبول الطلب' : 'Commande acceptée';

  static String notifBodyOrderAccepted(String reference) => isArabic
      ? (reference.isEmpty
            ? 'تم قبول طلبك من المتجر.'
            : 'تم قبول طلبك $reference من المتجر.')
      : (reference.isEmpty
            ? 'Votre commande a été acceptée par le commerçant.'
            : 'Votre commande $reference a été acceptée par le commerçant.');

  static String get notifTitleOrderRejected =>
      isArabic ? 'رُفض الطلب' : 'Commande refusée';

  static String notifBodyOrderRejected(String reference) => isArabic
      ? (reference.isEmpty
            ? 'رفض المتجر طلبك.'
            : 'رفض المتجر طلبك $reference.')
      : (reference.isEmpty
            ? 'Le commerçant a refusé votre commande.'
            : 'Le commerçant a refusé votre commande $reference.');

  static String get notifTitleOrderCancelled =>
      isArabic ? 'أُلغي الطلب' : 'Commande annulée';

  static String notifBodyOrderCancelled(String reference) => isArabic
      ? (reference.isEmpty
            ? 'تم إلغاء طلبك.'
            : 'تم إلغاء طلبك $reference.')
      : (reference.isEmpty
            ? 'Votre commande a été annulée.'
            : 'Votre commande $reference a été annulée.');

  static String get notifTitleOrderReady =>
      isArabic ? 'الطلب جاهز' : 'Commande prête';

  static String notifBodyOrderReady(String reference) => isArabic
      ? (reference.isEmpty
            ? 'طلبك جاهز للاستلام.'
            : 'طلبك $reference جاهز للاستلام.')
      : (reference.isEmpty
            ? 'Votre commande est prête pour le retrait.'
            : 'Votre commande $reference est prête pour le retrait.');

  static String get notifTitleDriverAssigned =>
      isArabic ? 'تم تعيين مندوب' : 'Livreur assigné';

  static String notifBodyDriverAssigned(String reference) => isArabic
      ? (reference.isEmpty
            ? 'تم تعيين مندوب لطلبك.'
            : 'تم تعيين مندوب لطلبك $reference.')
      : (reference.isEmpty
            ? 'Un livreur a été assigné à votre commande.'
            : 'Un livreur a été assigné à votre commande $reference.');

  static String get notifTitleDeliveryCompleted =>
      isArabic ? 'تم التوصيل' : 'Commande livrée';

  static String notifBodyDeliveryCompleted(String reference) => isArabic
      ? (reference.isEmpty ? 'تم توصيل طلبك.' : 'تم توصيل طلبك $reference.')
      : (reference.isEmpty
            ? 'Votre commande a été livrée.'
            : 'Votre commande $reference a été livrée.');

  static String get notifTitlePaymentSucceeded =>
      isArabic ? 'تم الدفع' : 'Paiement réussi';

  static String notifBodyPaymentSucceeded(String reference) => isArabic
      ? (reference.isEmpty
            ? 'تم تأكيد الدفع.'
            : 'تم تأكيد الدفع للطلب $reference.')
      : (reference.isEmpty
            ? 'Le paiement a réussi.'
            : 'Le paiement de la commande $reference a réussi.');

  static String get notifTitleRefundRefunded =>
      isArabic ? 'اكتمل الاسترداد' : 'Remboursement effectué';

  static String notifBodyRefundRefunded(String reference) => isArabic
      ? (reference.isEmpty
            ? 'اكتمل استرداد للطلب.'
            : 'اكتمل استرداد للطلب $reference.')
      : (reference.isEmpty
            ? 'Un remboursement a été effectué.'
            : 'Un remboursement pour la commande $reference a été effectué.');

  static String get notifTitleMatchOffer =>
      isArabic ? 'عرض توصيل جديد' : 'Nouvelle course proposée';

  static String get notifBodyMatchOffer => isArabic
      ? 'لديك عرض توصيل جديد. افتح التطبيق للقبول أو الرفض قبل انتهاء المهلة.'
      : 'Vous avez une nouvelle course. Ouvrez l’application pour accepter ou refuser avant expiration.';

  static String get notifTitleSettlementFinalized =>
      isArabic ? 'اكتمل التسوية' : 'Règlement finalisé';

  static String get notifBodySettlementFinalized => isArabic
      ? 'يتوفر كشف تسوية للتاجر. هذا ليس تأكيد تحويل بنكي.'
      : 'Un relevé de règlement commerçant est disponible. Ceci n’est pas une confirmation de virement.';

  static String get notifTitleDriverEarningCreated =>
      isArabic ? 'سُجّل ربح' : 'Gain enregistré';

  static String get notifBodyDriverEarningCreated => isArabic
      ? 'سُجّل ربح توصيل في حسابك.'
      : 'Un gain de livraison a été enregistré sur votre compte.';

  static String get notifTitleMerchantOrderCreated =>
      isArabic ? 'طلب جديد' : 'Nouvelle commande';

  static String notifBodyMerchantOrderCreated(String reference) => isArabic
      ? (reference.isEmpty
            ? 'يتطلب طلب جديد انتباهك.'
            : 'يتطلب الطلب $reference انتباهك.')
      : (reference.isEmpty
            ? 'Une nouvelle commande nécessite votre attention.'
            : 'Une nouvelle commande $reference nécessite votre attention.');

  static String get catalogUnwired => isArabic ? 'الكتالوج والصور وأهلية التوصيل غير مربوطة.' : 'Catalogue, photos et éligibilité livraison ne sont pas branchés.';

  static String get openPreview => isArabic ? 'فتح الشاشة (معاينة)' : 'Ouvrir l’écran (aperçu)';

  static String get arabicRtlPending => isArabic
      ? 'اتجاه RTL مفعّل.'
      : 'Mention historique inutilisée — RTL arabe.';

  static String get logout => isArabic ? 'تسجيل الخروج' : 'Déconnexion';

  static String get logoutConfirmTitle => isArabic ? 'هل تريد تسجيل الخروج من SpeedyGo؟' : 'Voulez-vous vous déconnecter de SpeedyGo ?';

  static String get logoutConfirmBody => isArabic ? 'ستغادر هذه الجلسة على هذا الجهاز.' : 'Vous allez quitter cette session sur cet appareil.';

  static String get logoutSessionActive => isArabic ? 'جلسة نشطة على هذا الجهاز' : 'Session active sur cet appareil';

  static String get logoutNoteLocal => isArabic ? 'ستُغلق جلسة هذا الجهاز.' : 'La session de cet appareil sera fermée.';

  static String get logoutNoteOrders => isArabic ? 'ستبقى طلباتك الجارية مرتبطة بحسابك.' : 'Vos commandes en cours resteront liées à votre compte.';

  static String get logoutNoteReconnect => isArabic ? 'ستحتاج إلى تسجيل الدخول مجددًا لتتبّع توصيلاتك.' : 'Vous devrez vous reconnecter pour suivre vos livraisons.';

  static String get logoutNoteSafe => isArabic ? 'سلتك وعناوينك المحفوظة بأمان.' : 'Votre panier et vos adresses enregistrées sont en sécurité.';

  static String get logoutConfirmAction => isArabic ? 'تسجيل الخروج' : 'Se déconnecter';

  static String get cancel => isArabic ? 'إلغاء' : 'Annuler';

  static String get logoutLocalOnly => isArabic ? 'تم تسجيل خروجك على هذا الجهاز. تعذّر تأكيد الإبطال على الخادم.' : 'Vous êtes déconnecté sur cet appareil. La révocation serveur n’a pas pu être confirmée.';

  static String get addressesTitle => isArabic ? 'العناوين المحفوظة' : 'Adresses enregistrées';

  static String get addressesEmpty => isArabic ? 'لا يوجد عنوان محفوظ. يمكنك تصفّح SpeedyGo دون إضافة عنوان.' : 'Aucune adresse enregistrée. Vous pouvez parcourir SpeedyGo sans en ajouter.';

  static String get addressesLoadError => isArabic ? 'تعذّر تحميل العناوين.' : 'Impossible de charger les adresses.';

  static String get addressesDefaultSection => isArabic ? 'العنوان الافتراضي' : 'Adresse par défaut';

  static String get addressesOtherSection => isArabic ? 'عناوين أخرى' : 'Autres adresses';

  static String get addAddress => isArabic ? 'إضافة عنوان' : 'Ajouter une adresse';

  static String get addAddressShort => isArabic ? 'إضافة' : 'Ajouter';

  static String get addAddressNew => isArabic ? 'إضافة عنوان جديد' : 'Ajouter une nouvelle adresse';

  static String get editAddress => isArabic ? 'تعديل العنوان' : 'Modifier l’adresse';

  static String get saveAddress => isArabic ? 'حفظ العنوان' : 'Enregistrer l’adresse';

  static String get addressTypeLabel => isArabic ? 'نوع العنوان' : 'Type d’adresse';

  static String get addressLabelField => isArabic ? 'التسمية' : 'Libellé';

  static String get addressLabelHint => isArabic ? 'مثال: المنزل' : 'Ex: Domicile';

  static String get addressTextField => isArabic ? 'العنوان التفصيلي' : 'Adresse détaillée';

  static String get addressTextHint => isArabic ? 'مثال: Cité 1500 Logements, Bloc 12' : 'Ex: Cité 1500 Logements, Bloc 12';

  static String get addressLatitudeField => isArabic ? 'خط العرض' : 'Latitude';

  static String get addressLongitudeField => isArabic ? 'خط الطول' : 'Longitude';

  static String get addressCoordsHint => isArabic ? 'أكّد النقطة على الخريطة. تبقى الإحداثيات داخلية.' : 'Confirmez le point sur la carte. Les coordonnées restent internes.';

  static String get addressChooseOnMap => isArabic ? 'اختيار على الخريطة' : 'Choisir sur la carte';

  static String get addressPointConfirmed => isArabic ? 'تم تأكيد الموقع' : 'Emplacement confirmé';

  static String get addressPointRequired => isArabic ? 'اختر وأكّد نقطة التوصيل على الخريطة.' : 'Choisissez et confirmez le point de livraison sur la carte.';

  static String get addressBuildingField => isArabic ? 'المبنى' : 'Bâtiment';

  static String get addressFloorField => isArabic ? 'الطابق' : 'Étage';

  static String get addressEntranceField => isArabic ? 'المدخل' : 'Entrée';

  static String get addressLandmarkField => isArabic ? 'علامة مميّزة' : 'Point de repère';

  static String get addressWilayaField => isArabic ? 'الولاية' : 'Wilaya';

  static String get addressWilayaHint => isArabic ? 'Sidi Bel Abbès للإطلاق' : 'Sidi Bel Abbès pour le lancement';

  static String get locationPickerTitle => isArabic ? 'نقطة التوصيل' : 'Point de livraison';

  static String get locationPickerMoveHint => isArabic ? 'اسحب الخريطة تحت الدبوس ثم أكّد.' : 'Faites glisser la carte sous l’épingle, puis confirmez.';

  static String get locationPickerConfirm => isArabic ? 'تأكيد هذا الموقع' : 'Confirmer cet emplacement';

  static String get locationSearchHint => isArabic ? 'ابحث عن عنوان' : 'Rechercher une adresse';

  static String get locationSearchLoading => isArabic ? 'جاري البحث…' : 'Recherche en cours…';

  static String get locationSearchUnavailable => isArabic ? 'البحث عن العنوان غير مُعدّ. حدّد النقطة على الخريطة.' : 'La recherche d’adresse n’est pas configurée. Choisissez le point sur la carte.';

  static String get locationSearchEmpty => isArabic ? 'لا توجد نتائج لهذا البحث.' : 'Aucun résultat pour cette recherche.';

  static String get locationSearchFailed => isArabic ? 'فشل البحث. أعد المحاولة أو حدّد النقطة على الخريطة.' : 'La recherche a échoué. Réessayez ou choisissez le point sur la carte.';

  static String get locationGpsDenied => isArabic ? 'رُفض الوصول إلى الموقع. يمكنك مع ذلك تحديد النقطة على الخريطة.' : 'Accès à la position refusé. Vous pouvez quand même choisir le point sur la carte.';

  static String get locationGpsDeniedForever => isArabic ? 'الموقع محظور لهذا التطبيق. افتح الإعدادات، أو حدّد النقطة على الخريطة.' : 'La position est bloquée pour cette app. Ouvrez Réglages, ou choisissez le point sur la carte.';

  static String get locationCoverageOutside => isArabic ? 'هذا العنوان خارج المنطقة المخدومة حاليًا.' : 'Cette adresse est hors de la zone desservie pour le moment.';

  static String get locationCoverageInside => isArabic ? 'العنوان ضمن منطقة التوصيل.' : 'Adresse dans la zone de livraison.';

  static String get locationMapTilesDev => isArabic ? 'خريطة تطوير (بلاطات OSM). خرائط Google غير مفعّلة.' : 'Carte de développement (tuiles OSM). Google Maps n’est pas activé.';

  static String get locationMapUnavailable => isArabic ? 'خرائط Google غير مُعدّة. لا يمكن تأكيد نقطة التوصيل هنا.' : 'Google Maps n’est pas configuré. Impossible de confirmer un point ici.';

  static String get pushOrderInaccessible => isArabic
      ? 'هذا الطلب غير موجود.'
      : 'Cette commande est introuvable.';

  static String get locationSearchDisabledOnDevMap => isArabic ? 'بحث Google معطّل على خريطة التطوير. حرّك الدبوس ثم أكّد.' : 'La recherche Google est désactivée sur la carte de développement. Déplacez l’épingle, puis confirmez.';

  static String get addressLabelRequired => isArabic ? 'أدخل تسمية.' : 'Saisissez un libellé.';

  static String get addressLabelTooLong => isArabic ? 'لا يمكن أن تتجاوز التسمية 64 حرفًا.' : 'Le libellé ne peut pas dépasser 64 caractères.';

  static String get addressTextRequired => isArabic ? 'أدخل العنوان التفصيلي.' : 'Saisissez l’adresse détaillée.';

  static String get addressTextTooLong => isArabic ? 'لا يمكن أن يتجاوز العنوان 500 حرف.' : 'L’adresse ne peut pas dépasser 500 caractères.';

  static String get addressLatitudeInvalid => isArabic ? 'أدخل خط عرض بين -90 و 90.' : 'Saisissez une latitude entre -90 et 90.';

  static String get addressLongitudeInvalid => isArabic ? 'أدخل خط طول بين -180 و 180.' : 'Saisissez une longitude entre -180 et 180.';

  static String get addressCoordsRequired => isArabic ? 'خط العرض وخط الطول إلزاميان.' : 'Latitude et longitude sont obligatoires.';

  static String get addressFirstDefaultHint => isArabic ? 'يصبح أول عنوان محفوظ هو العنوان الافتراضي للحساب.' : 'La première adresse enregistrée devient l’adresse par défaut du compte.';

  static String get addressDefaultHint => isArabic ? 'لتغيير العنوان الافتراضي، استخدم «تعيين كافتراضي» في قائمة العناوين.' : 'Pour changer l’adresse par défaut, utilisez « Définir par défaut » dans la liste des adresses.';

  static String get useMyLocation => isArabic ? 'استخدام موقعي' : 'Utiliser ma position';

  static String get setAsDefault => isArabic ? 'تعيين كافتراضي' : 'Définir par défaut';

  static String get defaultAddressBadge => isArabic ? 'افتراضي' : 'Par défaut';

  static String get selectedAddressBadge => isArabic ? 'محدَّد' : 'Sélectionnée';

  static String get deleteAddress => isArabic ? 'حذف' : 'Supprimer';

  static String get deleteAddressTitle => isArabic ? 'حذف هذا العنوان؟' : 'Supprimer cette adresse ?';

  static String get deleteAddressBody => isArabic ? 'سيُزال من دفتر عناوينك. الطلبات السابقة لا تتغيّر.' : 'Elle sera retirée de votre carnet. Les commandes déjà passées ne sont pas modifiées.';

  static String get confirmDelete => isArabic ? 'حذف' : 'Supprimer';

  static String get addressPickerTitle => isArabic ? 'عنوان التوصيل' : 'Adresse de livraison';

  static String get addressPickerEmpty => isArabic ? 'لا يوجد عنوان محفوظ. أضف عنوانًا لاختياره.' : 'Aucune adresse enregistrée. Ajoutez-en une pour la sélectionner.';

  static String get chooseThisAddress => isArabic ? 'اختيار هذا العنوان' : 'Choisir cette adresse';

  static String get addressSelectionHint => isArabic ? 'يظهر هذا الاختيار في الرئيسية. لا يغيّر العنوان الافتراضي للحساب.' : 'Cette sélection s’affiche à l’accueil. Elle ne change pas l’adresse par défaut du compte.';

  static String get addressNotFound => isArabic ? 'هذا العنوان غير موجود.' : 'Cette adresse est introuvable.';

  static String get addressInvalid => isArabic ? 'هذا العنوان غير صالح.' : 'Cette adresse n’est pas valide.';

  static String get addressDefaultConflict => isArabic ? 'تعذّر تعيين هذا العنوان كافتراضي حاليًا.' : 'Impossible de définir cette adresse par défaut pour le moment.';

  static String get addressSaving => isArabic ? 'جاري الحفظ…' : 'Enregistrement…';

  static String get addressReconciling => isArabic ? 'جاري التحقق من العنوان…' : 'Vérification de l’adresse…';

  static String get addressSaved => isArabic ? 'تم حفظ العنوان' : 'Adresse enregistrée';

  static String get addressSaveUnconfirmed => isArabic ? 'تعذّر تأكيد الحفظ. تم الاحتفاظ بإدخالاتك.' : 'L’enregistrement n’a pas pu être confirmé. Vos saisies ont été conservées.';

  static String get locationPermissionTitle => isArabic ? 'فعّل موقعك' : 'Activez votre localisation';

  static String get locationPermissionBody => isArabic ? 'يمكن لـ SpeedyGo اقتراح موقعك الحالي على الخريطة. يمكنك أيضًا تحديد النقطة يدويًا. لا يُؤكَّد التوصيل إلا عند الدفع.' : 'SpeedyGo peut proposer votre position actuelle sur la carte. Vous pouvez aussi choisir le point à la main. La livraison n’est confirmée qu’au paiement.';

  static String get locationBenefitCoordsTitle => isArabic ? 'موقع دقيق' : 'Position précise';

  static String get locationBenefitCoordsBody => isArabic ? 'يضع نقطة التوصيل قربك، دون إدخال يدوي.' : 'Place le point de livraison près de vous, sans saisie manuelle.';

  static String get locationBenefitDeliveryTitle => isArabic ? 'التوصيل عند الدفع' : 'Livraison au paiement';

  static String get locationBenefitDeliveryBody => isArabic ? 'تبقى أهلية التوصيل مُتحقَّقًا منها عند الدفع، وليس هنا.' : 'L’éligibilité de livraison reste vérifiée au moment du paiement, pas ici.';

  static String get locationPrivacyNote => isArabic ? 'يُستخدم موقعك فقط لاقتراح نقطة على الخريطة. يمكنك نقلها.' : 'Votre localisation n’est utilisée que pour proposer un point sur la carte. Vous pouvez le déplacer.';

  static String get allowLocation => isArabic ? 'السماح بالموقع' : 'Autoriser la localisation';

  static String get enterAddressManually => isArabic ? 'إدخال عنوان يدويًا' : 'Saisir une adresse manuellement';

  static String get locationDenied => isArabic ? 'رُفض الموقع. حدّد النقطة على الخريطة، أو اسمح به في الإعدادات.' : 'La localisation a été refusée. Choisissez le point sur la carte, ou autorisez-la dans les réglages.';

  static String get locationDeniedForever => isArabic ? 'الموقع محظور لـ SpeedyGo. اسمح به في إعدادات الجهاز، أو حدّد النقطة على الخريطة.' : 'La localisation est bloquée pour SpeedyGo. Autorisez-la dans les réglages de l’appareil, ou choisissez le point sur la carte.';

  static String get locationServicesDisabled => isArabic ? 'خدمات الموقع معطّلة. فعّلها، أو حدّد النقطة على الخريطة.' : 'Les services de localisation sont désactivés. Activez-les, ou choisissez le point sur la carte.';

  static String get locationUnavailable => isArabic ? 'الموقع غير متاح حاليًا. حدّد النقطة على الخريطة.' : 'La position n’est pas disponible pour le moment. Choisissez le point sur la carte.';

  static String get confirmLocationTitle => isArabic ? 'تأكيد الموقع' : 'Confirmer l’emplacement';

  static String get confirmLocationBody => isArabic ? 'تحقّق من هذه النقطة. لا تُحفظ ما لم تحفظ العنوان، ولا تثبت أهلية التوصيل.' : 'Vérifiez ce point. Il n’est pas enregistré tant que vous n’enregistrez pas l’adresse, et il ne prouve pas l’éligibilité de livraison.';

  static String get confirmLocationAction => isArabic ? 'تأكيد الموقع' : 'Confirmer la position';

  static String get locationNotAMap => isArabic ? 'هذه الخطوة تؤكد نقطة GPS. عدّلها لاحقًا على الخريطة إن لزم.' : 'Cette étape confirme le point GPS. Ajustez-le ensuite sur la carte si besoin.';

  static String get gpsPointObtained => isArabic ? 'تم الحصول على الموقع الحالي' : 'Position actuelle obtenue';

  static String get trackingPositionUpdated => isArabic ? 'تم تحديث موقع المندوب' : 'Position du livreur mise à jour';

  static String get confirmLocationPrecisionNote => isArabic ? 'دقة العنوان مطلوبة' : 'Précision de l’adresse requise';

  static String get confirmLocationCoordsFallback => isArabic ? 'موقع GPS' : 'Position GPS';

  static String get addressLabelHome => isArabic ? 'المنزل' : 'Domicile';

  static String get addressLabelWork => isArabic ? 'العمل' : 'Travail';

  static String get addressLabelOther => isArabic ? 'آخر' : 'Autre';

  static String get offline => isArabic ? 'تحقّق من اتصالك ثم أعد المحاولة.' : 'Vérifiez votre connexion, puis réessayez.';

  static String get retry => isArabic ? 'إعادة المحاولة' : 'Réessayer';

  static String get refresh => isArabic ? 'تحديث' : 'Actualiser';

  static String get unexpected => isArabic ? 'حدث خطأ. أعد المحاولة.' : 'Une erreur s’est produite. Réessayez.';

  static String get sessionExpired => isArabic ? 'انتهت جلستك. سجّل الدخول.' : 'Votre session a expiré. Connectez-vous.';

  static String get reauthRequired => isArabic ? 'سجّل الدخول مجددًا للمتابعة. الجلسة السابقة لم تعد صالحة هنا.' : 'Reconnectez-vous pour continuer. L’ancienne session n’est plus utilisable ici.';

  static String get securityTitle => isArabic ? 'الأمان' : 'Sécurité';

  static String get securitySessionsHeading => isArabic ? 'الجلسات النشطة' : 'Sessions actives';

  static String get securityAccountHeading => isArabic ? 'معلومات الحساب' : 'Informations de compte';

  static String get securityVerifiedPhone => isArabic ? 'رقم موثَّق' : 'Numéro vérifié';

  static String get securityCurrentBadge => isArabic ? 'هذا الجهاز' : 'Cet appareil';

  static String get securityCurrentPill => isArabic ? 'الحالي' : 'COURANT';

  static String get securityEmpty => isArabic ? 'لا توجد جلسة نشطة.' : 'Aucune session active.';

  static String get securityLoadError => isArabic ? 'تعذّر تحميل الجلسات.' : 'Impossible de charger les sessions.';

  static String get securityRevoke => isArabic ? 'إبطال' : 'Révoquer';

  static String get securityRevokeTitle => isArabic ? 'إبطال هذه الجلسة؟' : 'Révoquer cette session ?';

  static String get securityRevokeBody => isArabic ? 'سيحتاج هذا الجهاز إلى تسجيل الدخول مجددًا. تبقى جلستك الحالية نشطة.' : 'Cet appareil devra se reconnecter. Votre session actuelle reste active.';

  static String get securityRevokeCurrentTitle => isArabic ? 'إبطال جلسة هذا الجهاز؟' : 'Révoquer la session de cet appareil ?';

  static String get securityRevokeCurrentBody => isArabic ? 'سيتم تسجيل خروجك فورًا على هذا الجهاز.' : 'Vous serez déconnecté immédiatement sur cet appareil.';

  static String get securityRevokeConfirm => isArabic ? 'إبطال' : 'Révoquer';

  static String get securityLogoutAll => isArabic ? 'تسجيل الخروج من كل الأجهزة' : 'Déconnecter tous les appareils';

  static String get securityLogoutAllTitle => isArabic ? 'تسجيل الخروج من كل الأجهزة؟' : 'Déconnecter tous les appareils ?';

  static String get securityLogoutAllBody => isArabic ? 'ستُلغى كل الجلسات، بما فيها هذه. سيتم تسجيل خروجك فورًا وستحتاج إلى تسجيل الدخول مجددًا.' : 'Toutes les sessions seront révoquées, y compris celle-ci. Vous serez déconnecté immédiatement et devrez vous reconnecter.';

  static String get securityOtpGuidanceTitle => isArabic ? 'نصائح أمنية' : 'Conseils de sécurité';

  static String get securityOtpGuidance => isArabic ? 'يستخدم تسجيل الدخول في SpeedyGo رمز SMS لمرة واحدة. لا توجد مصادقة ثنائية منفصلة. لا تشارك هذا الرمز أبدًا.' : 'La connexion SpeedyGo utilise un code SMS à usage unique. Il n’existe pas de double authentification séparée. Ne partagez jamais ce code.';

  static String get securityLogoutAllConfirm => isArabic ? 'تسجيل الخروج من الكل' : 'Tout déconnecter';

  static String get securityReportSuspicious => isArabic ? 'الإبلاغ عن نشاط مشبوه' : 'Signaler une activité suspecte';

  static String get securityRevokeUncertain => isArabic ? 'الإبطال غير مؤكد. جاري التحديث…' : 'La révocation n’est pas confirmée. Actualisation en cours…';

  static String get securityRevokedOk => isArabic ? 'تم إبطال الجلسة.' : 'Session révoquée.';

  static String get notificationsBrand => isArabic ? 'SPEEDYGO' : 'SPEEDYGO';

  static String get notificationsEmptyHint => isArabic ? 'ستظهر تنبيهات الطلب هنا عند توفّرها.' : 'Les alertes de commande apparaîtront ici dès qu’elles seront disponibles.';

  static String get notificationsPermissionLink => isArabic ? 'الأذونات' : 'Autorisations';

  static String get notificationsPrefsLink => isArabic ? 'التفضيلات' : 'Préférences';

  static String get otpServerUnavailable => isArabic ? 'خدمة المصادقة غير متاحة مؤقتًا. أعد المحاولة لاحقًا.' : 'Le service d’authentification est temporairement indisponible. Réessayez plus tard.';

  static String get otpCooldownHint => isArabic ? 'انتظر قبل طلب جديد.' : 'Patientez avant une nouvelle demande.';

  static String ratingReviewsHeading(String merchantName) =>
      isArabic ? 'التقييمات — $merchantName' : 'Avis — $merchantName';

  static String otpSentTo(String masked) =>
      isArabic ? 'أُرسل الرمز إلى $masked' : 'Code envoyé au $masked';

  static String resendIn(String clock) =>
      isArabic ? 'إعادة إرسال الرمز خلال $clock' : 'Renvoyer le code dans $clock';

  static String landingHello(String name) =>
      isArabic ? 'مرحبًا، $name' : 'Bonjour, $name';

  static String homeGreeting(String name, {DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    final first = name.trim().split(RegExp(r'\s+')).first;
    if (isArabic) {
      final hello = hour >= 18 || hour < 6 ? 'مساء الخير' : 'صباح الخير';
      return '$hello، $first \u{1F44B}';
    }
    final hello = hour >= 18 || hour < 6 ? 'Bonsoir' : 'Bonjour';
    return '$hello, $first \u{1F44B}';
  }

  static String checkoutPromoApplied(String code) =>
      isArabic ? 'تم تطبيق الرمز $code' : 'Code $code appliqué';

  static String optionSelectCount(int min, int max) {
    if (min == max) {
      if (isArabic) {
        return min == 1 ? 'اختر خيارًا واحدًا' : 'اختر $min خيارات';
      }
      return min == 1 ? 'Sélectionnez 1 option' : 'Sélectionnez $min options';
    }
    return isArabic
        ? 'اختر من $min إلى $max خيارات'
        : 'Sélectionnez $min–$max options';
  }

  static String promoFixedHeadline(String formattedAmount) =>
      isArabic
          ? 'خصم حتى $formattedAmount'
          : 'Jusqu’à $formattedAmount de réduction';

  static String promoRateHeadline(String percent) =>
      isArabic ? 'خصم $percent' : '$percent de réduction';

  static String confirmLocationClientLabel(String name) =>
      isArabic ? 'العميل: $name' : 'Client : $name';

  static String errorForCode(String? code) {
    switch (code) {
      case 'AUTH_INVALID_IDENTIFIER':
        return isArabic ? 'هذا الرقم غير صالح.' : 'Ce numéro n’est pas valide.';
      case 'AUTH_INVALID_OTP':
        return isArabic ? 'رمز غير صحيح. أعد المحاولة.' : 'Code incorrect. Réessayez.';
      case 'AUTH_OTP_EXPIRED':
        return isArabic ? 'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.' : 'Ce code a expiré. Demandez-en un nouveau.';
      case 'AUTH_OTP_ATTEMPTS_EXCEEDED':
        return isArabic ? 'محاولات كثيرة. اطلب رمزًا جديدًا.' : 'Trop de tentatives. Demandez un nouveau code.';
      case 'AUTH_RATE_LIMITED':
        return isArabic ? 'يرجى الانتظار قبل إعادة إرسال رمز.' : 'Veuillez patienter avant de renvoyer un code.';
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
        return isArabic ? 'لا يمكن لهذا الحساب تسجيل الدخول.' : 'Ce compte ne peut pas se connecter.';
      case 'CUSTOMER_PROFILE_ALREADY_EXISTS':
        return isArabic ? 'ملفك الشخصي موجود بالفعل.' : 'Votre profil existe déjà.';
      case 'CUSTOMER_PROFILE_NOT_FOUND':
        return isArabic ? 'الملف الشخصي غير موجود. أعد المحاولة.' : 'Profil introuvable. Réessayez.';
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
        return isArabic ? 'صفحة الكتالوج هذه غير صالحة.' : 'Cette page de catalogue n’est pas valide.';
      case 'CART_ITEM_NOT_FOUND':
        return isArabic ? 'هذه السلعة لم تعد في السلة.' : 'Cet article n’est plus dans le panier.';
      case 'CART_BRANCH_MISMATCH':
        return cartBranchConflict;
      case 'CART_PRODUCT_NOT_AVAILABLE':
        return isArabic ? 'هذا المنتج غير متاح للسلة.' : 'Ce produit n’est pas disponible pour le panier.';
      case 'CART_OPTION_NOT_AVAILABLE':
        return isArabic ? 'هذا الخيار لم يعد متاحًا.' : 'Cette option n’est plus disponible.';
      case 'CART_OPTION_INVALID':
        return isArabic ? 'تركيبة الخيارات هذه غير صالحة.' : 'Cette combinaison d’options n’est pas valide.';
      case 'CART_REQUIRED_OPTION_MISSING':
        return isArabic ? 'حدّد الخيارات الإلزامية.' : 'Sélectionnez les options obligatoires.';
      case 'CART_INVALID_QUANTITY':
        return isArabic ? 'يجب أن تكون الكمية بين 1 و 99.' : 'La quantité doit être comprise entre 1 et 99.';
      case 'CART_MUTATION_UNCERTAIN':
        return cartAddUnconfirmed;
      case 'CHECKOUT_CART_REQUIRED':
        return isArabic ? 'سلتك فارغة أو لم تعد موجودة.' : 'Votre panier est vide ou n’existe plus.';
      case 'CHECKOUT_CART_NOT_READY':
        return cartNotReady;
      case 'CHECKOUT_ADDRESS_NOT_FOUND':
        return isArabic ? 'هذا العنوان لم يعد متاحًا.' : 'Cette adresse n’est plus disponible.';
      case 'CHECKOUT_ADDRESS_COORDINATES_REQUIRED':
        return isArabic ? 'هذا العنوان بلا نقطة توصيل مؤكدة.' : 'Cette adresse n’a pas de point de livraison confirmé.';
      case 'CHECKOUT_ADDRESS_OUTSIDE_ZONE':
        return isArabic ? 'هذا العنوان ليس ضمن منطقة توصيل.' : 'Cette adresse n’est pas dans une zone de livraison.';
      case 'CHECKOUT_DELIVERY_ZONE_AMBIGUOUS':
        return isArabic ? 'منطقة توصيل هذا العنوان غير محدّدة. اختر عنوانًا آخر.' : 'La zone de livraison de cette adresse n’est pas déterminée. Choisissez une autre adresse.';
      case 'CHECKOUT_PRICING_RULE_NOT_FOUND':
        return isArabic ? 'رسوم التوصيل غير متاحة لهذا العنوان.' : 'Les frais de livraison ne sont pas disponibles pour cette adresse.';
      case 'CHECKOUT_PRICING_CONFIGURATION_INVALID':
        return isArabic ? 'تسعير التوصيل غير متاح حاليًا.' : 'La tarification de livraison n’est pas disponible pour le moment.';
      case 'CHECKOUT_MERCHANT_NOT_OPERATIONAL':
        return isArabic ? 'هذا المتجر لا يقبل الطلبات حاليًا.' : 'Ce commerce n’accepte pas de commande pour le moment.';
      case 'CHECKOUT_BRANCH_NOT_OPERATIONAL':
        return isArabic ? 'نقطة البيع هذه لا تقبل الطلبات حاليًا.' : 'Ce point de vente n’accepte pas de commande pour le moment.';
      case 'CHECKOUT_BRANCH_CLOSED':
        return isArabic ? 'هذا المتجر مغلق حاليًا.' : 'Ce commerce est fermé pour le moment.';
      case 'CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED':
        return isArabic ? 'أوقات عمل هذا المتجر غير متاحة.' : 'Les horaires de ce commerce ne sont pas disponibles.';
      case 'CHECKOUT_BRANCH_OUTSIDE_ZONE':
        return isArabic ? 'هذا المتجر لا يوصّل إلى العنوان المحدّد. تم الاحتفاظ بالسلة.' : 'Ce commerce ne livre pas à l’adresse sélectionnée. Le panier est conservé.';
      case 'PROMOTION_CODE_INVALID':
        return isArabic ? 'رمز التخفيض هذا غير صالح.' : 'Ce code promo n’est pas valide.';
      case 'PROMOTION_NOT_FOUND':
        return isArabic ? 'رمز التخفيض هذا غير موجود.' : 'Ce code promo est introuvable.';
      case 'PROMOTION_INACTIVE':
        return isArabic ? 'رمز التخفيض هذا غير نشط.' : 'Ce code promo n’est pas actif.';
      case 'PROMOTION_NOT_YET_ACTIVE':
        return isArabic ? 'رمز التخفيض هذا غير نشط بعد.' : 'Ce code promo n’est pas encore actif.';
      case 'PROMOTION_EXPIRED':
        return isArabic ? 'انتهت صلاحية رمز التخفيض هذا.' : 'Ce code promo a expiré.';
      case 'PROMOTION_CONFIGURATION_INVALID':
        return isArabic ? 'هذا العرض غير قابل للتطبيق.' : 'Cette promotion n’est pas applicable.';
      case 'PROMOTION_STACKING_UNSUPPORTED':
        return isArabic ? 'لا يمكن جمع هذا العرض مع غيره.' : 'Cette promotion ne peut pas être combinée.';
      case 'PROMOTION_REDEMPTION_CONFLICT':
        return isArabic ? 'لم يعد هذا العرض قابلاً للاستخدام.' : 'Cette promotion n’est plus utilisable.';
      case 'PROMOTION_ZERO_PAYABLE_UNSUPPORTED':
        return isArabic ? 'هذا العرض غير قابل للتطبيق على هذا الطلب.' : 'Cette promotion n’est pas applicable à cette commande.';
      case 'ORDER_CART_REQUIRED':
        return isArabic ? 'سلتك فارغة أو لم تعد موجودة.' : 'Votre panier est vide ou n’existe plus.';
      case 'ORDER_CART_NOT_READY':
        return cartNotReady;
      case 'ORDER_ADDRESS_NOT_FOUND':
        return isArabic ? 'هذا العنوان لم يعد متاحًا.' : 'Cette adresse n’est plus disponible.';
      case 'ORDER_ADDRESS_COORDINATES_REQUIRED':
        return isArabic ? 'هذا العنوان بلا نقطة توصيل مؤكدة.' : 'Cette adresse n’a pas de point de livraison confirmé.';
      case 'ORDER_ADDRESS_OUTSIDE_ZONE':
        return isArabic ? 'هذا العنوان ليس ضمن منطقة توصيل.' : 'Cette adresse n’est pas dans une zone de livraison.';
      case 'ORDER_DELIVERY_ZONE_AMBIGUOUS':
        return isArabic ? 'منطقة توصيل هذا العنوان غير محدّدة.' : 'La zone de livraison de cette adresse n’est pas déterminée.';
      case 'ORDER_PRICING_RULE_NOT_FOUND':
        return isArabic ? 'رسوم التوصيل غير متاحة لهذا العنوان.' : 'Les frais de livraison ne sont pas disponibles pour cette adresse.';
      case 'ORDER_PRICING_CONFIGURATION_INVALID':
        return isArabic ? 'تسعير التوصيل غير متاح حاليًا.' : 'La tarification de livraison n’est pas disponible pour le moment.';
      case 'ORDER_MERCHANT_NOT_OPERATIONAL':
        return isArabic ? 'هذا المتجر لا يقبل الطلبات حاليًا.' : 'Ce commerce n’accepte pas de commande pour le moment.';
      case 'ORDER_BRANCH_NOT_OPERATIONAL':
        return isArabic ? 'نقطة البيع هذه لا تقبل الطلبات حاليًا.' : 'Ce point de vente n’accepte pas de commande pour le moment.';
      case 'ORDER_BRANCH_CLOSED':
        return isArabic ? 'هذا المتجر مغلق حاليًا.' : 'Ce commerce est fermé pour le moment.';
      case 'ORDER_BRANCH_HOURS_NOT_CONFIGURED':
        return isArabic ? 'أوقات عمل هذا المتجر غير متاحة.' : 'Les horaires de ce commerce ne sont pas disponibles.';
      case 'ORDER_BRANCH_OUTSIDE_ZONE':
        return isArabic ? 'هذا المتجر لا يوصّل إلى العنوان المحدّد. تم الاحتفاظ بالسلة.' : 'Ce commerce ne livre pas à l’adresse sélectionnée. Le panier est conservé.';
      case 'ORDER_ALREADY_CREATED':
        return isArabic ? 'تم إنشاء طلب مسبقًا من هذه السلة.' : 'Une commande a déjà été créée depuis ce panier.';
      case 'ORDER_NOT_FOUND':
        return isArabic ? 'هذا الطلب غير موجود.' : 'Cette commande est introuvable.';
      case 'DELIVERY_NOT_FOUND':
      case 'TRACKING_DELIVERY_NOT_FOUND':
        return isArabic ? 'لا يوجد توصيل مرتبط بهذا الطلب بعد.' : 'Aucune livraison n’est encore associée à cette commande.';
      case 'TRACKING_UNAUTHORIZED':
        return isArabic ? 'التتبّع غير متاح لهذا الطلب.' : 'Le suivi n’est pas disponible pour cette commande.';
      case 'ORDER_PAYMENT_METHOD_INVALID':
        return isArabic ? 'طريقة الدفع هذه غير متاحة.' : 'Ce mode de paiement n’est pas disponible.';
      case 'PAYMENT_NOT_FOUND':
        return isArabic ? 'دفع هذا الطلب غير موجود.' : 'Le paiement de cette commande est introuvable.';
      case 'PAYMENT_METHOD_NOT_ELECTRONIC':
        return paymentNotElectronic;
      case 'PAYMENT_ALREADY_SUCCEEDED':
        return paymentSucceededTitle;
      case 'PAYMENT_NOT_INITIABLE':
        return isArabic ? 'لم يعد بالإمكان بدء هذا الدفع.' : 'Ce paiement ne peut plus être initié.';
      case 'PAYMENT_AMOUNT_MISMATCH':
      case 'PAYMENT_CURRENCY_MISMATCH':
      case 'PAYMENT_INVALID_STATE':
        return isArabic ? 'الدفع غير متوافق مع الطلب.' : 'Le paiement n’est pas cohérent avec la commande.';
      case 'PAYMENT_PROVIDER_UNAVAILABLE':
        return isArabic ? 'مقدّم خدمة الدفع غير متاح.' : 'Le prestataire de paiement est indisponible.';
      case 'PAYMENT_PROVIDER_CONFIGURATION_INVALID':
        return isArabic ? 'مقدّم خدمة الدفع غير مُعدّ.' : 'Le prestataire de paiement n’est pas configuré.';
      case 'PAYMENT_INITIATE_SERVER_UNCERTAIN':
        return paymentInitiateUncertain;
      case 'ORDER_RECONFIRMATION_REQUIRED':
        return orderReconfirmationRequired;
      case 'ORDER_FINANCIAL_CONFIGURATION_INVALID':
      case 'ORDER_EXPECTED_AMOUNTS_INVALID':
        return isArabic ? 'مبالغ الطلب لم تعد صالحة.' : 'Les montants de la commande ne sont plus valides.';
      case 'ORDER_CANCELLATION_NOT_ALLOWED':
      case 'ORDER_CANCELLATION_FULFILLMENT_ACTIVE':
      case 'ORDER_CANCELLATION_COD_COLLECTED':
      case 'ORDER_CANCELLATION_REFUND_REQUIRED':
      case 'ORDER_CANCELLATION_CONFLICT':
        return orderCancelNotEligible;
      case 'ORDER_CANCELLATION_REASON_INVALID':
        return isArabic ? 'سبب الإلغاء هذا غير صالح.' : 'Cette raison d’annulation n’est pas valide.';
      case 'ORDER_CANCELLATION_SERVER_UNCERTAIN':
        return orderCancelPendingVerification;
      case 'SUPPORT_NOT_FOUND':
        return isArabic ? 'هذه التذكرة غير موجودة.' : 'Ce ticket est introuvable.';
      case 'SUPPORT_FORBIDDEN':
        return isArabic ? 'الدعم غير متاح لهذا الحساب.' : 'Le support n’est pas disponible pour ce compte.';
      case 'SUPPORT_INVALID_STATE':
        return supportReplyClosed;
      case 'SUPPORT_INVALID_INPUT':
        return supportBodyInvalid;
      case 'SUPPORT_RESOURCE_FORBIDDEN':
        return isArabic ? 'لا يمكن ربط هذا الطلب بالبلاغ.' : 'Cette commande ne peut pas être associée à la demande.';
      case 'SUPPORT_CREATE_UNCERTAIN':
        return supportCreateUncertain;
      case 'SUPPORT_REPLY_UNCERTAIN':
        return supportReplyUncertain;
      case 'RATING_NOT_FOUND':
        return isArabic ? 'هذا التقييم غير موجود.' : 'Cette note est introuvable.';
      case 'RATING_FORBIDDEN':
        return isArabic ? 'التقييم غير متاح لهذا الحساب.' : 'La notation n’est pas disponible pour ce compte.';
      case 'RATING_INVALID_STATE':
        return ratingOrderIneligible;
      case 'RATING_INVALID_INPUT':
        return ratingScoreRequired;
      case 'RATING_ALREADY_EXISTS':
        return ratingAlreadyDone;
      case 'RATING_SELF_NOT_ALLOWED':
        return isArabic ? 'لا يمكنك تقييم هذا الهدف.' : 'Vous ne pouvez pas noter cette cible.';
      case 'RATING_INTEGRITY':
        return isArabic ? 'تقييم المندوب غير متاح لهذا الطلب.' : 'La notation livreur n’est pas disponible pour cette commande.';
      case 'RATING_MERCHANT_UNCERTAIN':
      case 'RATING_DRIVER_UNCERTAIN':
        return ratingSubmitUncertain;
      case 'VALIDATION_ERROR':
        return isArabic ? 'بعض المعلومات غير صالحة.' : 'Certaines informations sont invalides.';
      default:
        return unexpected;
    }
  }
}
