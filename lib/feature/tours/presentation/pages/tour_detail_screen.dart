import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tour_entity.dart';
import '../../../home/tabs/community/presentation/public_profile_screen.dart';
import '../../../auth/data/models/user.dart';
import 'booking_confirmation_screen.dart';

class TourDetailScreen extends StatelessWidget {
  final TourEntity tour;

  const TourDetailScreen({Key? key, required this.tour}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tour.title,
                style: const TextStyle(
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  fontFamily: 'Marcellus',
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: 'tour_image_${tour.id}',
                child: tour.images.isNotEmpty
                    ? Image.network(
                        tour.images.first,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.3),
                        colorBlendMode: BlendMode.darken,
                      )
                    : Container(color: Colors.grey),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Price and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${tour.price}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            tour.rating > 0 ? '${tour.rating} (${tour.reviewCount})' : 'New',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Metadata Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.calendar_month, 'Date & Time', DateFormat('MMM d, yyyy - h:mm a').format(tour.meetingTime)),
                        const Divider(height: 24),
                        _buildInfoRow(context, Icons.people, 'Max Attendees', '${tour.maxAttendees} people'),
                        const Divider(height: 24),
                        _buildInfoRow(context, Icons.location_on, 'Location', '${tour.meetingLatitude.toStringAsFixed(4)}, ${tour.meetingLongitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('About This Tour', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    tour.description,
                    style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.5),
                  ),

                  const SizedBox(height: 24),
                  const Text('Destinations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tour.destinations.map((dest) => Chip(
                      label: Text(dest),
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    )).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Text('Your Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      child: const Icon(Icons.person),
                    ),
                    title: const Text('View Guide Profile'),
                    subtitle: const Text('Tap to see credentials and reviews'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PublicProfileScreen(
                          user: UserModel(
                            id: tour.guideId,
                            email: 'guide@guide.com',
                            firstName: 'Guide',
                            lastName: 'Profile',
                            birthDate: DateTime.now(),
                            role: 'guide',
                            profileImageUrl: '',
                            createdAt: DateTime.now(),
                          ),
                        )),
                      );
                    },
                  ),

                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (_) => BookingConfirmationScreen(tour: tour)),
             );
          },
          child: const Text('Book Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
