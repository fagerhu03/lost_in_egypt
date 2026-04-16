import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/presentation/pages/quiz_flow_screen.dart';
import '../../../../../../../../theme/theme.dart';
import '../../../../../navigator/widget/account_menu_button.dart';
import '../../../../../navigator/widget/search_header.dart';

class CustomizePlanCard extends StatefulWidget {
  final VoidCallback? onTap;

  const CustomizePlanCard({super.key, this.onTap});

  @override
  State<CustomizePlanCard> createState() => _CustomizePlanCardState();
}

class _CustomizePlanCardState extends State<CustomizePlanCard> {
  String? _profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizFlowScreen(
              searchHeader: SearchHeader(onSignOut: () {}),
              accountMenu: AccountMenuButton(onSignOut: () {}),
            ),
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
              color: isDark ? AppColors.darkPrimaryButton : AppColors.lightBox,
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
                  color: isDark ? AppColors.darkText : AppColors.lightBox,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
