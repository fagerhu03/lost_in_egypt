// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lost in Egypt';

  @override
  String get navHome => 'Home';

  @override
  String get navCommunity => 'Community';

  @override
  String get navMap => 'Map';

  @override
  String get navCamera => 'Camera';

  @override
  String get navMore => 'More';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonReset => 'Reset';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsDisplayCurrency => 'Display Currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsResetBadges => 'Reset Badges (Debug)';

  @override
  String get settingsBadgesResetSuccess => 'Badges successfully reset!';

  @override
  String get settingsResetTasteSignals => 'Reset Taste Signals (Debug)';

  @override
  String get settingsResetTasteSignalsTitle => 'Reset Taste Signals?';

  @override
  String get settingsResetTasteSignalsBody =>
      'This clears every personalisation signal recorded for you — saved likes, dismissals, quiz answers, visit history. Recommendations will reset to defaults until you interact again.';

  @override
  String get settingsTasteSignalsReset => 'Taste signals reset.';

  @override
  String get settingsTasteSignalsResetError =>
      'Couldn\'t reset signals. Try again.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }
}
