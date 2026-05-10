import 'package:flutter/material.dart';

import '../../../../../../../../../../theme/theme.dart';

class QuizScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextText;
  final int stepIndex;
  final int totalSteps;

  const QuizScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onNext,
    required this.onBack,
    required this.stepIndex,
    this.totalSteps = 5,
    this.nextText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.darkPrimaryButton;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final labelColor = isDark ? AppColors.darkText : AppColors.lightBox;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── Header: back button + "Step X of 5" ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Step ${stepIndex + 1} of $totalSteps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.55),
                        letterSpacing: 0.5,
                        fontFamily: 'Marcellus',
                      ),
                    ),
                  ),
                  // Invisible balance for the back button
                  const SizedBox(width: 38),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Gold progress bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (stepIndex + 1) / totalSteps,
                  minHeight: 5,
                  backgroundColor: primary.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Content card ───────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Marcellus',
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(child: child),
                    const SizedBox(height: 14),

                    // ── Next / Finish ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: onNext,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              nextText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Marcellus',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              nextText == 'Finish'
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
