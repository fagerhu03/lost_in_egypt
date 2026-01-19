import 'package:flutter/material.dart';

class TrianglePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final int index;
  final int total;
  final VoidCallback onNext;

  const TrianglePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TriangleClipper(),
      child: Container(
        height: 360,
        width: double.infinity,
        color: const Color(0xffFCFBE8).withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),

            // ✅ تغيير العنوان بس من غير تحريك الشيب
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                title,
                key: ValueKey("title_$index"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Marcellus",
                  color: Color(0xFF4D5420),
                ),
              ),
            ),

            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                subtitle,
                key: ValueKey("sub_$index"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontFamily: "Marcellus",
                  color: Color(0xFF4D5420),
                ),
              ),
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: onNext,
              child: Container(
                width: 110,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF7A8450),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _dots(index, total),
          ],
        ),
      ),
    );
  }

  Widget _dots(int active, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: active == i ? const Color(0xFF4D5420) : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.18);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.18);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
