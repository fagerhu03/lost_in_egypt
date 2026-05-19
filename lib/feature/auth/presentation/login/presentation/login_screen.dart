import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_bloc.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_event.dart';
import 'package:lost_in_egypt/feature/auth/presentation/login/bloc/login_state.dart';
import 'package:lost_in_egypt/feature/auth/presentation/forget_password/presentation/forget_password_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/role_selection_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_password_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_text_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/auth_gate.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/complete_profile_screen.dart';
import 'package:lost_in_egypt/core/utils/snack_bar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool obscure = true;

  // Apple Sign-In is hidden until we have an Apple Developer account.
  // The data-source throws `operation-not-supported` if invoked — flip this
  // to `true` once `sign_in_with_apple` is wired up.
  static const bool _appleEnabled = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _doLogin(BuildContext context) {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please fill in your email and password.');
      return;
    }

    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute(page: AuthGate()),
        (route) => false,
      );
    }
  }

  void _navigateToCompleteProfile() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute(page: const CompleteProfileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginFailure) {
              showErrorSnackBar(context, state.error);
            } else if (state is LoginSuccess) {
              if (state.isNewSocialUser) {
                _navigateToCompleteProfile();
                return;
              }

              final user = state.user;
              if (user != null && user.role == 'guide' && user.applicationStatus != 'approved') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your guide application is pending approval.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              _navigateToHome();
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;

            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    children: [
                      SizedBox(height: 60.h),

                      Image.asset(
                        "assets/logo/logo_colorful_comp.png",
                        height: 140.h,
                      ),

                      SizedBox(height: 25.h),

                      Text(
                        "Log in to unlock your journey.",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xff634700),
                          fontFamily: "Marcellus",
                        ),
                      ),

                      SizedBox(height: 20.h),

                      AuthTextField(
                        controller: _emailController,
                        hintText: "Enter your email",
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        focusNode: _emailFocus,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),

                      SizedBox(height: 15.h),

                      AuthPasswordField(
                        controller: _passwordController,
                        hintText: "Enter your password",
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        focusNode: _passwordFocus,
                        onSubmitted: (_) => _doLogin(context),
                        onVisibilityToggle: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),

                      SizedBox(height: 25.h),

                      Material(
                        color: const Color(0xFFD6A00F),
                        borderRadius: BorderRadius.circular(10.r),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: isLoading ? null : () => _doLogin(context),
                          borderRadius: BorderRadius.circular(10.r),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: Center(
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black87,
                                    )
                                  : Text(
                                      "Log In",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "Marcellus",
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15.h),

                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            FadePageRoute(page: const ForgetPasswordScreen()),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: const Color(0xff634700),
                            fontSize: 16.sp,
                            fontFamily: "Marcellus",
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      SizedBox(height: 30.h),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.black54, thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(
                              'OR SIGN IN WITH',
                              style: TextStyle(
                                color: const Color(0xff634700),
                                fontSize: 14.sp,
                                fontFamily: 'Marcellus',
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.black54, thickness: 1),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context
                                    .read<LoginBloc>()
                                    .add(LoginWithGoogleSubmitted()),
                            child: Image.asset(
                              "assets/social/google.png",
                              height: 40.h,
                            ),
                          ),
                          SizedBox(width: 20.w),

                          if (_appleEnabled) ...[
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => context
                                      .read<LoginBloc>()
                                      .add(LoginWithAppleSubmitted()),
                              child: Image.asset(
                                "assets/social/apple.png",
                                height: 40.h,
                              ),
                            ),
                            SizedBox(width: 20.w),
                          ],

                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context
                                    .read<LoginBloc>()
                                    .add(LoginWithFacebookSubmitted()),
                            child: Image.asset(
                              "assets/social/facebook.png",
                              height: 40.h,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 25.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.black87,
                              fontFamily: "Marcellus",
                            ),
                          ),
                          SizedBox(width: 5.w),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                FadePageRoute(page: const RoleSelectionScreen()),
                              );
                            },
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Color(0xFFD6A00F),
                                fontWeight: FontWeight.w600,
                                fontFamily: "Marcellus",
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
