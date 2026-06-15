import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';

class TourAttendeesScreen extends StatelessWidget {
  final String tourId;
  final String tourTitle;

  const TourAttendeesScreen({super.key, required this.tourId, required this.tourTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendees', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('tourId', isEqualTo: tourId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48.r, color: theme.colorScheme.error),
                  SizedBox(height: 12.h),
                  const Text('Error loading attendees'),
                  SizedBox(height: 8.h),
                  Text(
                    'A Firestore index may be needed.\nCheck debug console for the link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data?.docs ?? [];
          final confirmed = bookings.where((b) => (b.data() as Map)['status'] == 'confirmed').toList();
          final cancelled = bookings.where((b) => (b.data() as Map)['status'] == 'cancelled').toList();

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 80.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  SizedBox(height: 16.h),
                  Text('No bookings yet', style: TextStyle(fontSize: 18.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  SizedBox(height: 8.h),
                  Text(
                    'When travelers book this tour,\nthey\'ll appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              // Summary header
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${confirmed.length}', 'Confirmed', Colors.green),
                    Container(width: 1, height: 40.h, color: primary.withValues(alpha: 0.2)),
                    _statItem('${cancelled.length}', 'Cancelled', Colors.red),
                    Container(width: 1, height: 40.h, color: primary.withValues(alpha: 0.2)),
                    _statItem('${bookings.length}', 'Total', primary),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              if (confirmed.isNotEmpty) ...[
                Text('Confirmed (${confirmed.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: theme.colorScheme.onSurface)),
                SizedBox(height: 12.h),
                ...confirmed.map((doc) => _AttendeeCard(bookingData: doc.data() as Map<String, dynamic>, bookingId: doc.id)),
                SizedBox(height: 20.h),
              ],

              if (cancelled.isNotEmpty) ...[
                Text('Cancelled (${cancelled.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.red)),
                SizedBox(height: 12.h),
                ...cancelled.map((doc) => _AttendeeCard(bookingData: doc.data() as Map<String, dynamic>, bookingId: doc.id, isCancelled: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12.sp, color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _AttendeeCard extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;
  final bool isCancelled;

  const _AttendeeCard({required this.bookingData, required this.bookingId, this.isCancelled = false});

  @override
  State<_AttendeeCard> createState() => _AttendeeCardState();
}

class _AttendeeCardState extends State<_AttendeeCard> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.bookingData['userId']).get();
      if (mounted) {
        setState(() {
          _userData = doc.exists ? doc.data() : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(child: SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final name = '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim();
    final username = _userData?['username'] as String? ?? '';
    final phone = _userData?['phone'] ?? _userData?['phoneNumber'] ?? '';
    final email = _userData?['email'] ?? '';
    final profileUrl = _userData?['profileImageUrl'] ?? '';
    final userId = widget.bookingData['userId'] as String? ?? '';
    final paymentStatus = widget.bookingData['paymentStatus'] ?? 'none';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            onTap: _userData != null && userId.isNotEmpty
                ? () {
                    final userModel = UserModel.fromMap(_userData!, userId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: userModel)),
                    );
                  }
                : null,
            leading: ShimmerAvatar(
              url: profileUrl,
              radius: 24.r,
              fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              fallbackIconColor: theme.colorScheme.primary,
            ),
            title: Text(name.isNotEmpty ? name : 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (username.isNotEmpty)
                  Text('@$username', style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.primary.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                if (email.isNotEmpty)
                  Text(email, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                if (phone.isNotEmpty)
                  Text(phone, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid' ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    paymentStatus == 'paid' ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_userData != null) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right, size: 18.r,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 10.h),
            child: Row(
              children: [
                if (phone.isNotEmpty)
                  _actionButton(Icons.phone, 'Call', () => _launchUrl('tel:$phone')),
                if (phone.isNotEmpty)
                  _actionButton(Icons.message, 'WhatsApp', () => _launchUrl('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9+]'), '')}')),
                if (email.isNotEmpty)
                  _actionButton(Icons.email, 'Email', () => _launchUrl('mailto:$email')),
                const Spacer(),
                if (!widget.isCancelled)
                  _actionButton(Icons.cancel, 'Cancel', () => _cancelBooking(context), color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.r, color: c),
              SizedBox(width: 4.w),
              Text(label, style: TextStyle(fontSize: 12.sp, color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? The traveler will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': 'cancelled',
      });
      // Notify the traveler
      final touristId = widget.bookingData['userId'] as String?;
      if (touristId != null && touristId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(touristId)
            .collection('notifications')
            .add({
          'recipientId': touristId,
          'senderId': 'system',
          'senderName': 'Lost in Egypt',
          'senderAvatar': '',
          'title': '⚠️ Booking Cancelled',
          'message': 'Your booking has been cancelled by the guide.',
          'type': 'booking_cancelled',
          'deepLinkTargetId': widget.bookingData['tourId'],
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
