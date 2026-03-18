import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
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
                        Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Error loading bookings', style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: 8),
                        Text(
                          'Firestore may need a composite index.\nCheck the debug console for a link.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings yet',
                          style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore tours and book your first adventure!',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.35)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _BookingCard(data: docs[index].data() as Map<String, dynamic>),
                );
              },
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BookingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = data['status'] ?? 'pending';
    final paymentStatus = data['paymentStatus'] ?? 'none';
    final tourId = data['tourId'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final date = (data['date'] as Timestamp?)?.toDate();

    final statusColor = {
      'confirmed': Colors.green,
      'cancelled': Colors.red,
      'pending': Colors.orange,
    }[status] ?? Colors.grey;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('tours').doc(tourId).get(),
      builder: (context, tourSnap) {
        final tourData = tourSnap.data?.data() as Map<String, dynamic>?;
        final tourTitle = tourData?['title'] ?? 'Unknown Tour';
        final tourImage = (tourData?['images'] as List?)?.isNotEmpty == true ? tourData!['images'][0] : null;
        final tourLocation = tourData?['meetingLocationName'] ?? '';

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tour image + title
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: tourImage != null
                      ? Image.network(tourImage, width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.landscape, size: 24)),
                ),
                title: Text(tourTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: tourLocation.isNotEmpty
                    ? Text(tourLocation, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)))
                    : null,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Details
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    _infoChip(Icons.calendar_today, date != null ? DateFormat.yMMMd().format(date) : 'TBD', theme),
                    const SizedBox(width: 12),
                    _infoChip(
                      paymentStatus == 'paid' ? Icons.check_circle : Icons.pending,
                      paymentStatus == 'paid' ? 'Paid' : 'Pending',
                      theme,
                      color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(
                        DateFormat.yMMMd().format(createdAt),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.35)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme, {Color? color}) {
    final c = color ?? theme.colorScheme.onSurface.withOpacity(0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
