import 'package:flutter/material.dart';
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

class _HomeWrapperState extends State<HomeWrapper> {
  final PageController _controller = PageController();

  int index = 0; // start at home

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
      extendBody: true, // ✅ يخلي الباترن يبان تحت الـ bottom bar

      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => index = i),
        children: pages,
      ),

      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: index, // ✅ مش ثابت
        style: TabStyle.reactCircle,
        height: 70,
        curveSize: 90,

        // ✅ خليها semi-transparent عشان الباترن يظهر تحتها
        backgroundColor: const Color(0xffE9E4BC).withOpacity(0.85),

        activeColor: const Color(0xff4D5420),
        color: const Color(0xff4D5420).withOpacity(0.55),
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
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
