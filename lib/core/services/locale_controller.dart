import 'package:flutter/material.dart';

/// App-wide locale controller.
///
/// Mirrors the pattern of [ThemeController] and [CurrencyController] — a static
/// singleton [ValueNotifier] that [MaterialApp] listens to. Changing
/// [locale.value] rebuilds the whole app (and flips text direction to RTL for
/// Arabic automatically, since Flutter derives [Directionality] from the active
/// locale).
///
/// Firestore stores the preference as the human-readable string
/// `"English"` | `"Arabic"` on `users/{uid}.language`; [setLanguage] maps that
/// to a [Locale]. [AuthGate] initialises it from the signed-in user; the
/// Settings screen calls [setLanguage] when the user toggles language.
class LocaleController {
  LocaleController._();

  /// Currently active locale. Defaults to English.
  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('en'));

  /// Set the locale from the Firestore `language` string
  /// (`"English"` | `"Arabic"`). Unknown values fall back to English.
  static void setLanguage(String? language) {
    locale.value =
        (language == 'Arabic') ? const Locale('ar') : const Locale('en');
  }

  /// Set the locale directly from an ISO language code (`"en"` | `"ar"`).
  static void setLocaleCode(String code) {
    locale.value = (code == 'ar') ? const Locale('ar') : const Locale('en');
  }

  /// `true` when the active locale is right-to-left (Arabic).
  static bool get isRtl => locale.value.languageCode == 'ar';

  /// The active ISO language code (`"en"` | `"ar"`). Passed to AI Cloud
  /// Functions (story / trip / TTS) so generated content matches the UI language.
  static String get localeCode => locale.value.languageCode;

  /// The Firestore `language` string for the active locale.
  static String get languageLabel =>
      locale.value.languageCode == 'ar' ? 'Arabic' : 'English';
}
