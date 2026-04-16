import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/presentation/pages/trip_time_step.dart';
import '../manager/trip_planner_controller.dart';
import 'area_step.dart';
import 'budget_step.dart';
import 'date_location_step.dart';
import 'interest_step.dart';
import 'result_screen.dart';


class QuizFlowScreen extends StatefulWidget {
  final Widget searchHeader;
  final Widget accountMenu;

  const QuizFlowScreen({
    super.key,
    required this.searchHeader,
    required this.accountMenu,
  });

  @override
  State<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends State<QuizFlowScreen> {
  final PageController _pageController = PageController();
  final TripPlannerController controller = TripPlannerController();

  void nextPage() {
    if (controller.currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            prompt: controller.buildPrompt(),
          ),
        ),
      );
    }
  }

  void backPage() {
    if (controller.currentPage == 0) {
      Navigator.pop(context); // يرجع لـ SoloTripScreen
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
            searchHeader: widget.searchHeader,
            accountMenu: widget.accountMenu,
          ),
          InterestStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
            searchHeader: widget.searchHeader,
            accountMenu: widget.accountMenu,
          ),
          AreaStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
            searchHeader: widget.searchHeader,
            accountMenu: widget.accountMenu,
          ),
          TripTimeStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
            searchHeader: widget.searchHeader,
            accountMenu: widget.accountMenu,
          ),
          BudgetStep(
            controller: controller,
            onNext: nextPage,
            onBack: backPage,
            searchHeader: widget.searchHeader,
            accountMenu: widget.accountMenu,
          ),
        ],
      ),
    );
  }
}