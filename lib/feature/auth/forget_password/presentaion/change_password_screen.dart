import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool obscure1 = true;
  bool obscure2 = true;

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
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  // ICON
                  Image.asset(
                    "assets/icons/password_reset.png",
                    height: 150,
                  ),

                  const SizedBox(height: 20),

                  // TITLE
                  const Text(
                    "Change Your Password",
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: "Marcellus",
                      color: Color(0xff634700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SUB-TEXT
                  const Text(
                    "Enter a new password below to change your\npassword",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Marcellus",
                      color: Color(0xff634700),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // NEW PASSWORD
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
                      obscureText: obscure1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Marcellus",
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "New password*",
                        hintStyle: const TextStyle(
                          color: Colors.white60,
                          fontFamily: "Marcellus",
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure1 ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscure1 = !obscure1;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // CONFIRM PASSWORD
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
                      obscureText: obscure2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Marcellus",
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Confirm password*",
                        hintStyle: const TextStyle(
                          color: Colors.white60,
                          fontFamily: "Marcellus",
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure2 ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              obscure2 = !obscure2;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // RESET BUTTON
                  GestureDetector(
                    onTap: () {
                      // TODO: Reset password logic
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

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
