import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../../../../auth/data/models/user.dart';

class GuideCard extends StatelessWidget {
  final UserModel guide;

  const GuideCard({
    super.key,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor =
    isDark ? AppColors.darkText : AppColors.lightText;

    final labelColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.65)
        : AppColors.lightText.withValues(alpha: 0.55);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        // ✅ Brighter box in light mode
        color: isDark
            ? AppColors.darkBox.withValues(alpha: 0.65)
            : Color(0xffFFFEF0),

        borderRadius: BorderRadius.circular(14.r),

        border: Border.all(
          color: isDark
              ? AppColors.darkText.withValues(alpha: 0.12)
              : const Color(0xFFE6D8B8),
        ),

        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ShimmerImage(
                    url: guide.profileImageUrl,
                    width: 82.r,
                    height: 82.r,
                    borderRadius: BorderRadius.circular(14.r),
                    fallbackIcon: Icons.person,
                    fallbackBackgroundColor: isDark
                        ? const Color(0xFF3E2C1E)
                        : const Color(0xFF7A4B1D),
                    fallbackIconColor: const Color(0xFFEDE9D9),
                    fallbackIconSize: 52.r,
                  ),
                  PositionedDirectional(
                    top: 4.h,
                    end: 4.w,
                    child: Container(
                      width: 18.r,
                      height: 18.r,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black54 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade300,
                        size: 12.r,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${guide.firstName} ${guide.lastName}'.trim(),
                      style: TextStyle(
                        fontSize: 28.sp,
                        color: titleColor,
                        height: 0.95,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (guide.reviewCount == 0)
                      Text(
                        "New Guide",
                        style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.w600)
                      )
                    else
                      Row(
                        children: [
                          Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 16.sp)),
                          Icon(Icons.star, color: Colors.amber, size: 18.r),
                          Text(' (${guide.reviewCount})', style: TextStyle(color: labelColor, fontSize: 14.sp)),
                        ],
                      ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 15.r,
                          color: titleColor,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: titleColor,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                    // Removed contact for price
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(
            height: 1.h,
            color: isDark
                ? AppColors.darkText.withValues(alpha: 0.15)
                : AppColors.lightText.withValues(alpha: 0.15),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Language',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  guide.certifiedLanguages.isNotEmpty ? guide.certifiedLanguages.join(', ') : 'Arabic, English',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Time',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Flexible',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
