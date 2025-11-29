import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:pinput/pinput.dart';
import 'new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> _verifyOtp() async {
    if (otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 4-digit code")),
      );
      return;
    }

    setState(() => isLoading = true);

    bool valid = EmailOTP.verifyOTP(
      otp: otpController.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() => isLoading = false);

    if (valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 55,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontFamily: "Marcellus",
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD6A00F),
          width: 2,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),

      extendBodyBehindAppBar: true,

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
                Image.asset(
                  "assets/icons/otp.png",
                  height: 150,
                ),
                const Text(
                  "Verification",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the 4-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: "Marcellus",
                    fontSize: 16,
                    color: Color(0xff634700),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================== PINPUT FIELD ====================
                Pinput(
                  length: 4,
                  controller: otpController,
                  defaultPinTheme: defaultTheme,
                  focusedPinTheme: focusedTheme,
                  separatorBuilder: (index) => const SizedBox(width: 10),
                  keyboardType: TextInputType.number,
                  pinAnimationType: PinAnimationType.scale,
                ),

                const SizedBox(height: 25),

                GestureDetector(
                  onTap: isLoading ? null : _verifyOtp,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6A00F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.black87,
                      )
                          : const Text(
                        "Verify Code",
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

                const Text(
                  "Resend Code",
                  style: TextStyle(
                    fontFamily: "Marcellus",
                    fontSize: 14,
                    color: Color(0xff634700),
                    decoration: TextDecoration.underline,
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
