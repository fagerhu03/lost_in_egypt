import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/empty_notifications_view.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notif_card.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notification_settings_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _notificationsStream = _repo.getNotifications(userId);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && userId.isNotEmpty) {
        _repo.markAllAsRead(userId);
      }
    });
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
                      color: primary.withOpacity(0.18),
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
                                Border.all(color: primary.withOpacity(0.25)),
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
                                          Colors.red.withOpacity(0.85),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) async {
                                    await _repo.deleteNotification(notif.id);
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
                                    onTap: () {},
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                "Marking notifications?",
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.75),
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
