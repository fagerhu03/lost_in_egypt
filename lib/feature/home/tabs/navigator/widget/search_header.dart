import 'package:flutter/material.dart';

// import 'package:firebase_auth/firebase_auth.dart';
// import '../../community/data/repositories/firebase_community_repository.dart';
// import '../../../notification/notification_screen.dart'; // Import Notification Screen

class SearchHeader extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const SearchHeader({
    super.key,
    this.profileImageUrl,
    required this.onSignOut,
  });

//   @override
//   Widget build(BuildContext context) {
//     // Instance of repo to fetch notification count
//     final FirebaseCommunityRepository repo = FirebaseCommunityRepository();
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       height: 60,
//       width: double.infinity,
//       child: Row(
//         children: [
//           const SizedBox(width: 12),
//
//           // 🔍 SEARCH BAR (Kept same as before)
//           Expanded(
//             child: Container(
//               height: 48,
//               padding: const EdgeInsets.symmetric(horizontal: 18),
//               decoration: BoxDecoration(
//                 color: const Color(0xff4D5420).withOpacity(0.50),
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       "Where do you want to go?",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.90),
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: "Marcellus",
//                       ),
//                     ),
//                   ),
//                   Icon(
//                     Icons.search,
//                     color: Colors.white.withOpacity(0.95),
//                     size: 24,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           const SizedBox(width: 12),
//
//           // 👤 PROFILE DROPDOWN (Updated to match Community)
//           StreamBuilder<int>(
//             stream: repo.getUnreadCountStream(),
//             builder: (context, snapshot) {
//               final int unreadCount = snapshot.data ?? 0;
//               final String badgeText = unreadCount > 9 ? "9+" : "$unreadCount";
//
//               return PopupMenuButton<String>(
//                 offset: const Offset(0, 50),
//                 color: const Color(0xffFFFDF4),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//
//                 // The Button UI (Profile Pic with Badge)
//                 child: Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: const Color(0xff4D5420).withOpacity(0.50),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                   child: Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       // Avatar Image
//                       Container(
//                         width: 44,
//                         height: 44,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           image:
//                               (profileImageUrl != null &&
//                                   profileImageUrl!.isNotEmpty)
//                               ? DecorationImage(
//                                   image: NetworkImage(profileImageUrl!),
//                                   fit: BoxFit.cover,
//                                 )
//                               : null,
//                         ),
//                         child:
//                             (profileImageUrl == null ||
//                                 profileImageUrl!.isEmpty)
//                             ? Icon(
//                                 Icons.person,
//                                 size: 26,
//                                 color: Colors.white.withOpacity(0.95),
//                               )
//                             : null,
//                       ),
//
//                       // Red Dot (Only visible if unread > 0)
//                       if (unreadCount > 0)
//                         Positioned(
//                           top: 0,
//                           right: 0,
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: const BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//
//                 // Menu Logic
//                 onSelected: (value) {
//                   if (value == 'notifications') {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const NotificationScreen(),
//                       ),
//                     );
//                   } else if (value == 'logout') {
//                     onSignOut();
//                   }
//                 },
//
//                 // Menu Items
//                 itemBuilder: (BuildContext context) {
//                   return [
//                     const PopupMenuItem<String>(
//                       enabled: false,
//                       child: Text(
//                         "My Account",
//                         style: TextStyle(
//                           fontFamily: "Marcellus",
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xff4D5420),
//                         ),
//                       ),
//                     ),
//                     const PopupMenuDivider(),
//
//                     // ⭐ Notification Centre Item
//                     PopupMenuItem<String>(
//                       value: 'notifications',
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Row(
//                             children: [
//                               Icon(
//                                 Icons.notifications_outlined,
//                                 color: Color(0xFF7A6A55),
//                                 size: 20,
//                               ),
//                               SizedBox(width: 10),
//                               Text(
//                                 "Notification Centre",
//                                 style: TextStyle(fontFamily: "Marcellus"),
//                               ),
//                             ],
//                           ),
//                           // ⭐ Number Badge
//                           if (unreadCount > 0)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Text(
//                                 badgeText,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//
//                     // Sign Out Item
//                     const PopupMenuItem<String>(
//                       value: 'logout',
//                       child: Row(
//                         children: [
//                           Icon(Icons.logout, color: Colors.red, size: 20),
//                           SizedBox(width: 10),
//                           Text(
//                             "Sign Out",
//                             style: TextStyle(fontFamily: "Marcellus"),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ];
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xff4D5420).withOpacity(0.50),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Where do you want to go?",
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: "Marcellus",
              ),
            ),
          ),
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.95),
            size: 24,
          ),
        ],
      ),
    );
  }
}