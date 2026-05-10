import 'package:flutter/material.dart';
import '../../account/presentation/account_screen.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../notification/domain/repositories/notifications_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../notification/notification_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/tours/presentation/bloc/guide_tours_cubit.dart' as lost_in_egypt_tours;
import 'package:lost_in_egypt/feature/tours/presentation/pages/guide_dashboard_screen.dart' as lost_in_egypt_tours;
import 'package:lost_in_egypt/feature/admin/presentation/pages/admin_dashboard_screen.dart' as lost_in_egypt_admin;

class AccountMenuButton extends StatefulWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const AccountMenuButton({
    super.key,
    this.profileImageUrl,
    required this.onSignOut,
  });

  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton> {
  late Stream<int> _unreadStream;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final NotificationsRepository repo = sl<NotificationsRepository>();

    if (user != null) {
      _unreadStream = repo.getUnreadCount(user.uid);
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    } else {
      _unreadStream = Stream.value(0);
      _userStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final avatarBg = primary.withOpacity(isDark ? 0.25 : 0.18);
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(0.12);

    return StreamBuilder<int>(
      stream: _unreadStream,
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data ?? 0;
        final String badgeText = unreadCount > 9 ? "9+" : "$unreadCount";

          return StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, userSnapshot) {
              final bool isGuide = userSnapshot.data?.exists == true && 
                  (userSnapshot.data!.data() as Map<String, dynamic>)['isVerifiedGuide'] == true;
              final bool isAdmin = userSnapshot.data?.exists == true &&
                  (userSnapshot.data!.data() as Map<String, dynamic>)['role'] == 'admin';

              return PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
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
                    image: (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(widget.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
                      ? Icon(Icons.person, size: 26, color: onSurface.withOpacity(0.9))
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

              case 'guide_dashboard':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => lost_in_egypt_tours.GuideToursCubit(
                        getGuideToursUseCase: GetIt.I(),
                      ),
                      child: const lost_in_egypt_tours.GuideDashboardScreen(),
                    ),
                  ),
                );
                break;

              case 'admin_dashboard':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const lost_in_egypt_admin.AdminDashboardScreen(),
                  ),
                );
                break;

              case 'logout':
              widget.onSignOut();
              break;
            }
          },

          itemBuilder: (BuildContext context) {
            final textStyle = TextStyle(
              fontFamily: "Marcellus",
              color: onSurface.withOpacity(0.9),
            );

            final iconColor = onSurface.withOpacity(0.75);

            return [
              PopupMenuItem<String>(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "My Account",
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              PopupMenuDivider(height: 1, color: onSurface.withOpacity(0.12)),

              if (isGuide) ...[
                PopupMenuItem<String>(
                  value: 'guide_dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_customize, color: iconColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Guide Dashboard",
                        style: textStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                PopupMenuDivider(height: 1, color: onSurface.withOpacity(0.12)),
              ],

              if (isAdmin) ...[
                PopupMenuItem<String>(
                  value: 'admin_dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Admin Dashboard",
                        style: textStyle.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                PopupMenuDivider(height: 1, color: onSurface.withOpacity(0.12)),
              ],

              PopupMenuItem<String>(
                value: 'notifications',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: iconColor, size: 20),
                        const SizedBox(width: 10),
                        Text("Notification Centre", style: textStyle),
                      ],
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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

              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Text("Sign Out", style: textStyle),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  },
);
}
}