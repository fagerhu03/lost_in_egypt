import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_text_field.dart';

import 'package:lost_in_egypt/core/utils/snack_bar_utils.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendPasswordReset() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(context);
    final email = _emailController.text.trim();

    // 1. Basic Input Validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.forgotEnterEmail)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Send Firebase Native Password Reset Email Direct
      // Note: We intentionally DO NOT verify if the email exists first.
      // This is the industry-standard "Email Enumeration Protection" best practice.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        setState(() {
          _emailSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.forgotResetSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = l.forgotFailedSend;
        if (e.code == 'invalid-email') msg = l.forgotInvalidEmail;

        showErrorSnackBar(context, msg);
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
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBE8),
        image: DecorationImage(
          image: AssetImage("assets/pattern_comp.png"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Color(0xff634700)),
        ),
        extendBodyBehindAppBar: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(30.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON
                Image.asset(
                  "assets/icons/error.png",
                  height: 150.h,
                  errorBuilder: (_, _, _) => Icon(Icons.lock_reset, size: 100.r, color: const Color(0xff634700)),
                ),

                Text(
                  _emailSent ? l.forgotEmailSentTitle : l.forgotResetTitle,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                    color: const Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20.h),

                Text(
                  _emailSent
                    ? l.forgotEmailSentBody(_emailController.text)
                    : l.forgotResetBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                    fontSize: 16.sp,
                    color: const Color(0xff634700),
                  ),
                ),

                SizedBox(height: 30.h),

                if (!_emailSent) ...[
                  // EMAIL INPUT
                  AuthTextField(
                    controller: _emailController,
                    hintText: l.authEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) _sendPasswordReset();
                    },
                  ),

                  SizedBox(height: 25.h),

                  Material(
                    color: const Color(0xFFD6A00F),
                    borderRadius: BorderRadius.circular(10.r),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: _isLoading ? null : _sendPasswordReset,
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black87)
                              : Text(
                                  l.forgotSendLink,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // BACK TO LOGIN BUTTON
                  Material(
                    color: const Color(0xFFD6A00F),
                    borderRadius: BorderRadius.circular(10.r),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Center(
                          child: Text(
                            l.forgotReturnToLogin,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}