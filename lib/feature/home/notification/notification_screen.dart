import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/empty_notifications_view.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notif_card.dart';
import 'package:lost_in_egypt/feature/home/notification/widget/notification_settings_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../tabs/community/data/repositories/firebase_community_repository.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseCommunityRepository _repo = FirebaseCommunityRepository();

  static const Color _bg = Color(0xFFF6F2E6);
  static const Color _text = Color(0xFF7C6A4D);
  static const Color _chip = Color(0xFF4D5420);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _repo.markAllNotificationsAsRead();
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: _text, size: 18),
                      ),
                      const Spacer(),
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          color: _text,
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => NotificationSettingsSheet.open(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _chip.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _chip.withOpacity(0.25)),
                        ),
                        child: const Text(
                          "Customize your notifications!",
                          style: TextStyle(
                            color: _chip,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _repo.getNotificationsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return EmptyNotificationsView(
                            onTapSettings: () => NotificationSettingsSheet.open(context),
                          );
                        }

                        return ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 4),
                            const Padding(
                              padding: EdgeInsets.only(left: 6, bottom: 8),
                              child: Text(
                                "Previously",
                                style: TextStyle(
                                  color: _text,
                                  fontFamily: "Marcellus",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final String notifId = doc.id;

                              final bool isRead = data['isRead'] ?? false;
                              final Timestamp? ts = data['timestamp'];
                              final date = ts?.toDate() ?? DateTime.now();

                              final String senderName =
                              (data['senderName'] ?? "Someone").toString();
                              final String message =
                              (data['message'] ?? "interacted with your post").toString();
                              final String avatar =
                              (data['senderAvatar'] ?? "").toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Dismissible(
                                  key: ValueKey(notifId),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 18),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (_) async {
                                    await _deleteNotification(notifId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Notification deleted")),
                                      );
                                    }
                                  },
                                  child: NotifCard(
                                    isRead: isRead,
                                    senderName: senderName,
                                    message: message,
                                    timeText: timeago.format(date),
                                    avatarUrl: avatar.isEmpty ? null : avatar,
                                    onTap: () {},
                                  ),
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                "Marking notifications?",
                                style: TextStyle(
                                  color: _text.withOpacity(0.75),
                                  fontFamily: "Marcellus",
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: InkWell(
                                onTap: () => NotificationSettingsSheet.open(context),
                                child: Text(
                                  "See how it works",
                                  style: TextStyle(
                                    color: _chip.withOpacity(0.95),
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
