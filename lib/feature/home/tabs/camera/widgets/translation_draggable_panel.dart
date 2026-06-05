import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TranslationDraggablePanel extends StatelessWidget {
  final Map<String, String> translations;
  final String targetLang;

  const TranslationDraggablePanel({
    super.key,
    required this.translations,
    required this.targetLang,
  });

  @override
  Widget build(BuildContext context) {
    // Combine all translated values
    final String fullTranslation = translations.values
        .where((t) => t.isNotEmpty && t != "Translating...")
        .join('\n');

    if (fullTranslation.trim().isEmpty) return const SizedBox.shrink();

    final isArabic = targetLang == 'Arabic';

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.08,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.95), // Theme surface color
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Translation Result",
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.black26, height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Directionality(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    fullTranslation,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
