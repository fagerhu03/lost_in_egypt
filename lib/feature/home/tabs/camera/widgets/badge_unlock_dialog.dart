import 'package:flutter/material.dart';
import '../../account/domain/badge_model.dart';
import 'dart:math' as math;

class BadgeUnlockDialog extends StatefulWidget {
  final BadgeModel badge;

  const BadgeUnlockDialog({super.key, required this.badge});

  static void show(BuildContext context, BadgeModel badge) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Badge Unlocked",
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) => BadgeUnlockDialog(badge: badge),
      transitionBuilder: (context, anim1, anim2, child) {
        // Curve for a smooth popping effect
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors matching the AccountScreen prototype
    final Color cardColor =
        isDark ? theme.colorScheme.surface.withValues(alpha: 0.9) : const Color(0xFFF3F2E4);
    final Color textColor = isDark ? Colors.white : const Color(0xFF6B3A28);
    final Color goldButtonColor = const Color(0xFFC79A00);
    final Color bodyTextColor =
        isDark ? Colors.white70 : const Color(0xFF6B3A28).withValues(alpha: 0.8);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white12 : goldButtonColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "New Badge Unlocked!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Animated Glowing Badge Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: goldButtonColor.withValues(alpha: 0.15),
                        border: Border.all(color: goldButtonColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: goldButtonColor.withValues(
                                alpha: 0.4 * (_pulseAnimation.value - 0.5)),
                            blurRadius: 25,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating inner glow
                          Transform.rotate(
                            angle: _pulseController.value * 2 * math.pi,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Colors.transparent,
                                    goldButtonColor.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // The Badge Icon itself
                          Icon(widget.badge.iconData, color: goldButtonColor, size: 55),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              Text(
                widget.badge.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Marcellus",
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.badge.description,
                style: TextStyle(
                  fontSize: 15,
                  color: bodyTextColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldButtonColor,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Awesome!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
