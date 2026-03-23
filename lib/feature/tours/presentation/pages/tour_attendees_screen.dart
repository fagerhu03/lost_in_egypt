import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';

class TourAttendeesScreen extends StatelessWidget {
  final String tourId;
  final String tourTitle;

  const TourAttendeesScreen({Key? key, required this.tourId, required this.tourTitle}) : super(key: key);

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
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  const Text('Error loading attendees'),
                  const SizedBox(height: 8),
                  Text(
                    'A Firestore index may be needed.\nCheck debug console for the link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
                  Icon(Icons.people_outline, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Text(
                    'When travelers book this tour,\nthey\'ll appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.35)),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary.withOpacity(0.15), primary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${confirmed.length}', 'Confirmed', Colors.green),
                    Container(width: 1, height: 40, color: primary.withOpacity(0.2)),
                    _statItem('${cancelled.length}', 'Cancelled', Colors.red),
                    Container(width: 1, height: 40, color: primary.withOpacity(0.2)),
                    _statItem('${bookings.length}', 'Total', primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (confirmed.isNotEmpty) ...[
                Text('Confirmed (${confirmed.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                ...confirmed.map((doc) => _AttendeeCard(bookingData: doc.data() as Map<String, dynamic>, bookingId: doc.id)),
                const SizedBox(height: 20),
              ],

              if (cancelled.isNotEmpty) ...[
                Text('Cancelled (${cancelled.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                const SizedBox(height: 12),
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final name = '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim();
    final username = _userData?['username'] as String? ?? '';
    final phone = _userData?['phone'] ?? _userData?['phoneNumber'] ?? '';
    final email = _userData?['email'] ?? '';
    final profileUrl = _userData?['profileImageUrl'] ?? '';
    final userId = widget.bookingData['userId'] as String? ?? '';
    final status = widget.bookingData['status'] ?? 'pending';
    final paymentStatus = widget.bookingData['paymentStatus'] ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            onTap: _userData != null && userId.isNotEmpty
                ? () {
                    final userModel = UserModel.fromMap(_userData!, userId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: userModel)),
                    );
                  }
                : null,
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: profileUrl.isEmpty ? Icon(Icons.person, color: theme.colorScheme.primary) : null,
            ),
            title: Text(name.isNotEmpty ? name : 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (username.isNotEmpty)
                  Text('@$username', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary.withOpacity(0.8), fontWeight: FontWeight.w500)),
                if (email.isNotEmpty)
                  Text(email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                if (phone.isNotEmpty)
                  Text(phone, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid' ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentStatus == 'paid' ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_userData != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ],
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
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
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
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
