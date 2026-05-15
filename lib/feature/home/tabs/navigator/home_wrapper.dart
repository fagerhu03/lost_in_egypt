import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../../../../theme/theme.dart';
import '../camera/presentation/camera_screen.dart';
import '../community/presentation/community_screen.dart';
import '../home/home_screen.dart';
import '../map/presentation/map_screen.dart';
import '../more/presentation/more_screen.dart';
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
  }

  void _handleTabSwitch() {
    final int i = MapFocusService.instance.tabSwitchNotifier.value;
    if (!mounted || i < 0 || i >= _pages.length) return;

    setState(() {
      index = i;
      _isNavBarVisible = true;
    });

    _tabController.animateTo(i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    MapFocusService.instance.tabSwitchNotifier.removeListener(_handleTabSwitch);
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ✅ navbar background from AppColors in dark mode
    final bg = isDark
        ? AppColors.darkBackground // FCFBE8
        : theme.scaffoldBackgroundColor;

    // ✅ better icon colors for that light navbar in dark mode
    final primary = isDark
        ? AppColors.darkNavBar
        : theme.colorScheme.primary;

    final inactive = isDark
        ? AppColors.darkNavBar.withValues(alpha: 0.50)
        : theme.colorScheme.primary.withValues(alpha: 0.50);

    // NO PopScope. Every previous attempt to intercept the system back here
    // ("back from non-home tab → switch to Home") has resurfaced the bug
    // where pressing back from any pushed sub-route (Settings, Translator,
    // Tours, Guides, etc.) jumps to Home with a hard reload. Behaviour now:
    //   • Press back on a sub-route → pops the sub-route (Flutter default).
    //   • Press back on any tab when HomeWrapper is topmost → exits the app
    //     (Android default).
    // Switching back to Home tab can still happen via the navbar or via a
    // deep-link calling MapFocusService.instance.tabSwitchNotifier. No
    // automatic "back jumps to home tab" — that's what kept breaking.
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
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
          physics: const NeverScrollableScrollPhysics(),
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
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _isNavBarVisible
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 28,
                      spreadRadius: 6,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ConvexAppBar(
                  controller: _tabController,
                  initialActiveIndex: index,
                  style: TabStyle.react,
                  height: 55.h,
                  curveSize: 90,
                  backgroundColor: bg,
                  activeColor: primary,
                  color: inactive,
                  elevation: 0,
                  items: _navItems,
                  onTap: (i) {
                    setState(() {
                      index = i;
                      _isNavBarVisible = true;
                    });
                    _tabController.animateTo(i);
                    // Smooth slide between tabs — kills the hard-snap visual
                    // ("ugly refresh") people kept complaining about.
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}