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
}
