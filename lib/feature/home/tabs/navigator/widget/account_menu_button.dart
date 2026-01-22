import 'package:flutter/material.dart';
import '../../account/account_screen.dart';
import '../../community/data/repositories/firebase_community_repository.dart';
import '../../../notification/notification_screen.dart';

class AccountMenuButton extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const AccountMenuButton({
    super.key,
    this.profileImageUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseCommunityRepository repo = FirebaseCommunityRepository();

    return StreamBuilder<int>(
      stream: repo.getUnreadCountStream(),
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data ?? 0;
        final String badgeText = unreadCount > 9 ? "9+" : "$unreadCount";

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          color: const Color(0xffFFFDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xff4D5420).withOpacity(0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                      ? Icon(
                    Icons.person,
                    size: 26,
                    color: Colors.white.withOpacity(0.95),
                  )
                      : null,
                ),

                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          onSelected: (value) {
            switch (value) {
              case 'account':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
                break;

              case 'notifications':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
                break;

              case 'logout':
                onSignOut();
                break;
            }
          },


          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'account',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Color(0xFF7A6A55),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "My Account",
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontWeight: FontWeight.bold,
                        color: Color(0xff4D5420),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),

              PopupMenuItem<String>(
                value: 'notifications',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF7A6A55),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Notification Centre",
                          style: TextStyle(fontFamily: "Marcellus"),
                        ),
                      ],
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Sign Out",
                      style: TextStyle(fontFamily: "Marcellus"),
                    ),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
