import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lost_in_egypt/feature/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:lost_in_egypt/feature/auth/presentation/auth_gate.dart';
import 'package:lost_in_egypt/core/utils/dob_validator.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/core/utils/snack_bar_utils.dart';

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

  static const List<String> _months = DobValidator.months;

  List<String> get _days =>
      DobValidator.daysFor(monthName: _selectedMonth, year: _selectedYear);

  List<String> get _years => DobValidator.yearsList();

  Future<void> _handleFinalize() async {
    final dobResult = DobValidator.validate(
      monthName: _selectedMonth,
      day: _selectedDay,
      year: _selectedYear,
    );
    if (dobResult.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dobResult.error!)),
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
        Navigator.of(context).pushAndRemoveUntil(
          FadePageRoute(page: const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBarFromException(context, e);
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
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "One Last Step",
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: const Color(0xff634700),
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    "We need your birthdate to customize your journey in Egypt.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp, fontFamily: "Marcellus"),
                  ),
                  SizedBox(height: 30.h),
                  
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
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _dropdown(
                          _days,
                          _selectedDay,
                          "Day",
                          (v) => setState(() => _selectedDay = v),
                        ),
                      ),
                      SizedBox(width: 10.w),
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
            
                  SizedBox(height: 40.h),

                  GestureDetector(
                    onTap: _isLoading ? null : _handleFinalize,
                    child: Container(
                      width: double.infinity,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black87)
                          : Text(
                            "Complete Setup",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18.sp,
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
        color: const Color(0xFF7A8450).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
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