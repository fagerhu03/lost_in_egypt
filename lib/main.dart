import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'; 
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'feature/home/tabs/navigator/home_wrapper.dart';
import 'firebase_options.dart';
import 'feature/auth/login/presentaion/login_screen.dart';
import 'feature/auth/sign_up/presentaion/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ⭐ FORCE LATEST MAP RENDERER 
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost in Egypt',
      theme: ThemeData(fontFamily: 'Marcellus'),
      
      // ⭐ Instead of 'initialRoute', we use 'home' with our AuthGate
      home: const AuthGate(),
      
      // Keep routes for manual navigation (Navigator.pushNamed)
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeWrapper(),
      },
    );
  }
}

// ⭐ THE AUTH GATE
// This listens to Firebase. If a user is found, it skips Onboarding/Login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While Firebase is checking (Loading state)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User FOUND (Logged in) -> Go to Home
        if (snapshot.hasData) {
          return const HomeWrapper();
        }

        // 3. User NOT FOUND (Logged out/New) -> Go to Onboarding
        return const OnboardingScreen();
      },
    );
  }
}