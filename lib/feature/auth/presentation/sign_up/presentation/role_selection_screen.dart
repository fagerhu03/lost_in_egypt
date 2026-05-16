import 'package:flutter/material.dart';
import 'package:lost_in_egypt/core/utils/page_transitions.dart';
import 'package:lost_in_egypt/feature/auth/presentation/sign_up/presentation/signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool? isGuideSelected;

  void _navigateToSignup(BuildContext context, bool isGuide) {
    Navigator.of(context).push(
      FadePageRoute(
        page: SignupScreen(isGuidePreselected: isGuide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bool isDark = false; // Forced to light mode as requested
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFCFBE8);
    final textColor = isDark ? Colors.white70 : const Color(0xff634700);

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
              const SizedBox(height: 60),

              // LOGO
              Center(
                child: Image.asset(
                  "assets/logo/logo_colorful_comp.png",
                  height: 140,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Are you a...",
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "Marcellus",
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 50),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Traveler Card
                      Expanded(
                        child: _RoleCard(
                          title: "TRAVELER!",
                          imagePath: "assets/icons/adventure.png",
                          isSelected: isGuideSelected == false,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              isGuideSelected = false;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
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
                      const SizedBox(width: 16),
                      // Guide Card
                      Expanded(
                        child: _RoleCard(
                          title: "GUIDE!",
                          imagePath: "assets/icons/guide.png",
                          isSelected: isGuideSelected == true,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              isGuideSelected = true;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
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
              const SizedBox(height: 60),
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
    const bool isDark = false; // Forced to light mode as requested
    final cardColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFCFBE8);
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05);
    final textColor = isDark ? Colors.white : const Color(0xff634700);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: isSelected ? 320 : 250,
        margin: EdgeInsets.only(bottom: isSelected ? 0 : 30),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
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
                fontSize: isSelected ? 20 : 16,
                fontFamily: "Marcellus",
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 120 : 80,
              width: isSelected ? 120 : 80,
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
