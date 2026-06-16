import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../core/widgets/shimmer_image.dart';
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
import '../../../../core/services/guide_location_service.dart';
import '../../../../core/widgets/app_error_widget.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _isSharing = GuideLocationService.instance.isSharing;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<GuideToursCubit>().fetchTours(user.uid);
    }
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      await GuideLocationService.instance.stopSharing();
      if (mounted) setState(() => _isSharing = false);
    } else {
      await GuideLocationService.instance.startSharing();
      if (mounted) setState(() => _isSharing = GuideLocationService.instance.isSharing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guideDashTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSharing ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: _isSharing ? Colors.green : null,
            ),
            tooltip: _isSharing ? l10n.guideDashStopSharing : l10n.guideDashShareLocation,
            onPressed: _toggleSharing,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.guideDashScanTicket,
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
                    Icon(Icons.tour, size: 80.r, color: onSurface.withValues(alpha: 0.2)),
                    SizedBox(height: 16.h),
                    Text(l10n.guideDashNoTours, style: TextStyle(fontSize: 20.sp, color: onSurface.withValues(alpha: 0.5))),
                    SizedBox(height: 8.h),
                    Text(l10n.guideDashCreateFirst, style: TextStyle(fontSize: 14.sp, color: onSurface.withValues(alpha: 0.35))),
                  ],
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              children: [
                // ── Earnings Summary ──
                _EarningsSummary(tours: tours),
                SizedBox(height: 20.h),

                Text(l10n.guideDashYourTours(tours.length), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: onSurface)),
                SizedBox(height: 12.h),

                ...tours.map((tour) => _GuideTourCard(
                  tour: tour,
                  onRefresh: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && mounted) {
                      context.read<GuideToursCubit>().fetchTours(user.uid);
                    }
                  },
                )),
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
          if (user != null && context.mounted) {
            context.read<GuideToursCubit>().fetchTours(user.uid);
          }
        },
        label: Text(l10n.guideDashCreateTour, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .where('guideId', isEqualTo: guideId)
          .where('status', isEqualTo: 'confirmed')
          .get(),
      builder: (context, snapshot) {
        int totalBookings = 0;
        double totalRevenue = 0;

        if (snapshot.hasError) {
          return AppErrorWidget(message: l10n.guideDashEarningsError);
        }

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
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('${tours.length}', l10n.guideDashStatTours, Icons.tour, primary),
              Container(width: 1, height: 50.h, color: primary.withValues(alpha: 0.15)),
              _statItem('$totalBookings', l10n.guideDashStatBookings, Icons.confirmation_number, Colors.green),
              Container(width: 1, height: 50.h, color: primary.withValues(alpha: 0.15)),
              ValueListenableBuilder<String>(
                valueListenable: CurrencyController.currency,
                builder: (_, currency, _) => FutureBuilder<double>(
                  future: CurrencyService.instance.convertFromEGP(totalRevenue, currency),
                  builder: (_, snap) {
                    final label = snap.hasData
                        ? CurrencyService.format(snap.data!, currency)
                        : snap.hasError
                            ? 'EGP ${totalRevenue.toStringAsFixed(0)} ΓÜá'
                            : 'EGP ${totalRevenue.toStringAsFixed(0)}';
                    return _statItem(label, l10n.guideDashStatRevenue, Icons.monetization_on, Colors.amber[700]!);
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
        Icon(icon, color: color, size: 24.r),
        SizedBox(height: 6.h),
        Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12.sp, color: color.withValues(alpha: 0.7))),
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
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: SizedBox(
              height: 140.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ShimmerImage(
                    url: tour.images.isNotEmpty ? tour.images.first : null,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.landscape,
                    fallbackBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    fallbackIconColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    fallbackIconSize: 48.r,
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                  // Price tag
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: ValueListenableBuilder<String>(
                        valueListenable: CurrencyController.currency,
                        builder: (_, currency, _) => FutureBuilder<double>(
                          future: CurrencyService.instance.convertFromEGP(tour.price, currency),
                          builder: (_, snap) => Text(
                            snap.hasData
                                ? CurrencyService.format(snap.data!, currency)
                                : snap.hasError
                                    ? 'EGP ${tour.price.toStringAsFixed(0)} ΓÜá'
                                    : 'EGP ${tour.price.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 8.h,
                    left: 12.w,
                    right: 12.w,
                    child: Text(
                      tour.title,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
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
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                _infoChip(Icons.calendar_today, DateFormat('MMM d').format(tour.meetingTime), theme),
                SizedBox(width: 12.w),
                _infoChip(Icons.people, l10n.guideDashMax(tour.maxAttendees), theme),
                SizedBox(width: 12.w),
                _infoChip(Icons.repeat, tour.frequency, theme),
                const Spacer(),
                if (tour.reviewCount > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.r),
                      Text(' ${tour.rating.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: theme.colorScheme.onSurface)),
                    ],
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(l10n.tourCardNew, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
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
              if (snap.hasError) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: AppErrorWidget(message: l10n.guideDashBookingsError, icon: Icons.book_outlined),
                );
              }
              final count = snap.data?.docs.length ?? 0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: (count > 0 ? Colors.green : Colors.grey).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    count > 0 ? l10n.guideDashConfirmedBookings(count) : l10n.attendeesEmpty,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: count > 0 ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 8.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 10.h),
            child: Row(
              children: [
                _actionButton(context, Icons.visibility, l10n.guideDashView, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)));
                }),
              _actionButton(context, Icons.edit, l10n.commonEdit, () async {
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
                _actionButton(context, Icons.people, l10n.attendeesTitle, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TourAttendeesScreen(tourId: tour.id, tourTitle: tour.title)),
                  );
                }),
                _actionButton(context, Icons.delete, l10n.commonDelete, () => _confirmDelete(context), color: Colors.red),
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
        Icon(icon, size: 13.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        SizedBox(width: 3.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              Icon(icon, size: 20.r, color: c),
              SizedBox(height: 2.h),
              Text(label, style: TextStyle(fontSize: 10.sp, color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(l10n.guideDashDeleteTitle),
        content: Text(l10n.guideDashDeleteBody(tour.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('tours').doc(tour.id).delete();
      // Also cancel all pending bookings
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tourId', isEqualTo: tour.id)
          .where('status', isEqualTo: 'confirmed')
          .get();
      for (final doc in bookings.docs) {
        final touristId = (doc.data())['userId'] as String?;
        await doc.reference.update({'status': 'cancelled'});
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
            'title': '⚠️ Tour Cancelled',
            'message': 'The tour "${tour.title}" has been cancelled by the guide.',
            'type': 'tour_cancelled',
            'deepLinkTargetId': tour.id,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
      onRefresh();
    }
  }
}
