import 'package:flutter/material.dart';
import '../../forget_password/presentaion/forget_password_screen.dart';
import '../../sign_up/presentaion/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;

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
              // Set a max-width for larger screens if desired, but infinity is fine.
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
              children: [
                const SizedBox(height: 60),

                // LOGO
                Image.asset(
                  "assets/logo/logo_colorful.png",
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

                const SizedBox(height: 15),

                // PASSWORD FIELD
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8450).withOpacity(0.70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 3,
                  ),
                  child: TextField(
                    obscureText: obscure,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Marcellus",
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your password",
                      hintStyle: TextStyle(
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

                // LOGIN BUTTON
                GestureDetector(
                  onTap: () {
                    // TODO: login logic
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

                // DIVIDER TEXT
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

                // SOCIAL BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/social/google.png", height: 40),
                    const SizedBox(width: 20),
                    Image.asset("assets/social/apple.png", height: 40),
                    const SizedBox(width: 20),
                    Image.asset("assets/social/facebook.png", height: 40),
                  ],
                ),

                const SizedBox(height: 25),

                // CREATE ACCOUNT
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
    ));
  }
}
