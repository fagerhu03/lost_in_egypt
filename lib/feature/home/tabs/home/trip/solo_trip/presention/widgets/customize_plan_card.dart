import 'package:flutter/material.dart';
import '../../../../../../../../theme/theme.dart';
import '../customize_plan_screen.dart';

class CustomizePlanCard extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomizePlanCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomizePlanScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkPatternOverlay
              : const Color(0xFFFFFEF0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 47,
              color: isDark
                  ? AppColors.darkPrimaryButton
                  : AppColors.lightBox,
            ),
            const SizedBox(width: 18),
            Flexible(
              child: Text(
                "Customize your\nown plan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkText
                      : AppColors.lightBox,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}