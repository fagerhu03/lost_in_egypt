import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/signup_screen.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool? isGuideSelected;

  void _navigateToSignup(BuildContext context, bool _) {
    // Both tourist + guide signups go through the same screen now — guides
    // apply later from their dashboard, not at signup time.
    Navigator.of(context).push(
      FadePageRoute(page: const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bgColor = const Color(0xFFFCFBE8);
    final textColor = const Color(0xff634700);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/pattern_comp.png"),
            fit: BoxFit.cover,
            opacity: 0.15, // lowered opacity for both
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 60.h),

              // LOGO
              Center(
                child: Image.asset(
                  "assets/logo/logo_colorful_comp.png",
                  height: 140.h,
                ),
              ),

              SizedBox(height: 40.h),

              Text(
                l10n.roleSelectionTitle,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 50.h),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Traveler Card
                      Expanded(
                        child: _RoleCard(
                          title: l10n.roleTraveler,
                          imagePath: "assets/icons/adventure.png",
                          isSelected: isGuideSelected == false,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              isGuideSelected = false;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                _navigateToSignup(context, false);
                                // reset selection after pushing to avoid red flash on back
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) setState(() => isGuideSelected = null);
                                });
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Guide Card
                      Expanded(
                        child: _RoleCard(
                          title: l10n.roleGuide,
                          imagePath: "assets/icons/guide.png",
                          isSelected: isGuideSelected == true,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              isGuideSelected = true;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                _navigateToSignup(context, true);
                                // reset selection after pushing to avoid red flash on back
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) setState(() => isGuideSelected = null);
                                });
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = const Color(0xFFFCFBE8);
    final shadowColor = Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05);
    final textColor = const Color(0xff634700);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: (isSelected ? 320 : 250).h,
        margin: EdgeInsets.only(bottom: (isSelected ? 0 : 30).h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSelected ? title.toUpperCase() : title,
              style: TextStyle(
                fontSize: (isSelected ? 20 : 16).sp,
                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: (isSelected ? 120 : 80).r,
              width: (isSelected ? 120 : 80).r,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
