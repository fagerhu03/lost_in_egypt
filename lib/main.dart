import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paymob/flutter_paymob.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/services/locale_controller.dart';
import 'package:lost_in_egypt/theme/app_theme.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/di/service_locator.dart' as di;

import 'feature/home/tabs/navigator/home_wrapper.dart';
import 'firebase_options.dart';
import 'feature/auth/presentation/login/presentation/login_screen.dart';
import 'feature/auth/presentation/login/bloc/login_bloc.dart';
import 'feature/auth/presentation/sign_up/presentation/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';
import 'feature/home/notification/domain/services/local_notification_service.dart';
import 'feature/home/tabs/map/data/places_api_service.dart';
import 'feature/home/tabs/map/data/datasources/map_focus_service.dart';

// ✅ add these imports for saved theme
import 'feature/tours/presentation/pages/map_picker_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/auth_gate.dart';

/// Must be a top-level function for FCM background processing.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are displayed natively by FCM — no extra work needed.
}

/// Routes a tapped push notification to the right in-app destination. Currently
/// handles the daily-discovery push (focus the landmark on the map); other
/// types are deep-linked from the in-app notification centre instead. Safe to
/// call once HomeWrapper is mounted — focus drives the map via ValueNotifiers,
/// no BuildContext needed.
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  if (data['type'] == 'daily_discovery') {
    final name = data['landmark'] ?? '';
    final lat = double.tryParse(data['lat'] ?? '');
    final lng = double.tryParse(data['lng'] ?? '');
    if (name.isNotEmpty && lat != null && lng != null) {
      MapFocusService.instance.focusDiscovery(name, lat, lng);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("WARNING: .env file not found, Maps API might fail if not injected via CLI.");
  }

  // Dev kill-switch — when `PLACES_API_DISABLED=true` is in `.env`, every
  // PlacesApiService entry point short-circuits and MapRepository falls
  // through to the bundled 500-landmark asset. Lets us test the rest of the
  // app without burning Places API quota.
  PlacesApiService.disabled =
      (dotenv.env['PLACES_API_DISABLED'] ?? '').toLowerCase() == 'true';
  final rawKillSwitch = dotenv.env['PLACES_API_DISABLED'];
  if (PlacesApiService.disabled) {
    debugPrint('🛑 PLACES API KILL-SWITCH IS ON '
        '(PLACES_API_DISABLED=true). All Places API calls will be blocked '
        'this session. Remove the flag from .env to re-enable.');
  } else {
    // Positive confirmation so a stale bundled .env (assets are baked in at
    // build time — a hot reload / reinstalling the same APK keeps the old
    // value) is obvious from the logs. Echoes the raw parsed value too.
    debugPrint('✅ PLACES API ENABLED '
        '(PLACES_API_DISABLED=${rawKillSwitch ?? '<unset>'}). Note: a fresh '
        'API call only fires when memory + disk + Firestore caches all miss — '
        '"0 API calls!" in the log means cached Places data is being served.');
  }

  try {
    // Check if empty, but catch duplicate-app just in case the native
    // side already initialized it before Flutter's apps list updated.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized implicitly.');
    } else {
      debugPrint('Firebase init error: $e');
    }
  }

  await di.init();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ⭐ FORCE LATEST MAP RENDERER
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }
  
  try {
    tz.initializeTimeZones();
    await LocalNotificationService().init();
  } catch (e) {
    debugPrint("LocalNotifications Initialization Error: $e");
  }

  // intl date-symbol data for Arabic so DateFormat(..., 'ar') renders Arabic
  // month/weekday names (en_US is bundled by default). Used by the event
  // detail screen's localized dates.
  try {
    await initializeDateFormatting('ar');
  } catch (e) {
    debugPrint("Date formatting init error: $e");
  }

  // Arabic relative-time strings for the `timeago` package (notification list).
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // ── FCM setup ───────────────────────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS: show notifications while app is in foreground
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Foreground: show via flutter_local_notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      LocalNotificationService().showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Lost in Egypt',
        body: message.notification!.body ?? '',
        payload: message.data['type'],
      );
    }
  });

  // Background tap (app alive in background): HomeWrapper is already mounted, so
  // route straight away.
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

  // Cold-start tap (app was terminated): HomeWrapper isn't mounted yet, so queue
  // the action — it's drained on HomeWrapper's first frame once the tab/map
  // infrastructure is live.
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    MapFocusService.instance.pendingLaunchAction =
        () => _handleNotificationTap(initialMessage);
  }

  // Background tap: update FCM token on refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': newToken});
    }
  });

  // Initialize Paymob SDK
  try {
    await FlutterPaymob.instance.initialize(
      apiKey: dotenv.env['PAYMOB_API_KEY'] ?? '',
      integrationID: int.tryParse(dotenv.env['PAYMOB_INTEGRATION_ID_CARD'] ?? '') ?? 0,
      walletIntegrationId: int.tryParse(dotenv.env['PAYMOB_INTEGRATION_ID_WALLET'] ?? '') ?? 0,
      iFrameID: int.tryParse(dotenv.env['PAYMOB_IFRAME_ID'] ?? '') ?? 0,
    );
  } catch (e) {
    debugPrint('Paymob initialization error: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // ignore: deprecated_member_use
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error\n$stack');
    return true;
  };

  // TEMP DIAGNOSTIC — remove once the Tours-screen grey-box bug is fixed.
  // In a release/TestFlight build a widget that throws during build is replaced
  // by a blank light-grey box (the default release ErrorWidget) which hides the
  // real exception. This override paints the exception text on screen instead so
  // it can be read/screenshotted from a release build. It is layout-safe in both
  // bounded and unbounded (ListView item) contexts.
  ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFFB00020),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
            textAlign: TextAlign.center,
            maxLines: 40,
            overflow: TextOverflow.clip,
          ),
        ),
      );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, mode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleController.locale,
            builder: (context, locale, _) {
              // Locale-aware default font: Cairo for Arabic, Marcellus for
              // Latin. The Cairo fallback means any Marcellus-tagged text still
              // renders Arabic glyphs on-brand instead of the system font.
              final fontFamily = AppTheme.fontFamilyFor(locale);
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context).appTitle,

                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,

                theme: AppTheme.light.copyWith(
                  textTheme: ThemeData.light().textTheme.apply(
                        fontFamily: fontFamily,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                ),
                darkTheme: AppTheme.dark.copyWith(
                  textTheme: ThemeData.dark().textTheme.apply(
                        fontFamily: fontFamily,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                ),

                themeMode: mode,

                home: AuthGate(),

                routes: {
                  '/onboarding': (context) => const OnboardingScreen(),
                  '/login': (context) => BlocProvider<LoginBloc>(
                        create: (_) => di.sl<LoginBloc>(),
                        child: const LoginScreen(),
                      ),
                  '/signup': (context) => const SignupScreen(),
                  '/home': (context) => HomeWrapper(),
                  '/map_picker': (context) => const MapPickerScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
