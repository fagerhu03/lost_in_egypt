import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackBackgroundColor;
  final Color? fallbackIconColor;
  final double? fallbackIconSize;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const ShimmerImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fallbackBackgroundColor,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final bg = fallbackBackgroundColor ?? onSurface.withValues(alpha: 0.08);
    final iconColor = fallbackIconColor ?? onSurface.withValues(alpha: 0.4);
    final iconSize = fallbackIconSize ?? 32;
    final radius = borderRadius ?? BorderRadius.zero;

    if (url == null || url!.isEmpty) {
      return _fallback(bg, iconColor, iconSize, radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (_, _) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            color: Colors.grey[400],
          ),
        ),
        errorWidget: (_, _, _) => _fallback(bg, iconColor, iconSize, radius),
      ),
    );
  }

  Widget _fallback(Color bg, Color iconColor, double iconSize, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: iconSize, color: iconColor),
    );
  }
}
