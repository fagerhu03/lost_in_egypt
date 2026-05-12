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

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/theme/app_theme.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/di/service_locator.dart' as di;

import 'feature/home/tabs/navigator/home_wrapper.dart';
import 'firebase_options.dart';
import 'feature/auth/presentation/login/presentation/login_screen.dart';
import 'feature/auth/presentation/login/bloc/login_bloc.dart';
import 'feature/auth/presentation/sign_up/presentation/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';
import 'feature/home/notification/domain/services/local_notification_service.dart';

// ✅ add these imports for saved theme
import 'feature/home/tabs/more/data/settings_repository.dart';
import 'feature/auth/data/models/user.dart';
import 'feature/auth/presentation/email_verification_screen.dart';
import 'feature/tours/presentation/pages/map_picker_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/auth_gate.dart';

/// Must be a top-level function for FCM background processing.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are displayed natively by FCM — no extra work needed.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("WARNING: .env file not found, Maps API might fail if not injected via CLI.");
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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lost in Egypt',

            theme: AppTheme.light.copyWith(
              textTheme:
                  ThemeData.light().textTheme.apply(fontFamily: 'Marcellus'),
            ),
            darkTheme: AppTheme.dark.copyWith(
              textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Marcellus'),
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
              '/home': (context) => const HomeWrapper(),
              '/map_picker': (context) => const MapPickerScreen(),
            },
          );
        },
      ),
    );
  }
}
