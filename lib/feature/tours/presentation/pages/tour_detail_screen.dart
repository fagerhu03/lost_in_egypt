import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'full_screen_tour_map_screen.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../auth/data/models/user.dart';
import 'booking_confirmation_screen.dart';
import '../../../../core/widgets/universal_report_dialog.dart';
import '../../../admin/data/models/report_model.dart';
import '../../../admin/domain/repositories/reports_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/account_screen.dart';

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
            actions: [
              // Hide report button if the user is the guide who created the tour
              if (FirebaseAuth.instance.currentUser?.uid != tour.guideId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') {
                      UniversalReportDialog.show(
                        context,
                        reportType: ReportType.tour,
                        reportedItemId: tour.id,
                        reportedItemOwnerId: tour.guideId,
                        repository: GetIt.I<ReportsRepository>(),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Report Tour'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tour.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                  fontFamily: 'Marcellus',
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: 'tour_image_${tour.id}',
                child: tour.images.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: tour.images.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade300),
                            errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
                          ),
                          // Dark gradient overlay to ensure text visibility
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ],
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
                            tour.rating > 0 && !tour.rating.isNaN && !tour.rating.isInfinite
                              ? '${tour.rating.toStringAsFixed(1)} (${tour.reviewCount})'
                              : 'New',
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
                        _buildInfoRow(context, Icons.location_on, 'Location', tour.meetingLocationName),
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

                  // Map Preview
                  const SizedBox(height: 24),
                  const Text('Meetup Location & Route', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(tour.meetingLatitude, tour.meetingLongitude),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('meeting_point'),
                              position: LatLng(tour.meetingLatitude, tour.meetingLongitude),
                              infoWindow: InfoWindow(title: tour.meetingLocationName, snippet: 'Meetup Point'),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FullScreenTourMapScreen(tour: tour)),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, size: 20),
                                SizedBox(width: 4),
                                Text('Tap to expand', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Schedule Display
                  const SizedBox(height: 24),
                  const Text('Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildScheduleRow(context, tour.frequency),

                  // Image Gallery
                  if (tour.images.length > 1) ...[
                    const SizedBox(height: 24),
                    const Text('Gallery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tour.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.hardEdge,
                              child: InkWell(
                                onTap: () => _showGalleryViewer(context, tour.images, index),
                                child: Ink.image(
                                  image: CachedNetworkImageProvider(tour.images[index]),
                                  width: 160,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Your Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _GuideInfoTile(guideId: tour.guideId),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ReviewsSection(tour: tour),

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
        child: FirebaseAuth.instance.currentUser?.uid == tour.guideId
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: null,
                child: const Text('This is your tour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )
            : ElevatedButton(
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

  Widget _buildScheduleRow(BuildContext context, String frequency) {
    if (frequency == 'One-Time') {
      return Text('This is a one-time tour.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
    }
    
    final days = frequency.split(', ');
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allDays.map((day) {
        final isSelected = days.contains(day);
        return Chip(
          label: Text(day),
          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void _showGalleryViewer(BuildContext context, List<String> images, int initialIndex) {
  showDialog(
    context: context,
    builder: (_) => _GalleryViewerDialog(images: images, initialIndex: initialIndex),
  );
}

class _GalleryViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryViewerDialog({required this.images, required this.initialIndex});

  @override
  State<_GalleryViewerDialog> createState() => _GalleryViewerDialogState();
}

class _GalleryViewerDialogState extends State<_GalleryViewerDialog> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Image counter
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideInfoTile extends StatefulWidget {
  final String guideId;
  const _GuideInfoTile({required this.guideId});

  @override
  State<_GuideInfoTile> createState() => _GuideInfoTileState();
}

class _GuideInfoTileState extends State<_GuideInfoTile> {
  UserModel? _guide;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchGuide();
  }

  Future<void> _fetchGuide() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.guideId).get();
      if (doc.exists && mounted) {
        setState(() {
          _guide = UserModel.fromMap(doc.data()!, doc.id);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_guide == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: const Icon(Icons.person),
        ),
        title: const Text('Guide not found'),
      );
    }
    final guide = _guide!;
    final displayName = '${guide.firstName} ${guide.lastName}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        backgroundImage: guide.profileImageUrl.isNotEmpty ? CachedNetworkImageProvider(guide.profileImageUrl) : null,
        child: guide.profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(displayName.isNotEmpty ? displayName : 'Your Guide', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: guide.reviewCount > 0
          ? Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text('${guide.rating.toStringAsFixed(1)} (${guide.reviewCount} reviews)', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            )
          : Text('Verified Guide', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: guide)),
        );
      },
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final TourEntity tour;

  const _ReviewsSection({required this.tour});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (currentUid != null && currentUid != tour.guideId)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('tourId', isEqualTo: tour.id)
                    .where('userId', isEqualTo: currentUid)
                    .where('status', isEqualTo: 'confirmed')
                    .get(),
                builder: (context, snapshot) {
                  final hasBooked = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  if (!hasBooked) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _showAddReviewDialog(context, tour.id),
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Write a Review'),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tours')
              .doc(tour.id)
              .collection('reviews')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Error loading reviews');
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No reviews yet. Be the first to review!', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final reviewDoc = docs[index];
                final data = reviewDoc.data() as Map<String, dynamic>;
                final rating = (data['rating'] ?? 0.0).toDouble();
                final text = data['text'] ?? '';
                final userName = data['userName'] ?? 'Anonymous';
                final userId = data['userId'] as String?;
                final userImage = data['userImage'] as String?;
                final isOwnReview = userId == currentUid;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _navigateToReviewerProfile(context, userId),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          backgroundImage: userImage != null && userImage.isNotEmpty ? CachedNetworkImageProvider(userImage) : null,
                          child: userImage == null || userImage.isEmpty ? const Icon(Icons.person, size: 20) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Review Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _navigateToReviewerProfile(context, userId),
                                    child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating ? Icons.star : Icons.star_border,
                                      size: 14,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 4),
                                // Action menu
                                _buildReviewActionMenu(context, reviewDoc.id, data, isOwnReview),
                              ],
                            ),
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewActionMenu(BuildContext context, String reviewDocId, Map<String, dynamic> data, bool isOwnReview) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditReviewDialog(context, tour.id, reviewDocId, data);
            break;
          case 'delete':
            _showDeleteReviewConfirmation(context, tour.id, reviewDocId, data);
            break;
          case 'report':
            UniversalReportDialog.show(
              context,
              reportType: ReportType.comment,
              reportedItemId: '${tour.id}_$reviewDocId',
              repository: GetIt.I<ReportsRepository>(),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        if (isOwnReview) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Review')]),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Review', style: TextStyle(color: Colors.red))]),
          ),
        ],
        if (!isOwnReview)
          const PopupMenuItem(
            value: 'report',
            child: Row(children: [Icon(Icons.flag, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Report Review')]),
          ),
      ],
    );
  }

  void _navigateToReviewerProfile(BuildContext context, String? userId) async {
    if (userId == null) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (context.mounted) Navigator.pop(context);
      if (doc.exists && context.mounted) {
        final u = UserModel.fromMap(doc.data()!, doc.id);
        if (u.id == currentUid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: u)));
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showEditReviewDialog(BuildContext context, String tourId, String reviewDocId, Map<String, dynamic> oldData) {
    double selectedRating = (oldData['rating'] ?? 5.0).toDouble();
    final textController = TextEditingController(text: oldData['text'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                         icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Update your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    try {
                      Navigator.pop(context);
                      final oldRating = (oldData['rating'] ?? 0.0).toDouble();
                      final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final tourDoc = await transaction.get(tourRef);
                        if (!tourDoc.exists) return;

                        final tData = tourDoc.data()!;
                        final int count = (tData['reviewCount'] ?? 0) as int;
                        double currentAvg = (tData['rating'] ?? 0.0).toDouble();
                        if (currentAvg.isNaN || currentAvg.isInfinite) currentAvg = 0.0;

                        // Recalculate: remove old rating contribution, add new
                        double newAvg = count > 0 ? ((currentAvg * count) - oldRating + selectedRating) / count : selectedRating;
                        if (newAvg.isNaN || newAvg.isInfinite) newAvg = selectedRating;

                        transaction.update(tourRef.collection('reviews').doc(reviewDocId), {
                          'rating': selectedRating,
                          'text': textController.text.trim(),
                        });

                        transaction.update(tourRef, {'rating': newAvg});
                      });
                    } catch (e) {
                      debugPrint('Error editing review: $e');
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteReviewConfirmation(BuildContext context, String tourId, String reviewDocId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text('Are you sure you want to delete your review? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  final oldRating = (data['rating'] ?? 0.0).toDouble();
                  final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);

                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final tourDoc = await transaction.get(tourRef);
                    if (!tourDoc.exists) return;

                    final tData = tourDoc.data()!;
                    final int count = (tData['reviewCount'] ?? 0) as int;
                    double currentAvg = (tData['rating'] ?? 0.0).toDouble();
                    if (currentAvg.isNaN || currentAvg.isInfinite) currentAvg = 0.0;

                    final newCount = count - 1;
                    double newAvg = newCount > 0 ? ((currentAvg * count) - oldRating) / newCount : 0.0;
                    if (newAvg.isNaN || newAvg.isInfinite) newAvg = 0.0;

                    transaction.delete(tourRef.collection('reviews').doc(reviewDocId));
                    transaction.update(tourRef, {
                      'reviewCount': newCount,
                      'rating': newAvg,
                    });
                  });
                } catch (e) {
                  debugPrint('Error deleting review: $e');
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog(BuildContext context, String tourId) {
    double selectedRating = 5.0;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                         icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to review.')));
                      return;
                    }
                    
                    try {
                      Navigator.pop(context); // close dialog
                      final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);
                      final docRef = tourRef.collection('reviews').doc();
                      
                      final userName = user.displayName?.isNotEmpty == true ? user.displayName : 'Traveler';

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final tourDoc = await transaction.get(tourRef);
                        if (!tourDoc.exists) return;

                        final data = tourDoc.data()!;
                        final int currentCount = (data['reviewCount'] ?? 0) as int;
                        double currentRating = (data['rating'] ?? 0.0).toDouble();
                        if (currentRating.isNaN || currentRating.isInfinite) currentRating = 0.0;

                        final newCount = currentCount + 1;
                        double newRating = ((currentRating * currentCount) + selectedRating) / newCount;
                        if (newRating.isNaN || newRating.isInfinite) newRating = selectedRating;

                        transaction.set(docRef, {
                          'userId': user.uid,
                          'userName': userName,
                          'userImage': user.photoURL ?? '',
                          'rating': selectedRating,
                          'text': textController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        transaction.update(tourRef, {
                          'reviewCount': newCount,
                          'rating': newRating,
                        });
                      });
                      
                    } catch (e) {
                      debugPrint('Error adding review: $e');
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
