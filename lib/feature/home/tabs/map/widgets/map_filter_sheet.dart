import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';
import '../../home/data/models/map_item_models.dart';

class MapFilterSheet extends StatelessWidget {
  final String selectedCategory;
  final List<MapItem> allItems;
  final Function(String) onCategorySelected;
  final Set<String> savedPlaceIds;

  const MapFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.allItems,
    required this.onCategorySelected,
    this.savedPlaceIds = const {},
  });

  bool _shouldShowItem(MapItem item) {
    return !MapConfig.excludedCategories.contains(item.category.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final dividerColor = onSurface.withValues(alpha: 0.10);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: isDark ? 0.25 : 0.18),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    Text(
                      l10n.mapFilterByCategory,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: selectedCategory == 'all'
                            ? primary.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: selectedCategory == 'all'
                              ? primary.withValues(alpha: 0.25)
                              : Colors.green.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        selectedCategory == 'all' ? l10n.mapZoomFilterOn : l10n.mapShowingAll,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: selectedCategory == 'all' ? primary : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1.h, color: dividerColor),

              // Category list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: MapConfig.categories.length,
                  itemBuilder: (context, index) {
                    final category = MapConfig.categories[index];
                    final isSelected = category.id == selectedCategory;

                    final count = category.id == 'all'
                        ? allItems.where(_shouldShowItem).length
                        : category.id == 'favorites'
                            ? savedPlaceIds.length
                            : category.id == 'open_now'
                                ? allItems.where((item) => item.isCurrentlyOpen).length
                                : allItems
                            .where((item) =>
                    item.category.toLowerCase() ==
                        category.id.toLowerCase())
                            .length;

                    return Container(
                      color: surface,
                      child: ListTile(
                        leading: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withValues(alpha: 0.14)
                                : onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.06),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category.icon,
                              style: TextStyle(fontSize: 20.sp),
                            ),
                          ),
                        ),
                        title: Text(
                          mapCategoryLabel(l10n, category),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primary : onSurface,
                          ),
                        ),
                        subtitle: Text(
                          category.id == 'all'
                              ? l10n.mapCatPlacesZoom(count)
                              : category.id == 'favorites'
                                  ? l10n.mapCatSavedPlaces(count)
                                  : l10n.mapCatPlaces(count),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: primary)
                            : Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.45)),
                        onTap: () => onCategorySelected(category.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
