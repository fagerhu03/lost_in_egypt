import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../tours/domain/entities/tour_entity.dart';
import '../../../tours/presentation/pages/tour_detail_screen.dart';
import '../../../../core/services/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/widgets/shimmer_image.dart';

class TourCard extends StatelessWidget {
  final TourEntity tour;

  const TourCard({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      elevation: 0,
      shadowColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Banner
            Hero(
              tag: 'tour_image_${tour.id}',
              child: ShimmerImage(
                url: tour.images.isNotEmpty ? tour.images.first : null,
                height: 180.h,
                width: double.infinity,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                fallbackIcon: Icons.image_not_supported,
                fallbackBackgroundColor: Colors.grey[300],
                fallbackIconColor: Colors.grey[600],
                fallbackIconSize: 50.r,
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Rating badge
                      _buildRatingBadge(theme),
                      SizedBox(width: 12.w),
                      ValueListenableBuilder<String>(
                        valueListenable: CurrencyController.currency,
                        builder: (context, currency, _) {
                          return FutureBuilder<double>(
                            future: CurrencyService.instance.convertFromEGP(tour.price, currency),
                            builder: (context, snap) {
                              final label = snap.hasData
                                  ? CurrencyService.format(snap.data!, currency)
                                  : snap.hasError
                                      ? 'EGP ${tour.price.toStringAsFixed(0)} ΓÜá'
                                      : 'EGP ${tour.price.toStringAsFixed(0)}';
                              return Text(
                                label,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Metadata row
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      SizedBox(width: 4.w),
                      Text(
                        DateFormat('MMM d, yyyy').format(tour.meetingTime),
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      SizedBox(width: 16.w),
                      Icon(Icons.people, size: 16.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      SizedBox(width: 4.w),
                      Text(
                        'Up to ${tour.maxAttendees}',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),
                  // Destinations chips
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: tour.destinations.take(3).map((dest) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        dest,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )).toList(),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }

  Widget _buildRatingBadge(ThemeData theme) {
    final hasRating = tour.rating > 0 && !tour.rating.isNaN && !tour.rating.isInfinite && tour.reviewCount > 0;
    if (hasRating) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 16.r),
          SizedBox(width: 2.w),
          Text(
            tour.rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            ' (${tour.reviewCount})',
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }

}
