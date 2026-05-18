import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/settings_repository.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:lost_in_egypt/feature/onboarding/onboarding_screen.dart';
import 'package:lost_in_egypt/feature/onboarding/taste_quiz_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/email_verification_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/create_username_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/home_wrapper.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SettingsRepository _settingsRepo = SettingsRepository();

  String? _appliedForUid; // prevents re-applying every rebuild
  Future<void>? _initFuture;
  bool _isFirestoreEmailVerified = false;
  bool _hasUsername = true; // default true to avoid flash — corrected after load
  bool _quizCompleted = true; // default true to avoid flash — corrected after load

  Future<void> _applySavedTheme(User firebaseUser) async {
    try {
      final results = await Future.wait([
        _settingsRepo.fetchCurrentUser().timeout(const Duration(seconds: 3)),
        SharedPreferences.getInstance(),
      ]);
      final userModel = results[0] as UserModel?;
      final prefs = results[1] as SharedPreferences;
      if (userModel != null) {
        _isFirestoreEmailVerified = userModel.emailVerified;
        _hasUsername = userModel.username.isNotEmpty;
      }
      // Quiz completion: Firestore `quizCompletedAt` is the source of truth
      // (written by the `applyQuizAnswers` Cloud Function). SharedPrefs is a
      // device-local cache so the gate still works on cold-start when offline.
      // Checking only SharedPrefs broke device-switch and cache-clear: returning
      // users hit the quiz screen again even though they'd completed it.
      final hasFirestoreQuiz = userModel?.quizCompletedAt != null;
      final hasLocalQuiz = prefs.getBool('taste_quiz_completed') ?? false;
      _quizCompleted = hasFirestoreQuiz || hasLocalQuiz;
      // Backfill the local cache from Firestore so offline launches are fast.
      if (hasFirestoreQuiz && !hasLocalQuiz) {
        await prefs.setBool('taste_quiz_completed', true);
      }
      ThemeController.setDark(userModel?.isDarkMode ?? false);
      CurrencyController.setCurrency(userModel?.preferredCurrency ?? 'EGP');
    } catch (_) {
      // fallback if fetch fails
      ThemeController.setDark(false);
      CurrencyController.setCurrency('EGP');
    }

    // ── FCM token registration (Non-blocking) ────────────────────────────
    Future.microtask(() async {
      try {
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.requestPermission();
        }
        final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 5));
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .update({'fcmToken': token});
        }
      } catch (e) {
        debugPrint('FCM token registration error: $e');
      }
    });

    // ── Weather bootstrap (fire-and-forget, Cairo coords as initial anchor) ─
    // The map screen will refresh with accurate GPS coords once it loads.
    Future.microtask(() => WeatherController.refresh(30.0444, 31.2357));

    // ── Battery optimization exemption (Android only — Samsung/OEM fix) ────
    if (Platform.isAndroid) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final alreadyPrompted = prefs.getBool('battery_opt_prompted') ?? false;
        if (!alreadyPrompted) {
          final isDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
          if (isDisabled != true) {
            await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
          }
          await prefs.setBool('battery_opt_prompted', true);
        }
      } catch (e) {
        debugPrint('Battery optimization check error: $e');
      }
    }
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
          _initFuture = null;
          _hasUsername = true;
          _quizCompleted = true;
          CurrencyController.setCurrency('EGP');
          // ThemeController.setDark(false);

          return const OnboardingScreen();
        }

        if (_appliedForUid != firebaseUser.uid) {
          _appliedForUid = firebaseUser.uid;
          _initFuture = Future.wait([
            firebaseUser.reload().catchError((_) {}),
            _applySavedTheme(firebaseUser)
          ]);
        }

        // Apply saved theme BEFORE showing HomeWrapper
        return FutureBuilder<void>(
          future: _initFuture,
          builder: (context, themeSnap) {
            if (themeSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Always get the freshly reloaded user to ensure emailVerified is accurate
            final freshUser = FirebaseAuth.instance.currentUser;

            // OAuth providers (Google, Facebook, Apple) verify identity
            // themselves — no need to gate users on email-link verification.
            // Without this, Facebook users whose Facebook-side email isn't
            // verified can get trapped on the verification screen with no
            // working escape.
            final isOAuthOnly = freshUser != null &&
                freshUser.providerData.isNotEmpty &&
                freshUser.providerData
                    .every((p) => p.providerId != 'password');

            if (freshUser != null &&
                !freshUser.emailVerified &&
                !_isFirestoreEmailVerified &&
                !isOAuthOnly) {
              return EmailVerificationScreen(
                onVerified: () => setState(() => _isFirestoreEmailVerified = true),
                // Session-only skip — re-prompts on next cold start. Prevents
                // any new user from being permanently trapped if their email
                // never arrives.
                onSkip: () => setState(() => _isFirestoreEmailVerified = true),
              );
            }
            // Route to username creation if the user hasn't set one yet
            if (!_hasUsername) {
              return const CreateUsernameScreen();
            }
            // Taste quiz — shown once after username is set, before home
            if (!_quizCompleted) {
              return TasteQuizScreen(
                onDone: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('taste_quiz_completed', true);
                  if (mounted) setState(() => _quizCompleted = true);
                },
              );
            }
            // Phone verification is no longer a startup gate. The number +
            // country are captured at signup (via IntlPhoneField), so the
            // engine has its nationalityCode from day 1. Verifying the SMS is
            // an on-demand trust step prompted at the natural moments —
            // posting in community, commenting, applying as a guide, or via
            // the "Verify Phone" tile in Edit Profile.
            return const HomeWrapper();
          },
        );
      },
    );
  }
}
