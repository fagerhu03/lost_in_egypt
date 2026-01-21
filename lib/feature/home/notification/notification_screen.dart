import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabs/community/data/repositories/firebase_community_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseCommunityRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF4A3D2E)),
        title: const Text("Notifications", style: TextStyle(color: Color(0xFF4A3D2E), fontFamily: "Marcellus", fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: repo.getNotificationsStream(),
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
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? ts = data['timestamp'];
              final date = ts?.toDate() ?? DateTime.now();

              return ListTile(
                tileColor: isRead ? Colors.transparent : const Color(0xFFE6A44A).withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: "${data['senderName']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: data['message'] ?? "interacted with your post"),
                    ],
                  ),
                ),
                subtitle: Text(
                  timeago.format(date), 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)
                ),
                onTap: () {
                  repo.markNotificationAsRead(id);
                  // Optional: Navigate to the post
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: ... fetch post ...)));
                },
              );
            },
          );
        },
      ),
    );
  }
}