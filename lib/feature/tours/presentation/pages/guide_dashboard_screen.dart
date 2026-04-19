import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../bloc/guide_tours_cubit.dart';
import '../bloc/guide_tours_state.dart';
import '../bloc/create_tour_cubit.dart';
import '../../domain/entities/tour_entity.dart';
import 'create_tour_screen.dart';
import 'tour_detail_screen.dart';
import 'tour_attendees_screen.dart';
import 'qr_scanner_screen.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/currency_controller.dart';
import '../../../../core/services/currency_service.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<GuideToursCubit>().fetchTours(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Ticket',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<GuideToursCubit, GuideToursState>(
        builder: (context, state) {
          if (state is GuideToursLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GuideToursError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is GuideToursLoaded) {
            final tours = state.tours;
            if (tours.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tour, size: 80, color: onSurface.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text('No tours yet', style: TextStyle(fontSize: 20, color: onSurface.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('Create your first tour!', style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.35))),
                  ],
                ),
              );
            }
            final activeTours = tours.where((t) => !t.isArchived).toList();
            final archivedTours = tours.where((t) => t.isArchived).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── Earnings Summary ──
                _EarningsSummary(tours: tours),
                const SizedBox(height: 20),

                Text('Your Tours (${activeTours.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                const SizedBox(height: 12),

                ...activeTours.map((tour) => _GuideTourCard(
                  tour: tour,
                  onRefresh: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && mounted) {
                      context.read<GuideToursCubit>().fetchTours(user.uid);
                    }
                  },
                )),

                // ── Past / Archived Tours ──
                if (archivedTours.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _ArchivedToursSection(
                    archivedTours: archivedTours,
                    onRefresh: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && mounted) {
                        context.read<GuideToursCubit>().fetchTours(user.uid);
                      }
                    },
                  ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => CreateTourCubit(
                  createTourUseCase: sl(),
                  updateTourUseCase: sl(),
                ),
                child: const CreateTourScreen(),
              ),
            ),
          );
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && mounted) {
            context.read<GuideToursCubit>().fetchTours(user.uid);
          }
        },
        label: const Text('Create Tour', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFC79A00),
      ),
    );
  }
}

