import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/error_handler.dart';

class EmailVerificationScreen extends StatefulWidget {
  /// Called when verification is confirmed (either via Firebase Auth or
  /// a manual Firestore override). Lets AuthGate route past this screen
  /// without a full re-fetch loop.
  final VoidCallback? onVerified;

  const EmailVerificationScreen({super.key, this.onVerified});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      await _auth.currentUser?.reload();

      bool isEmailVerified = false;
      if (_auth.currentUser != null) {
        if (_auth.currentUser!.emailVerified) {
          isEmailVerified = true;
        } else {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();
            if (doc.exists && doc.data()?['emailVerified'] == true) {
              isEmailVerified = true;
            }
          } catch (e) {
            debugPrint("Error fetching user doc: $e");
          }
        }
      }

      if (isEmailVerified) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'emailVerified': true});
        widget.onVerified?.call();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email not yet verified. Please check your inbox."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking verification: $e");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email resent! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handleGenericError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : const Color(0xFFFCFBE8),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_read,
                  size: 100.r,
                  color: isDark ? Colors.amber : const Color(0xFFC79A00),
                ),
                SizedBox(height: 32.h),
                Text(
                  "Verify Your Email",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "We've sent a verification link to your email address. Please click the link to verify your account and gain access to Lost in Egypt.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 48.h),
                SizedBox(
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.amber : const Color(0xFFC79A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isChecking
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "I've Verified",
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: _isResending
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Resend Verification Email"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
