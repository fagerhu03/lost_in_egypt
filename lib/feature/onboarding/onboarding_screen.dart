import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/onboarding/start_screen.dart';
import 'triangle_panel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _pages = [
    _PageData(
      image: 'assets/onboarding/onboard1.jpg',
      title: 'Welcome to Egypt',
      subtitle:
          'Where every street tells a story,\nand every sunset feels like magic.\nGet Lost in wonders',
    ),
    _PageData(
      image: 'assets/onboarding/onboard2.jpg',
      title: 'Plan Your Trip\nwith Ease',
      subtitle:
          'Organise your itinerary, apply for your visa,\nand book unique experiences and events\nacross Egypt effortlessly',
    ),
    _PageData(
      image: 'assets/onboarding/onboard3.jpg',
      title: 'Your Adventure\nStarts!',
      subtitle:
          "You're all set! Begin your adventure and\nexplore Egypt like never before.",
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final page in _pages) {
      precacheImage(AssetImage(page.image), context);
    }
    // Warm the decode cache for StartScreen's background so it's ready
    // before the user taps "Get Started" — prevents the image pop-in.
    precacheImage(
      ResizeImage(const AssetImage('assets/onboarding/start_screen.png'), width: 1080),
      context,
    );
    precacheImage(const AssetImage('assets/logo/logo_light_comp.png'), context);
  }

  void _goNext() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _goToStart();
    }
  }

  void _goToStart() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final current = _pages[_index];

    return Scaffold(
      body: Stack(
        children: [
          // Background PageView — swipeable
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Image.asset(
              _pages[i].image,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.darken,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return Container(color: const Color(0xFF0B1D26));
              },
            ),
          ),

          // Skip button — hidden on last slide
          if (!isLast)
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 12,
              end: 20.w,
              child: TextButton(
                onPressed: _goToStart,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.85),
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(fontSize: 14.sp, fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo']),
                ),
              ),
            ),

          // Bottom panel — passes swipe gestures through to PageView
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -200 && _index < _pages.length - 1) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                  );
                } else if (v > 200 && _index > 0) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: TrianglePanel(
                title: current.title,
                subtitle: current.subtitle,
                index: _index,
                total: _pages.length,
                onNext: _goNext,
                buttonLabel: isLast ? 'Get Started' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String image;
  final String title;
  final String subtitle;
  const _PageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
