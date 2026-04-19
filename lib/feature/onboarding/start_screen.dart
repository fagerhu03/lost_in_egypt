import 'package:flutter/material.dart';

import 'package:lost_in_egypt/feature/auth/presentation/login/presentation/login_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const _bgImage = 'assets/onboarding/start_screen.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      ResizeImage(const AssetImage(_bgImage), width: 1080),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D26),
      body: Stack(
        children: [
          // Decode at 1080px wide max — eliminates high-res PNG decode stall
          Positioned.fill(
            child: Image(
              image: ResizeImage(const AssetImage(_bgImage), width: 1080),
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return const ColoredBox(color: Color(0xFF0B1D26));
              },
            ),
          ),

          // Text + Button
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/logo/logo_light_comp.png",
              height: 200, // Adjust height as needed
            ),
          ),

          // Button at bottom
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: const Color(0xFFD6A00F),
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Container(
                    width: 260,
                    height: 55,
                    alignment: Alignment.center,
                    child: const Text(
                      "START EXPLORING",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Marcellus",
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
