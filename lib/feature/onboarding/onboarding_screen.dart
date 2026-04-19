import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/onboarding/start_screen.dart';
import 'triangle_panel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int index = 0;

  final pagesData = const [
    {
      "image": "assets/onboarding/onboard1.jpg",
      "title": "Welcome to Egypt",
      "subtitle":
      "Where every street tells a story,\nand every sunset feels like magic.\nGet Lost in wonders",
    },
    {
      "image": "assets/onboarding/onboard2.jpg",
      "title": "Plan Your Trip\nwith Ease",
      "subtitle":
      "Organize your itinerary, apply for your visa,\nand book unique experiences and events\nacross Egypt effortlessly",
    },
    {
      "image": "assets/onboarding/onboard3.jpg",
      "title": "Your Adventure\nStart!",
      "subtitle":
      "You're all set! Begin your adventure and\nexplore Egypt like never before.",
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache all onboarding images to avoid flash on first display
    for (final page in pagesData) {
      precacheImage(AssetImage(page['image']!), context);
    }
  }

  void goNext() {
    if (index < pagesData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = pagesData[index];

    return Scaffold(
      body: Stack(
        children: [
          // ✅ الخلفية بس هي اللي بتسوايب
          PageView.builder(
            controller: _controller,
            itemCount: pagesData.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (context, i) {
              return Image.asset(
                pagesData[i]["image"]!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.45),
                colorBlendMode: BlendMode.darken,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return Container(color: const Color(0xFF0B1D26));
                },
              );
            },
          ),

          // Bottom panel: allow horizontal swipes to pass through to the PageView
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200 && index < pagesData.length - 1) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                  );
                } else if (velocity > 200 && index > 0) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: TrianglePanel(
                title: current["title"]!,
                subtitle: current["subtitle"]!,
                index: index,
                total: pagesData.length,
                onNext: goNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
