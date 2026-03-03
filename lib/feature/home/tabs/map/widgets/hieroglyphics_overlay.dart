import 'dart:math';
import 'package:flutter/material.dart';

class HieroglyphicsOverlay extends StatefulWidget {
  const HieroglyphicsOverlay({super.key});

  static void show(BuildContext context) {
    bool isPopped = false;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Allow user to tap away if they want to
      barrierLabel: "Hieroglyphics Matrix",
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 1000),
      pageBuilder: (dialogContext, anim1, anim2) {
        // Auto dismiss after 3.5 seconds
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (!isPopped && dialogContext.mounted) {
            isPopped = true;
            Navigator.of(dialogContext).pop();
          }
        });
        
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            isPopped = true;
          },
          child: const HieroglyphicsOverlay()
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  State<HieroglyphicsOverlay> createState() => _HieroglyphicsOverlayState();
}

class _HieroglyphicsOverlayState extends State<HieroglyphicsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MatrixRainPainter(
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: const Text(
                    "CURSE RELEASED",
                    style: TextStyle(
                      fontFamily: "Marcellus",
                      fontSize: 36,
                      color: Color(0xFFC79A00),
                      letterSpacing: 8.0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.red, blurRadius: 20),
                        Shadow(color: Colors.amber, blurRadius: 40),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixRainPainter extends CustomPainter {
  final double animationValue;
  
  // Safe cross-platform ancient-looking symbols, mix of latin and basic shapes
  final List<String> symbols = [
    '☥', '𓂀', '𓆣', '𓁤', 'A', 'X', 'O', 'I', 'V', 'T', 'M', 'W', '∇', '∆', '⍋', '⍒', '⍟', '☀', '☾', '★'
  ];

  _MatrixRainPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Columns setup
    const double fontSize = 20.0;
    final int columns = (size.width / fontSize).floor();
    
    for (int i = 0; i < columns; i++) {
      // Stable randomization per column based on its index
      Random r = Random(i);
      
      double speed = 0.2 + (r.nextDouble() * 0.8); // 0.2 to 1.0
      
      double totalHeight = size.height + 400;
      double offset = r.nextDouble() * totalHeight;
      double yPos = ((animationValue * speed * 3000 + offset) % totalHeight) - 200;
      
      int tailLength = 10 + r.nextInt(15);
      
      for (int j = 0; j < tailLength; j++) {
        // dynamic char selection changing fast but stable per position
        int charIndex = (DateTime.now().millisecondsSinceEpoch ~/ 150 + i * j) % symbols.length;
        String char = symbols[charIndex];
        
        // head is bright gold, tail fades to dark maroon/black
        double alpha = 1.0 - (j / tailLength);
        Color color = j == 0 
            ? const Color(0xFFFFD700) 
            : const Color(0xFFC79A00).withValues(alpha: alpha);
            
        textPainter.text = TextSpan(
          text: char,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: j == 0 ? FontWeight.bold : FontWeight.normal,
            shadows: j == 0 ? [const Shadow(color: Colors.amber, blurRadius: 10)] : null,
          ),
        );
        
        textPainter.layout();
        // Paint upwards to form the tail behind the descending head
        textPainter.paint(canvas, Offset(i * fontSize, yPos - (j * fontSize * 1.2)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) => true;
}
