import 'package:flutter/material.dart';
import '../../../../../../../../../../core/constants/trip_options.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/option_chip.dart';
import '../widgets/quiz_scaffold.dart';

class TripTimeStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Widget searchHeader;
  final Widget accountMenu;

  const TripTimeStep({
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
      title: '4. Day or Night?',
      onNext: onNext,
      onBack: onBack,
      searchHeader: searchHeader,
      accountMenu: accountMenu,
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        children: TripOptions.tripTimes.map((item) {
          return OptionChip(
            label: item,
            isSelected: controller.plan.tripTime == item,
            onTap: () => controller.setTripTime(item),
          );
        }).toList(),
      ),
    );
  }
}