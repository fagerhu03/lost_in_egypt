import 'dart:async'; // ✅ اتضاف: علشان Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ اتضاف: استيراد الشاشات اللي هنروح لها بعد السبلاتش
import '../onboarding/onboarding_screen.dart';
import '../home/tabs/navigator/home_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeWrapper()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
