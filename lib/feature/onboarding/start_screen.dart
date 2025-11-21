import 'package:flutter/material.dart';

import '../auth/login/presentaion/login_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4D8B4), // beige background
      body: Stack(
        children: [
          // Full Image
          Positioned.fill(
            child: Image.asset(
              "assets/onboarding/start_screen.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Text + Button
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/logo/logo_light.png",
              height: 200, // Adjust height as needed
            ),
          ),

          // Button at bottom
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: Container(
                  width: 260,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6A00F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "START EXPLORING",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Marcellus",
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
