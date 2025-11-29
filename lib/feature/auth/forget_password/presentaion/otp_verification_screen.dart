import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'new_password_screen.dart'; 

class OtpVerificationScreen extends StatefulWidget {
  // FIX 1: Removed 'myAuth' from constructor (it's static now)
  final String email;

  const OtpVerificationScreen({
    super.key, 
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    
    // FIX 2: Use Static "verifyOTP" method
    bool valid = EmailOTP.verifyOTP(otp: _otpController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (valid) {
        // Success! Go to New Password Screen
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: const BackButton(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFCFBE8)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Verification",
                  style: TextStyle(
                    fontSize: 24, 
                    fontFamily: "Marcellus", 
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter the code sent to \n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: "Marcellus", fontSize: 16),
                ),
                const SizedBox(height: 30),
                
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8450).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontFamily: "Marcellus",
                      fontSize: 24,
                      letterSpacing: 10,
                    ),
                    maxLength: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0000",
                      counterText: "",
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                GestureDetector(
                  onTap: _isLoading ? null : _verifyOtp,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}