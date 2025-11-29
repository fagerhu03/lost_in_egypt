import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
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
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Email OTP configuration (Correct way)
    EmailOTP.config(
      appEmail: "support@lostinegypt.com",
      appName: "Lost in Egypt",
      otpLength: 4,
      otpType: OTPType.numeric,
    );

    // Send OTP
    bool success =
    await EmailOTP.sendOTP(email: _emailController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Sent! Check your email.")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpVerificationScreen(email: _emailController.text.trim()),
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
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON
                Image.asset(
                  "assets/icons/error.png",
                  height: 150,
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
