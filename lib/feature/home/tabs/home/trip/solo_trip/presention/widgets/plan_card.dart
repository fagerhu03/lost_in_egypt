import 'package:flutter/material.dart';
import 'package:lost_in_egypt/core/services/place_photos_service.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryButton
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            'Best for you',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightPrimaryButton,
                              fontFamily: 'Marcellus',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isBestMatch && isSaved) const SizedBox(width: 6),
                  if (isSaved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimaryButton
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightPrimaryButton
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_rounded,
                              size: 12,
                              color: AppColors.lightPrimaryButton),
                          const SizedBox(width: 3),
                          Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightPrimaryButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: _TripThumbnail(tripId: tripId, image: image),
                        )
                      : _TripThumbnail(tripId: tripId, image: image),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            fontFamily: 'Marcellus',
                          ),
                        ),
                        if (tagline != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            tagline!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 16,
                              color: index < rating
                                  ? AppColors.lightPrimaryButton
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (durationLabel != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 14,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                durationLabel!,
                                style: TextStyle(
                                  fontSize: 13,
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
      return Image.asset(widget.image, width: 140, height: 140, fit: BoxFit.cover);
    }

    final theme = TripTheme.forId(widget.tripId!);
    return SizedBox(
      width: 140,
      height: 140,
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
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(theme.icon, color: Colors.white, size: 13),
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
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(theme.icon, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