/// ─── Earnings Summary Header ────────────────────────────────────────────
class _EarningsSummary extends StatelessWidget {
  final List<TourEntity> tours;
  const _EarningsSummary({required this.tours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final guideId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .where('guideId', isEqualTo: guideId)
          .where('status', isEqualTo: 'confirmed')
          .get(),
      builder: (context, snapshot) {
        int totalBookings = 0;
        double totalRevenue = 0;

        if (snapshot.hasData) {
          totalBookings = snapshot.data!.docs.length;
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Use stored totalAmountEGP if available; fall back to price × quantity
            final stored = (data['totalAmountEGP'] as num?)?.toDouble();
            if (stored != null && stored > 0) {
              totalRevenue += stored;
            } else {
              final tourId = data['tourId'] ?? '';
              final quantity = (data['quantity'] as num?)?.toDouble() ?? 1;
              final tour = tours.where((t) => t.id == tourId).firstOrNull;
              if (tour != null) totalRevenue += tour.price * quantity;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.15), primary.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('${tours.length}', 'Tours', Icons.tour, primary),
              Container(width: 1, height: 50, color: primary.withOpacity(0.15)),
              _statItem('$totalBookings', 'Bookings', Icons.confirmation_number, Colors.green),
              Container(width: 1, height: 50, color: primary.withOpacity(0.15)),
              ValueListenableBuilder<String>(
                valueListenable: CurrencyController.currency,
                builder: (_, currency, __) => FutureBuilder<double>(
                  future: CurrencyService.instance.convertFromEGP(totalRevenue, currency),
                  builder: (_, snap) {
                    final label = snap.hasData
                        ? CurrencyService.format(snap.data!, currency)
                        : 'EGP ${totalRevenue.toStringAsFixed(0)}';
                    return _statItem(label, 'Revenue', Icons.monetization_on, Colors.amber[700]!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
      ],
    );
  }
}

/// ─── Guide Tour Card with Actions ───────────────────────────────────────
class _GuideTourCard extends StatelessWidget {
  final TourEntity tour;
  final VoidCallback onRefresh;

  const _GuideTourCard({required this.tour, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image + overlay info
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  tour.images.isNotEmpty
                      ? Image.network(tour.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]))
                      : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Center(child: Icon(Icons.landscape, size: 48, color: Theme.of(context).colorScheme.outline.withOpacity(0.5)))),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ),
                  // Price tag
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ValueListenableBuilder<String>(
                        valueListenable: CurrencyController.currency,
                        builder: (_, currency, __) => FutureBuilder<double>(
                          future: CurrencyService.instance.convertFromEGP(tour.price, currency),
                          builder: (_, snap) => Text(
                            snap.hasData
                                ? CurrencyService.format(snap.data!, currency)
                                : 'EGP ${tour.price.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: Text(
                      tour.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _infoChip(
                  Icons.calendar_today,
                  tour.recurrenceType != 'one_time' && tour.nextOccurrence != null
                      ? 'Next: ${DateFormat('MMM d').format(tour.nextOccurrence!)}'
                      : DateFormat('MMM d').format(tour.meetingTime),
                  theme,
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.people,
                  tour.totalCapacity > 0
                      ? '${tour.maxAttendees}/${tour.totalCapacity} spots'
                      : '${tour.maxAttendees} remaining',
                  theme,
                ),
                const SizedBox(width: 12),
                _infoChip(Icons.repeat, tour.frequency, theme),
                const Spacer(),
                if (tour.reviewCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${tour.rating.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
                  ),
              ],
            ),
          ),

          // Booking count
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('bookings')
                .where('tourId', isEqualTo: tour.id)
                .where('status', isEqualTo: 'confirmed')
                .get(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (count > 0 ? Colors.green : Colors.grey).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count > 0 ? '📌 $count confirmed booking${count == 1 ? '' : 's'}' : 'No bookings yet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: count > 0 ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _actionButton(context, Icons.visibility, 'View', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)));
                }),
              _actionButton(context, Icons.edit, 'Edit', () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => CreateTourCubit(
                        createTourUseCase: sl(),
                        updateTourUseCase: sl(),
                      ),
                      child: CreateTourScreen(tourToEdit: tour),
                    ),
                  ),
                );
                  onRefresh();
                }),
                _actionButton(context, Icons.people, 'Attendees', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TourAttendeesScreen(tourId: tour.id, tourTitle: tour.title)),
                  );
                }),
                _actionButton(context, Icons.delete, 'Delete', () => _confirmDelete(context), color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Tour'),
        content: Text('Are you sure you want to delete "${tour.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Optimistically remove from UI immediately
      if (context.mounted) {
        context.read<GuideToursCubit>().removeTour(tour.id);
      }

      await FirebaseFirestore.instance.collection('tours').doc(tour.id).delete();

      // Batch-update all active bookings to 'tour_deleted' and notify tourists
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tourId', isEqualTo: tour.id)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in bookingsSnapshot.docs) {
          batch.update(doc.reference, {'status': 'tour_deleted'});
          final userId = (doc.data())['userId'] as String?;
          if (userId != null && userId.isNotEmpty) {
            final notifRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc();
            batch.set(notifRef, {
              'recipientId': userId,
              'senderId': 'system',
              'senderName': 'Lost in Egypt',
              'senderAvatar': '',
              'title': 'Tour No Longer Available',
              'message': 'The tour "${tour.title}" has been removed by the guide.',
              'type': 'tour_cancelled',
              'deepLinkTargetId': '',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      }

      // Full refresh to sync server state
      if (context.mounted) {
        context.read<GuideToursCubit>().fetchTours(tour.guideId);
      }
    }
  }
}

/// ─── Archived (Past) Tours Section ─────────────────────────────────────────
class _ArchivedToursSection extends StatefulWidget {
  final List<TourEntity> archivedTours;
  final VoidCallback onRefresh;

  const _ArchivedToursSection({required this.archivedTours, required this.onRefresh});

  @override
  State<_ArchivedToursSection> createState() => _ArchivedToursSectionState();
}

class _ArchivedToursSectionState extends State<_ArchivedToursSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: onSurface.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18, color: onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'Past / Archived Tours (${widget.archivedTours.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          ...widget.archivedTours.map((tour) => Opacity(
            opacity: 0.65,
            child: _GuideTourCard(tour: tour, onRefresh: widget.onRefresh),
          )),
        ],
      ],
    );
  }
}
