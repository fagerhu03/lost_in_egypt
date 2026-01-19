import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../camra/camra_screen.dart';
import '../community/community_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../more/more_screen.dart';

// ⭐ 1. Add 'with SingleTickerProviderStateMixin' here
class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  
  // ⭐ 2. Add a TabController to sync the bar with the swipe
  late TabController _tabController;
  int index = 0;

  final pages = const [
    HomeScreen(),      // 0
    CommunityScreen(), // 1
    CameraScreen(),    // 2
    MapScreen(),       // 3
    MoreScreen(),      // 4
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the controller with 5 tabs
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: PageView(
        controller: _pageController,
        
        // Disable swipe ONLY on the Map tab (index 3)
        physics: index == 3 
            ? const NeverScrollableScrollPhysics() 
            : const BouncingScrollPhysics(),
            
        onPageChanged: (i) {
          setState(() => index = i);
          // ⭐ 3. Sync: When page swipes, move the bottom bar
          _tabController.animateTo(i);
        },
        children: pages,
      ),

      bottomNavigationBar: ConvexAppBar(
        // ⭐ 4. Connect the controller here
        controller: _tabController,
        
        style: TabStyle.react,
        height: 50,
        curveSize: 90,
        backgroundColor: const Color(0xffE9E4BC),
        activeColor: const Color(0xff4D5420),
        color: const Color(0xff4D5420).withOpacity(0.60),
        elevation: 12,

        items: const [
          TabItem(icon: Icons.home_filled, title: "Home"),
          TabItem(icon: Icons.explore, title: "Community"),
          TabItem(icon: Icons.camera_alt_rounded, title: "Camera"),
          TabItem(icon: Icons.map_rounded, title: "Map"),
          TabItem(icon: Icons.more_horiz, title: "More"),
        ],

        onTap: (i) {
          setState(() => index = i);
          // ⭐ 5. Sync: When bar tapped, move the page
          _pageController.jumpToPage(i);
        },
      ),
    );
  }
}