import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'Lost in Egypt'**
  String get appTitle;

  /// Bottom navigation tab label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation tab label for the Community tab.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// Bottom navigation tab label for the Map tab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom navigation tab label for the Camera tab.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get navCamera;

  /// Bottom navigation tab label for the More tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Generic Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic Reset button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Title of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings tile to choose the app language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// Settings tile to choose the preferred display currency.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get settingsDisplayCurrency;

  /// Settings tile to toggle light/dark theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Name of the English language, shown in the language toggle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the Arabic language, shown in the language toggle (endonym).
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Debug-only settings tile that clears earned badges.
  ///
  /// In en, this message translates to:
  /// **'Reset Badges (Debug)'**
  String get settingsResetBadges;

  /// Confirmation snackbar after badges are reset.
  ///
  /// In en, this message translates to:
  /// **'Badges successfully reset!'**
  String get settingsBadgesResetSuccess;

  /// Debug-only settings tile that clears recommendation signals.
  ///
  /// In en, this message translates to:
  /// **'Reset Taste Signals (Debug)'**
  String get settingsResetTasteSignals;

  /// Title of the confirmation dialog for resetting taste signals.
  ///
  /// In en, this message translates to:
  /// **'Reset Taste Signals?'**
  String get settingsResetTasteSignalsTitle;

  /// Body text of the reset-taste-signals confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This clears every personalisation signal recorded for you — saved likes, dismissals, quiz answers, visit history. Recommendations will reset to defaults until you interact again.'**
  String get settingsResetTasteSignalsBody;

  /// Confirmation snackbar after taste signals are reset.
  ///
  /// In en, this message translates to:
  /// **'Taste signals reset.'**
  String get settingsTasteSignalsReset;

  /// Error snackbar when resetting taste signals fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reset signals. Try again.'**
  String get settingsTasteSignalsResetError;

  /// App version label at the bottom of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
