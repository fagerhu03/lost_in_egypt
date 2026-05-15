import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/empty_notifications_view.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notif_card.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notification_settings_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:lost_in_egypt/feature/home/tabs/community/presentation/post_detail_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/data/model/community_post_model.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/tours/data/models/tour_model.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/tour_detail_screen.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/booking_history_screen.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/guide_dashboard_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/my_plans_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lost_in_egypt/feature/tours/presentation/bloc/guide_tours_cubit.dart';
import 'package:lost_in_egypt/feature/tours/domain/usecases/get_guide_tours_usecase.dart';
import 'package:get_it/get_it.dart';

import '../../../core/di/service_locator.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/entities/notification_entity.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationsRepository _repo = sl<NotificationsRepository>();
  late Stream<List<NotificationEntity>> _notificationsStream;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = sl<FirebaseAuth>().currentUser?.uid ?? '';
    _notificationsStream = _repo.getNotifications(_userId);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _userId.isNotEmpty) {
        _repo.markAllAsRead(_userId);
      }
    });
  }

  Future<void> _handleNotifTap(NotificationEntity notif) async {
    if (!notif.isRead) {
      await _repo.markAsRead(_userId, notif.id);
    }
    final targetId = notif.deepLinkTargetId;
    if (targetId == null || targetId.isEmpty) return;

    try {
      // ── Community: post likes / comments ────────────────────────────
      if (notif.type == 'comment' || notif.type.startsWith('like')) {
        final parts = targetId.split('_');
        final postId = parts[0];
        final commentId = parts.length > 1 ? parts[1] : null;
        final doc = await sl<FirebaseFirestore>()
            .collection('community_posts').doc(postId).get();
        if (!doc.exists || !mounted) return;
        final post = CommunityPostModel.fromSnapshot(doc);
        MapFocusService.instance.tabSwitchNotifier.value = 1;
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: post, highlightCommentId: commentId)));
        return;
      }

      // ── Tourist: booking confirmed, tour cancelled, or booking cancelled by guide
      if (notif.type == 'booking_confirmed' || notif.type == 'tour_cancelled' ||
          notif.type == 'tour_updated' || notif.type == 'booking_cancelled') {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
        return;
      }

      // ── Guide: new booking received → navigate to guide dashboard
      if (notif.type == 'booking') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => GuideToursCubit(
                getGuideToursUseCase: GetIt.I<GetGuideToursUseCase>()),
            child: const GuideDashboardScreen(),
          ),
        ));
        return;
      }

      // ── Weather alert for active solo plan ──────────────────────────
      if (notif.type == 'weather_alert') {
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyPlansScreen()));
        return;
      }

      // ── Weekly AI-picked recommendations → Home tab (For You carousel) ─
      if (notif.type == 'weekly_recommendations') {
        if (!mounted) return;
        // Pop back to HomeWrapper, then switch to Home tab where For You lives.
        Navigator.of(context).popUntil((r) => r.isFirst);
        MapFocusService.instance.tabSwitchNotifier.value = 0;
        return;
      }

      // ── Daily discovery push → Home tab (same surface as weekly) ───────
      if (notif.type == 'daily_discovery') {
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
        MapFocusService.instance.tabSwitchNotifier.value = 0;
        return;
      }

      // ── Guide: new review → navigate to tour detail ──────────────────
      if (notif.type == 'review') {
        final doc = await sl<FirebaseFirestore>()
            .collection('tours').doc(targetId).get();
        if (!doc.exists || !mounted) return;
        final tour = TourModel.fromMap(doc.data()!, doc.id);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)));
        return;
      }
    } catch (e) {
      debugPrint('Notification deep link error: $e');
    }
  }

  Future<void> _handleAvatarTap(String senderId) async {
    if (senderId.isEmpty) return;
    try {
      final doc = await sl<FirebaseFirestore>().collection('users').doc(senderId).get();
      if (doc.exists && mounted) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: user)));
      }
    } catch(e) { /* ignore */ }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final patternOpacity = isDark ? 0.1 : 0.35;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: onSurface, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        "Notifications",
                        style: TextStyle(
                          color: onSurface,
                          fontFamily: "Marcellus",
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.center,
                    child: Material(
                      color: primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => NotificationSettingsSheet.open(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: primary.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            "Customize your notifications!",
                            style: TextStyle(
                              color: primary,
                              fontFamily: "Marcellus",
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<List<NotificationEntity>>(
                      stream: _notificationsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child:
                                  CircularProgressIndicator(color: primary));
                        }

                        final notifications = snapshot.data ?? [];

                        if (notifications.isEmpty) {
                          return EmptyNotificationsView(
                            onTapSettings: () =>
                                NotificationSettingsSheet.open(context),
                          );
                        }

                        return ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, bottom: 8),
                              child: Text(
                                "Previously",
                                style: TextStyle(
                                  color: onSurface,
                                  fontFamily: "Marcellus",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            ...notifications.map((notif) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Dismissible(
                                  key: ValueKey(notif.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding:
                                        const EdgeInsets.only(right: 18),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red.withValues(alpha: 0.85),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) async {
                                    await _repo.deleteNotification(_userId, notif.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Notification deleted")),
                                      );
                                    }
                                  },
                                  child: NotifCard(
                                    isRead: notif.isRead,
                                    senderName: notif.senderName,
                                    message: notif.message,
                                    timeText: timeago.format(notif.timestamp),
                                    avatarUrl: notif.senderAvatar.isEmpty
                                        ? null
                                        : notif.senderAvatar,
                                    onTap: () => _handleNotifTap(notif),
                                    onAvatarTap: () => _handleAvatarTap(notif.senderId),
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                "Marking notifications?",
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.75),
                                  fontFamily: "Marcellus",
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: InkWell(
                                onTap: () =>
                                    NotificationSettingsSheet.open(context),
                                child: Text(
                                  "See how it works",
                                  style: TextStyle(
                                    color: primary,
                                    fontFamily: "Marcellus",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
