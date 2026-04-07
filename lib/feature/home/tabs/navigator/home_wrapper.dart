import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/notification/domain/repositories/notifications_repository.dart';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../camera/presentation/camera_screen.dart';
import '../community/presentation/community_screen.dart';
import '../home/home_screen.dart';
import '../map/presentation/map_screen.dart';
import '../more/presentation/more_screen.dart';
import '../../../admin/presentation/pages/upcoming_bookings_screen.dart';

import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;

  int index = 0;
  bool _isNavBarVisible = true;
  bool _isGuide = false;

  late List<Widget> _pages;
  late List<TabItem> _navItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _pages = [
      const HomeScreen(),
      const CommunityScreen(),
      const MapScreen(),
      const CameraScreen(),
      MoreScreen(),
    ];

    _navItems = const [
      TabItem(icon: Icons.home_filled, title: "Home"),
      TabItem(icon: Icons.people_rounded, title: "Community"),
      TabItem(icon: Icons.location_pin, title: "Map"),
      TabItem(icon: Icons.camera_alt_rounded, title: "Camera"),
      TabItem(icon: Icons.more_horiz, title: "More"),
    ];

    MapFocusService.instance.tabSwitchNotifier.addListener(_handleTabSwitch);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      sl<NotificationsRepository>().startListeningForNewNotifications(uid);
    }
  }



  void _handleTabSwitch() {
    final int i = MapFocusService.instance.tabSwitchNotifier.value;
    if (!mounted || i < 0 || i >= _pages.length) return;

    setState(() {
      index = i;
      _isNavBarVisible = true;
    });

    _tabController.animateTo(i);
    _pageController.jumpToPage(i);
  }

  @override
  void dispose() {
    MapFocusService.instance.tabSwitchNotifier.removeListener(_handleTabSwitch);
    sl<NotificationsRepository>().stopListening();
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = theme.scaffoldBackgroundColor;
    final primary = theme.colorScheme.primary;
    final inactive = theme.colorScheme.onSurface.withOpacity(0.60);

    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];
          final isOffline = results.isNotEmpty &&
              results.every((r) => r == ConnectivityResult.none);
          return Column(
            children: [
              if (isOffline)
                Material(
                  color: Colors.amber.shade700,
                  child: const SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        "You're offline — some features may be unavailable",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (index == 1) {
                      if (notification.direction == ScrollDirection.reverse &&
                          _isNavBarVisible) {
                        setState(() => _isNavBarVisible = false);
                      } else if (notification.direction == ScrollDirection.forward &&
                          !_isNavBarVisible) {
                        setState(() => _isNavBarVisible = true);
                      }
                    }
                    return true;
                  },
                  child: PageView(
                    controller: _pageController,
                    physics: (index == 2 || index == 3)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() {
                        index = i;
                        _isNavBarVisible = true;
                      });
                      _tabController.animateTo(i);
                    },
                    children: _pages,
                  ),
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1),
        child: Container(
          decoration: BoxDecoration(
            // ✅ shadow goes UP (visible)
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.02) // visible glow in dark mode
                    : Colors.black.withOpacity(0.1), // visible shadow in light mode
                blurRadius: 28,
                spreadRadius: 6,
                offset: const Offset(0, -10), // IMPORTANT: negative = shadow up
              ),
            ],
          ),
          child: ConvexAppBar(
            controller: _tabController,
            style: TabStyle.react,
            height: 55,
            curveSize: 90,
            backgroundColor: bg,
            activeColor: primary,
            color: inactive,
            elevation: 0, // keep 0, we use BoxShadow instead
            items: _navItems,
            onTap: (i) {
              setState(() {
                index = i;
                _isNavBarVisible = true;
              });
              _tabController.animateTo(i);
              _pageController.jumpToPage(i);
            },
          ),
        ),
      ),    );
  }
}
