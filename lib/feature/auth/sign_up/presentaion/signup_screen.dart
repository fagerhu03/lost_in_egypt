import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/data/datasources/auth_remote_datasource.dart'; 
import '../../login/presentaion/login_screen.dart'; // Verify this path for your LoginScreen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // 2. State Variables
  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;

  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<String> get _days {
    return List<String>.generate(31, (i) => (i + 1).toString());
  }

  List<String> get _years {
    final int currentYear = DateTime.now().year;
    return List<String>.generate(100, (i) => (currentYear - i).toString());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // 3. Validation Logic
  bool _validateForm() {
    // Name Regex: Letters and spaces only, min 2 chars
    final nameRegex = RegExp(r"^[a-zA-Z\s]{2,}$");
    
    if (!nameRegex.hasMatch(_firstNameController.text.trim())) {
      _showError("First Name must contain valid letters (min 2).");
      return false;
    }
    if (!nameRegex.hasMatch(_lastNameController.text.trim())) {
      _showError("Last Name must contain valid letters (min 2).");
      return false;
    }

    // Date Strict Check
    if (_selectedMonth == null || _selectedDay == null || _selectedYear == null) {
      _showError("Please select your full Date of Birth.");
      return false;
    }

    // Email Regex
    final emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address.");
      return false;
    }

    // Password Regex: 8+ chars, 1 letter, 1 number
    final passwordRegex = RegExp(r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$");
    if (!passwordRegex.hasMatch(_passwordController.text)) {
      _showError("Password must be 8+ chars, with at least 1 letter and 1 number.");
      return false;
    }

    if (_passwordController.text != _confirmPassController.text) {
      _showError("Passwords do not match.");
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 4. Signup Action
  Future<void> _handleSignup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // NOTE: In the final app, use Dependency Injection (GetIt) or BlocProvider to get this
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

      // We use ! here because validateForm() guaranteed they are not null
      await dataSource.signUp(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        birthMonth: _selectedMonth!,
        birthDay: _selectedDay!,
        birthYear: _selectedYear!,
        phoneNumber: "", // Placeholder until UI adds phone field
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to Login or Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Signup Failed";
      if (e.code == 'email-already-in-use') msg = "This email is already registered.";
      if (e.code == 'weak-password') msg = "The password is too weak.";
      if (mounted) _showError(msg);
    } catch (e) {
      if (mounted) _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========================== UI BUILD ==========================

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
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // LOGO
                  Image.asset(
                    "assets/logo/logo_colorful_comp.png",
                    height: 140,
                  ),

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
                  _inputField("First Name", _firstNameController),

                  const SizedBox(height: 10),

                  // LAST NAME
                  _inputField("Last Name", _lastNameController),

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
                  _inputField("Email", _emailController),

                  const SizedBox(height: 15),

                  // PASSWORD
                  _passwordField(
                    hint: "Enter your password",
                    obscure: obscure1,
                    controller: _passwordController,
                    onTap: () => setState(() => obscure1 = !obscure1),
                  ),

                  const SizedBox(height: 15),

                  // CONFIRM PASSWORD
                  _passwordField(
                    hint: "Confirm your password",
                    obscure: obscure2,
                    controller: _confirmPassController,
                    onTap: () => setState(() => obscure2 = !obscure2),
                  ),

                  const SizedBox(height: 25),

                  // SIGN UP BUTTON
                  GestureDetector(
                    onTap: _isLoading ? null : _handleSignup,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.black87) 
                          : const Text(
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
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: "Marcellus",
                        ),
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

  Widget _inputField(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: TextField(
        controller: controller,
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

  Widget _passwordField({
    required String hint,
    required bool obscure,
    required VoidCallback onTap,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: TextField(
        controller: controller,
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