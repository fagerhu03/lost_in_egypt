import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';

class MapSearchResults extends StatelessWidget {
  final List<MapItem> searchResults;
  final bool hasSearchText;
  final Function(MapItem) onSearchResultTapped;

  const MapSearchResults({
    super.key,
    required this.searchResults,
    required this.hasSearchText,
    required this.onSearchResultTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    if (searchResults.isEmpty && hasSearchText) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: isDark ? 0.94 : 0.98),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: onSurface.withValues(alpha: 0.4),
              size: 20.r,
            ),
            SizedBox(width: 8.w),
            Text(
              AppLocalizations.of(context).mapNoPlacesFound,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      constraints: BoxConstraints(maxHeight: 300.h),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.94 : 0.98),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: searchResults.length,
          separatorBuilder: (_, _) => Divider(
            height: 1.h,
            color: onSurface.withValues(alpha: 0.07),
          ),
          itemBuilder: (context, index) {
            final item = searchResults[index];
            String categoryIcon = '📍';
            try {
              final cat = MapConfig.categories.firstWhere(
                (c) => c.id.toLowerCase() == item.category.toLowerCase(),
              );
              categoryIcon = cat.icon;
            } catch (_) {}

            return InkWell(
              onTap: () => onSearchResultTapped(item),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categoryIcon,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.category.toUpperCase(),
                            style: TextStyle(
                              color: primary.withValues(alpha: 0.8),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: onSurface.withValues(alpha: 0.25),
                      size: 14.r,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
