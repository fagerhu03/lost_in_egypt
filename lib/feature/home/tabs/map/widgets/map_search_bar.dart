import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'hieroglyphics_overlay.dart';
import 'ufo_overlay.dart';
import 'sandstorm_overlay.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onClearSearch;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 14.w),
          Icon(
            Icons.search_rounded,
            color: onSurface.withValues(alpha: 0.5),
            size: 22.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              style: TextStyle(
                color: onSurface,
                fontSize: 15.sp,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                final lower = value.trim().toLowerCase();
                if (lower == "1922") {
                  searchController.clear();
                  searchFocusNode.unfocus();
                  HieroglyphicsOverlay.show(context);
                } else if (lower == "alien" || lower == "ufo" || lower == "area 51") {
                  searchController.clear();
                  searchFocusNode.unfocus();
                  UfoOverlay.show(context);
                } else if (lower == "sandstorm") {
                  searchController.clear();
                  searchFocusNode.unfocus();
                  SandstormOverlay.show(context);
                }
              },
              decoration: InputDecoration(
                hintText: 'Search places...',
                hintStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 15.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClearSearch,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: Icon(
                    Icons.close_rounded,
                    color: onSurface.withValues(alpha: 0.5),
                    size: 20.r,
                  ),
                ),
              ),
            )
          else
            SizedBox(width: 14.w),
        ],
      ),
    );
  }
}
