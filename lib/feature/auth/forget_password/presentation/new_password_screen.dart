import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Rebuild UI when password changes to show requirements
    _passController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ✅ ENHANCED: Better password validation with detailed messages
  String? _validatePasswordStrength() {
    final password = _passController.text;

    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  bool _validatePassword() {
    // 1. Check password strength
    final strengthError = _validatePasswordStrength();
    if (strengthError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strengthError), backgroundColor: Colors.red),
      );
      return false;
    }

    // 2. Check passwords match
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _handlePasswordReset() async {
    if (!_validatePassword()) return;
    setState(() => _isLoading = true);

    try {
      // CALL THE CLOUD FUNCTION to reset password
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'forceResetPassword',
      );

      await callable.call(<String, dynamic>{
        'email': widget.email,
        'newPassword': _passController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password changed successfully! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to Login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseFunctionsException catch (e) {
      // ✅ Better error handling for specific Firebase errors
      String errorMsg = e.message ?? 'Password reset failed';

      if (e.code == 'invalid-argument') {
        errorMsg = 'Invalid email or password. Please try again.';
      } else if (e.code == 'not-found') {
        errorMsg = 'User not found. Please check the email.';
      } else if (e.code == 'permission-denied') {
        errorMsg = 'You do not have permission to reset this password.';
      } else if (e.code == 'unavailable') {
        errorMsg = 'Service temporarily unavailable. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
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
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset("assets/icons/password_reset.png", height: 140),
                const Text(
                  "Change Your Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter a new password below to change your password",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Marcellus",
                    color: Color(0xff634700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _passwordField(
                  "New Password",
                  _passController,
                  obscure1,
                  () => setState(() => obscure1 = !obscure1),
                ),
                const SizedBox(height: 15),

                // ✅ NEW: Password requirements indicator
                if (_passController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8E2C8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password must contain:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF714611),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirement(
                          'At least 8 characters',
                          _passController.text.length >= 8,
                        ),
                        _buildRequirement(
                          'At least one letter',
                          RegExp(r'[a-zA-Z]').hasMatch(_passController.text),
                        ),
                        _buildRequirement(
                          'At least one number',
                          RegExp(r'[0-9]').hasMatch(_passController.text),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),
                _passwordField(
                  "Confirm Password",
                  _confirmController,
                  obscure2,
                  () => setState(() => obscure2 = !obscure2),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _isLoading ? null : _handlePasswordReset,
                  child: Opacity(
                    opacity: _isLoading ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      height: 50,
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
                                "Reset Password",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Marcellus",
                                ),
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
    );
  }

  // ✅ NEW: Helper widget to show password requirement status
  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met
                  ? Colors.green
                  : const Color(0xFF714611).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(
    String hint,
    TextEditingController controller,
    bool obscure,
    VoidCallback onTap,
  ) {
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
}
