// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تائه في مصر';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCommunity => 'المجتمع';

  @override
  String get navMap => 'الخريطة';

  @override
  String get navCamera => 'الكاميرا';

  @override
  String get navMore => 'المزيد';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonReset => 'إعادة تعيين';

  @override
  String get commonTryAgain => 'حاول مرة أخرى';

  @override
  String get commonDismiss => 'تجاهل';

  @override
  String get reportUser => 'الإبلاغ عن المستخدم';

  @override
  String get reportTour => 'الإبلاغ عن الجولة';

  @override
  String get reportPost => 'الإبلاغ عن المنشور';

  @override
  String get reportComment => 'الإبلاغ عن التعليق';

  @override
  String get reportReasonPrompt => 'ما سبب الإبلاغ عن هذا؟';

  @override
  String get reportAdditionalDetails => 'تفاصيل إضافية (اختياري)';

  @override
  String get reportSubmit => 'إرسال البلاغ';

  @override
  String get reportMustBeLoggedIn => 'يجب تسجيل الدخول لإرسال بلاغ.';

  @override
  String get reportSelectReason => 'يرجى اختيار سبب الإبلاغ.';

  @override
  String get reportDescriptionTooLong => 'يجب ألا يتجاوز الوصف 500 حرف.';

  @override
  String get reportSuccess => 'تم إرسال البلاغ بنجاح. شكرًا لك.';

  @override
  String get weatherTapForForecast => 'اضغط لعرض توقعات 7 أيام';

  @override
  String get weatherConditionsNow => 'حالة الطقس في مصر الآن';

  @override
  String get weather7DayForecast => 'توقعات 7 أيام';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSelectLanguage => 'اختر اللغة';

  @override
  String get settingsDisplayCurrency => 'عملة العرض';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsResetBadges => 'إعادة تعيين الشارات (تصحيح)';

  @override
  String get settingsBadgesResetSuccess => 'تمت إعادة تعيين الشارات بنجاح!';

  @override
  String get settingsResetTasteSignals => 'إعادة تعيين تفضيلاتك (تصحيح)';

  @override
  String get settingsResetTasteSignalsTitle => 'إعادة تعيين تفضيلاتك؟';

  @override
  String get settingsResetTasteSignalsBody =>
      'سيؤدي هذا إلى مسح كل إشارات التخصيص المسجَّلة لك — الإعجابات المحفوظة والتجاهلات وإجابات الاختبار وسجل الزيارات. ستعود التوصيات إلى الوضع الافتراضي حتى تتفاعل مرة أخرى.';

  @override
  String get settingsTasteSignalsReset => 'تمت إعادة تعيين التفضيلات.';

  @override
  String get settingsTasteSignalsResetError =>
      'تعذّر إعادة التعيين. حاول مرة أخرى.';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get commonContinue => 'متابعة';

  @override
  String get authEmailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get authPasswordHint => 'أدخل كلمة المرور';

  @override
  String get loginTagline => 'سجّل الدخول لتبدأ رحلتك.';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get loginOrSignInWith => 'أو سجّل الدخول عبر';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟';

  @override
  String get loginCreateAccount => 'إنشاء حساب';

  @override
  String get loginFillEmailPassword =>
      'يرجى إدخال بريدك الإلكتروني وكلمة المرور.';

  @override
  String get loginGuidePending => 'طلب الإرشاد الخاص بك قيد المراجعة.';

  @override
  String get forgotEnterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get forgotResetSent =>
      'إذا كان هناك حساب مطابق، فقد أُرسل رابط إعادة التعيين.';

  @override
  String get forgotFailedSend => 'تعذّر إرسال بريد إعادة التعيين';

  @override
  String get forgotInvalidEmail => 'صيغة البريد الإلكتروني غير صحيحة.';

  @override
  String get forgotEmailSentTitle => 'تم إرسال البريد!';

  @override
  String get forgotResetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String forgotEmailSentBody(String email) {
    return 'إذا كان هناك حساب مسجَّل بالبريد $email، فقد أرسلنا رابطًا آمنًا لإعادة تعيين كلمة المرور. يُرجى التحقق من بريدك.';
  }

  @override
  String get forgotResetBody =>
      'أدخل بريدك الإلكتروني لتصلك رسالة بها رابط آمن لإعادة تعيين كلمة المرور.';

  @override
  String get forgotSendLink => 'إرسال رابط إعادة التعيين';

  @override
  String get forgotReturnToLogin => 'العودة لتسجيل الدخول';

  @override
  String get usernameTitle => 'اختر اسم\nالمستخدم';

  @override
  String get usernameSubtitle =>
      'هكذا سيجدك الآخرون في المجتمع. يمكنك تغييره لاحقًا من ملفك الشخصي.';

  @override
  String usernameAvailable(String handle) {
    return '@$handle متاح!';
  }

  @override
  String get usernameRules =>
      'من 3 إلى 20 حرفًا · أحرف وأرقام وشُرَط سفلية فقط';

  @override
  String get usernameTooShort => 'قصير جدًا — 3 أحرف على الأقل';

  @override
  String get usernameTooLong => 'طويل جدًا — 20 حرفًا كحد أقصى';

  @override
  String get usernameInvalidChars =>
      'أحرف إنجليزية صغيرة وأرقام وشُرَط سفلية فقط';

  @override
  String get usernameTaken => 'اسم المستخدم هذا مُستخدَم بالفعل';

  @override
  String get usernameCheckFailed => 'تعذّر التحقق من التوفّر — حاول مرة أخرى';

  @override
  String get usernameTakenJustNow => 'تم حجز هذا الاسم للتو — جرّب اسمًا آخر';

  @override
  String get usernameSaveFailed => 'تعذّر الحفظ — يُرجى المحاولة مرة أخرى';

  @override
  String get roleSelectionTitle => 'هل أنت...';

  @override
  String get roleTraveler => 'مسافر!';

  @override
  String get roleGuide => 'مرشد!';

  @override
  String get completeProfileTitle => 'خطوة أخيرة';

  @override
  String get completeProfileSubtitle =>
      'نحتاج تاريخ ميلادك لتخصيص رحلتك في مصر.';

  @override
  String get completeProfileButton => 'إكمال الإعداد';

  @override
  String get dobMonth => 'الشهر';

  @override
  String get dobDay => 'اليوم';

  @override
  String get dobYear => 'السنة';

  @override
  String get signupTitle => 'حساب جديد';

  @override
  String get signupFirstNameHint => 'الاسم الأول';

  @override
  String get signupLastNameHint => 'اسم العائلة';

  @override
  String get signupDateOfBirth => 'تاريخ الميلاد';

  @override
  String get signupEmailHint => 'البريد الإلكتروني';

  @override
  String get signupPhoneLabel => 'رقم الهاتف';

  @override
  String get signupConfirmPasswordHint => 'أكّد كلمة المرور';

  @override
  String get signupButton => 'إنشاء حساب';

  @override
  String get signupHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signupFirstNameInvalid =>
      'يجب أن يحتوي الاسم الأول على أحرف صحيحة (حرفان على الأقل).';

  @override
  String get signupLastNameInvalid =>
      'يجب أن يحتوي اسم العائلة على أحرف صحيحة (حرفان على الأقل).';

  @override
  String get signupEmailInvalid => 'يرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get signupPasswordWeak =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل وتتضمن حرفًا ورقمًا واحدًا على الأقل.';

  @override
  String get signupPasswordsNoMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get signupPhoneInvalid => 'يرجى إدخال رقم هاتف صحيح.';

  @override
  String get signupSuccess =>
      'تم إنشاء الحساب! يرجى تأكيد بريدك الإلكتروني للمتابعة.';

  @override
  String get signupEmailInUse => 'هذا البريد الإلكتروني مسجَّل بالفعل.';

  @override
  String get signupPasswordTooWeak => 'كلمة المرور ضعيفة جدًا.';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'نهارك سعيد';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting، $name 👋';
  }

  @override
  String get homeWhereToGo => 'إلى أين تريد أن تذهب؟';

  @override
  String get homePopularPlaces => 'أماكن شائعة';

  @override
  String get homeForYou => 'مختارة لك';

  @override
  String get homeExperiences => 'تجارب';

  @override
  String get homeSeeAll => 'عرض الكل ‹';

  @override
  String get homeNoEventsInCategory => 'لا توجد فعاليات في هذه الفئة';

  @override
  String get homePopularTours => 'جولات شائعة';

  @override
  String get homePlanYourTrip => 'خطّط لرحلتك';

  @override
  String get homeTripGuides => 'المرشدون';

  @override
  String get homeTripSolo => 'رحلة فردية';

  @override
  String get communityTitle => 'المجتمع';

  @override
  String get communitySearchPostsHint => 'ابحث في المنشورات...';

  @override
  String get communitySortTooltip => 'ترتيب';

  @override
  String get communityTagLocation => 'وسم موقع';

  @override
  String get communitySearchPlacesHint => 'ابحث عن أماكن في مصر...';

  @override
  String get communityTypeToSearch => 'اكتب للبحث عن الأماكن...';

  @override
  String get communityPostCategory => 'فئة المنشور';

  @override
  String get communityCategoryPhotos => 'صور';

  @override
  String get communityCategoryQuestions => 'أسئلة';

  @override
  String get communityCategoryGuides => 'إرشادات';

  @override
  String get communityCategoryLandmarks => 'معالم';

  @override
  String get communityCategoryTips => 'نصائح المسافر';

  @override
  String get communitySortPosts => 'ترتيب المنشورات';

  @override
  String get communitySortNewest => 'الأحدث';

  @override
  String get communitySortTopRated => 'الأعلى تقييمًا';

  @override
  String get communitySortMostDiscussed => 'الأكثر نقاشًا';

  @override
  String get communitySomethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get communityNoPostsYet => 'لا توجد منشورات بعد. كن أول من ينشر!';

  @override
  String communityNoResultsFor(String query) {
    return 'لا نتائج لـ \'$query\'';
  }

  @override
  String get communityNoPostsInCategory => 'لا توجد منشورات في هذه الفئة بعد.';

  @override
  String get communityNewPosts => 'منشورات جديدة — اضغط للتحديث';

  @override
  String get communityTrending => 'الرائج';

  @override
  String get communityClearFilter => 'مسح التصفية';

  @override
  String get communityTopExplorers => 'أبرز المستكشفين في هذا الموجز';

  @override
  String communityPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منشور',
      many: '$count منشورًا',
      few: '$count منشورات',
      two: 'منشوران',
      one: 'منشور واحد',
    );
    return '$_temp0';
  }

  @override
  String get communityWeeklyChallenge => 'تحدي الأسبوع';

  @override
  String get communityPostNow => 'انشر الآن';

  @override
  String get communityComposerHint => 'شارك تجربتك في مصر...';

  @override
  String get communityPostButton => 'نشر';

  @override
  String get communityAddPhotosTooltip => 'إضافة صور';

  @override
  String get communityTagLocationTooltip => 'وسم موقع';

  @override
  String get communityCategoryTooltip => 'الفئة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonReport => 'إبلاغ';

  @override
  String get commentEditTitle => 'تعديل التعليق';

  @override
  String get commentDeleteTitle => 'حذف التعليق';

  @override
  String get commentDeleteConfirm => 'هل أنت متأكد من حذف هذا التعليق؟';

  @override
  String get commentReply => 'رد';

  @override
  String commentReplyingTo(String name) {
    return 'ردًا على @$name';
  }

  @override
  String get commentWriteReply => 'اكتب ردًا...';

  @override
  String get commentWriteComment => 'اكتب تعليقًا...';

  @override
  String get commentsEmpty => 'لا توجد تعليقات بعد. كن أول من يعلّق!';

  @override
  String commentViewReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض $count رد',
      many: 'عرض $count ردًا',
      few: 'عرض $count ردود',
      two: 'عرض ردين',
      one: 'عرض رد واحد',
    );
    return '$_temp0 ◂';
  }

  @override
  String get commentHideReplies => 'إخفاء الردود ▴';

  @override
  String get commentsViewMore => 'عرض المزيد من التعليقات';

  @override
  String commentsHeader(int count) {
    return 'التعليقات ($count)';
  }

  @override
  String get moreTitle => 'المزيد';

  @override
  String get moreCurrency => 'العملة';

  @override
  String get moreHelp => 'المساعدة';

  @override
  String get moreTranslator => 'المترجم';

  @override
  String get moreContactUs => 'اتصل بنا';

  @override
  String get moreSosButton => 'الطوارئ — أرقام النجدة';

  @override
  String get contactCouldNotOpen => 'تعذّر فتح الرابط';

  @override
  String contactEmailCopied(String email) {
    return 'تم نسخ $email إلى الحافظة';
  }

  @override
  String get contactTitle => 'اتصل بنا';

  @override
  String get contactHeadline => 'نحن هنا لمساعدتك';

  @override
  String get contactSubtitle =>
      'تواصل معنا عبر أي من القنوات أدناه وسنرد عليك في أقرب وقت ممكن.';

  @override
  String get contactEmailSupport => 'الدعم عبر البريد الإلكتروني';

  @override
  String get contactWhatsApp => 'واتساب';

  @override
  String get contactWhatsAppSubtitle => 'تحدّث معنا مباشرة';

  @override
  String get contactInstagram => 'إنستغرام';

  @override
  String get contactResponseTimes => 'أوقات الاستجابة';

  @override
  String get contactRespEmail => 'البريد الإلكتروني';

  @override
  String get contactRespInstagram => 'رسائل إنستغرام';

  @override
  String get contactTimeEmail => 'خلال 24 ساعة';

  @override
  String get contactTimeWhatsApp => 'خلال بضع ساعات';

  @override
  String get contactTimeInstagram => 'خلال يوم إلى يومين';

  @override
  String get sosAppBarTitle => 'الطوارئ';

  @override
  String get sosFindNearestHelp => 'ابحث عن أقرب مساعدة';

  @override
  String get sosPolice => 'الشرطة';

  @override
  String get sosHospital => 'مستشفى';

  @override
  String get sosFireStation => 'المطافئ';

  @override
  String sosFindNearest(String category) {
    return 'ابحث عن أقرب $category';
  }

  @override
  String sosRefresh(String category) {
    return 'تحديث — $category';
  }

  @override
  String get sosUsingLocation => 'باستخدام موقعك الحالي';

  @override
  String get sosEnableLocation =>
      'يرجى تفعيل خدمة الموقع في إعدادات جهازك للعثور على مساعدة قريبة.';

  @override
  String get sosLocationError => 'تأكد من تفعيل خدمات الموقع وحاول مرة أخرى.';

  @override
  String sosNoResults(String category) {
    return 'لم يتم العثور على $category ضمن 10 كم. حاول الانتقال إلى منطقة أخرى.';
  }

  @override
  String get sosSearchFailed => 'فشل البحث — تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get sosCouldNotDial => 'تعذّر فتح تطبيق الاتصال';

  @override
  String get sosEmergencyNumbers => 'أرقام الطوارئ';

  @override
  String get sosNumbersNote =>
      'هذه أرقام الطوارئ الرسمية في مصر. شرطة السياحة (126) لديها عاملون يتحدثون الإنجليزية.';

  @override
  String get sosTouristPolice => 'شرطة السياحة';

  @override
  String get sosAmbulance => 'الإسعاف';

  @override
  String get sosFireBrigade => 'المطافئ';

  @override
  String get sosGasEmergency => 'طوارئ الغاز';

  @override
  String get sosTouristPoliceSubtitle =>
      'عاملون يتحدثون الإنجليزية · متاح 24/7';

  @override
  String get sosForTourists => 'للسياح';

  @override
  String get sosCall => 'اتصال';

  @override
  String get sosMap => 'الخريطة';

  @override
  String get accountUser => 'مستخدم';

  @override
  String get accountYourTaste => 'ذوقك';

  @override
  String get accountSettingsHeader => 'إعدادات الحساب:';

  @override
  String get accountEditProfile => 'تعديل الملف الشخصي';

  @override
  String get accountApplyGuide => 'تقدّم لتصبح مرشدًا';

  @override
  String get accountMyBookings => 'حجوزاتي';

  @override
  String get accountSavedPosts => 'المنشورات المحفوظة';

  @override
  String get accountMyPlans => 'خططي';

  @override
  String get accountMembership => 'العضوية';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountGuideApplication => 'طلب الإرشاد';

  @override
  String get accountStatusUnderReview => 'قيد المراجعة';

  @override
  String get accountStatusNotApproved => 'غير مقبول';

  @override
  String get planExplorerFree => 'المستكشف — مجاني';

  @override
  String get planActive => 'نشط';

  @override
  String get planCurrentDesc =>
      'خطتك الحالية — استمتع بجميع الميزات الأساسية في تائه في مصر مجانًا.';

  @override
  String get planWhatsIncluded => 'ما المتضمَّن';

  @override
  String get planFeatDiscoveryTitle => 'اكتشاف المعالم بالذكاء الاصطناعي';

  @override
  String get planFeatDiscoveryDesc =>
      'تعرّف على عدد غير محدود من المعالم عبر كاميرتك';

  @override
  String get planFeatStoriesTitle => 'قصص تاريخية بالذكاء الاصطناعي';

  @override
  String get planFeatStoriesDesc => 'استمع إلى قصص شيّقة عن كل معلم تكتشفه';

  @override
  String get planFeatMapTitle => 'خريطة تفاعلية';

  @override
  String get planFeatMapDesc =>
      'استكشف أكثر من 500 معلم مصري مع تحديد الموقع والمسارات';

  @override
  String get planFeatToursTitle => 'تصفّح واحجز الجولات';

  @override
  String get planFeatToursDesc =>
      'تصفّح الجولات الإرشادية واحجز مع مرشدين معتمدين';

  @override
  String get planFeatBadgesTitle => 'الشارات والتلعيب';

  @override
  String get planFeatBadgesDesc => 'اكسب شارات كلما استكشفت المزيد من مصر';

  @override
  String get planFeatCommunityTitle => 'موجز المجتمع';

  @override
  String get planFeatCommunityDesc => 'شارك اكتشافاتك وتواصل مع مسافرين آخرين';

  @override
  String get planFeatTranslatorTitle => 'المترجم';

  @override
  String get planFeatTranslatorDesc =>
      'ترجم النصوص باستخدام كاميرتك في الوقت الحقيقي';

  @override
  String get planFeatCurrencyTitle => 'محوّل العملات';

  @override
  String get planFeatCurrencyDesc => 'حوّل بين 16 عملة فورًا';

  @override
  String get planFeatNotificationsTitle => 'إشعارات الحجز';

  @override
  String get planFeatNotificationsDesc => 'احصل على إشعارات بتأكيدات جولاتك';

  @override
  String get planComingSoon => 'قريبًا';

  @override
  String get planComingSoonDesc =>
      'نعمل على ميزات مميزة تشمل وضع عدم الاتصال، وتجارب إرشادية حصرية، وأدوات متقدمة لتخطيط الرحلات. ترقّبوا — وسيبقى التطبيق الأساسي مجانيًا دائمًا.';

  @override
  String get profileViewTitle => 'الملف الشخصي';

  @override
  String get profileUserNotFound => 'لم يتم العثور على المستخدم';

  @override
  String get profileEmail => 'البريد الإلكتروني';

  @override
  String get profilePhone => 'الهاتف';

  @override
  String get profilePostsStat => 'المنشورات';

  @override
  String get profilePlacesStat => 'الأماكن';

  @override
  String get profileRole => 'الدور';

  @override
  String get profileRoleAdmin => 'مشرف';

  @override
  String get profileRoleVerifiedGuide => 'مرشد موثَّق';

  @override
  String get profileRoleTourist => 'سائح';

  @override
  String get profileAbout => 'نبذة';

  @override
  String get profileInterests => 'الاهتمامات';

  @override
  String get profileSocial => 'التواصل الاجتماعي';

  @override
  String get profileInstagram => 'إنستغرام';

  @override
  String get profileTwitter => 'تويتر';

  @override
  String get profileContact => 'معلومات التواصل';

  @override
  String get profileBadges => 'الشارات';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editPhotoUpdated => 'تم تحديث صورة الملف الشخصي ✅';

  @override
  String get editPhotoUploadError => 'حدث خطأ أثناء رفع الصورة. حاول مرة أخرى.';

  @override
  String get editPhoneMustVerify => 'يجب التحقق من رقم الهاتف قبل الحفظ';

  @override
  String get editInstagramRule =>
      'إنستغرام: حروف وأرقام و. و_ فقط (30 كحد أقصى)';

  @override
  String get editTwitterRule =>
      'تويتر/إكس: حروف وأرقام و. و_ فقط (15 كحد أقصى)';

  @override
  String get editUsernameEmpty => 'لا يمكن أن يكون اسم المستخدم فارغًا';

  @override
  String get editLangRequestTitle => 'طلب إضافة لغة';

  @override
  String get editLangRequestBody =>
      'بموجب القانون المصري، يحتاج المرشدون إلى اعتماد رسمي للإرشاد بلغات معيّنة. يرجى إدخال اللغة التي ترغب في إضافتها. سيتحقق المشرف من سجلات النقابة/وزارة السياحة الخاصة بك.';

  @override
  String get editLangRequestHint => 'مثال: الإسبانية، الألمانية، الإيطالية';

  @override
  String get editLangSubmit => 'إرسال الطلب';

  @override
  String get editLangPending => 'لديك بالفعل طلب لغة قيد المراجعة.';

  @override
  String get editLangSubmitted => 'تم إرسال الطلب! سيراجعه المشرف قريبًا.';

  @override
  String get editProfileUpdated => 'تم تحديث الملف الشخصي ✅';

  @override
  String get editProfileCompletion => 'اكتمال الملف الشخصي';

  @override
  String get editSectionBasic => 'المعلومات الأساسية';

  @override
  String get editFullName => 'الاسم الكامل';

  @override
  String get editUsername => 'اسم المستخدم';

  @override
  String get editPhoneNumber => 'رقم الهاتف';

  @override
  String get editNationality => 'الجنسية';

  @override
  String get editSectionContact => 'معلومات التواصل';

  @override
  String get editSectionAbout => 'نبذة عنك';

  @override
  String get editBio => 'نبذة';

  @override
  String get editBioHint => 'أخبرنا عن نفسك...';

  @override
  String get editSectionSocial => 'روابط التواصل الاجتماعي (اختياري)';

  @override
  String get editSocialHint => 'اسم المستخدم (بدون @)';

  @override
  String get editTwitterLabel => 'تويتر/إكس';

  @override
  String get editSectionGuide => 'بيانات اعتماد المرشد';

  @override
  String get editCertifiedLangs => 'اللغات المعتمدة (مقفلة)';

  @override
  String get editNoCertifiedLangs => 'لا توجد لغات معتمدة بعد.';

  @override
  String get editRequestNewLang => 'طلب لغة جديدة';

  @override
  String get editSearchNationality => 'ابحث عن الجنسية';

  @override
  String get editUsernameHint => 'your_handle';

  @override
  String get editVerificationStatus => 'حالة التحقق';

  @override
  String get editVerificationEmailSent =>
      'تم إرسال رسالة التحقق! تحقق من بريدك الوارد.';

  @override
  String get editResend => 'إعادة الإرسال';

  @override
  String get editVerifyNow => 'تحقّق الآن';

  @override
  String get editSaveChanges => 'حفظ التغييرات';
}
