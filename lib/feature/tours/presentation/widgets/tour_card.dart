import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../tours/domain/entities/tour_entity.dart';
import '../../../tours/presentation/pages/tour_detail_screen.dart';
import '../../../../core/services/currency_controller.dart';
import '../../../../core/services/currency_service.dart';

class TourCard extends StatelessWidget {
  final TourEntity tour;

  const TourCard({Key? key, required this.tour}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: tour.images.isNotEmpty
                      ? Image.network(
                          tour.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating badge
                      _buildRatingBadge(theme),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: CurrencyController.currency,
                        builder: (context, currency, _) {
                          return FutureBuilder<double>(
                            future: CurrencyService.instance.convertFromEGP(tour.price, currency),
                            builder: (context, snap) {
                              final label = snap.hasData
                                  ? CurrencyService.format(snap.data!, currency)
                                  : 'EGP ${tour.price.toStringAsFixed(0)}';
                              return Text(
                                label,
                                style: TextStyle(
                                  fontSize: 18,
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
                  const SizedBox(height: 8),
                  
                  // Metadata row
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(tour.meetingTime),
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'Up to ${tour.maxAttendees}',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  // Destinations chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tour.destinations.take(3).map((dest) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        dest,
                        style: TextStyle(
                          fontSize: 10,
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
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 2),
          Text(
            '${tour.rating.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            ' (${tour.reviewCount})',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: const Center(
        child: Icon(Icons.landscape, size: 48, color: Colors.grey),
      ),
    );
  }
}
