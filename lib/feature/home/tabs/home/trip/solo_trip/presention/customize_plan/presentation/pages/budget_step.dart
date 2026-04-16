import 'package:flutter/material.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/quiz_scaffold.dart';

class BudgetStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Widget searchHeader;
  final Widget accountMenu;

  const BudgetStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
    required this.searchHeader,
    required this.accountMenu,
  });

  @override
  Widget build(BuildContext context) {
    return QuizScaffold(
      title: '5. What is your budget?',
      onNext: onNext,
      onBack: onBack,
      searchHeader: searchHeader,
      accountMenu: accountMenu,
      nextText: 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Min Budget: ${controller.plan.minBudget.toInt()} EGP'),
          Slider(
            value: controller.plan.minBudget,
            min: 500,
            max: 20000,
            divisions: 39,
            onChanged: controller.setMinBudget,
          ),
          const SizedBox(height: 18),
          Text('Max Budget: ${controller.plan.maxBudget.toInt()} EGP'),
          Slider(
            value: controller.plan.maxBudget,
            min: 500,
            max: 30000,
            divisions: 59,
            onChanged: controller.setMaxBudget,
          ),
        ],
      ),
    );
  }
}