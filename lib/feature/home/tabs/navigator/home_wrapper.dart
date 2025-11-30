import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../camra/camra_screen.dart';
import '../community/community_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../more/more_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final PageController _controller = PageController();
  int index = 0;

  final pages = const [
    HomeScreen(),
    CommunityScreen(),
    CameraScreen(),
    MapScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // PAGEVIEW (correct)
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => index = i),
        children: pages,  // ✔ must be a list of widgets
      ),

      // BOTTOM BAR (correct)
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: 0,
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
          _controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
