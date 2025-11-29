import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'feature/auth/login/presentaion/login_screen.dart';
import 'feature/auth/sign_up/presentaion/signup_screen.dart';
import 'feature/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // TESTING: Force logout on start so you can test login again
  // await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost in Egypt',
      theme: ThemeData(fontFamily: 'Marcellus'),
      
      initialRoute: '/onboarding',
      
      routes: {
        //placeholder Scaffold for testing login success
        '/': (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("LOGIN SUCCESSFUL!"), 
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  }, 
                  child: const Text("Logout & Restart")
                )
              ],
            ),
          ),
        ),

        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}