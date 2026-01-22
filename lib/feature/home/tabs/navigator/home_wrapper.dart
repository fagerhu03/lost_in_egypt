import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Needed for ScrollDirection
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../camra/camra_screen.dart';
import '../community/presentation/community_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../more/more_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  int index = 0;
  
  // ⭐ NEW: Track if bar is visible
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      
      // ⭐ 1. Wrap Body to listen for scrolls coming from children
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          // Only react if we are on the Community Tab (index 1)
          if (index == 1) {
            if (notification.direction == ScrollDirection.reverse && _isNavBarVisible) {
              // Scrolling Down -> Hide
              setState(() => _isNavBarVisible = false);
            } else if (notification.direction == ScrollDirection.forward && !_isNavBarVisible) {
              // Scrolling Up -> Show
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
              // ⭐ Always show bar when switching tabs
              _isNavBarVisible = true; 
            });
            _tabController.animateTo(i);
          },
          children: pages,
        ),
      ),

      // ⭐ 2. Animate the Bottom Bar height
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1), // (0,1) slides it down 100% of its height
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
            setState(() => index = i);
            _pageController.jumpToPage(i);
          },
        ),
      ),
    );
  }
}