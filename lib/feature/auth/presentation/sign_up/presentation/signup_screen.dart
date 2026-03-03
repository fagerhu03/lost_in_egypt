import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/presentation/login_screen.dart'; // Verify this path for your LoginScreen
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_text_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_password_field.dart';
import 'package:lost_in_egypt/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lost_in_egypt/feature/guide_application/presentation/pages/apply_guide_screen.dart' as lost_in_egypt_guide_screen;
import 'package:lost_in_egypt/feature/guide_application/presentation/bloc/apply_guide_cubit.dart' as lost_in_egypt_guide_cubit;
import 'package:lost_in_egypt/feature/guide_application/domain/usecases/apply_guide_usecase.dart' as lost_in_egypt_guide_usecase;
import 'package:get_it/get_it.dart';


import 'package:lost_in_egypt/main.dart'; // Import AuthGate

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

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
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
    if (_selectedMonth == null ||
        _selectedDay == null ||
        _selectedYear == null) {
      _showError("Please select your full Date of Birth.");
      return false;
    }

    // Date validity and age check
    try {
      final int day = int.parse(_selectedDay!);
      final int year = int.parse(_selectedYear!);
      final int monthIndex = _months.indexOf(_selectedMonth!) + 1;

      // Months that never have 31 days
      const monthsWith30Days = ['April', 'June', 'September', 'November'];

      // 1) February cannot have 30 or 31
      if (_selectedMonth == 'February' && (day == 30 || day == 31)) {
        _showError("February cannot have 30 or 31 days.");
        return false;
      }

      // 2) Months that cannot have 31 days (April, June, September, November, February)
      if (day == 31 &&
          (monthsWith30Days.contains(_selectedMonth) ||
              _selectedMonth == 'February')) {
        _showError("The selected month cannot have 31 days.");
        return false;
      }

      final DateTime dob = DateTime(year, monthIndex, day);

      // Extra safety: ensure the constructed date matches the selected values
      if (dob.year != year || dob.month != monthIndex || dob.day != day) {
        _showError("Please select a valid Date of Birth.");
        return false;
      }

      // Age must be at least 16
      final int age = _calculateAge(dob);
      if (age < 16) {
        _showError("You must be at least 16 years old to sign up.");
        return false;
      }
    } catch (_) {
      _showError("Please select a valid Date of Birth.");
      return false;
    }

    // Email Regex - ✅ IMPROVED: More strict validation
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address.");
      return false;
    }

    // Password Regex: 8+ chars, 1 letter, 1 number
    final passwordRegex = RegExp(
      r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$",
    );
    if (!passwordRegex.hasMatch(_passwordController.text)) {
      _showError(
        "Password must be 8+ chars, with at least 1 letter and 1 number.",
      );
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

  bool _applyAsGuide = false;

  // 4. Signup Action
  Future<void> _handleSignup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );

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
        if (_applyAsGuide) {
          // If applying as guide, redirect directly to ApplyGuideScreen 
          // They are now authenticated but require extra steps
          Navigator.of(context).pushAndRemoveUntil(
             FadePageRoute(
               page: BlocProvider(
                 create: (context) => lost_in_egypt_guide_cubit.ApplyGuideCubit(
                   applyGuideUseCase: GetIt.I<lost_in_egypt_guide_usecase.ApplyGuideUseCase>(),
                 ),
                 child: lost_in_egypt_guide_screen.ApplyGuideScreen(
                   isFromSignup: true,
                 ),
               ),
             ),
             (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Created Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            FadePageRoute(page: const AuthGate()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Signup Failed";
      if (e.code == 'email-already-in-use')
        msg = "This email is already registered.";
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
                  AuthTextField(
                    hintText: "First Name", 
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 10),

                  // LAST NAME
                  AuthTextField(
                    hintText: "Last Name", 
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                  ),

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
                  AuthTextField(
                    hintText: "Email", 
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 15),

                  // PASSWORD
                  AuthPasswordField(
                    hintText: "Enter your password",
                    obscureText: obscure1,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    onVisibilityToggle: () => setState(() => obscure1 = !obscure1),
                  ),

                  const SizedBox(height: 15),

                  // CONFIRM PASSWORD
                  AuthPasswordField(
                    hintText: "Confirm your password",
                    obscureText: obscure2,
                    controller: _confirmPassController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    onVisibilityToggle: () => setState(() => obscure2 = !obscure2),
                  ),

                  const SizedBox(height: 25),

                  // APPLY AS GUIDE CHECKBOX
                  Row(
                    children: [
                      Checkbox(
                        value: _applyAsGuide,
                        onChanged: (bool? value) {
                          setState(() {
                            _applyAsGuide = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFD6A00F),
                        checkColor: Colors.black87,
                      ),
                      const Expanded(
                        child: Text(
                          "I want to apply to be a Guide",
                          style: TextStyle(
                            color: Colors.black87,
                            fontFamily: "Marcellus",
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

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
                            ? const CircularProgressIndicator(
                                color: Colors.black87,
                              )
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
                            FadePageRoute(page: const LoginScreen()),
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
