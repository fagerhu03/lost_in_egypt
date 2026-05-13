import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    precacheImage(const AssetImage('assets/logo/logo_light_comp.png'), context);
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
              color: Colors.black.withValues(alpha: 0.5),
              colorBlendMode: BlendMode.darken,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: child,
                );
              },
            ),
          ),

          Positioned(
            top: 180.h,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/logo/logo_light_comp.png",
              height: 200.h,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: child,
                );
              },
            ),
          ),

          Positioned(
            bottom: 120.h,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: const Color(0xFFD6A00F),
                borderRadius: BorderRadius.circular(10.r),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Container(
                    width: 260.w,
                    height: 55.h,
                    alignment: Alignment.center,
                    child: Text(
                      "START EXPLORING",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Marcellus",
                        letterSpacing: 1.2,
                        fontSize: 16.sp,
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
