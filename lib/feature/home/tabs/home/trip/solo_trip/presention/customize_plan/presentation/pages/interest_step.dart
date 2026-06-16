import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../../../../../../../core/constants/trip_options.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/option_chip.dart';
import '../widgets/quiz_scaffold.dart';

const _interestEmojis = {
  'Shopping': '🛍',
  'Nightlife': '🌙',
  'Monuments': '🏛',
  'Museums': '🏺',
  'Nature & Parks': '🌿',
  'Beaches': '🏖',
  'Culture & Traditions': '🎭',
  'Entertainment': '🎡',
  'Adventure Activities': '🧗',
  'Local Experiences': '🍽',
};

class InterestStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const InterestStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return QuizScaffold(
      title: AppLocalizations.of(context).soloQuizInterestsTitle,
      stepIndex: 1,
      onNext: onNext,
      onBack: onBack,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10.w,
          runSpacing: 12.h,
          children: TripOptions.interests.map((item) {
            return OptionChip(
              label: item,
              emoji: _interestEmojis[item],
              isSelected: controller.plan.interests.contains(item),
              onTap: () => controller.toggleInterest(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
