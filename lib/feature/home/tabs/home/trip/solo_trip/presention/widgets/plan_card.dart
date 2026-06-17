import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/services/place_photos_service.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../../../../../theme/theme.dart';
import 'trip_theme.dart';

class PlanCard extends StatelessWidget {
  final String title;
  final String location;
  final int rating;
  final String image;
  final VoidCallback? onTap;

  /// When true, shows a gold "Best for you ✨" badge at the top of the card.
  final bool isBestMatch;

  /// Short tagline shown below the title, e.g. "Walk through 1,400 years…".
  final String? tagline;

  /// Duration pill shown below the rating, e.g. "2 days".
  final String? durationLabel;

  /// Optional Hero tag — when provided the thumbnail animates into the detail screen.
  final String? heroTag;

  /// Trip id used to look up the gradient theme. When provided the thumbnail
  /// shows the trip's gradient + emoji instead of the asset image.
  final String? tripId;

  /// When true, shows a small filled bookmark badge so the user can spot
  /// trips they've already saved at a glance.
  final bool isSaved;

  const PlanCard({
    super.key,
    required this.title,
    required this.location,
    required this.rating,
    required this.image,
    this.onTap,
    this.isBestMatch = false,
    this.tagline,
    this.durationLabel,
    this.heroTag,
    this.tripId,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor =
        isDark ? AppColors.darkBox.withValues(alpha: 0.8) : const Color(0xFFF3EEE2);

    final titleColor = isDark ? AppColors.darkText : AppColors.lightBox;

    final subtitleColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.6)
        : const Color(0xFF9A7A4D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: isBestMatch
              ? Border.all(color: AppColors.lightPrimaryButton, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBestMatch || isSaved) ...[
              Row(
                children: [
                  if (isBestMatch)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryButton
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨', style: TextStyle(fontSize: 12.sp)),
                          SizedBox(width: 4.w),
                          Text(
                            AppLocalizations.of(context).soloBestForYou,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightPrimaryButton,
                              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isBestMatch && isSaved) SizedBox(width: 6.w),
                  if (isSaved)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryButton
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.lightPrimaryButton
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_rounded,
                              size: 12.r,
                              color: AppColors.lightPrimaryButton),
                          SizedBox(width: 3.w),
                          Text(
                            AppLocalizations.of(context).soloStatusSaved,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightPrimaryButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: _TripThumbnail(tripId: tripId, image: image),
                        )
                      : _TripThumbnail(tripId: tripId, image: image),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          ),
                        ),
                        if (tagline != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            tagline!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: subtitleColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 16.r,
                              color: index < rating
                                  ? AppColors.lightPrimaryButton
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14.r,
                              color: subtitleColor,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (durationLabel != null) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 14.r,
                                color: subtitleColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                durationLabel!,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip thumbnail — loads a real Places API photo, gradient while loading ─────

class _TripThumbnail extends StatefulWidget {
  final String? tripId;
  final String image;

  const _TripThumbnail({required this.tripId, required this.image});

  @override
  State<_TripThumbnail> createState() => _TripThumbnailState();
}

class _TripThumbnailState extends State<_TripThumbnail> {
  Future<String?>? _photoFuture;

  @override
  void initState() {
    super.initState();
    if (widget.tripId != null) {
      final theme = TripTheme.forId(widget.tripId!);
      _photoFuture = PlacePhotosService.instance
          .getPhotoUrl(widget.tripId!, theme.photoQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripId == null) {
      return Image.asset(widget.image, width: 140.r, height: 140.r, fit: BoxFit.cover);
    }

    final theme = TripTheme.forId(widget.tripId!);
    return SizedBox(
      width: 140.r,
      height: 140.r,
      child: FutureBuilder<String?>(
        future: _photoFuture,
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Gradient sits behind the image as a colour-matched background
                _GradientBox(theme: theme),
                ShimmerImage(
                  url: url,
                  fit: BoxFit.cover,
                ),
                // Subtle icon badge so the trip type is still visible
                PositionedDirectional(
                  end: 8.w,
                  bottom: 8.h,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(theme.icon, color: Colors.white, size: 13.r),
                  ),
                ),
              ],
            );
          }
          return _GradientBox(theme: theme);
        },
      ),
    );
  }
}

class _GradientBox extends StatelessWidget {
  final TripTheme theme;
  const _GradientBox({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140.r,
      height: 140.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -16.h,
            end: -16.w,
            child: Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(theme.icon, color: Colors.white, size: 28.r),
            ),
          ),
        ],
      ),
    );
  }
}
