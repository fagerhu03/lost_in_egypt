import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- APP IMPORTS ---
import '../../forget_password/presentaion/forget_password_screen.dart';
import '../../sign_up/presentaion/signup_screen.dart';
import '../../data/datasources/auth_remote_datasource.dart'; 
import '../../data/repository_impl/auth_repository_impl.dart';
import '../../sign_up/presentaion/complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- STATE MANAGEMENT ---
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

  // --- LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    // 1. Validation: Ensure fields are not empty
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Setup Data Layer
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      // 3. Attempt Login
      final result = await repository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 4. Handle Result
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Welcome back, ${userEntity.firstName}!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GOOGLE LOGIN ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      final result = await repository.signInWithGoogle();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            // Null userEntity means "New User" -> Go to Complete Profile
            if (userEntity != null) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
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

  // --- FACEBOOK LOGIN ---
  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    try {
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      final result = await repository.signInWithFacebook();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            if (userEntity != null) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
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

  // --- APPLE LOGIN (MOCK) ---
  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      final result = await repository.signInWithApple();

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
            );
          }
        },
        (userEntity) {
          if (mounted) {
            if (userEntity != null) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
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

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCFBE8),
          image: DecorationImage(
            image: AssetImage("assets/pattern.png"),
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

                  // LOGO
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                    child: TextField(
                      controller: _emailController, 
                      style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: obscure,
                      style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
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
                            ? const CircularProgressIndicator(color: Colors.black87)
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

                  // FORGOT PASSWORD LINK
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

                  // DIVIDER
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

                  // --- SOCIAL BUTTONS (WIRED UP) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGoogleLogin,
                        child: Image.asset("assets/social/google.png", height: 40),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _isLoading ? null : _handleAppleLogin,
                        child: Image.asset("assets/social/apple.png", height: 40),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _isLoading ? null : _handleFacebookLogin,
                        child: Image.asset("assets/social/facebook.png", height: 40),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // CREATE ACCOUNT LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.black87, fontFamily: "Marcellus"),
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