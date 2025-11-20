import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final int index;
  final VoidCallback onNext;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.5), // Adjust opacity to make it darker or lighter
            colorBlendMode: BlendMode.darken,
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: ClipPath(
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
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,fontFamily: "Marcellus",
                      color: Color(0xFF4D5420),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontFamily: "Marcellus",
                      color: Color(0xFF4D5420),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // NEXT BUTTON
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
                  _dots(index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dots(int active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color:
            active == i ? const Color(0xFF4D5420) : Colors.grey.shade400,
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
