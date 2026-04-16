import 'package:flutter/material.dart';

import '../../../../../../../../../../theme/theme.dart';


class QuizScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextText;
  final Widget searchHeader;
  final Widget accountMenu;

  const QuizScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onNext,
    required this.onBack,
    required this.searchHeader,
    required this.accountMenu,
    this.nextText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color:
                      isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: searchHeader),
                  const SizedBox(width: 8),
                  accountMenu,
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPatternOverlay
                      : AppColors.lightPatternOverlay,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz:',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightBox,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1.2,
                      width: double.infinity,
                      color: AppColors.darkPrimaryButton,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(child: child),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkPrimaryButton,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onNext,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(nextText),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
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