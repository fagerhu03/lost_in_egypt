import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:lost_in_egypt/theme/app_theme.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';

import 'core/di/service_locator.dart' as di;

import 'feature/home/tabs/navigator/home_wrapper.dart';
import 'firebase_options.dart';
import 'feature/auth/login/presentation/login_screen.dart';
import 'feature/auth/sign_up/presentation/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';

// ✅ add these imports for saved theme
import 'feature/home/tabs/more/data/settings_repository.dart';
import 'feature/auth/data/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  await di.init();

  // ⭐ FORCE LATEST MAP RENDERER
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
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

          home: const AuthGate(),

          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeWrapper(),
          },
        );
      },
    );
  }
}

// ⭐ THE AUTH GATE (UPDATED: applies saved theme once)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SettingsRepository _settingsRepo = SettingsRepository();

  String? _appliedForUid; // prevents re-applying every rebuild

  Future<void> _applySavedThemeIfNeeded(User firebaseUser) async {
    if (_appliedForUid == firebaseUser.uid) return;

    try {
      final UserModel? userModel = await _settingsRepo.fetchCurrentUser();
      ThemeController.setDark(userModel?.isDarkMode ?? false);
    } catch (_) {
      // fallback if fetch fails
      ThemeController.setDark(false);
    }

    _appliedForUid = firebaseUser.uid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          // Optional: reset to light on logout
          _appliedForUid = null;
          // ThemeController.setDark(false);

          return const OnboardingScreen();
        }

        // Apply saved theme BEFORE showing HomeWrapper
        return FutureBuilder<void>(
          future: _applySavedThemeIfNeeded(firebaseUser),
          builder: (context, themeSnap) {
            if (themeSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const HomeWrapper();
          },
        );
      },
    );
  }
}