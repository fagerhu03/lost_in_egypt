import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabs/community/data/repositories/firebase_community_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../tabs/community/presentation/post_detail_screen.dart'; // Import to navigate to post
import '../tabs/community/presentation/community_screen.dart'; // Import if needed for navigation logic

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseCommunityRepository _repo = FirebaseCommunityRepository();

  @override
  void initState() {
    super.initState();
    // ⭐ CLEAR BADGE ON OPEN
    // We delay slightly to let the build finish, then mark all as read
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _repo.markAllNotificationsAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF4A3D2E)),
        title: const Text(
          "Notifications", 
          style: TextStyle(
            color: Color(0xFF4A3D2E), 
            fontFamily: "Marcellus", 
            fontWeight: FontWeight.bold
          )
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _repo.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // If it's unread, show a highlight color, otherwise transparent
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? ts = data['timestamp'];
              final date = ts?.toDate() ?? DateTime.now();

              return Container(
                color: isRead ? Colors.transparent : const Color(0xFFE6A44A).withOpacity(0.1),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (data['senderAvatar'] != null && data['senderAvatar'] != "")
                        ? NetworkImage(data['senderAvatar'])
                        : null,
                    child: (data['senderAvatar'] == null || data['senderAvatar'] == "")
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontSize: 14, fontFamily: "Mako"),
                      children: [
                        TextSpan(
                          text: "${data['senderName']} ", 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        TextSpan(text: data['message'] ?? "interacted with your post"),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timeago.format(date), 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ),
                  onTap: () {
                    // Optional: Add logic here to fetch the specific post and navigate to it
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}