import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/utils/error_handler.dart';

class PhoneVerificationScreen extends StatefulWidget {
  /// Called after successful verification. If null, falls back to Navigator.pop(true).
  final VoidCallback? onVerified;

  /// Called when the user taps "Skip for now". If null, no skip option is shown.
  final VoidCallback? onSkip;

  const PhoneVerificationScreen({super.key, this.onVerified, this.onSkip});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  String _completePhoneNumber = "";
  // ISO 3166-1 alpha-2 country code from the phone picker (e.g. "EG", "US").
  // Written to users/{uid}.nationalityCode on successful verification so the
  // recommendation engine's country-prior cold-start path can score new users
  // before they accumulate personal signals. Default matches initialCountryCode.
  String _isoCode = "EG";
  String _verificationId = "";
  bool _codeSent = false;
  bool _isLoading = false;

  // Controller
  final TextEditingController _otpController = TextEditingController();

  /// Send verification code via Firebase Phone Auth
  Future<void> _sendCode() async {
    if (_completePhoneNumber.isEmpty) return;
    
    // DEVELOPER BYPASS
    if (_completePhoneNumber == "+201111111111") {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'phoneNumber': _completePhoneNumber,
          'phoneVerified': true,
          'nationalityCode': _isoCode,
        }, SetOptions(merge: true));
        if (mounted) {
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.pop(context, true);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Developer Phone Verified! ✅"), backgroundColor: Colors.green),
          );
        }
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _linkCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError(e.message ?? "Verification failed");
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showError(ErrorHandler.handleGenericError(e));
      setState(() => _isLoading = false);
    }
  }

  /// Verify the SMS code via Firebase Phone Auth
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      await _linkCredential(credential);
    } catch (e) {
      _showError("Invalid Code");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Link to Firebase Auth
      await user.linkWithCredential(credential);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phoneNumber': _completePhoneNumber,
        'phoneVerified': true,
        'nationalityCode': _isoCode,
      }, SetOptions(merge: true));

      if (mounted) {
        if (widget.onVerified != null) {
          widget.onVerified!();
        } else {
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Phone Verified! ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showError("This phone number is already linked to another account.");
      } else {
        _showError("Error linking number: ${e.message}");
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _showError(ErrorHandler.handleGenericError(e));
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC79A00);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onSkip != null
            ? IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF714611)),
                onPressed: widget.onSkip,
              )
            : IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF714611)),
                onPressed: () => Navigator.pop(context, false),
              ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phonelink_lock,
                size: 50.r,
                color: goldColor,
              ),
            ),
            SizedBox(height: 24.h),

            Text(
              _codeSent ? "Enter Code" : "Verify Phone Number",
              style: TextStyle(
                fontFamily: "Marcellus",
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF714611),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _codeSent
                  ? "We sent a text message to $_completePhoneNumber with your verification code. Valid for 10 minutes."
                  : "To keep our community safe, please verify your phone number before posting.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
            SizedBox(height: 32.h),

            if (!_codeSent)
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                initialCountryCode: 'EG',
                onChanged: (phone) {
                  _completePhoneNumber = phone.completeNumber;
                  _isoCode = phone.countryISOCode;
                },
              ),

            if (_codeSent)
              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: PinTheme(
                  width: 50.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  textStyle: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF714611),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 50.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: goldColor, width: 2),
                  ),
                ),
              ),

            SizedBox(height: 40.h),

            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_codeSent ? _verifyOtp : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_codeSent ? "Verify Code" : "Send Code"),
              ),
            ),

            if (_codeSent)
              TextButton(
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text(
                  "Change Number",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            if (widget.onSkip != null)
              TextButton(
                onPressed: widget.onSkip,
                child: const Text(
                  "Skip for now",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
