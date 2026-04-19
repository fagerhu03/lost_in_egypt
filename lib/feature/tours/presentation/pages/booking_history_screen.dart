import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../feature/home/tabs/map/data/datasources/map_focus_service.dart';
import '../../../../feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/tour_model.dart';
import '../../../auth/data/models/user.dart';
import '../../../../feature/home/tabs/community/presentation/universal_profile_screen.dart';
import 'booking_confirmation_screen.dart';
import '../../../../feature/reviews/data/datasources/reviews_data_source.dart';
import '../../../../feature/reviews/data/models/review_model.dart';
import '../../../../feature/home/notification/data/datasources/notifications_data_source.dart';
import '../../../../feature/home/notification/data/models/notification_model.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings'), centerTitle: true),
        body: const Center(child: Text('Please log in')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _BookingTab(userId: user.uid, upcoming: true),
            _BookingTab(userId: user.uid, upcoming: false),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab content (upcoming / past)
// ─────────────────────────────────────────────────────────────────────────────

class _BookingTab extends StatefulWidget {
  final String userId;
  final bool upcoming;

  const _BookingTab({required this.userId, required this.upcoming});

  @override
  State<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<_BookingTab> {
  static const int _pageSize = 10;
  int _limit = _pageSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('date', descending: !widget.upcoming)
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                const Text('Error loading bookings'),
                const SizedBox(height: 8),
                Text(
                  'Check the debug console for a Firestore index link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Use sessionDate if set (recurring tours), otherwise fall back to date
          final sessionDate = (data['sessionDate'] as Timestamp?)?.toDate();
          final date = sessionDate ?? (data['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          final status = data['status'] ?? '';
          if (status == 'cancelled' || status == 'tour_deleted') return !widget.upcoming;
          return widget.upcoming ? date.isAfter(now) : date.isBefore(now);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.upcoming ? Icons.explore_outlined : Icons.history,
                  size: 80,
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.upcoming ? 'No upcoming tours' : 'No past tours',
                  style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                if (widget.upcoming) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Explore tours and book your next adventure!',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.35)),
                  ),
                ],
              ],
            ),
          );
        }

        // Show Load More only if we received exactly _limit raw docs (more may exist)
        final hasMore = allDocs.length == _limit;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: docs.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == docs.length) {
              return TextButton(
                onPressed: () => setState(() => _limit += _pageSize),
                child: const Text('Load more'),
              );
            }
            final data = docs[i].data() as Map<String, dynamic>;
            return _BookingCard(bookingId: docs[i].id, data: data, upcoming: widget.upcoming);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact booking card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final bool upcoming;

  const _BookingCard({required this.bookingId, required this.data, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'pending';
    // Use sessionDate if set (recurring tours), fall back to date
    final sessionDate = (data['sessionDate'] as Timestamp?)?.toDate();
    final date = sessionDate ?? (data['date'] as Timestamp?)?.toDate();
    final tourId = data['tourId'] ?? '';
    final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
    final totalEGP = (data['totalAmountEGP'] as num?)?.toDouble() ?? 0;

    final statusColor = {
      'confirmed': Colors.green,
      'cancelled': Colors.red,
      'pending': Colors.orange,
      'completed': Colors.blue,
      'tour_deleted': Colors.grey,
      'checked_in': Colors.teal,
      'partially_checked_in': Colors.teal,
    }[status] ?? Colors.grey;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('tours').doc(tourId).get(),
      builder: (context, snap) {
        final tourData = snap.data?.data() as Map<String, dynamic>?;
        final title = tourData?['title'] ?? 'Unknown Tour';
        final images = tourData?['images'] as List?;
        final imageUrl = images?.isNotEmpty == true ? images!.first as String? : null;
        final location = tourData?['meetingLocationName'] ?? '';

        return InkWell(
          onTap: () {
            if (tourData == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(
                  bookingId: bookingId,
                  bookingData: data,
                  tourData: tourData,
                  upcoming: upcoming,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? CachedNetworkImage(imageUrl: imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                        : Container(
                            width: 56,
                            height: 56,
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(Icons.landscape, color: theme.colorScheme.onSurfaceVariant),
                          ),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: location.isNotEmpty
                      ? Text(location, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)))
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'tour_deleted' ? 'TOUR REMOVED' : status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (status == 'tour_deleted')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Tour no longer available', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        date != null ? DateFormat('MMM d, yyyy · h:mm a').format(date) : 'TBD',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const Spacer(),
                      Text(
                        '$quantity ticket${quantity > 1 ? 's' : ''} · EGP ${totalEGP.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (upcoming && date != null && status != 'cancelled')
                  _CountdownBanner(tourDate: date, theme: theme),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown banner
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBanner extends StatefulWidget {
  final DateTime tourDate;
  final ThemeData theme;

  const _CountdownBanner({required this.tourDate, required this.theme});

  @override
  State<_CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<_CountdownBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final diff = widget.tourDate.difference(DateTime.now());
    if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) return const SizedBox.shrink();
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    String label;
    if (d > 0) {
      label = '$d day${d > 1 ? 's' : ''} ${h}h ${m}m';
    } else if (h > 0) {
      label = '${h}h ${m}m ${s}s';
    } else {
      label = '${m}m ${s}s';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 14, color: widget.theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'Starts in $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking detail screen
// ─────────────────────────────────────────────────────────────────────────────

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> tourData;
  final bool upcoming;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
    required this.tourData,
    required this.upcoming,
  }) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _cancelling = false;
  Map<String, dynamic>? _guideData;
  Map<String, dynamic>? _weatherData;
  bool _qrVisible = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadGuide();
    _loadWeather();
    _checkReview();
  }

  Future<void> _loadGuide() async {
    final guideId = widget.tourData['guideId'] ?? '';
    if (guideId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(guideId).get();
      if (doc.exists && mounted) setState(() => _guideData = doc.data());
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    final lat = widget.tourData['meetingLatitude'];
    final lng = widget.tourData['meetingLongitude'];
    final sessionTs = widget.bookingData['sessionDate'] as Timestamp?;
    final dateTs = sessionTs ?? widget.bookingData['date'] as Timestamp?;
    if (lat == null || lng == null || dateTs == null) return;

    final date = dateTs.toDate();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&timezone=auto&start_date=$dateStr&end_date=$dateStr',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) setState(() => _weatherData = json);
      }
    } catch (_) {}
  }

  Future<void> _checkReview() async {
    final user = FirebaseAuth.instance.currentUser;
    final tourId = widget.bookingData['tourId'] ?? '';
    if (user == null || tourId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('tourId', isEqualTo: tourId)
          .where('touristId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (mounted) setState(() => _hasReviewed = snap.docs.isNotEmpty);
    } catch (_) {}
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      final quantity = (widget.bookingData['quantity'] as num?)?.toInt() ?? 1;
      final tourId = widget.bookingData['tourId'] ?? '';

      String tourTitle = widget.tourData['title'] ?? 'a tour';
      String guideId = widget.bookingData['guideId'] ?? '';

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
        final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);
        final tourSnap = await txn.get(tourRef);
        final currentCap = (tourSnap.data()?['maxAttendees'] as num?)?.toInt() ?? 0;
        tourTitle = tourSnap.data()?['title'] ?? tourTitle;
        txn.update(bookingRef, {'status': 'cancelled'});
        txn.update(tourRef, {'maxAttendees': currentCap + quantity});
      });

      // Notify the guide
      if (guideId.isNotEmpty) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          String touristName = 'A tourist';
          String touristImage = user?.photoURL ?? '';
          if (user != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              final d = userDoc.data()!;
              final full = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
              touristName = full.isNotEmpty ? full : (d['username'] ?? 'A tourist');
              touristImage = d['profileImageUrl'] ?? touristImage;
            }
          }
          await NotificationsDataSourceImpl().sendNotification(NotificationModel(
            id: const Uuid().v4(),
            recipientId: guideId,
            senderId: user?.uid ?? '',
            senderName: touristName,
            senderAvatar: touristImage,
            title: 'Booking Cancelled',
            message: 'cancelled their booking for "$tourTitle"',
            type: 'booking_cancelled',
            deepLinkTargetId: tourId,
            isRead: false,
            timestamp: DateTime.now(),
          ));
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  void _addToCalendar() {
    final sessionTs = widget.bookingData['sessionDate'] as Timestamp?;
    final rawDateTs = widget.bookingData['date'] as Timestamp?;
    final dateTs = sessionTs ?? rawDateTs;
    final title = widget.tourData['title'] ?? 'Tour';
    final location = widget.tourData['meetingLocationName'] ?? '';
    if (dateTs == null) return;

    final start = dateTs.toDate();
    final end = start.add(const Duration(hours: 2));

    Add2Calendar.addEvent2Cal(Event(
      title: 'Lost in Egypt: $title',
      description: 'Meeting point: $location\nBooking ID: ${widget.bookingId}',
      location: location,
      startDate: start,
      endDate: end,
    ));
  }

  void _shareTicket() {
    final title = widget.tourData['title'] ?? 'Tour';
    final sessionTs = widget.bookingData['sessionDate'] as Timestamp?;
    final rawDateTs = widget.bookingData['date'] as Timestamp?;
    final effectiveDateTs = sessionTs ?? rawDateTs;
    final date = effectiveDateTs != null ? DateFormat('EEE, MMM d yyyy · h:mm a').format(effectiveDateTs.toDate()) : 'TBD';
    final location = widget.tourData['meetingLocationName'] ?? '';
    final quantity = (widget.bookingData['quantity'] as num?)?.toInt() ?? 1;

    Share.share(
      '🏺 Lost in Egypt – Tour Ticket\n\n'
      'Tour: $title\n'
      'Date: $date\n'
      'Meeting point: $location\n'
      'Tickets: $quantity\n'
      'Booking ref: ${widget.bookingId}\n\n'
      'See you there!',
    );
  }

  Future<void> _contactGuide({bool callPhone = false}) async {
    if (_guideData == null) return;
    final phone = _guideData!['phoneNumber'] as String?;
    final email = _guideData!['email'] as String?;

    Uri? uri;
    if (callPhone && phone != null && phone.isNotEmpty) {
      uri = Uri.parse('tel:$phone');
    } else if (!callPhone && email != null && email.isNotEmpty) {
      uri = Uri.parse('mailto:$email');
    }

    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(callPhone ? 'No phone number on file' : 'No email on file')),
        );
      }
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(callPhone ? 'Could not open phone app' : 'Could not open email app')),
        );
      }
    }
  }

  void _showLeaveReviewSheet() {
    double rating = 5;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setLS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                  onPressed: () => setLS(() => rating = (i + 1).toDouble()),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final tourId = widget.bookingData['tourId'] ?? '';
                    final guideId = widget.bookingData['guideId'] ?? '';
                    if (user == null || tourId.isEmpty) return;
                    String userName = 'Traveler';
                    String userImage = user.photoURL ?? '';
                    try {
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users').doc(user.uid).get();
                      if (userDoc.exists) {
                        final d = userDoc.data()!;
                        final full = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
                        userName = full.isNotEmpty ? full : (d['username'] ?? 'Traveler');
                        userImage = d['profileImageUrl'] ?? userImage;
                      }
                    } catch (_) {}
                    try {
                      await ReviewsDataSourceImpl().submitReview(ReviewModel(
                        id: const Uuid().v4(),
                        tourId: tourId,
                        guideId: guideId,
                        touristId: user.uid,
                        rating: rating,
                        comment: commentCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        userName: userName,
                        userImage: userImage,
                      ));
                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() => _hasReviewed = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rebook(BuildContext context) {
    // Reconstruct TourEntity from Firestore data to navigate to booking confirmation
    try {
      final tourData = widget.tourData;
      final tourId = tourData['id'] ?? widget.bookingData['tourId'] ?? '';
      final maxAttendees = (tourData['maxAttendees'] as num?)?.toInt() ?? 0;
      final tour = TourModel(
        id: tourId,
        guideId: tourData['guideId'] ?? '',
        title: tourData['title'] ?? '',
        description: tourData['description'] ?? '',
        destinations: List<String>.from(tourData['destinations'] ?? []),
        price: (tourData['price'] as num?)?.toDouble() ?? 0,
        meetingLatitude: (tourData['meetingLatitude'] as num?)?.toDouble() ?? 0,
        meetingLongitude: (tourData['meetingLongitude'] as num?)?.toDouble() ?? 0,
        meetingTime: (tourData['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        frequency: tourData['frequency'] ?? '',
        meetingLocationName: tourData['meetingLocationName'] ?? '',
        images: List<String>.from(tourData['images'] ?? []),
        maxAttendees: maxAttendees,
        rating: (tourData['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (tourData['reviewCount'] as num?)?.toInt() ?? 0,
        createdAt: (tourData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalCapacity: (tourData['totalCapacity'] as num?)?.toInt() ?? maxAttendees,
        recurrenceType: tourData['recurrenceType'] as String? ?? 'one_time',
        recurrenceDays: (tourData['recurrenceDays'] as List?)?.map((e) => e as int).toList() ?? [],
        meetingTimeOfDay: tourData['meetingTimeOfDay'] as String? ?? '',
        nextOccurrence: (tourData['nextOccurrence'] as Timestamp?)?.toDate(),
        isArchived: tourData['isArchived'] as bool? ?? false,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingConfirmationScreen(tour: tour)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to re-book: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.bookingData['status'] ?? 'pending';
    // Use sessionDate if set, otherwise fall back to date
    final sessionDateTs = widget.bookingData['sessionDate'] as Timestamp?;
    final dateTs = widget.bookingData['date'] as Timestamp?;
    final tourDate = sessionDateTs?.toDate() ?? dateTs?.toDate();
    final title = widget.tourData['title'] ?? 'Tour';
    final images = widget.tourData['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images!.first as String? : null;
    final location = widget.tourData['meetingLocationName'] ?? '';
    final lat = (widget.tourData['meetingLatitude'] as num?)?.toDouble();
    final lng = (widget.tourData['meetingLongitude'] as num?)?.toDouble();
    final quantity = (widget.bookingData['quantity'] as num?)?.toInt() ?? 1;
    final totalEGP = (widget.bookingData['totalAmountEGP'] as num?)?.toDouble() ?? 0;
    final paymentRef = widget.bookingData['paymentReference'] ?? '';
    final isCancelled = status == 'cancelled';

    final statusColor = {
      'confirmed': Colors.green,
      'cancelled': Colors.red,
      'pending': Colors.orange,
      'completed': Colors.blue,
      'tour_deleted': Colors.grey,
      'checked_in': Colors.teal,
      'partially_checked_in': Colors.teal,
    }[status] ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.landscape, size: 80, color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + status ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Info grid ────────────────────────────────────────────
                  _InfoRow(Icons.calendar_today, 'Date',
                      tourDate != null ? DateFormat('EEE, MMM d yyyy · h:mm a').format(tourDate) : 'TBD',
                      theme),
                  _InfoRow(Icons.place_outlined, 'Meeting point', location, theme),
                  _InfoRow(Icons.confirmation_number_outlined, 'Tickets',
                      '$quantity ticket${quantity > 1 ? 's' : ''}', theme),
                  _InfoRow(Icons.payments_outlined, 'Total paid',
                      'EGP ${totalEGP.toStringAsFixed(0)}', theme),
                  if (paymentRef.isNotEmpty)
                    _InfoRow(Icons.receipt_outlined, 'Payment ref', paymentRef, theme),

                  // ── Guide info ───────────────────────────────────────────
                  if (_guideData != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _GuideRow(
                      guideData: _guideData!,
                      guideId: widget.tourData['guideId'] ?? '',
                      theme: theme,
                    ),
                  ],

                  // ── Weather ──────────────────────────────────────────────
                  if (_weatherData != null && !isCancelled) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _WeatherRow(weatherData: _weatherData!, theme: theme),
                  ],

                  // ── Countdown ────────────────────────────────────────────
                  if (widget.upcoming && tourDate != null && !isCancelled) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 4),
                    _CountdownBanner(tourDate: tourDate, theme: theme),
                  ],

                  // ── QR Code ticket ───────────────────────────────────────
                  const SizedBox(height: 20),
                  const Divider(),
                  InkWell(
                    onTap: () => setState(() => _qrVisible = !_qrVisible),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          const Text('View QR Ticket',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const Spacer(),
                          Icon(_qrVisible ? Icons.expand_less : Icons.expand_more),
                        ],
                      ),
                    ),
                  ),
                  if (_qrVisible)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: widget.bookingId.isEmpty ? 'invalid' : widget.bookingId,
                              size: 180,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Booking ID: ${widget.bookingId.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Show this to your guide upon arrival',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                  // ── Meeting point → open in Map tab ─────────────────────
                  if (lat != null && lng != null) ...[
                    const Divider(),
                    InkWell(
                      onTap: () {
                        final mapItem = PlaceModel(
                          id: 'meeting_${widget.bookingId}',
                          title: location.isNotEmpty ? location : title,
                          category: 'Meeting Point',
                          coordinate: GeoPoint(lat, lng),
                          imagePath: '',
                          imagePaths: [],
                          locationAddress: location,
                          rating: 0,
                          price: 0,
                          duration: '',
                          weather: '',
                          description: 'Meeting point for tour: $title',
                          tags: const [],
                          importance: 0,
                          isCurrentlyOpen: true,
                          openingHoursText: '',
                          reviews: const [],
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          MapFocusService.instance.triggerFocus(mapItem);
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('View Meeting Point',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                Text('Opens in Map tab',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                            const Spacer(),
                            Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Utility actions (chips) ──────────────────────────────
                  if (!isCancelled || _guideData != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isCancelled) ...[
                          _ActionChip(
                            icon: Icons.calendar_month,
                            label: 'Add to Calendar',
                            onTap: _addToCalendar,
                            theme: theme,
                          ),
                          _ActionChip(
                            icon: Icons.share,
                            label: 'Share Ticket',
                            onTap: _shareTicket,
                            theme: theme,
                          ),
                        ],
                        if (_guideData != null) ...[
                          _ActionChip(
                            icon: Icons.phone_outlined,
                            label: 'Call Guide',
                            onTap: () => _contactGuide(callPhone: true),
                            theme: theme,
                          ),
                          _ActionChip(
                            icon: Icons.email_outlined,
                            label: 'Email Guide',
                            onTap: () => _contactGuide(callPhone: false),
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ],

                  // ── Primary / destructive actions (full-width buttons) ────
                  if (!widget.upcoming && !isCancelled && !_hasReviewed) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: const Text('Leave a Review',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _showLeaveReviewSheet,
                      ),
                    ),
                  ],
                  if (!widget.upcoming) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Re-book This Tour',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _rebook(context),
                      ),
                    ),
                  ],
                  if (widget.upcoming && !isCancelled) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.cancel_outlined,
                            size: 18, color: _cancelling ? Colors.red.withOpacity(0.4) : Colors.red),
                        label: Text('Cancel Booking',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _cancelling ? Colors.red.withOpacity(0.4) : Colors.red,
                            )),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _cancelling ? Colors.red.withOpacity(0.3) : Colors.red.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _cancelling ? null : _cancelBooking,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow(this.icon, this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final Map<String, dynamic> guideData;
  final String guideId;
  final ThemeData theme;

  const _GuideRow({required this.guideData, required this.guideId, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = '${guideData['firstName'] ?? ''} ${guideData['lastName'] ?? ''}'.trim();
    final avatar = guideData['profileImageUrl'] as String?;
    final rating = (guideData['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (guideData['reviewCount'] as num?)?.toInt() ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: guideId.isNotEmpty
          ? () {
              final userModel = UserModel.fromMap(guideData, guideId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UniversalProfileScreen(user: userModel),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
              child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : 'Your Guide',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                reviewCount > 0
                    ? Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(1)} ($reviewCount)',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      )
                    : Text('New Guide',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
            const Spacer(),
            Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final ThemeData theme;

  const _WeatherRow({required this.weatherData, required this.theme});

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }

  @override
  Widget build(BuildContext context) {
    try {
      final daily = weatherData['daily'] as Map<String, dynamic>?;
      if (daily == null) return const SizedBox.shrink();
      final codes = daily['weather_code'] as List?;
      final maxTemps = daily['temperature_2m_max'] as List?;
      final minTemps = daily['temperature_2m_min'] as List?;
      if (codes == null || codes.isEmpty) return const SizedBox.shrink();

      final code = (codes.first as num).toInt();
      final maxT = (maxTemps?.first as num?)?.toStringAsFixed(0) ?? '--';
      final minT = (minTemps?.first as num?)?.toStringAsFixed(0) ?? '--';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(_weatherEmoji(code), style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather on tour day',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 2),
                Text('$maxT°C / $minT°C',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final ThemeData theme;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: onTap == null ? c.withOpacity(0.4) : c),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: onTap == null ? c.withOpacity(0.4) : c,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
