import 'package:flutter/material.dart';

import '../../login/presentaion/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool obscure1 = true;
  bool obscure2 = true;

  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<String> get _days {
    // This can be improved to get days based on selected month and year
    return List<String>.generate(31, (i) => (i + 1).toString());
  }

  List<String> get _years {
    final int currentYear = DateTime.now().year;
    // Generate a list of years, for example, from currentYear down to 100 years ago.
    return List<String>.generate(100, (i) => (currentYear - i).toString());
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
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // LOGO
                  Image.asset("assets/logo/logo_colorful.png", height: 140),

                  const SizedBox(height: 20),
                  const Text(
                    "New Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Marcellus",
                      color: Color(0xff634700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // FIRST NAME
                  _inputField("First Name"),

                  const SizedBox(height: 10),

                  // LAST NAME
                  _inputField("Last Name"),

                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date of birth",
                      style: TextStyle(
                        color: Color(0xff634700),
                        fontSize: 16,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _monthDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _dayDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _yearDropdown()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // EMAIL
                  _inputField("Email"),

                  const SizedBox(height: 15),

                  // PASSWORD
                  _passwordField(
                    hint: "Enter your password",
                    obscure: obscure1,
                    onTap: () => setState(() => obscure1 = !obscure1),
                  ),

                  const SizedBox(height: 15),

                  // CONFIRM PASSWORD
                  _passwordField(
                    hint: "Confirm your password",
                    obscure: obscure2,
                    onTap: () => setState(() => obscure2 = !obscure2),
                  ),

                  const SizedBox(height: 25),

                  // SIGN UP BUTTON
                  GestureDetector(
                    onTap: () {
                      // TODO: sign up logic
                    },
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign up",
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

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.black87, fontFamily: "Marcellus"),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Color(0xFFD6A00F),
                            fontWeight: FontWeight.w600,
                            fontFamily: "Marcellus",
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================== WIDGETS ========================

  Widget _inputField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontFamily: "Marcellus",
          ),
        ),
      ),
    );
  }

  Widget _monthDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          hint: const Text(
            "Month",
            style: TextStyle(color: Colors.white70, fontFamily: "Marcellus"),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color(0xFF7A8450),
          style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
          onChanged: (String? newValue) {
            setState(() {
              _selectedMonth = newValue;
            });
          },
          items: _months.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _dayDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDay,
          hint: const Text(
            "Day",
            style: TextStyle(color: Colors.white70, fontFamily: "Marcellus"),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color(0xFF7A8450),
          style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDay = newValue;
            });
          },
          items: _days.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _yearDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          hint: const Text(
            "Year",
            style: TextStyle(color: Colors.white70, fontFamily: "Marcellus"),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color(0xFF7A8450),
          style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
          onChanged: (String? newValue) {
            setState(() {
              _selectedYear = newValue;
            });
          },
          items: _years.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}

Widget _passwordField({
  required String hint,
  required bool obscure,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF7A8450).withOpacity(0.70),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
    child: TextField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontFamily: "Marcellus"),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white60,
          fontFamily: "Marcellus",
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: onTap,
        ),
      ),
    ),
  );
}
