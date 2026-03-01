import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lost_in_egypt/feature/auth/data/repository_impl/auth_repository_impl.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  bool _isLoading = false;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<String> get _days => List<String>.generate(31, (i) => (i + 1).toString());

  List<String> get _years {
    final int currentYear = DateTime.now().year;
    return List<String>.generate(100, (i) => (currentYear - i).toString());
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

  Future<void> _handleFinalize() async {
    if (_selectedMonth == null || _selectedDay == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your Date of Birth")),
      );
      return;
    }

    try {
      final int day = int.parse(_selectedDay!);
      final int year = int.parse(_selectedYear!);
      final int monthIndex = _months.indexOf(_selectedMonth!) + 1; // 1–12

      // Months that never have 31 days
      const monthsWith30Days = ['April', 'June', 'September', 'November'];

      // 1) February cannot have 30 or 31
      if (_selectedMonth == 'February' && (day == 30 || day == 31)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("February cannot have 30 or 31 days.")),
        );
        return;
      }

      // 2) Months that cannot have 31 days
      if (day == 31 &&
          (monthsWith30Days.contains(_selectedMonth) ||
              _selectedMonth == 'February')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The selected month cannot have 31 days.")),
        );
        return;
      }

      final DateTime dob = DateTime(year, monthIndex, day);

      // General safety: ensure the constructed date is valid
      if (dob.year != year || dob.month != monthIndex || dob.day != day) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a valid Date of Birth")),
        );
        return;
      }

      // Age must be at least 16
      final int age = _calculateAge(dob);
      if (age < 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You must be at least 16 years old to use this app."),
          ),
        );
        return;
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid Date of Birth")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = AuthRemoteDataSourceImpl(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      final repository = AuthRepositoryImpl(remoteDataSource: dataSource);

      await repository.completeSocialProfile(
        birthMonth: _selectedMonth!,
        birthDay: _selectedDay!,
        birthYear: _selectedYear!,
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFCFBE8),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "One Last Step",
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xff634700),
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "We need your birthdate to customize your journey in Egypt.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontFamily: "Marcellus"),
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          _months,
                          _selectedMonth,
                          "Month",
                          (v) => setState(() => _selectedMonth = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dropdown(
                          _days,
                          _selectedDay,
                          "Day",
                          (v) => setState(() => _selectedDay = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dropdown(
                          _years,
                          _selectedYear,
                          "Year",
                          (v) => setState(() => _selectedYear = v),
                        ),
                      ),
                    ],
                  ),
            
                  const SizedBox(height: 40),
            
                  GestureDetector(
                    onTap: _isLoading ? null : _handleFinalize,
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
                            "Complete Setup",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String? value,
    String hint,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withOpacity(0.70),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white70),
          ),
          isExpanded: true,
          dropdownColor: const Color(0xFF7A8450),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}