import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lost_in_egypt/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lost_in_egypt/feature/auth/data/repository_impl/auth_repository_impl.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendPasswordReset() async {
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
      // 2. Send Firebase Native Password Reset Email Direct
      // Note: We intentionally DO NOT verify if the email exists first.
      // This is the industry-standard "Email Enumeration Protection" best practice.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        setState(() {
          _emailSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("If an account exists, a reset link was sent."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Failed to send reset email";
        if (e.code == 'invalid-email') msg = "Invalid email formatting.";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected Error: \$e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xff634700)),
      ),
      extendBodyBehindAppBar: true,
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
                  "assets/icons/error.png",
                  height: 150,
                  errorBuilder: (c, e, s) => const Icon(Icons.lock_reset, size: 100, color: Color(0xff634700)),
                ),

                Text(
                  _emailSent ? "Email Sent!" : "Reset Password",
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  _emailSent 
                    ? "If an account is registered to ${_emailController.text}, we've sent a secure password reset link. Please check your email."
                    : "Enter your email to receive a secure password reset link.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: "Marcellus",
                    fontSize: 16,
                    color: Color(0xff634700),
                  ),
                ),

                const SizedBox(height: 30),

                if (!_emailSent) ...[
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
                    onTap: _isLoading ? null : _sendPasswordReset,
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
                                "Send Reset Link",
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
                ] else ...[
                  // BACK TO LOGIN BUTTON
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "Return to Login",
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
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}