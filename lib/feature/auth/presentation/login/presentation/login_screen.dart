import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lost_in_egypt/feature/auth/presentation/forget_password/presentation/forget_password_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/signup_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/complete_profile_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_text_field.dart';
import 'package:lost_in_egypt/feature/auth/presentation/widgets/auth_password_field.dart';
import 'package:lost_in_egypt/feature/auth/domain/repositories/auth_repository.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/home_wrapper.dart';
import 'package:lost_in_egypt/core/constants/strings.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(authRepository: sl<AuthRepository>()),
      child: const LoginScreenView(),
    );
  }
}

class LoginScreenView extends StatefulWidget {
  const LoginScreenView({super.key});

  @override
  State<LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<LoginScreenView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(page: const HomeWrapper()),
      (route) => false,
    );
  }

  void _doLogin(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.requiredField),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _navigateToCompleteProfile() {
    Navigator.of(context).push(
      FadePageRoute(page: const CompleteProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is LoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.loginSuccess),
                backgroundColor: Colors.green,
              ),
            );
            
            if (state.isNewSocialUser) {
              _navigateToCompleteProfile();
            } else {
              _navigateToHome();
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return Container(
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
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // --- LOGO ---
                      Image.asset(
                        "assets/logo/logo_colorful_comp.png",
                        height: 140,
                      ),

                      const SizedBox(height: 25),

                      const Text(
                         "Log in to unlock your journey.",
                         style: TextStyle(
                           fontSize: 16,
                           color: Color(0xff634700),
                           fontFamily: "Marcellus",
                         ),
                       ),

                       const SizedBox(height: 20),

                       // --- EMAIL INPUT ---
                       AuthTextField(
                         controller: _emailController,
                         hintText: "Enter your email",
                         keyboardType: TextInputType.emailAddress,
                         textInputAction: TextInputAction.next,
                         focusNode: _emailFocus,
                         onSubmitted: (_) => _passwordFocus.requestFocus(),
                       ),

                       const SizedBox(height: 15),

                       // --- PASSWORD INPUT ---
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

                       const SizedBox(height: 25),

                       // --- LOGIN BUTTON ---
                       Material(
                         color: const Color(0xFFD6A00F),
                         borderRadius: BorderRadius.circular(10),
                         clipBehavior: Clip.hardEdge,
                         child: InkWell(
                           onTap: isLoading ? null : () => _doLogin(context),
                           borderRadius: BorderRadius.circular(10),
                           child: SizedBox(
                             width: double.infinity,
                             height: 50,
                             child: Center(
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black87,
                                    )
                                  : const Text(
                                      "Log In",
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

                       const SizedBox(height: 15),

                       // --- FORGOT PASSWORD LINK ---
                       GestureDetector(
                         onTap: () {
                           Navigator.of(context).push(
                             FadePageRoute(page: const ForgetPasswordScreen()),
                           );
                         },
                         child: const Text(
                           "Forgot Password?",
                           style: TextStyle(
                             color: Color(0xff634700),
                             fontSize: 16,
                             fontFamily: "Marcellus",
                             decoration: TextDecoration.underline,
                           ),
                         ),
                       ),

                       const SizedBox(height: 30),

                       // --- DIVIDER ---
                       Row(
                         children: const [
                           Expanded(
                             child: Divider(color: Colors.black54, thickness: 1),
                           ),
                           Padding(
                             padding: EdgeInsets.symmetric(horizontal: 8.0),
                             child: Text(
                               "OR SIGN IN WITH",
                               style: TextStyle(
                                 color: Color(0xff634700),
                                 fontSize: 14,
                                 fontFamily: "Marcellus",
                               ),
                             ),
                           ),
                           Expanded(
                             child: Divider(color: Colors.black54, thickness: 1),
                           ),
                         ],
                       ),

                       const SizedBox(height: 20),

                       // --- SOCIAL BUTTONS ---
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           // Google
                           GestureDetector(
                             onTap: isLoading
                                 ? null
                                 : () => context
                                     .read<LoginBloc>()
                                     .add(LoginWithGoogleSubmitted()),
                             child: Image.asset(
                               "assets/social/google.png",
                               height: 40,
                             ),
                           ),
                           const SizedBox(width: 20),

                           // Apple
                           GestureDetector(
                             onTap: isLoading
                                 ? null
                                 : () => context
                                     .read<LoginBloc>()
                                     .add(LoginWithAppleSubmitted()),
                             child: Image.asset(
                               "assets/social/apple.png",
                               height: 40,
                             ),
                           ),
                           const SizedBox(width: 20),

                           // Facebook
                           GestureDetector(
                             onTap: isLoading
                                 ? null
                                 : () => context
                                     .read<LoginBloc>()
                                     .add(LoginWithFacebookSubmitted()),
                             child: Image.asset(
                               "assets/social/facebook.png",
                               height: 40,
                             ),
                           ),
                         ],
                       ),

                       const SizedBox(height: 25),

                       // --- CREATE ACCOUNT LINK ---
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
                           const SizedBox(width: 5),
                           GestureDetector(
                             onTap: () {
                               Navigator.of(context).push(
                                 FadePageRoute(page: const SignupScreen()),
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

                       const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
