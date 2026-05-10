import 'package:flutter/material.dart';
import '../../../../../../../../../../core/constants/trip_options.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/option_chip.dart';
import '../widgets/quiz_scaffold.dart';

const _areaEmojis = {
  'Cairo': '🏙',
  'Luxor': '🏺',
  'Aswan': '⛵',
  'Alexandria': '🌊',
  'Hurghada': '🤿',
  'Sharm El-Sheikh': '🐠',
  'Dahab': '🏕',
  'Siwa': '🌴',
  'Fayoum': '🦅',
  'North Coast': '🏖',
};

class AreaStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AreaStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return QuizScaffold(
      title: 'Where do you want to explore?',
      stepIndex: 2,
      onNext: onNext,
      onBack: onBack,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 12,
          children: TripOptions.areas.map((item) {
            return OptionChip(
              label: item,
              emoji: _areaEmojis[item],
              isSelected: controller.plan.areas.contains(item),
              onTap: () => controller.toggleArea(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
