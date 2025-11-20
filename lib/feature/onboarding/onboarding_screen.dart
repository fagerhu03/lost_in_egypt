import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/onboarding/start_screen.dart';

import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int pageIndex = 0;

  final pagesData = [
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

  void goNext() {
    if (pageIndex < 2) {
      setState(() {
        pageIndex++;
      });
    } else {
      // هنا تروحي للصفحة الأساسية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = pagesData[pageIndex];
    return Scaffold(
      body: OnboardingPage(
        image: current["image"]!,
        title: current["title"]!,
        subtitle: current["subtitle"]!,
        index: pageIndex,
        onNext: goNext,
      ),
    );
  }
}
