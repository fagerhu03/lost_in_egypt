import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UfoOverlay extends StatefulWidget {
  const UfoOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "UFO",
      barrierColor: Colors.transparent, // Invisible barrier so map is seen
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const UfoOverlay();
      },
    );
  }

  @override
  State<UfoOverlay> createState() => _UfoOverlayState();
}

class _UfoOverlayState extends State<UfoOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _horizontalAnimation;
  late Animation<double> _verticalAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Moves from off-screen left to off-screen right
    _horizontalAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Bobs up and down slightly
    _verticalAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.3), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a Material with transparent background just to hold the animation over the map
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: width * _horizontalAnimation.value,
                top: height * _verticalAnimation.value,
                child: Text(
                  "🛸",
                  style: TextStyle(
                    fontSize: 64.sp,
                    shadows: const [
                      Shadow(
                        color: Colors.greenAccent,
                        blurRadius: 20,
                      )
                    ]
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
