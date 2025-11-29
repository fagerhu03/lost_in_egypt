import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import 'change_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 52,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        fontFamily: "Marcellus",
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6A00F), width: 2),
      ),
    );

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
            child: Column(
              children: [
                const SizedBox(height: 80),

                Image.asset("assets/icons/otp.png", height: 150),

                const SizedBox(height: 20),

                const Text(
                  "Verification",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Marcellus",
                    fontWeight: FontWeight.w600,
                    color: Color(0xff634700),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "you will get an OTP via email",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                  ),
                ),

                const SizedBox(height: 25),

                // ⭐ Pinput 6 digits + animation
                Pinput(
                  length: 6,
                  controller: otpController,
                  defaultPinTheme: defaultTheme,
                  focusedPinTheme: focusedTheme,
                  separatorBuilder: (index) => const SizedBox(width: 10),

                  // animation built-in
                  pinAnimationType: PinAnimationType.scale,

                  onCompleted: (code) {
                    // print("OTP = $code");
                  },
                ),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                  child: Container(
                    width: 300,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6A00F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "Verify",
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

                const SizedBox(height: 20),
                // here we need to change it with counting but later when i navigate with firebase
                const Text(
                  "Resend code",
                  style: TextStyle(
                    color: Color(0xff634700),
                    fontSize: 16,
                    fontFamily: "Marcellus",
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
