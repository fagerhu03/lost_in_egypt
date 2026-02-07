import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- AUTH FEATURE IMPORTS ---
import '../../forget_password/presentation/forget_password_screen.dart';
import '../../sign_up/presentation/signup_screen.dart';
import '../../sign_up/presentation/complete_profile_screen.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/di/service_locator.dart';

// --- HOME SCREEN IMPORT ---
// import '../../../home/tabs/home/home_screen.dart';
import '../../../home/tabs/navigator/home_wrapper.dart';

// ✅ NEW: Import error handler and constants
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===========================================================================
  // 1. STATE VARIABLES & CONTROLLERS
  // ===========================================================================
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 2. HELPER METHODS (NAVIGATION)
  // ===========================================================================

  /// Navigates to the Home Screen and removes all previous screens (Login/Onboarding)
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      // CHANGE HERE: Navigate to HomeWrapper, NOT HomeScreen
      MaterialPageRoute(builder: (context) => const HomeWrapper()),
      (route) => false,
    );
  }

  /// Navigates to the Complete Profile Screen (For new Social Users)
  void _navigateToCompleteProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
    );
  }

  // ===========================================================================
  // 3. AUTHENTICATION LOGIC
  // ===========================================================================

  /// Handles Standard Email/Password Login
  Future<void> _handleLogin() async {
    // A. Validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.requiredField),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ NEW: Validate email format
    final emailError = ErrorHandler.validateEmail(_emailController.text.trim());
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // B. Dependency Injection (Using GetIt)
      final repository = sl<AuthRepository>();

      // C. Call Repository
      final result = await repository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // D. Handle Result (Either Failure or Success)
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "${AppStrings.loginSuccess} ${userEntity.firstName}!",
                ),
                backgroundColor: Colors.green,
              ),
            );
            _navigateToHome(); // Navigate to Home
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      // ✅ NEW: Use centralized error handler
      final errorMsg = ErrorHandler.handleAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // ✅ NEW: Use generic error handler
      final errorMsg = ErrorHandler.handleGenericError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles Google Sign In
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final repository = sl<AuthRepository>();

      final result = await repository.signInWithGoogle();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            if (userEntity != null) {
              // EXISTING USER -> GO HOME
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            } else {
              // NEW USER -> COMPLETE PROFILE
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompleteProfileScreen(),
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles Facebook Sign In
  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    try {
      final repository = sl<AuthRepository>();

      final result = await repository.signInWithFacebook();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            if (userEntity != null) {
              _navigateToHome();
            } else {
              _navigateToCompleteProfile();
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles Apple Sign In (Mock/Real)
  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      final repository = sl<AuthRepository>();

      final result = await repository.signInWithApple();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            if (userEntity != null) {
              _navigateToHome();
            } else {
              _navigateToCompleteProfile();
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // 4. UI BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCFBE8),
          image: DecorationImage(
            image: AssetImage("assets/pattern_comp.png"),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // --- LOGO ---
                  Image.asset(
                    "assets/logo/logo_colorful_comp.png",
                    height: 140,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Log in to unlock your journey.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff634700),
                      fontFamily: "Marcellus",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- EMAIL INPUT ---
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A8450).withOpacity(0.70),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 3,
                    ),
                    // Removed 'const', Added 'controller'
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Marcellus",
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter your email",
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontFamily: "Marcellus",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- PASSWORD INPUT ---
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A8450).withOpacity(0.70),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 3,
                    ),
                    // Added 'controller'
                    child: TextField(
                      controller: _passwordController,
                      obscureText: obscure,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Marcellus",
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter your password",
                        hintStyle: const TextStyle(
                          color: Colors.white60,
                          fontFamily: "Marcellus",
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscure = !obscure;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- LOGIN BUTTON ---
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black87,
                              )
                            : const Text(
                                "Log In",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Marcellus",
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- FORGOT PASSWORD LINK ---
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgetPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xff634700),
                        fontSize: 16,
                        fontFamily: "Marcellus",
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- DIVIDER ---
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Colors.black54, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "OR SIGN IN WITH",
                          style: TextStyle(
                            color: Color(0xff634700),
                            fontSize: 14,
                            fontFamily: "Marcellus",
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.black54, thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- SOCIAL BUTTONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleLogin,
                        child: Image.asset(
                          "assets/social/google.png",
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Apple
                      GestureDetector(
                        onTap: _isLoading ? null : _handleAppleLogin,
                        child: Image.asset(
                          "assets/social/apple.png",
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Facebook
                      GestureDetector(
                        onTap: _isLoading ? null : _handleFacebookLogin,
                        child: Image.asset(
                          "assets/social/facebook.png",
                          height: 40,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // --- CREATE ACCOUNT LINK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: "Marcellus",
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: Color(0xFFD6A00F),
                            fontWeight: FontWeight.w600,
                            fontFamily: "Marcellus",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
