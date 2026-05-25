import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final IconData fallbackIcon;
  final Color? fallbackBackgroundColor;
  final Color? fallbackIconColor;
  final double? iconSize;

  const ShimmerAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.fallbackIcon = Icons.person,
    this.fallbackBackgroundColor,
    this.fallbackIconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final bg = fallbackBackgroundColor ?? onSurface.withValues(alpha: 0.08);
    final iconColor = fallbackIconColor ?? primary;
    final diameter = radius * 2;
    final resolvedIconSize = iconSize ?? radius;

    if (url == null || url!.isEmpty) {
      return _fallback(diameter, bg, iconColor, resolvedIconSize);
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        memCacheHeight: (diameter * 3).round(),
        memCacheWidth: (diameter * 3).round(),
        placeholder: (_, _) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
          child: Container(
            width: diameter,
            height: diameter,
            color: Colors.grey[400],
          ),
        ),
        errorWidget: (_, _, _) => _fallback(diameter, bg, iconColor, resolvedIconSize),
      ),
    );
  }

  Widget _fallback(double diameter, Color bg, Color iconColor, double size) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(fallbackIcon, size: size, color: iconColor),
    );
  }
}
