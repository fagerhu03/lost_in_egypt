import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repository_impl/auth_repository_impl.dart';
import 'otp_verification_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    // 1. Basic Input Validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Initialize Repo (Manual Injection)
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      // 3. Check if Email Exists in Database
      final result = await repository.checkEmailExists(email);

      // We use 'await' inside the fold to handle the async flow cleanly
      await result.fold(
        (failure) {
          // Failure checking email (Connection error, etc.)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error checking email: ${failure.message}")),
          );
        },
        (exists) async {
          if (!exists) {
            // CASE A: Email does NOT exist
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("This email is not registered."),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            // CASE B: Email Exists -> Send OTP
            
            // Configure OTP
            EmailOTP.config(
              appEmail: "support@lostinegypt.com",
              appName: "Lost in Egypt",
              otpLength: 4,
              otpType: OTPType.numeric,
            );

            // Trigger Email
            bool success = await EmailOTP.sendOTP(email: email);

            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OTP Sent! Check your email.")),
                );
                // Navigate
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtpVerificationScreen(email: email),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to send OTP. Try again."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON
                Image.asset(
                  "assets/icons/error.png", // Ensure this asset exists
                  height: 150,
                  errorBuilder: (c, e, s) => const Icon(Icons.lock_reset, size: 100, color: Color(0xff634700)),
                ),

                const Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Enter your email to receive a 4-digit code.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Marcellus",
                    fontSize: 16,
                    color: Color(0xff634700),
                  ),
                ),

                const SizedBox(height: 30),

                // EMAIL INPUT
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8450).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 3),
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

                const SizedBox(height: 25),

                GestureDetector(
                  onTap: _isLoading ? null : _sendOtp,
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
                              color: Colors.black87)
                          : const Text(
                              "Send Code",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}