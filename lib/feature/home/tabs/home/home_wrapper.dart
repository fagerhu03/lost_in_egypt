import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

// ✅ CRITICAL: Use the package import
import 'package:lost_in_egypt/feature/home/tabs/map/services/map_focus_service.dart';

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
  final GlobalKey<ConvexAppBarState> _appBarKey = GlobalKey<ConvexAppBarState>();
  int index = 0;

  final pages = const [
    HomeScreen(),      // 0
    CommunityScreen(), // 1
    CameraScreen(),    // 2
    MapScreen(),       // 3
    MoreScreen(),      // 4
  ];

  @override
  Widget build(BuildContext context) {
    // ⭐ LISTENER: Watches for the "Switch Tab" signal
    return ValueListenableBuilder<int?>(
      valueListenable: MapFocusService.instance.tabSwitchNotifier,
      builder: (context, targetIndex, child) {
        
        if (targetIndex != null) {
          print("🏠 HOME WRAPPER: Switching to Tab $targetIndex");
          
          // Use postFrameCallback to avoid build conflicts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (index != targetIndex) {
              setState(() => index = targetIndex);
              _controller.jumpToPage(targetIndex);
              _appBarKey.currentState?.animateTo(targetIndex);
            }
            // Clear the signal so it doesn't loop
            MapFocusService.instance.tabSwitchNotifier.value = null;
          });
        }

        return Scaffold(
          extendBody: true,
          body: PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => index = i),
            children: pages,
          ),
          bottomNavigationBar: ConvexAppBar(
            key: _appBarKey,
            initialActiveIndex: index,
            style: TabStyle.reactCircle,
            height: 70,
            curveSize: 90,
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
              _controller.jumpToPage(i);
            },
          ),
        );
      },
    );
  }
}