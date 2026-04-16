import 'package:flutter/material.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/quiz_scaffold.dart';

class DateLocationStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Widget searchHeader;
  final Widget accountMenu;

  const DateLocationStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
    required this.searchHeader,
    required this.accountMenu,
  });

  Future<void> _pickDate(
      BuildContext context, {
        required bool isFrom,
      }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );

    if (picked == null) return;

    if (isFrom) {
      controller.updateFromDate(picked);
    } else {
      controller.updateToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = controller.plan.fromDate?.toString().split(' ').first;
    final to = controller.plan.toDate?.toString().split(' ').first;

    return QuizScaffold(
      title: '1. Choose your dates and location',
      onNext: onNext,
      onBack: onBack,
      searchHeader: searchHeader,
      accountMenu: accountMenu,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickDate(context, isFrom: true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(from ?? 'Select from date'),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickDate(context, isFrom: false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(to ?? 'Select to date'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: controller.updateLocation,
            decoration: const InputDecoration(
              hintText: 'Enter your location',
            ),
          ),
        ],
      ),
    );
  }
}