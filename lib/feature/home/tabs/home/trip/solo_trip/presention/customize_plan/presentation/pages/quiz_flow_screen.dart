import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/services/recommendation_mappings.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/presentation/pages/trip_time_step.dart';
import '../manager/trip_planner_controller.dart';
import 'area_step.dart';
import 'budget_step.dart';
import 'date_location_step.dart';
import 'interest_step.dart';
import 'result_screen.dart';

class QuizFlowScreen extends StatefulWidget {
  const QuizFlowScreen({super.key});

  @override
  State<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends State<QuizFlowScreen> {
  final PageController _pageController = PageController();
  final TripPlannerController controller = TripPlannerController();

  void nextPage() {
    // TripTimeStep (page 3) requires at least one selection.
    if (controller.currentPage == 3 && controller.plan.tripTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).soloSelectDayNight),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (controller.currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _onFinish() {
    final plan = controller.plan;

    // Fire-and-forget: apply quiz answers to taste vector
    final answers = RecommendationMappings.answersFromSelections(
      selectedInterests: plan.interests,
      selectedAreas: plan.areas,
    );
    unawaited(RecommendationService.applyQuizAnswers(answers));

    // Fire-and-forget: warm-start from existing Firestore history.
    // Rate-limited server-side (1/day), so calling every quiz completion is safe.
    unawaited(RecommendationService.warmStart());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(plan: plan),
      ),
    );
  }

  void backPage() {
    if (controller.currentPage == 0) {
      Navigator.pop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: controller.setPage,
        children: [
          DateLocationStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
          ),
          InterestStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
          ),
          AreaStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
          ),
          TripTimeStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
          ),
          BudgetStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
          ),
        ],
      ),
    );
  }
}
