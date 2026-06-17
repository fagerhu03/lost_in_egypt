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
  String get reportReasonImpersonation => 'انتحال شخصية';

  @override
  String get reportReasonFakeAccount => 'حساب مزيّف';

  @override
  String get reportReasonHarassmentBullying => 'تحرّش أو تنمّر';

  @override
  String get reportReasonInappropriateProfile => 'محتوى ملف شخصي غير لائق';

  @override
  String get reportReasonScamFraud => 'احتيال أو نصب';

  @override
  String get reportReasonOther => 'أخرى';

  @override
  String get reportReasonSpamAds => 'محتوى غير مرغوب أو إعلانات';

  @override
  String get reportReasonHateSpeech => 'خطاب كراهية';

  @override
  String get reportReasonFalseInfo => 'معلومات كاذبة';

  @override
  String get reportReasonExplicitContent => 'محتوى صريح';

  @override
  String get reportReasonHarassment => 'تحرّش';

  @override
  String get reportReasonUnsafe => 'موقع أو نشاط غير آمن';

  @override
  String get reportReasonInaccurate => 'وصف غير دقيق';

  @override
  String get reportReasonFakeReviews => 'تقييمات مزيّفة';

  @override
  String get reportReasonOverpriced => 'أسعار مبالغ فيها أو رسوم خفية';

  @override
  String get weatherTapForForecast => 'اضغط لعرض توقعات 7 أيام';

  @override
  String get weatherConditionsNow => 'حالة الطقس في مصر الآن';

  @override
  String get weather7DayForecast => 'توقعات 7 أيام';

  @override
  String get weatherCondSandstorm => 'عاصفة رملية';

  @override
  String get weatherCondSandstormWarning => 'تحذير من عاصفة رملية';

  @override
  String get weatherCondDustHaze => 'ضباب ترابي';

  @override
  String get weatherCondExtremeHeat => 'حر شديد';

  @override
  String get weatherCondVeryHot => 'حار جدًا';

  @override
  String get weatherCondExtremeUV => 'أشعة فوق بنفسجية شديدة';

  @override
  String get weatherCondHighUV => 'أشعة فوق بنفسجية عالية';

  @override
  String get weatherCondClear => 'صحو';

  @override
  String get weatherCondGood => 'أحوال جيدة';

  @override
  String get weatherAdvisorySandstorm =>
      'عاصفة رملية في المنطقة — تجنّب جميع الأماكن المفتوحة. ارتدِ كمامة إذا اضطررت للخروج.';

  @override
  String get weatherAdvisoryDustHaze =>
      'ضباب ترابي يقلّل الرؤية. الزيارات الخارجية غير مناسبة؛ ارتدِ نظارة شمسية.';

  @override
  String weatherAdvisoryExtremeHeat(String temp) {
    return 'الإحساس الحراري $temp°م. زر المواقع المفتوحة قبل التاسعة صباحًا أو بعد الخامسة مساءً فقط. احمل ما لا يقل عن لترين من الماء.';
  }

  @override
  String weatherAdvisoryVeryHot(String temp) {
    return 'حار جدًا (الإحساس الحراري $temp°م). حافظ على ترطيب جسمك وابحث عن الظل كثيرًا.';
  }

  @override
  String weatherAdvisoryExtremeUV(String uv) {
    return 'مؤشر الأشعة فوق البنفسجية $uv — شديد. واقي الشمس والقبعة والنظارة الشمسية ضرورية. قلّل التعرّض وقت الظهيرة.';
  }

  @override
  String weatherAdvisoryHighUV(String uv) {
    return 'مؤشر الأشعة فوق البنفسجية $uv — مرتفع. ضع واقي شمس بمعامل حماية 50+ قبل الخروج.';
  }

  @override
  String get weatherAdvisoryGood =>
      'أحوال رائعة لاستكشاف الأماكن المفتوحة اليوم.';

  @override
  String get weatherDayToday => 'اليوم';

  @override
  String get weatherDayTomorrow => 'غدًا';

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
  String get dobMonthJanuary => 'يناير';

  @override
  String get dobMonthFebruary => 'فبراير';

  @override
  String get dobMonthMarch => 'مارس';

  @override
  String get dobMonthApril => 'أبريل';

  @override
  String get dobMonthMay => 'مايو';

  @override
  String get dobMonthJune => 'يونيو';

  @override
  String get dobMonthJuly => 'يوليو';

  @override
  String get dobMonthAugust => 'أغسطس';

  @override
  String get dobMonthSeptember => 'سبتمبر';

  @override
  String get dobMonthOctober => 'أكتوبر';

  @override
  String get dobMonthNovember => 'نوفمبر';

  @override
  String get dobMonthDecember => 'ديسمبر';

  @override
  String get dobErrorMissing => 'يرجى اختيار تاريخ ميلادك.';

  @override
  String get dobErrorInvalid => 'تاريخ ميلاد غير صالح.';

  @override
  String dobErrorTooManyDays(String month, String year, int days) {
    return '$month $year يحتوي على $days يومًا فقط.';
  }

  @override
  String dobErrorUnderage(int minAge) {
    return 'يجب أن يكون عمرك $minAge عامًا على الأقل لاستخدام التطبيق.';
  }

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
  String get tasteKeyHistory => 'تاريخ';

  @override
  String get tasteKeyAncientSites => 'مواقع أثرية';

  @override
  String get tasteKeyAttractions => 'معالم سياحية';

  @override
  String get tasteKeyMuseums => 'متاحف';

  @override
  String get tasteKeyMosques => 'مساجد';

  @override
  String get tasteKeyChurches => 'كنائس';

  @override
  String get tasteKeyParks => 'حدائق';

  @override
  String get tasteKeyBeaches => 'شواطئ';

  @override
  String get tasteKeyRestaurants => 'مطاعم';

  @override
  String get tasteKeyCafes => 'مقاهي';

  @override
  String get tasteKeyMarkets => 'أسواق';

  @override
  String get tasteKeyShopping => 'تسوّق';

  @override
  String get tasteKeyMonuments => 'آثار';

  @override
  String get tasteKeyArt => 'فنون';

  @override
  String get tasteKeyNightlife => 'حياة ليلية';

  @override
  String get tasteKeyThemeParks => 'مدن ملاهٍ';

  @override
  String get tasteKeyAquariums => 'أحواض مائية';

  @override
  String get tasteKeyZoos => 'حدائق حيوان';

  @override
  String get tasteKeySpas => 'منتجعات صحية';

  @override
  String get tasteKeyStadiums => 'ملاعب';

  @override
  String get tasteKeyEntertainment => 'ترفيه';

  @override
  String get tasteKeyCultural => 'ثقافي';

  @override
  String get tasteKeyNature => 'طبيعة';

  @override
  String get tasteKeyRelaxation => 'استرخاء';

  @override
  String get tasteKeyReligious => 'ديني';

  @override
  String get tasteKeyFamily => 'عائلي';

  @override
  String get tasteKeyAdventure => 'مغامرة';

  @override
  String get tasteKeyFood => 'طعام';

  @override
  String get tasteKeyAncient => 'قديم';

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

  @override
  String get currencyConverterTitle => 'محوّل العملات';

  @override
  String get currencyEnterValidAmount => 'يرجى إدخال مبلغ صالح';

  @override
  String currencyRateUnavailable(String currency) {
    return 'السعر غير متاح لـ $currency';
  }

  @override
  String get currencyFrom => 'من';

  @override
  String get currencyTo => 'إلى';

  @override
  String get currencyAmount => 'المبلغ';

  @override
  String get currencyEnterAmount => 'أدخل المبلغ';

  @override
  String get currencyConvert => 'تحويل';

  @override
  String get currencyResult => 'النتيجة';

  @override
  String get translatorInitFailed => 'فشل في تهيئة المترجم';

  @override
  String get translatorEnterText => 'يرجى إدخال نص للترجمة';

  @override
  String get translatorTimedOut =>
      'انتهت مهلة الترجمة. قد تكون النماذج قيد التنزيل — حاول مرة أخرى بعد لحظة.';

  @override
  String get translatorFailed =>
      'فشلت الترجمة. إذا كنت غير متصل، فقد لا تكون النماذج قد نُزّلت بعد.';

  @override
  String get translatorDownloadingModels =>
      'جارٍ تنزيل نماذج الترجمة للاستخدام دون اتصال...';

  @override
  String get translatorWorksOffline =>
      'يعمل دون اتصال — النماذج مخزّنة على الجهاز';

  @override
  String get translatorEnterTextHint => 'أدخل النص';

  @override
  String get translatorTranslationHint => 'الترجمة';

  @override
  String get translatorTranslate => 'ترجم';

  @override
  String get helpFaqTitle => 'المساعدة والأسئلة الشائعة';

  @override
  String get helpSecGettingStarted => 'البداية';

  @override
  String get helpSecMapPlaces => 'الخريطة والأماكن';

  @override
  String get helpSecBookings => 'الحجوزات والمدفوعات';

  @override
  String get helpSecCommunity => 'المجتمع';

  @override
  String get helpSecAccount => 'الحساب والإعدادات';

  @override
  String get helpSecOffline => 'وضع عدم الاتصال';

  @override
  String get helpSecSafety => 'السلامة والطوارئ';

  @override
  String get helpQDiscover => 'كيف أكتشف المعالم؟';

  @override
  String get helpADiscover =>
      'افتح تبويب الكاميرا ووجّه هاتفك نحو أي معلم مصري. سيتعرّف عليه الذكاء الاصطناعي ويُنشئ قصة تاريخية يقرأها مرشدك الشخصي بصوتٍ عالٍ. يُحفظ كل اكتشاف في ملفك الشخصي ويُحتسب ضمن تقدّم شاراتك.';

  @override
  String get helpQBadges => 'كيف أكسب الشارات؟';

  @override
  String get helpABadges =>
      'تُكتسب الشارات باكتشاف المعالم من خلال تبويب الكاميرا. زُر 1 و3 و5 و10 و20 معلمًا فريدًا لفتح شارات المستكشف المبتدئ، والسائح، ونابش المقابر، والمؤرّخ، والفرعون على التوالي. هناك أيضًا شارات مخفية — استكشف واعثر عليها!';

  @override
  String get helpQGuide => 'كيف أصبح مرشدًا سياحيًا؟';

  @override
  String get helpAGuide =>
      'اذهب إلى الحساب ← التقديم كمرشد. ستحتاج إلى رقم رخصة وزارة السياحة، ورقم النقابة، واللغات المعتمدة، والمستندات الداعمة. تُراجَع الطلبات من قِبل فريق الإدارة لدينا وسيتم إعلامك بالنتيجة داخل التطبيق.';

  @override
  String get helpQSavePlaces => 'هل يمكنني حفظ أماكن لزيارتها لاحقًا؟';

  @override
  String get helpASavePlaces =>
      'نعم! في تبويب الخريطة، اضغط على أي علامة معلم ثم اضغط أيقونة الإشارة المرجعية لحفظه. يمكنك أيضًا حفظ الفعاليات من تبويب الرئيسية بالضغط على أيقونة القلب في أي بطاقة فعالية. يمكنك الوصول إلى كل أماكنك المحفوظة من تبويب الخريطة ← الأماكن المحفوظة.';

  @override
  String get helpQRecognise => 'لم تتعرّف كاميرتي على معلم — ماذا أفعل؟';

  @override
  String get helpARecognise =>
      'تأكّد من أن المعلم يملأ معظم الإطار وأنه مُضاء جيدًا. اضغط زر الالتقاط وانتظر بضع ثوانٍ. إذا كان المعلم ثانويًا جدًا أو خارج المسار السياحي الرئيسي فقد لا يكون مُدرجًا في قاعدة البيانات بعد.';

  @override
  String get helpQBook => 'كيف أحجز جولة؟';

  @override
  String get helpABook =>
      'اذهب إلى تبويب الرئيسية وتصفّح الجولات الإرشادية المتاحة، أو ابحث عن واحدة في تبويب الخريطة. اختر جولة، وحدّد تاريخك وعدد التذاكر، ثم أكمل الدفع باستخدام أي من طرق الدفع المتاحة المعروضة عند الدفع (بطاقة، أو Apple Pay، أو محفظة هاتف).';

  @override
  String get helpQCancel => 'كيف ألغي حجزًا؟';

  @override
  String get helpACancel =>
      'اذهب إلى الحساب ← حجوزاتي، واعثر على الحجز ضمن تبويب القادمة، ثم اضغط إلغاء. تُحدَّد سياسات الاسترداد من قِبل كل مرشد — راجع تفاصيل الجولة قبل الحجز.';

  @override
  String get helpQSecure => 'هل معلومات الدفع الخاصة بي آمنة؟';

  @override
  String get helpASecure =>
      'نعم. تُعالَج المدفوعات عبر Paymob، وهي بوابة دفع معتمدة ومتوافقة مع معيار PCI. لا يخزّن تطبيق تائه في مصر تفاصيل بطاقتك أو محفظتك على خوادمه إطلاقًا.';

  @override
  String get helpQCurrency => 'كيف أغيّر عملة العرض؟';

  @override
  String get helpACurrency =>
      'اذهب إلى المزيد ← الإعدادات ← العملة المفضّلة. ستُعرض جميع أسعار الجولات في التطبيق بالعملة التي تختارها. أما الخصم الفعلي عند الدفع فيُعالَج دائمًا بالجنيه المصري عبر Paymob.';

  @override
  String get helpQPost => 'كيف أنشر في المجتمع؟';

  @override
  String get helpAPost =>
      'اضغط تبويب المجتمع ثم اضغط زر +. يمكنك كتابة نص، وإضافة صور، والإشارة إلى موقع، واختيار فئة (قصة سفر، سؤال، نصيحة، إلخ)، واستخدام #الوسوم أو @الإشارة إلى مستخدمين آخرين.';

  @override
  String get helpQReport => 'كيف أبلّغ عن منشور أو مستخدم؟';

  @override
  String get helpAReport =>
      'في أي منشور أو تعليق بالمجتمع، اضغط قائمة ⋮ واختر إبلاغ. يراجع فريق الإدارة لدينا جميع البلاغات ويتخذ إجراءً خلال 24 ساعة.';

  @override
  String get helpQUsername => 'كيف أغيّر اسم المستخدم الخاص بي؟';

  @override
  String get helpAUsername =>
      'اذهب إلى الحساب ← تعديل الملف الشخصي. يجب أن يكون اسم المستخدم (مثل @ahmed_x1) من 3 إلى 20 حرفًا، بأحرف إنجليزية صغيرة وأرقام وشرطات سفلية فقط، وفريدًا عالميًا. يُعرض على جميع منشوراتك وتعليقاتك.';

  @override
  String get helpQTheme => 'كيف أبدّل بين الوضع الفاتح والداكن؟';

  @override
  String get helpATheme =>
      'اذهب إلى المزيد ← الإعدادات وبدّل مفتاح الوضع الداكن. يُحفظ تفضيلك في حسابك ويُزامَن عبر أجهزتك.';

  @override
  String get helpQOfflineWhat => 'ماذا يمكنني استخدامه بدون اتصال بالإنترنت؟';

  @override
  String get helpAOfflineWhat =>
      'صُمّم تائه في مصر بشكل أساسي كتجربة متصلة بالإنترنت، لكن تبقى عدة ميزات متاحة دون اتصال:\n\n• علامات الخريطة — أكثر من 500 معلم مصري مُضمَّن محليًا في التطبيق، لذا تعرض الخريطة علامات المواقع حتى بدون إنترنت (أما بلاطات الخريطة نفسها فتتطلب اتصالاً).\n• الصور المخزّنة — الأماكن وصور الفعاليات التي شاهدتها سابقًا مخزّنة على جهازك وتُحمّل فورًا دون اتصال.\n• التعرّف على النص (الكاميرا ← مسح النص) — تعالج ML Kit النص بالكامل على الجهاز.\n• المترجم — بمجرد تنزيل حزمة لغة، تعمل الترجمة دون اتصال.\n• تنقّل التطبيق والشارات والإعدادات — متاحة دائمًا.';

  @override
  String get helpQOfflineNeed => 'ما الميزات التي تتطلب اتصالاً بالإنترنت؟';

  @override
  String get helpAOfflineNeed =>
      'تحتاج الميزات التالية إلى اتصال نشط:\n\n• التعرّف على المعالم عبر تبويب الكاميرا (يستخدم Google Cloud Vision API)\n• توليد القصص التاريخية بالذكاء الاصطناعي (يستخدم Google Gemini)\n• منشورات المجتمع والإعجابات والتعليقات (Firestore)\n• تصفّح الجولات وحجزها (Firestore)\n• موجز الفعاليات (Firestore)\n• تحويل العملات (أسعار صرف حيّة)\n• الطوارئ — البحث عن أقرب خدمات الطوارئ (Google Places API)\n• تسجيل الدخول أو إنشاء حساب (Firebase Auth)';

  @override
  String get helpQOfflineImprove =>
      'هل ستتحسّن الميزات المتاحة دون اتصال بمرور الوقت؟';

  @override
  String get helpAOfflineImprove =>
      'نعم. نخطّط لتوسيع دعم وضع عدم الاتصال في التحديثات المستقبلية، بما في ذلك أدلة المدن القابلة للتنزيل ومحتوى الجولات المخزّن. حافظ على تحديث التطبيق للحصول على هذه التحسينات.';

  @override
  String get helpQEmergency => 'ماذا أفعل في حالة الطوارئ؟';

  @override
  String get helpAEmergency =>
      'افتح المزيد ← الطوارئ. يمكنك العثور على أقرب قسم شرطة أو مستشفى أو محطة إطفاء باستخدام موقعك الحالي، أو الاتصال بأرقام الطوارئ الرسمية في مصر مباشرةً من التطبيق:\n• الشرطة: 122\n• الإسعاف: 123\n• الإطفاء: 180\n• شرطة السياحة: 126';

  @override
  String get soloTripTitle => 'رحلة فردية';

  @override
  String get soloRecommendedPlans => 'خطط موصى بها';

  @override
  String get soloPersonalised => 'مخصّصة بناءً على سجل سفرك';

  @override
  String get soloBestForYou => 'الأنسب لك';

  @override
  String get soloStatusActive => 'نشطة';

  @override
  String get soloStatusSaved => 'محفوظة';

  @override
  String get soloStatusCompleted => 'مكتملة';

  @override
  String get soloTabAll => 'الكل';

  @override
  String get soloCouldNotLoadPlans => 'تعذّر تحميل الخطط';

  @override
  String get soloContinueTour => 'متابعة الجولة';

  @override
  String get soloStartTour => 'ابدأ الجولة';

  @override
  String get soloCouldNotStart => 'تعذّر بدء الجولة. حاول مرة أخرى.';

  @override
  String get soloDeletePlanTitle => 'حذف الخطة؟';

  @override
  String get soloDeleteActiveBody =>
      'هذه الجولة قيد التنفيذ. حذفها سيلغي كل تقدّمك ولا يمكن التراجع عنه.';

  @override
  String get soloDeleteBody => 'لا يمكن التراجع عن هذا.';

  @override
  String get soloNoPlansYet => 'لا توجد خطط بعد';

  @override
  String get soloNoPlansSub =>
      'احفظ رحلة منسّقة أو أنشئ رحلتك الخاصة\nلتظهر هنا.';

  @override
  String get soloBrowseTrips => 'تصفّح الرحلات';

  @override
  String get soloCustomizeOwnPlan => 'خصّص خطتك\nالخاصة';

  @override
  String get soloSavePlan => 'حفظ الخطة';

  @override
  String get soloPlanSaved => 'تم حفظ الخطة! اعثر عليها في خططي.';

  @override
  String get soloCouldNotSave => 'تعذّر حفظ الخطة. حاول مرة أخرى.';

  @override
  String get soloHearStory => 'استمع إلى القصة';

  @override
  String get soloStorySilent => 'أرواح التاريخ صامتة الآن.';

  @override
  String get soloStoryPause => 'إيقاف مؤقت';

  @override
  String get soloStoryResume => 'استئناف';

  @override
  String get soloStoryListen => 'استماع';

  @override
  String get soloStoryGenerating => 'جارٍ إنشاء الصوت…';

  @override
  String get soloStoryReplay => 'إعادة من البداية';

  @override
  String get soloNavigateHere => 'التنقّل إلى هنا';

  @override
  String get soloViewFullRoute => 'عرض المسار كاملاً';

  @override
  String get soloViewFullRouteMap => 'عرض المسار كاملاً على الخريطة';

  @override
  String get soloFullRoute => 'المسار كاملاً';

  @override
  String get soloHighlights => 'أبرز المعالم';

  @override
  String get soloItinerary => 'خط سير الرحلة';

  @override
  String get tourEndTitle => 'إنهاء الجولة؟';

  @override
  String get tourEndBody =>
      'سيؤدي هذا إلى وضع علامة على الجولة كمكتملة. لا يزال بإمكانك عرضها في خططي.';

  @override
  String get tourEndConfirm => 'إنهاء الجولة';

  @override
  String get tourEnded => 'انتهت الجولة. اعثر عليها ضمن المكتملة في خططي.';

  @override
  String get tourInProgress => 'الجولة قيد التنفيذ';

  @override
  String get tourGo => 'انطلق';

  @override
  String get tourUpNext => 'التالي';

  @override
  String get tourComplete => 'اكتملت الجولة!';

  @override
  String tourStopsExplored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطة مُستكشَفة',
      many: '$count محطة مُستكشَفة',
      few: '$count محطات مُستكشَفة',
      two: 'محطتان مُستكشَفتان',
      one: 'محطة واحدة مُستكشَفة',
    );
    return '$_temp0';
  }

  @override
  String get tourCompleteSub => 'لقد عشت قلب مصر.\nاستكشاف رائع! 🌟';

  @override
  String get tourYouMightLove => 'قد يعجبك أيضًا';

  @override
  String get tourDone => 'تم';

  @override
  String get tourStartedTitle => '🗺️ بدأت جولتك!';

  @override
  String get tourOnboardTitle => 'إليك ما يمكنك فعله';

  @override
  String get tourLetsGo => 'هيا بنا!';

  @override
  String get tourFeatViewMap => 'عرض على الخريطة';

  @override
  String get tourFeatViewMapDesc =>
      'اضغط أيقونة الخريطة (أعلى اليمين) لرؤية محطاتك على الخريطة والتنقّل إلى أيٍّ منها.';

  @override
  String get tourFeatTrack => 'تتبّع التقدّم';

  @override
  String get tourFeatTrackDesc =>
      'ضع علامة على كل محطة عند زيارتها. يُحفظ تقدّمك تلقائيًا.';

  @override
  String get tourFeatStories => 'قصص الذكاء الاصطناعي';

  @override
  String get tourFeatStoriesDesc =>
      'وسّع أي محطة واضغط \"استمع إلى القصة\" للحصول على تاريخ ذلك المكان من الذكاء الاصطناعي.';

  @override
  String get resultCouldNotGenerate => 'تعذّر إنشاء خطتك.';

  @override
  String get resultPlanning => 'جارٍ التخطيط لرحلتك…';

  @override
  String get resultPlanningSub =>
      'مرشد الذكاء الاصطناعي يبني لك خط سير مخصّصًا يومًا بيوم.';

  @override
  String get resultCouldNotLoad => 'تعذّر تحميل خطتك';

  @override
  String resultCouldNotPin(String name) {
    return 'تعذّر تحديد $name على الخريطة بعد. حاول مرة أخرى بعد لحظة.';
  }

  @override
  String get resultCouldNotExport => 'تعذّر تصدير خط السير. حاول مرة أخرى.';

  @override
  String get resultDiscardTitle => 'تجاهل الخطة؟';

  @override
  String get resultDiscardBody =>
      'لن يتم حفظ هذه الخطة. يمكنك دائمًا إنشاء خطة جديدة.';

  @override
  String get resultKeep => 'احتفظ بها';

  @override
  String get resultDiscard => 'تجاهل';

  @override
  String get resultExportPdf => 'تصدير PDF';

  @override
  String resultLocationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موقع',
      many: '$count موقعًا',
      few: '$count مواقع',
      two: 'موقعان',
      one: 'موقع واحد',
    );
    return '$_temp0';
  }

  @override
  String resultDayNum(int num) {
    return 'اليوم $num';
  }

  @override
  String get resultViewOnMaps => 'عرض على الخرائط';

  @override
  String get resultShareSuffix => 'خُطّط له باستخدام تائه في مصر 🌍';

  @override
  String get quizNext => 'التالي';

  @override
  String get quizFinish => 'إنهاء';

  @override
  String quizStepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get soloQuizInterestsTitle => 'ما هي اهتماماتك؟';

  @override
  String get soloQuizAreasTitle => 'أين تريد أن تستكشف؟';

  @override
  String get soloQuizTripTimeTitle => 'رحلات نهارية أم سهرة ليلية؟';

  @override
  String get tripTimeDay => 'نهارًا';

  @override
  String get tripTimeDayDesc => 'المعابد والأسواق\nوالمغامرات في الهواء الطلق';

  @override
  String get tripTimeNight => 'ليلاً';

  @override
  String get tripTimeNightDesc => 'تناول الطعام والحياة الليلية\nوالترفيه';

  @override
  String get soloQuizBudgetTitle => 'ما هي ميزانيتك؟';

  @override
  String get budgetPresetBudget => 'اقتصادية';

  @override
  String get budgetPresetMid => 'متوسطة';

  @override
  String get budgetPresetLuxury => 'فاخرة';

  @override
  String get soloQuizDateTitle => 'اختر تواريخك وموقعك';

  @override
  String get soloDateFrom => 'من';

  @override
  String get soloDateStartHint => 'تاريخ البدء';

  @override
  String get soloDateTo => 'إلى';

  @override
  String get soloDateEndHint => 'تاريخ الانتهاء';

  @override
  String soloNightsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليلة',
      many: '$count ليلة',
      few: '$count ليالٍ',
      two: 'ليلتان',
      one: 'ليلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get soloStartLocationHint => 'من أين تبدأ رحلتك؟';

  @override
  String get soloSelectDayNight => 'يرجى اختيار نهارًا أو ليلاً أو كليهما.';

  @override
  String tourCardUpTo(int count) {
    return 'حتى $count';
  }

  @override
  String get tourCardNew => 'جديد';

  @override
  String get mapPickerFetching => 'جارٍ جلب العنوان...';

  @override
  String get mapPickerSelectedLocation => 'الموقع المحدد';

  @override
  String get mapPickerUnknownLocation => 'موقع غير معروف';

  @override
  String get mapPickerSearchHint => 'ابحث عن معلم أو وجهة...';

  @override
  String get mapPickerTapHint => 'اضغط في أي مكان على الخريطة لتحديد موقع';

  @override
  String get mapPickerConfirm => 'تأكيد الموقع';

  @override
  String get mapPickerCustomPin => 'موقع مخصّص';

  @override
  String get tourMapMeetupTitle => 'موقع اللقاء';

  @override
  String get tourMapStartPoint => 'نقطة بداية الجولة';

  @override
  String get tourMapMeetingPoint => 'نقطة اللقاء';

  @override
  String get tourMapDestinations => 'الوجهات التي ستزورها:';

  @override
  String get tourMapExplore => 'استكشف في الخريطة الرئيسية';

  @override
  String get tourMapNavigateRoute => 'التنقّل عبر مسار الجولة';

  @override
  String get qrTitle => 'مسح رمز التذكرة';

  @override
  String get qrPointCamera => 'وجّه الكاميرا نحو رمز تذكرة السائح';

  @override
  String get qrScanAnother => 'مسح تذكرة أخرى';

  @override
  String get qrBookingNotFound => 'لم يتم العثور على الحجز';

  @override
  String get qrUnknownTour => 'جولة غير معروفة';

  @override
  String get qrUnknownTraveler => 'مسافر غير معروف';

  @override
  String get qrValidTicket => 'تذكرة صالحة';

  @override
  String qrInvalidTicket(String status) {
    return 'تذكرة غير صالحة ($status)';
  }

  @override
  String get qrAllCheckedIn => 'تم تسجيل دخول جميع التذاكر';

  @override
  String qrPartiallyCheckedIn(int checked, int total) {
    return 'تم تسجيل الدخول جزئيًا ($checked/$total)';
  }

  @override
  String get qrRowTour => 'الجولة';

  @override
  String get qrRowDate => 'التاريخ';

  @override
  String get qrRowTickets => 'التذاكر';

  @override
  String get qrRowAmount => 'المبلغ';

  @override
  String get qrRowBookingId => 'رقم الحجز';

  @override
  String qrTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة',
      many: '$count تذكرة',
      few: '$count تذاكر',
      two: 'تذكرتان',
      one: 'تذكرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String qrCheckedInCount(int count) {
    return '$count تم تسجيلهم';
  }

  @override
  String get qrCheckInHowMany => 'كم عدد التذاكر للتسجيل؟';

  @override
  String get qrCheckInTourist => 'تسجيل دخول السائح';

  @override
  String qrCheckInRemaining(int count, int remaining) {
    return 'تسجيل دخول $count من $remaining المتبقية';
  }

  @override
  String qrAllTicketsCheckedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تسجيل دخول جميع التذاكر الـ$count!',
      many: 'تم تسجيل دخول جميع التذاكر الـ$count!',
      few: 'تم تسجيل دخول جميع التذاكر الـ$count!',
      two: 'تم تسجيل دخول التذكرتين!',
      one: 'تم تسجيل دخول التذكرة!',
    );
    return '$_temp0';
  }

  @override
  String qrCheckedInResult(int count, int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تسجيل دخول $count تذكرة.',
      many: 'تم تسجيل دخول $count تذكرة.',
      few: 'تم تسجيل دخول $count تذاكر.',
      two: 'تم تسجيل دخول تذكرتين.',
      one: 'تم تسجيل دخول تذكرة واحدة.',
    );
    return '$_temp0\nمتبقّي $remaining.';
  }

  @override
  String get commonNo => 'لا';

  @override
  String get attendeesTitle => 'الحاضرون';

  @override
  String get attendeesError => 'خطأ في تحميل الحاضرين';

  @override
  String get attendeesIndexHint =>
      'قد تكون هناك حاجة إلى فهرس Firestore.\nتحقق من وحدة التصحيح للحصول على الرابط.';

  @override
  String get attendeesEmpty => 'لا توجد حجوزات بعد';

  @override
  String get attendeesEmptySub =>
      'عندما يحجز المسافرون هذه الجولة،\nسيظهرون هنا.';

  @override
  String get attendeesStatConfirmed => 'مؤكَّد';

  @override
  String get attendeesStatCancelled => 'ملغى';

  @override
  String get attendeesStatTotal => 'الإجمالي';

  @override
  String attendeesSectionConfirmed(int count) {
    return 'مؤكَّد ($count)';
  }

  @override
  String attendeesSectionCancelled(int count) {
    return 'ملغى ($count)';
  }

  @override
  String get attendeesUnknownUser => 'مستخدم غير معروف';

  @override
  String get attendeesPaid => 'مدفوع';

  @override
  String get attendeesPending => 'قيد الانتظار';

  @override
  String get attendeesCall => 'اتصال';

  @override
  String get attendeesWhatsApp => 'واتساب';

  @override
  String get attendeesEmail => 'بريد إلكتروني';

  @override
  String get attendeesCancelBooking => 'إلغاء الحجز';

  @override
  String get attendeesCancelBody =>
      'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟ سيتم إخطار المسافر.';

  @override
  String get guideDashTitle => 'لوحة المرشد';

  @override
  String get guideDashStopSharing => 'إيقاف مشاركة الموقع المباشر';

  @override
  String get guideDashShareLocation => 'شارك موقعك المباشر مع السائحين';

  @override
  String get guideDashScanTicket => 'مسح التذكرة';

  @override
  String get guideDashNoTours => 'لا توجد جولات بعد';

  @override
  String get guideDashCreateFirst => 'أنشئ جولتك الأولى!';

  @override
  String guideDashYourTours(int count) {
    return 'جولاتك ($count)';
  }

  @override
  String get guideDashCreateTour => 'إنشاء جولة';

  @override
  String get guideDashEarningsError =>
      'تعذّر تحميل الأرباح.\nتحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get guideDashStatTours => 'الجولات';

  @override
  String get guideDashStatBookings => 'الحجوزات';

  @override
  String get guideDashStatRevenue => 'الإيرادات';

  @override
  String guideDashMax(int count) {
    return 'حتى $count';
  }

  @override
  String get guideDashBookingsError => 'تعذّر تحميل الحجوزات.';

  @override
  String guideDashConfirmedBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حجز مؤكَّد',
      many: '$count حجزًا مؤكَّدًا',
      few: '$count حجوزات مؤكَّدة',
      two: 'حجزان مؤكَّدان',
      one: 'حجز مؤكَّد واحد',
    );
    return '📌 $_temp0';
  }

  @override
  String get guideDashView => 'عرض';

  @override
  String get guideDashDeleteTitle => 'حذف الجولة';

  @override
  String guideDashDeleteBody(String title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get weekdayMon => 'الإثنين';

  @override
  String get weekdayTue => 'الثلاثاء';

  @override
  String get weekdayWed => 'الأربعاء';

  @override
  String get weekdayThu => 'الخميس';

  @override
  String get weekdayFri => 'الجمعة';

  @override
  String get weekdaySat => 'السبت';

  @override
  String get weekdaySun => 'الأحد';

  @override
  String get createEditTitle => 'تعديل الجولة';

  @override
  String get createNewTitle => 'إنشاء جولة جديدة';

  @override
  String get createUpdatedToast => 'تم تحديث الجولة!';

  @override
  String get createCreatedToast => 'تم إنشاء الجولة بنجاح!';

  @override
  String get createRequired => 'مطلوب';

  @override
  String get createFieldTitle => 'عنوان الجولة';

  @override
  String get createFieldDesc => 'الوصف';

  @override
  String get createDestinationsLabel => 'الوجهات (بحد أقصى 5)';

  @override
  String get createSearchDestination => 'ابحث عن وجهة...';

  @override
  String get createFieldPrice => 'السعر (ج.م)';

  @override
  String get createFieldMaxAttendees => 'الحد الأقصى للحضور';

  @override
  String get createMeetingLocation => 'موقع اللقاء';

  @override
  String get createSelectMeetingLocation => 'اختر موقع اللقاء';

  @override
  String get createSelectMeetingTime => 'اختر وقت اللقاء';

  @override
  String createMeetingTimePrefix(String time) {
    return 'وقت اللقاء: $time';
  }

  @override
  String get createScheduleFreq => 'أيام الجدولة';

  @override
  String get createImages => 'صور الجولة';

  @override
  String get createEditImages => 'تعديل صور الجولة';

  @override
  String get createSaveChanges => 'حفظ التغييرات';

  @override
  String get createSelectTime => 'يرجى اختيار وقت اللقاء.';

  @override
  String get createSelectImage => 'يرجى اختيار صورة واحدة على الأقل.';

  @override
  String get createSelectLocation => 'يرجى اختيار موقع اللقاء على الخريطة.';

  @override
  String get createAddDestination => 'يرجى إضافة وجهة واحدة على الأقل.';

  @override
  String get createPriceNegative => 'لا يمكن أن يكون السعر سالبًا.';

  @override
  String get createAttendeesZero =>
      'يجب أن يكون الحد الأقصى للحضور أكبر من صفر.';

  @override
  String get toursDiscoverTitle => 'اكتشف الجولات';

  @override
  String get toursSearchHint => 'ابحث عن وجهات أو مرشدين...';

  @override
  String get toursFilters => 'الفلاتر';

  @override
  String get toursPriceRange => 'نطاق السعر';

  @override
  String get toursMinRating => 'الحد الأدنى للتقييم';

  @override
  String toursStarsPlus(int count) {
    return '$count+ نجوم';
  }

  @override
  String get toursFrequency => 'التكرار';

  @override
  String get toursFreqDaily => 'يومي';

  @override
  String get toursFreqWeekly => 'أسبوعي';

  @override
  String get toursFreqWeekends => 'عطلات نهاية الأسبوع';

  @override
  String get toursFreqOneTime => 'لمرة واحدة';

  @override
  String get toursApplyFilters => 'تطبيق الفلاتر';

  @override
  String get toursSortNewest => 'الأحدث أولاً';

  @override
  String get toursSortCheapest => 'الأرخص أولاً';

  @override
  String get toursSortPriciest => 'الأغلى أولاً';

  @override
  String get toursSortHighestRated => 'الأعلى تقييمًا';

  @override
  String get toursSortMostPopular => 'الأكثر شعبية';

  @override
  String get toursSortLabelNewest => 'الأحدث';

  @override
  String get toursSortLabelCheapest => 'الأرخص';

  @override
  String get toursSortLabelPriciest => 'الأغلى';

  @override
  String get toursSortLabelTopRated => 'الأعلى تقييمًا';

  @override
  String get toursSortLabelPopular => 'شائع';

  @override
  String toursFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count جولة',
      many: 'تم العثور على $count جولة',
      few: 'تم العثور على $count جولات',
      two: 'تم العثور على جولتين',
      one: 'تم العثور على جولة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get toursLoadError =>
      'تعذّر تحميل الجولات.\nتحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get toursEmptyTitle => 'لم يتم العثور على جولات';

  @override
  String get toursEmptyFilters => 'حاول تعديل الفلاتر.';

  @override
  String get toursEmptySearch => 'حاول تعديل كلمة البحث.';

  @override
  String get toursClearFilters => 'مسح كل الفلاتر';

  @override
  String get toursRecommended => 'موصى به لك';

  @override
  String get bookingCheckoutTitle => 'الدفع';

  @override
  String get bookingLoginRequired => 'يرجى تسجيل الدخول للحجز.';

  @override
  String get bookingInvalidWallet =>
      'يرجى إدخال رقم هاتف مصري صالح (مثال: 01XXXXXXXXX).';

  @override
  String get bookingFullyBooked => 'عذرًا، هذه الجولة محجوزة بالكامل الآن.';

  @override
  String bookingSeatsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقعد فقط متبقٍّ. يرجى تقليل اختيارك.',
      many: '$count مقعدًا فقط متبقية. يرجى تقليل اختيارك.',
      few: '$count مقاعد فقط متبقية. يرجى تقليل اختيارك.',
      two: 'مقعدان فقط متبقيان. يرجى تقليل اختيارك.',
      one: 'مقعد واحد فقط متبقٍّ. يرجى تقليل اختيارك.',
    );
    return '$_temp0';
  }

  @override
  String get bookingPaymentFailed => 'تم إلغاء الدفع أو فشل.';

  @override
  String get bookingWalletFailed => 'فشل الدفع عبر المحفظة.';

  @override
  String get bookingKioskSoon => 'الدفع عبر الكشك قريبًا!';

  @override
  String bookingErrorPrefix(String message) {
    return 'خطأ في الحجز: $message';
  }

  @override
  String get bookingConfirmedTitle => 'تم تأكيد الحجز!';

  @override
  String bookingReservedBody(String title) {
    return 'تم حجز مكانك في \"$title\"!';
  }

  @override
  String bookingPaidSuccess(String amount) {
    return 'تم دفع $amount بنجاح.';
  }

  @override
  String get bookingViewMyBookings => 'عرض حجوزاتي';

  @override
  String get bookingBackHome => 'العودة إلى الرئيسية';

  @override
  String get bookingOrderSummary => 'ملخص الطلب';

  @override
  String get bookingGuests => 'الضيوف';

  @override
  String get bookingPaymentMethod => 'طريقة الدفع';

  @override
  String get bookingPayCardTitle => 'بطاقة ائتمان / خصم';

  @override
  String get bookingPayCardSub => 'فيزا، ماستركارد، ميزة';

  @override
  String get bookingPayWalletTitle => 'محفظة إلكترونية';

  @override
  String get bookingPayWalletSub => 'فودافون كاش، أورنج، اتصالات';

  @override
  String get bookingPayApplePayTitle => 'Apple Pay';

  @override
  String get bookingPayApplePaySub => 'iOS فقط • قريبًا';

  @override
  String get bookingPayKioskTitle => 'فوري / كشك';

  @override
  String get bookingPayKioskSub => 'ادفع في أكثر من 172,000 منفذ فوري';

  @override
  String get bookingWalletPhoneLabel => 'رقم هاتف المحفظة';

  @override
  String get bookingSecurityNote =>
      'تتم معالجة المدفوعات بأمان عبر Paymob. لا يتم تخزين بيانات بطاقتك محليًا أبدًا.';

  @override
  String get bookingBecauseBooked => 'لأنك حجزت هذه، قد تستمتع بـ';

  @override
  String get bookingProcessing => 'جارٍ معالجة الدفع...';

  @override
  String get bookingTotal => 'الإجمالي';

  @override
  String bookingChargedNote(String amount) {
    return 'يُحصَّل كـ $amount ج.م عبر Paymob';
  }

  @override
  String get bookingPaySecurely => 'ادفع بأمان';

  @override
  String get tourDetailReport => 'الإبلاغ عن الجولة';

  @override
  String get tourDetailNew => 'جديدة';

  @override
  String get tourDetailDateTime => 'التاريخ والوقت';

  @override
  String tourDetailPeople(int count) {
    return '$count أشخاص';
  }

  @override
  String get tourDetailLocation => 'الموقع';

  @override
  String get tourDetailAbout => 'عن هذه الجولة';

  @override
  String get tourDetailDestinations => 'الوجهات';

  @override
  String get tourDetailMeetupRoute => 'موقع اللقاء والمسار';

  @override
  String get tourDetailTapExpand => 'اضغط للتكبير';

  @override
  String get tourDetailSchedule => 'الجدول';

  @override
  String get tourDetailGallery => 'المعرض';

  @override
  String get tourDetailYourGuide => 'مرشدك';

  @override
  String get tourDetailYouMightEnjoy => 'قد يعجبك أيضًا';

  @override
  String get tourDetailYourTour => 'هذه جولتك';

  @override
  String get tourDetailBookNow => 'احجز الآن';

  @override
  String get tourDetailOneTime => 'هذه جولة لمرة واحدة.';

  @override
  String get tourDetailGuideNotFound => 'لم يتم العثور على المرشد';

  @override
  String tourDetailGuideRating(String rating, int count) {
    return '$rating ($count تقييمات)';
  }

  @override
  String get tourDetailReviews => 'التقييمات';

  @override
  String get tourDetailWriteReview => 'اكتب تقييمًا';

  @override
  String get tourDetailReviewsError => 'خطأ في تحميل التقييمات';

  @override
  String get tourDetailNoReviews => 'لا توجد تقييمات بعد. كن أول من يقيّم!';

  @override
  String get tourDetailShowMore => 'عرض المزيد من التقييمات';

  @override
  String get tourDetailAnonymous => 'مجهول';

  @override
  String get tourDetailEditReview => 'تعديل التقييم';

  @override
  String get tourDetailDeleteReview => 'حذف التقييم';

  @override
  String get tourDetailReportReview => 'الإبلاغ عن التقييم';

  @override
  String get tourDetailUpdateHint => 'حدّث تجربتك...';

  @override
  String get tourDetailUpdate => 'تحديث';

  @override
  String get tourDetailDeleteReviewBody =>
      'هل أنت متأكد أنك تريد حذف تقييمك؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get tourDetailShareHint => 'شارك تجربتك...';

  @override
  String get tourDetailSubmit => 'إرسال';

  @override
  String get commonLoadMore => 'تحميل المزيد';

  @override
  String get bookingStatusConfirmed => 'مؤكَّد';

  @override
  String get bookingStatusCancelled => 'ملغى';

  @override
  String get bookingStatusPending => 'قيد الانتظار';

  @override
  String get bookingStatusCompleted => 'مكتمل';

  @override
  String get bookingStatusCheckedIn => 'تم تسجيل الدخول';

  @override
  String get bookingStatusPartial => 'تم تسجيل الدخول جزئيًا';

  @override
  String get bookingHistTitle => 'حجوزاتي';

  @override
  String get bookingHistLoginRequired => 'يرجى تسجيل الدخول';

  @override
  String get bookingHistUpcoming => 'القادمة';

  @override
  String get bookingHistPast => 'السابقة';

  @override
  String get bookingHistLoadError =>
      'تعذّر تحميل الحجوزات.\nتحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get bookingHistNoUpcoming => 'لا توجد جولات قادمة';

  @override
  String get bookingHistNoPast => 'لا توجد جولات سابقة';

  @override
  String get bookingHistEmptyHint => 'استكشف الجولات واحجز مغامرتك القادمة!';

  @override
  String get bookingHistTbd => 'يُحدَّد لاحقًا';

  @override
  String bookingHistCountdownDHM(int days, int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0 $hoursس $minutesد';
  }

  @override
  String bookingHistCountdownHMS(int hours, int minutes, int seconds) {
    return '$hoursس $minutesد $secondsث';
  }

  @override
  String bookingHistCountdownMS(int minutes, int seconds) {
    return '$minutesد $secondsث';
  }

  @override
  String bookingHistStartsIn(String time) {
    return 'تبدأ خلال $time';
  }

  @override
  String get bookingHistCancelBody => 'هل أنت متأكد أنك تريد إلغاء هذا الحجز؟';

  @override
  String get bookingHistYesCancel => 'نعم، إلغاء';

  @override
  String get bookingHistCancelled => 'تم إلغاء الحجز';

  @override
  String get bookingHistReviewSubmitted => 'تم إرسال التقييم!';

  @override
  String get bookingHistNoPhone => 'لا يوجد رقم هاتف مسجّل';

  @override
  String get bookingHistNoEmail => 'لا يوجد بريد إلكتروني مسجّل';

  @override
  String get bookingHistCantOpenPhone => 'تعذّر فتح تطبيق الهاتف';

  @override
  String get bookingHistCantOpenEmail => 'تعذّر فتح تطبيق البريد';

  @override
  String get bookingHistLeaveReview => 'اترك تقييمًا';

  @override
  String get bookingHistSubmitReview => 'إرسال التقييم';

  @override
  String get bookingHistViewQr => 'عرض تذكرة QR';

  @override
  String bookingHistBookingId(String id) {
    return 'رقم الحجز: $id';
  }

  @override
  String get bookingHistShowGuide => 'أظهر هذا لمرشدك عند الوصول';

  @override
  String get bookingHistViewMeeting => 'عرض نقطة اللقاء';

  @override
  String get bookingHistOpensMap => 'يفتح في تبويب الخريطة';

  @override
  String get bookingHistGuide => 'المرشد';

  @override
  String get bookingHistTrackGuide => 'تتبّع المرشد مباشرة';

  @override
  String get bookingHistTrackGuideSub => 'شاهد موقع مرشدك في الوقت الفعلي';

  @override
  String get bookingHistTotalPaid => 'الإجمالي المدفوع';

  @override
  String get bookingHistPaymentRef => 'مرجع الدفع';

  @override
  String get bookingHistAddCalendar => 'أضف إلى التقويم';

  @override
  String get bookingHistShareTicket => 'مشاركة التذكرة';

  @override
  String get bookingHistCallGuide => 'اتصل بالمرشد';

  @override
  String get bookingHistEmailGuide => 'راسل المرشد';

  @override
  String get bookingHistRebook => 'أعد حجز هذه الجولة';

  @override
  String get bookingHistNewGuide => 'مرشد جديد';

  @override
  String get bookingHistWeatherDay => 'الطقس يوم الجولة';

  @override
  String bookingHistLiveLocation(String name) {
    return '$name – الموقع المباشر';
  }

  @override
  String get bookingHistWaitingLocation => 'في انتظار مشاركة المرشد لموقعه…';

  @override
  String bookingHistCalTitle(String title) {
    return 'تائه في مصر: $title';
  }

  @override
  String bookingHistCalDesc(String location, String id) {
    return 'نقطة اللقاء: $location\nرقم الحجز: $id';
  }

  @override
  String bookingHistShareText(
    String title,
    String date,
    String location,
    int tickets,
    String ref,
  ) {
    return '🏺 تائه في مصر – تذكرة جولة\n\nالجولة: $title\nالتاريخ: $date\nنقطة اللقاء: $location\nالتذاكر: $tickets\nمرجع الحجز: $ref\n\nنراك هناك!';
  }

  @override
  String get cameraLens => 'العدسة';

  @override
  String get cameraTranslation => 'الترجمة';

  @override
  String get cameraTranslationResult => 'نتيجة الترجمة';

  @override
  String get cameraNoLandmark => 'تعذّر التعرّف على أي معلم';

  @override
  String cameraNotInDb(String label) {
    return 'وجدنا \"$label\" لكنه غير موجود في قاعدة بياناتنا';
  }

  @override
  String get cameraConfigError => 'خطأ في الإعداد';

  @override
  String get cameraErrorTitle => 'خطأ';

  @override
  String get cameraLandmarkIdentified => 'تم التعرّف على المعلم';

  @override
  String cameraTapForecast(String condition) {
    return '$condition · اضغط لعرض التوقعات';
  }

  @override
  String get cameraStatusCapturing => 'جارٍ الالتقاط...';

  @override
  String get cameraStatusIdentifying => 'جارٍ التعرّف على المعلم...';

  @override
  String get cameraStatusTranslating => 'جارٍ الترجمة...';

  @override
  String cameraStatusDownloadingModel(String lang) {
    return 'جارٍ تنزيل حزمة اللغة $lang (قد يستغرق هذا دقيقة)...';
  }

  @override
  String get cameraErrNoCameras => 'لا توجد كاميرا متاحة على هذا الجهاز';

  @override
  String get cameraErrInitFailed =>
      'تعذّر تشغيل الكاميرا. يرجى إعادة تشغيل التطبيق.';

  @override
  String get cameraErrTranslationModels =>
      'تعذّر تنزيل حزم الترجمة. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get cameraErrLanguageModel =>
      'تعذّر تنزيل حزمة اللغة. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get cameraErrNoText => 'لم يُعثر على نص في الصورة المحددة.';

  @override
  String get cameraReadMore => 'اقرأ المزيد';

  @override
  String get cameraReadLess => 'عرض أقل';

  @override
  String get cameraTellStory => 'احكِ لي قصة';

  @override
  String get cameraConsulting => 'أستشير التاريخ...';

  @override
  String get cameraListen => 'استمع';

  @override
  String get cameraPause => 'إيقاف مؤقت';

  @override
  String get cameraResume => 'استئناف';

  @override
  String get cameraGenerating => 'جارٍ الإنشاء...';

  @override
  String get cameraReplay => 'إعادة من البداية';

  @override
  String get cameraAudioGenFailed => 'تعذّر إنشاء الصوت. حاول مرة أخرى.';

  @override
  String get cameraAudioPlayFailed => 'فشل تشغيل الصوت. حاول مرة أخرى.';

  @override
  String get cameraShowOnMap => 'عرض على الخريطة';

  @override
  String get cameraDone => 'تم';

  @override
  String get cameraNearby => 'قد يعجبك أيضًا في الجوار';

  @override
  String get sphinxRiddleTitle => 'لغز أبو الهول 🦁';

  @override
  String get sphinxPassTitle => 'يمكنك العبور 🦁';

  @override
  String get sphinxFailTitle => 'خطأ أيها الفاني 🌪️';

  @override
  String get sphinxRiddleBody =>
      '\"ما الذي يمشي على أربع في الصباح، واثنتين عند الظهيرة، وثلاث في المساء؟\"';

  @override
  String get sphinxPassBody =>
      'حكمتك تضاهي القدماء. يسمح لك أبو الهول بمواصلة رحلتك.';

  @override
  String get sphinxFailBody => 'ستبتلع رمال الزمن جهلك. عُد عندما تتعلّم.';

  @override
  String get sphinxAnswerAnimal => 'حيوان';

  @override
  String get sphinxAnswerHuman => 'إنسان';

  @override
  String get tripPlannerTitle => 'مخطط الرحلة';

  @override
  String get tripPlannerStart => 'ابدأ الرحلة';

  @override
  String get tripPlannerOptimising => 'جارٍ التحسين...';

  @override
  String get tripPlannerSearchHint => 'ابحث عن أماكن لإضافتها…';

  @override
  String tripPlannerStopsInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطة — سيتم تحسين المسار حسب أقصر مسافة',
      many: '$count محطة — سيتم تحسين المسار حسب أقصر مسافة',
      few: '$count محطات — سيتم تحسين المسار حسب أقصر مسافة',
      two: 'محطتان — سيتم تحسين المسار حسب أقصر مسافة',
      one: 'محطة واحدة — سيتم تحسين المسار حسب أقصر مسافة',
    );
    return '$_temp0';
  }

  @override
  String get tripPlannerEmptyTitle => 'خطّط ليومك في مصر';

  @override
  String get tripPlannerEmptySub =>
      'ابحث بالأعلى أو اختر من الاقتراحات بالأسفل';

  @override
  String get tripPlannerSuggested => 'مقترح لك';

  @override
  String get tripPlannerAdd => 'إضافة';

  @override
  String get placeDetailLoginToSave => 'يجب تسجيل الدخول لحفظ الأماكن.';

  @override
  String placeDetailMetersAway(int meters) {
    return 'على بُعد $meters م';
  }

  @override
  String placeDetailKmAway(String km) {
    return 'على بُعد $km كم';
  }

  @override
  String placeDetailTaxiFare(int low, int high) {
    return '~$low–$high ج.م بالتاكسي';
  }

  @override
  String get placeDetailOpenNow => 'مفتوح الآن';

  @override
  String get placeDetailClosed => 'مغلق';

  @override
  String get placeDetailClose => 'إغلاق';

  @override
  String get placeDetailDirections => 'الاتجاهات';

  @override
  String get placeDetailShare => 'مشاركة';

  @override
  String get placeDetailSaved => 'محفوظ';

  @override
  String get placeDetailAbout => 'نبذة';

  @override
  String get placeDetailDefaultDesc =>
      'اكتشف عجائب مصر القديمة وكنوزها الخفية. يقدّم هذا الموقع لمحة فريدة عن التاريخ والثقافة الغنية للمنطقة.';

  @override
  String placeDetailEntryFee(String price) {
    return '$price ج.م رسوم الدخول';
  }

  @override
  String get placeDetailReviews => 'ماذا يقول المسافرون';

  @override
  String placeDetailPostedHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نشر $count مسافر من هنا',
      many: 'نشر $count مسافرًا من هنا',
      few: 'نشر $count مسافرين من هنا',
      two: 'نشر مسافران من هنا',
      one: 'نشر مسافر واحد من هنا',
    );
    return '$_temp0';
  }

  @override
  String get placeDetailSeePosts => 'عرض المنشورات';

  @override
  String get placeDetailSimilar => 'أماكن مشابهة';

  @override
  String get placeDetailCrowdQuiet => 'هادئ الآن';

  @override
  String get placeDetailCrowdModerate => 'ازدحام متوسط';

  @override
  String get placeDetailCrowdBusy => 'مزدحم جدًا';

  @override
  String placeDetailPostsFrom(String name) {
    return 'منشورات من $name';
  }

  @override
  String get placeDetailNoPosts =>
      'لا توجد منشورات من هذا المكان بعد.\nكن أول من يشارك!';

  @override
  String get mapDiscovering => 'نكتشف مصر...';

  @override
  String get mapLoadingNearby => 'جارٍ تحميل الأماكن القريبة منك';

  @override
  String get mapArrivedTitle => 'لقد وصلت!';

  @override
  String mapArrivedBody(String name) {
    return 'لقد وصلت إلى $name';
  }

  @override
  String get mapFabTrip => 'رحلة';

  @override
  String get mapFabNearMe => 'بالقرب مني';

  @override
  String get mapFabSaved => 'المحفوظة';

  @override
  String mapStopOf(int current, int total) {
    return 'المحطة $current من $total';
  }

  @override
  String get mapNextStop => 'المحطة التالية';

  @override
  String get mapTripDone => 'تم! 🎉';

  @override
  String get mapBackToTour => 'العودة إلى الجولة';

  @override
  String get mapFindingRoute => 'جارٍ إيجاد المسار...';

  @override
  String mapEtaTotal(String distance, String duration) {
    return '$distance · $duration إجمالاً';
  }

  @override
  String mapStepProgress(int current, int total) {
    return 'الخطوة $current/$total';
  }

  @override
  String get mapAiPick => 'اختيار الذكاء الاصطناعي';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get mapSearchHint => 'ابحث عن أماكن...';

  @override
  String get mapNoPlacesFound => 'لم يتم العثور على أماكن';

  @override
  String get mapModeDrive => 'قيادة';

  @override
  String get mapModeWalk => 'سيرًا';

  @override
  String get mapModeTransit => 'مواصلات';

  @override
  String mapStepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خطوة',
      many: '$count خطوة',
      few: '$count خطوات',
      two: 'خطوتان',
      one: 'خطوة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get mapStartNavigation => 'بدء التنقّل';

  @override
  String get mapRouteSteps => 'خطوات المسار';

  @override
  String get mapArriveDestination => 'الوصول إلى الوجهة';

  @override
  String get mapCurseReleased => 'أُطلِقت اللعنة';

  @override
  String get mapFilterByCategory => 'التصفية حسب الفئة';

  @override
  String get mapZoomFilterOn => 'فلتر التكبير مفعّل';

  @override
  String get mapShowingAll => 'عرض الكل';

  @override
  String mapPlacesCount(int visible, int total) {
    return '$visible/$total مكان';
  }

  @override
  String mapCatPlacesZoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان • كبّر لرؤية المزيد',
      many: '$count مكانًا • كبّر لرؤية المزيد',
      few: '$count أماكن • كبّر لرؤية المزيد',
      two: 'مكانان • كبّر لرؤية المزيد',
      one: 'مكان واحد • كبّر لرؤية المزيد',
    );
    return '$_temp0';
  }

  @override
  String mapCatSavedPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان محفوظ',
      many: '$count مكانًا محفوظًا',
      few: '$count أماكن محفوظة',
      two: 'مكانان محفوظان',
      one: 'مكان محفوظ واحد',
    );
    return '$_temp0';
  }

  @override
  String mapCatPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان',
      many: '$count مكانًا',
      few: '$count أماكن',
      two: 'مكانان',
      one: 'مكان واحد',
    );
    return '$_temp0';
  }

  @override
  String get mapCatAll => 'الكل';

  @override
  String get mapCatFavorites => 'المفضلة';

  @override
  String get mapCatOpenNow => 'مفتوح الآن';

  @override
  String get mapCatTourism => 'السياحة';

  @override
  String get mapCatHistorical => 'تاريخي';

  @override
  String get mapCatMuseums => 'المتاحف';

  @override
  String get mapCatHotels => 'الفنادق';

  @override
  String get mapCatReligious => 'ديني';

  @override
  String get mapCatFood => 'الطعام والمطاعم';

  @override
  String get mapCatNature => 'الطبيعة';

  @override
  String get mapCatEntertainment => 'الترفيه';

  @override
  String get mapCatShopping => 'التسوق';

  @override
  String get accountMenuMyAccount => 'حسابي';

  @override
  String get accountMenuGuideDashboard => 'لوحة المرشد';

  @override
  String get accountMenuAdminDashboard => 'لوحة المسؤول';

  @override
  String get accountMenuNotifications => 'مركز الإشعارات';

  @override
  String get accountMenuSignOut => 'تسجيل الخروج';

  @override
  String get homeCatHotels => 'الفنادق';

  @override
  String get homeCatMuseums => 'المتاحف';

  @override
  String get homeCatRestaurants => 'المطاعم';

  @override
  String get homeCatMosques => 'المساجد';

  @override
  String get homeCatBeaches => 'الشواطئ';

  @override
  String get homeCatAdventure => 'مغامرة';

  @override
  String get catSort => 'ترتيب';

  @override
  String get catSortNameAsc => 'الاسم (أ → ي)';

  @override
  String get catSortNameDesc => 'الاسم (ي → أ)';

  @override
  String get catSortTopRated => 'الأعلى تقييمًا';

  @override
  String get catSortMostReviews => 'الأكثر تقييمات';

  @override
  String get catSortNearest => 'الأقرب';

  @override
  String get catSomethingWrong => 'حدث خطأ ما.';

  @override
  String get catNoRating => 'غير متاح';

  @override
  String catReviewsK(String count) {
    return '$count ألف تقييم';
  }

  @override
  String catReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييم',
      many: '$count تقييمًا',
      few: '$count تقييمات',
      two: 'تقييمان',
      one: 'تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String get eventCatAll => 'الكل';

  @override
  String get eventCatCultural => 'ثقافة وتراث';

  @override
  String get eventCatConcert => 'حفلات وموسيقى';

  @override
  String get eventCatTheatre => 'مسرح وعروض';

  @override
  String get eventCatFestival => 'مهرجانات';

  @override
  String get eventCatArt => 'فنون ومعارض';

  @override
  String get eventCatAdventure => 'مغامرات وأنشطة خارجية';

  @override
  String get eventCatFood => 'طعام وأسواق';

  @override
  String get eventCatCruise => 'رحلات بحرية وعشاء';

  @override
  String get eventsLoadError =>
      'تعذّر تحميل الفعاليات.\nتحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get eventsEmptyTitle => 'لا توجد فعاليات حاليًا';

  @override
  String get eventsEmptySubtitle =>
      'عُد قريبًا لمتابعة الفعاليات القادمة في مصر.';

  @override
  String get eventTailoredPick => 'اختيار مخصص لك';

  @override
  String get eventDateTime => 'التاريخ والوقت';

  @override
  String get eventLocation => 'الموقع';

  @override
  String eventCairoTime(String time) {
    return '$time (بتوقيت القاهرة)';
  }

  @override
  String get eventLocationEgypt => 'مصر';

  @override
  String get eventMapButton => 'الخريطة';

  @override
  String get eventAbout => 'عن هذه الفعالية';

  @override
  String get eventDefaultDescription =>
      'انضم إلينا في تجربة لا تُنسى! تجمع هذه الفعالية أفضل ما في الثقافة والترفيه والمجتمع في مصر. احجز تذاكرك الآن وكن جزءًا من شيء مميز.';

  @override
  String get eventShareThis => 'شارك هذه الفعالية';

  @override
  String eventViewOn(String source) {
    return 'العرض على $source';
  }

  @override
  String eventPostPrompt(String title) {
    return 'هل سيذهب أحد إلى $title؟ ✨';
  }

  @override
  String get eventPostToCommunity => 'انشر في المجتمع';

  @override
  String get eventPrice => 'السعر';

  @override
  String get eventSeeListing => 'عرض التفاصيل';

  @override
  String get eventTicketsUnavailable =>
      'التذاكر غير متوفرة عبر الإنترنت لهذه الفعالية.';

  @override
  String get eventGetTickets => 'احصل على التذاكر';

  @override
  String get eventRsvpNow => 'سجّل الآن';

  @override
  String get eventReviewerFallback => 'مستكشف';

  @override
  String get searchHint => 'ابحث عن المعالم والجولات والوجهات…';

  @override
  String get searchTabAll => 'الكل';

  @override
  String get searchTabPlaces => 'الأماكن';

  @override
  String get searchTabTours => 'الجولات';

  @override
  String get searchPersonalised => 'مخصّص حسب ذوقك';

  @override
  String get searchBadgeLandmark => 'معلم';

  @override
  String get searchBadgeTour => 'جولة';

  @override
  String get searchViewOnMap => 'العرض على الخريطة';

  @override
  String get searchEmptyTitle => 'ابحث عن معلم أو جولة';

  @override
  String get searchEmptyHint => 'جرّب «الأهرامات» أو «الأقصر» أو «متحف»…';

  @override
  String searchNoResultsFor(String query) {
    return 'لا توجد نتائج لـ «$query»';
  }

  @override
  String get searchPlacesError => 'تعذّر تحميل الأماكن.\nتحقق من اتصالك.';

  @override
  String get searchToursError => 'تعذّر تحميل الجولات.\nتحقق من اتصالك.';

  @override
  String get guidesSearchToursHint => 'ابحث عن الجولات...';

  @override
  String get guidesSearchGuidesHint => 'ابحث عن المرشدين...';

  @override
  String get guidesTabTours => 'الجولات';

  @override
  String get guidesTabGuides => 'المرشدون';

  @override
  String get guidesEmptyGuidesTitle => 'لا يوجد مرشدون';

  @override
  String get guidesEmptyHint => 'حاول تعديل بحثك أو عوامل التصفية.';

  @override
  String get guidesErrorTours => 'تعذّر تحميل الجولات.';

  @override
  String get guidesErrorGuides => 'تعذّر تحميل المرشدين.';

  @override
  String get guidesNoneAvailable => 'لا يوجد مرشدون متاحون.';

  @override
  String get communityFilterAll => 'الكل';

  @override
  String get communityFilterTips => '💡 نصائح';

  @override
  String get soloInterestShopping => 'التسوق';

  @override
  String get soloInterestNightlife => 'الحياة الليلية';

  @override
  String get soloInterestMonuments => 'الآثار';

  @override
  String get soloInterestMuseums => 'المتاحف';

  @override
  String get soloInterestNature => 'الطبيعة والحدائق';

  @override
  String get soloInterestBeaches => 'الشواطئ';

  @override
  String get soloInterestCulture => 'الثقافة والتقاليد';

  @override
  String get soloInterestEntertainment => 'الترفيه';

  @override
  String get soloInterestAdventure => 'أنشطة المغامرة';

  @override
  String get soloInterestLocal => 'التجارب المحلية';

  @override
  String get soloAreaCairo => 'القاهرة';

  @override
  String get soloAreaLuxor => 'الأقصر';

  @override
  String get soloAreaAswan => 'أسوان';

  @override
  String get soloAreaAlexandria => 'الإسكندرية';

  @override
  String get soloAreaHurghada => 'الغردقة';

  @override
  String get soloAreaSharm => 'شرم الشيخ';

  @override
  String get soloAreaDahab => 'دهب';

  @override
  String get soloAreaSiwa => 'سيوة';

  @override
  String get soloAreaFayoum => 'الفيوم';

  @override
  String get soloAreaNorthCoast => 'الساحل الشمالي';

  @override
  String soloPlanStopsProgress(int done, int total) {
    return '$done/$total محطات';
  }

  @override
  String get mapEasterEggCurse => 'تجرؤ على إيقاظ الفرعون... اللعنة حلّت عليك.';

  @override
  String get mapEasterEggSandstorm => 'الصحراء تبتلع كل شيء.';

  @override
  String profilePlacesVisited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان مُزار',
      many: '$count مكانًا مُزارًا',
      few: '$count أماكن مُزارة',
      two: 'مكانان مُزاران',
      one: 'مكان واحد مُزار',
      zero: 'لا أماكن مُزارة',
    );
    return '$_temp0';
  }

  @override
  String get accountMyProfile => 'ملفّي الشخصي';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsCustomize => 'خصّص إشعاراتك!';

  @override
  String get notificationsPrevious => 'سابقًا';

  @override
  String get notificationsEmptyTitle => 'لا إشعارات بعد';

  @override
  String get notificationsEmptyBody =>
      'ستظهر إشعاراتك هنا بمجرد\nأن تبدأ بتلقّيها.';

  @override
  String get notificationsSettings => 'إعدادات الإشعارات';

  @override
  String get commonDone => 'تم';

  @override
  String get notifPrefTitle => 'تفضيلات الإشعارات';

  @override
  String get notifPrefSubtitle => 'اختر ما تريد أن يصلك إشعار بشأنه.';

  @override
  String get notifPrefAll => 'كل الإشعارات';

  @override
  String get notifPrefAllSub => 'المفتاح الرئيسي لجميع التنبيهات';

  @override
  String get notifPrefBookings => 'الحجوزات والجولات';

  @override
  String get notifPrefBookingsSub => 'التأكيدات والإلغاءات والتحديثات';

  @override
  String get notifPrefCommunity => 'المجتمع';

  @override
  String get notifPrefCommunitySub => 'الإعجابات والتعليقات والإشارات والردود';

  @override
  String get notifPrefReviews => 'التقييمات';

  @override
  String get notifPrefReviewsSub => 'عندما يقيّم أحدهم جولتك';

  @override
  String get notifPrefGuide => 'تحديثات المرشد';

  @override
  String get notifPrefGuideSub => 'نتائج الطلب وشهادات اللغة';

  @override
  String get notifPrefDiscovery => 'اكتشاف بالذكاء الاصطناعي';

  @override
  String get notifPrefDiscoverySub => 'حقيقة يومية ‘هل تعلم؟’ عن مصر';

  @override
  String get badgeNoviceExplorer => 'مستكشف مبتدئ';

  @override
  String get badgeNoviceExplorerDesc => 'اكتشفت أول معلم لك.';

  @override
  String get badgeTourist => 'سائح';

  @override
  String get badgeTouristDesc => 'زرت 3 معالم.';

  @override
  String get badgeTombRaider => 'مقتحم المقابر';

  @override
  String get badgeTombRaiderDesc => 'زرت 5 معالم.';

  @override
  String get badgeHistorian => 'مؤرّخ';

  @override
  String get badgeHistorianDesc => 'زرت 10 معالم.';

  @override
  String get badgePharaoh => 'فرعون';

  @override
  String get badgePharaohDesc => 'زرت 20 معلمًا.';

  @override
  String get badgeImhotep => 'كبير الكهنة إيمحوتب';

  @override
  String get badgeImhotepDesc => 'اكتشفت خزنة المهندس الخفية.';

  @override
  String get badgeDeveloperPharaoh => 'فرعون المطوّرين';

  @override
  String get badgeDeveloperPharaohDesc => 'اكتشفت مقبرة المطوّر الخفية.';

  @override
  String get badgeRiddleSolver => 'حلّال الألغاز';

  @override
  String get badgeRiddleSolverDesc => 'أجبت على لغز أبو الهول.';
}
