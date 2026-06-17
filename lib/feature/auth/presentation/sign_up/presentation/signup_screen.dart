import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/presentation/login_screen.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_text_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_password_field.dart';
import 'package:lost_in_egypt/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lost_in_egypt/feature/auth/presentation/auth_gate.dart';
import 'package:lost_in_egypt/core/utils/dob_validator.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';
import 'package:lost_in_egypt/core/utils/snack_bar_utils.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;

  // Phone number captured from IntlPhoneField (full E.164 form, e.g. "+201234567890")
  // and the ISO 3166-1 alpha-2 country code (e.g. "EG"). Both written to
  // Firestore at signup. The ISO code is what the recommendation engine reads
  // for cold-start country-prior scoring — without it, new users get
  // popularity-only rankings until they edit their profile.
  String _completePhone = '';
  String _isoCode = 'EG';
  bool _phoneValid = false;

  static const _months = DobValidator.months;

  List<String> get _days =>
      DobValidator.daysFor(monthName: _selectedMonth, year: _selectedYear);

  List<String> get _years => DobValidator.yearsList();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final l10n = AppLocalizations.of(context);
    final nameRegex = RegExp(r'^[a-zA-Z\s]{2,}$');

    if (!nameRegex.hasMatch(_firstNameController.text.trim())) {
      _showError(l10n.signupFirstNameInvalid);
      return false;
    }
    if (!nameRegex.hasMatch(_lastNameController.text.trim())) {
      _showError(l10n.signupLastNameInvalid);
      return false;
    }

    final dobResult = DobValidator.validate(
      monthName: _selectedMonth,
      day: _selectedDay,
      year: _selectedYear,
    );
    if (dobResult.error != null) {
      _showError(dobErrorMessage(
        l10n,
        dobResult.error!,
        monthName: _selectedMonth,
        year: _selectedYear,
        maxDay: dobResult.maxDay,
      ));
      return false;
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError(l10n.signupEmailInvalid);
      return false;
    }

    final passwordRegex =
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');
    if (!passwordRegex.hasMatch(_passwordController.text)) {
      _showError(l10n.signupPasswordWeak);
      return false;
    }

    if (_passwordController.text != _confirmPassController.text) {
      _showError(l10n.signupPasswordsNoMatch);
      return false;
    }

    if (!_phoneValid || _completePhone.isEmpty) {
      _showError(l10n.signupPhoneInvalid);
      return false;
    }

    return true;
  }

  void _showError(String message) => showErrorSnackBar(context, message);

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
        phoneNumber: _completePhone,
        nationalityCode: _isoCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).signupSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          FadePageRoute(page: AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        _showError(AppLocalizations.of(context).signupEmailInUse);
      } else if (e.code == 'weak-password') {
        _showError(AppLocalizations.of(context).signupPasswordTooWeak);
      } else {
        _showError(ErrorHandler.handleAuthError(e));
      }
    } catch (e) {
      if (mounted) _showError(ErrorHandler.handleGenericError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _monthDropdown() => _dobDropdown(
        value: _selectedMonth,
        hint: AppLocalizations.of(context).dobMonth,
        items: _months,
        itemLabel: (m) => dobMonthLabel(AppLocalizations.of(context), m),
        onChanged: (v) => setState(() {
          _selectedMonth = v;
          if (_selectedDay != null && !_days.contains(_selectedDay)) {
            _selectedDay = null;
          }
        }),
      );

  Widget _dayDropdown() => _dobDropdown(
        value: _selectedDay,
        hint: AppLocalizations.of(context).dobDay,
        items: _days,
        onChanged: (v) => setState(() => _selectedDay = v),
      );

  Widget _yearDropdown() => _dobDropdown(
        value: _selectedYear,
        hint: AppLocalizations.of(context).dobYear,
        items: _years,
        onChanged: (v) => setState(() {
          _selectedYear = v;
          if (_selectedDay != null && !_days.contains(_selectedDay)) {
            _selectedDay = null;
          }
        }),
      );

  Widget _dobDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? itemLabel,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value != null
              ? const Color(0xFFD6A00F)
              : const Color(0xFF7A8450).withValues(alpha: 0.4),
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              color: const Color(0xFF7A8450),
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF7A8450), size: 20.r),
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
            color: const Color(0xff634700),
          ),
          dropdownColor: const Color(0xFFFCFBE8),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(itemLabel != null ? itemLabel(e) : e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBE8),
        image: DecorationImage(
          image: AssetImage('assets/pattern_comp.png'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xff634700)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  Image.asset(
                    'assets/logo/logo_colorful_comp.png',
                    height: 130.h,
                  ),

                  SizedBox(height: 16.h),
                  Text(
                    l10n.signupTitle,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      color: const Color(0xff634700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  AuthTextField(
                    hintText: l10n.signupFirstNameHint,
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                    focusNode: _firstNameFocus,
                    onSubmitted: (_) => _lastNameFocus.requestFocus(),
                  ),
                  SizedBox(height: 10.h),

                  AuthTextField(
                    hintText: l10n.signupLastNameHint,
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                    focusNode: _lastNameFocus,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  SizedBox(height: 14.h),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.signupDateOfBirth,
                      style: TextStyle(
                        color: const Color(0xff634700),
                        fontSize: 15.sp,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: _monthDropdown()),
                      SizedBox(width: 10.w),
                      Expanded(child: _dayDropdown()),
                      SizedBox(width: 10.w),
                      Expanded(child: _yearDropdown()),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  AuthTextField(
                    hintText: l10n.signupEmailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    focusNode: _emailFocus,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  SizedBox(height: 10.h),

                  // Required — captures both the full phone number AND the
                  // country (ISO alpha-2) for the recommendation engine's
                  // cold-start path. Matches the look of the other inputs:
                  // white fill, 12 r radius, olive border.
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF7A8450).withValues(alpha: 0.4),
                      ),
                    ),
                    child: IntlPhoneField(
                      initialCountryCode: 'EG',
                      decoration: InputDecoration(
                        labelText: l10n.signupPhoneLabel,
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        color: const Color(0xff634700),
                      ),
                      onChanged: (phone) {
                        _completePhone = phone.completeNumber;
                        _isoCode = phone.countryISOCode;
                      },
                      // The package itself validates length per-country; we
                      // mirror that result so _validateForm can short-circuit.
                      validator: (phone) {
                        final ok = phone != null && phone.number.isNotEmpty;
                        _phoneValid = ok;
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),

                  AuthPasswordField(
                    hintText: l10n.authPasswordHint,
                    obscureText: _obscure1,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    focusNode: _passwordFocus,
                    onSubmitted: (_) => _confirmPassFocus.requestFocus(),
                    onVisibilityToggle: () =>
                        setState(() => _obscure1 = !_obscure1),
                  ),
                  SizedBox(height: 10.h),

                  AuthPasswordField(
                    hintText: l10n.signupConfirmPasswordHint,
                    obscureText: _obscure2,
                    controller: _confirmPassController,
                    textInputAction: TextInputAction.done,
                    focusNode: _confirmPassFocus,
                    onSubmitted: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _handleSignup();
                    },
                    onVisibilityToggle: () =>
                        setState(() => _obscure2 = !_obscure2),
                  ),
                  SizedBox(height: 24.h),

                  GestureDetector(
                    onTap: _isLoading ? null : _handleSignup,
                    child: Container(
                      width: double.infinity,
                      height: 55.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black87)
                            : Text(
                                l10n.signupButton,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18.sp,
                                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.signupHaveAccount,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'],
                        ),
                      ),
                      SizedBox(width: 5.w),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          FadePageRoute(page: const LoginScreen()),
                        ),
                        child: Text(
                          l10n.loginButton,
                          style: const TextStyle(
                            color: Color(0xFFD6A00F),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
