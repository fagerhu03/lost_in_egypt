import 'package:flutter/material.dart';
import 'feature/auth/login/presentaion/login_screen.dart';
import 'feature/auth/sign_up/presentaion/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        }
    );
  }
}
