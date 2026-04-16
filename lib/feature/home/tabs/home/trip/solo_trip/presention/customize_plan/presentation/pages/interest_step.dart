import 'package:flutter/material.dart';
import '../../../../../../../../../../core/constants/trip_options.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/option_chip.dart';
import '../widgets/quiz_scaffold.dart';

class InterestStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Widget searchHeader;
  final Widget accountMenu;

  const InterestStep({
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
      title: '2. What is your interest?',
      onNext: onNext,
      onBack: onBack,
      searchHeader: searchHeader,
      accountMenu: accountMenu,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 12,
          children: TripOptions.interests.map((item) {
            return OptionChip(
              label: item,
              isSelected: controller.plan.interests.contains(item),
              onTap: () => controller.toggleInterest(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}