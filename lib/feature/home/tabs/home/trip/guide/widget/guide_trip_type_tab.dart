import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class GuideTripTypeTab extends StatelessWidget {
  final String title;
  final bool selected;

  const GuideTripTypeTab({
    super.key,
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ✅ Selected background changes with theme
    final activeColor = isDark ? AppColors.darkBox : AppColors.lightBox.withOpacity(0.5);

    // ✅ Unselected background also theme-aware + lighter
    final inactiveBg = isDark
        ? AppColors.darkBox.withOpacity(0.18)
        : AppColors.lightPatternOverlay.withOpacity(0.40);

    // ✅ Text colors
    final inactiveText = isDark
        ? AppColors.darkText.withOpacity(0.65)
        : const Color(0xFF7A4B1D).withOpacity(0.80);

    final selectedTextColor = isDark
        ? AppColors.darkText
        : AppColors.lightFieldText; // white

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkText.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? selectedTextColor : inactiveText,
            fontSize: 20,
            height: 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}