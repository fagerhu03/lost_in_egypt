import 'package:flutter/material.dart';

import 'otp_screen.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

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
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ERROR ICON
                  Image.asset(
                    "assets/icons/error.png",
                    height: 150,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Forget Password?",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff634700),
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Email Address",
                      style: TextStyle(
                        color: Color(0xff634700),
                        fontSize: 15,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // EMAIL FIELD
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A8450).withOpacity(0.70),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 3,
                    ),
                    child: const TextField(
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Marcellus",
                      ),
                      decoration: InputDecoration(
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

                  // RESET BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OtpScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "Reset Password",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // BACK TO LOGIN
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(
                        color: Color(0xff634700),
                        fontSize: 14,
                        fontFamily: "Marcellus",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
