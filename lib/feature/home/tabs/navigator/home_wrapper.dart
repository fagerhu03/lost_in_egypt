import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final PageController _controller = PageController();

  int index = 0;   // start at home

  final pages = const [
    Center(child: Text("Home", style: TextStyle(fontSize: 28))),
    Center(child: Text("Explore", style: TextStyle(fontSize: 28))),
    Center(child: Text("Camera", style: TextStyle(fontSize: 28))),
    Center(child: Text("Map", style: TextStyle(fontSize: 28))),
    Center(child: Text("More", style: TextStyle(fontSize: 28))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // ⭐ PAGEVIEW for animated navigation
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) {
          setState(() => index = i);
        },
        children: pages,
      ),

      // ⭐ REACT CIRCLE BOTTOM BAR
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: 0,
        style: TabStyle.reactCircle,  // ← THIS STYLE

        height: 70,
        curveSize: 90,
        // ❗ remove cornerRadius or bar breaks

        backgroundColor: const Color(0xffE9E4BC),
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

          // ⭐ FULL ANIMATED SLIDE
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
