import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/settings_repository.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:lost_in_egypt/feature/onboarding/onboarding_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/email_verification_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/create_username_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
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
  bool _isPhoneVerified = true; // default true to avoid flash — corrected after load

  Future<void> _applySavedTheme(User firebaseUser) async {
    try {
      final UserModel? userModel = await _settingsRepo.fetchCurrentUser();
      if (userModel != null) {
        _isFirestoreEmailVerified = userModel.emailVerified;
        _hasUsername = userModel.username.isNotEmpty;
        _isPhoneVerified = userModel.phoneVerified;
      }
      ThemeController.setDark(userModel?.isDarkMode ?? false);
      CurrencyController.setCurrency(userModel?.preferredCurrency ?? 'EGP');
    } catch (_) {
      // fallback if fetch fails
      ThemeController.setDark(false);
      CurrencyController.setCurrency('EGP');
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
          _isPhoneVerified = true;
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
            if (freshUser != null && !freshUser.emailVerified && !_isFirestoreEmailVerified) {
              return EmailVerificationScreen(
                onVerified: () => setState(() => _isFirestoreEmailVerified = true),
              );
            }
            // Route to username creation if the user hasn't set one yet
            if (!_hasUsername) {
              return const CreateUsernameScreen();
            }
            // Prompt phone verification (skippable — session-only skip)
            if (!_isPhoneVerified) {
              return PhoneVerificationScreen(
                onVerified: () => setState(() => _isPhoneVerified = true),
                onSkip: () => setState(() => _isPhoneVerified = true),
              );
            }
            return const HomeWrapper();
          },
        );
      },
    );
  }
}
