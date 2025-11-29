import 'package:flutter/material.dart';
import 'fancy_nav_bar.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int pageIndex = 0;
  final PageController controller = PageController();

  void changePage(int index) {
    setState(() => pageIndex = index);
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: PageView(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => pageIndex = i),
        children: const [
          Center(child: Text("Home")),
          Center(child: Text("Community")),
          Center(child: Text("Camera")),
          Center(child: Text("Map")),
          Center(child: Text("More")),
        ],
      ),

      bottomNavigationBar: FancyNavBar(
        currentIndex: pageIndex,
        onTap: changePage,
      ),
    );
  }
}
