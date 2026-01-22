import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../camera/camera_screen.dart';
import '../community/presentation/community_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../more/more_screen.dart';

import 'package:lost_in_egypt/feature/home/tabs/map/services/map_focus_service.dart';

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

  final pages = const [
    HomeScreen(),
    CommunityScreen(),
    CameraScreen(),
    MapScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    MapFocusService.instance.tabSwitchNotifier.addListener(_handleTabSwitch);
  }

  void _handleTabSwitch() {
    final int i = MapFocusService.instance.tabSwitchNotifier.value;
    if (!mounted) return;

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
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          physics: index == 3
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: (i) {
            setState(() {
              index = i;
              _isNavBarVisible = true;
            });
            _tabController.animateTo(i);
          },
          children: pages,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1),
        child: ConvexAppBar(
          controller: _tabController,
          style: TabStyle.react,
          height: 55,
          curveSize: 90,
          backgroundColor: const Color(0xffFCFBE8),
          activeColor: const Color(0xff714611),
          color: const Color(0xff714611).withOpacity(0.60),
          elevation: 12,
          items: const [
            TabItem(icon: Icons.home_filled, title: "Home"),
            TabItem(icon: Icons.people_rounded, title: "Community"),
            TabItem(icon: Icons.camera_alt_rounded, title: "Camera"),
            TabItem(icon: Icons.map_rounded, title: "Map"),
            TabItem(icon: Icons.more_horiz, title: "More"),
          ],
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
    );
  }
}
