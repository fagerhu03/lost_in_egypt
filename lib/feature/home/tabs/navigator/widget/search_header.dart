import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;
  final VoidCallback? onTap;

  const SearchHeader({
    super.key,
    this.profileImageUrl,
    required this.onSignOut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final bgColor = isDark
        ? Colors.black.withOpacity(0.15)
        : primary.withOpacity(0.18);

    final textColor = isDark
        ? onSurface.withOpacity(0.92)
        : Colors.white.withOpacity(0.92);

    final iconColor = textColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.10),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Where do you want to go?",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                ),
              ),
            ),
            Icon(
              Icons.search,
              color: iconColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
