import 'package:flutter/material.dart';
import 'dart:ui';

class FancyNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FancyNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xffE9E4BC),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.home_filled, 0),
          _navItem(Icons.explore_outlined, 1),
          _navItem(Icons.camera_alt_rounded, 2),
          _navItem(Icons.map_rounded, 3),
          _navItem(Icons.more_horiz, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool active = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? const Color(0xff4D5420).withOpacity(0.18) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: active ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            icon,
            size: 28,
            color: active ? const Color(0xff4D5420) : const Color(0xff4D5420).withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
