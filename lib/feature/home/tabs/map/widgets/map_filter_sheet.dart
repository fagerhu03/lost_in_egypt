import 'package:flutter/material.dart';
import '../map_config.dart';
import '../../home/data/models/map_item_models.dart';

class MapFilterSheet extends StatelessWidget {
  final String selectedCategory;
  final List<MapItem> allItems;
  final Function(String) onCategorySelected;

  const MapFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.allItems,
    required this.onCategorySelected,
  });

  bool _shouldShowItem(MapItem item) {
    return !MapConfig.excludedCategories.contains(item.category.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final dividerColor = onSurface.withOpacity(0.10);

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
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.12),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(isDark ? 0.25 : 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      "Filter by Category",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedCategory == 'all'
                            ? primary.withOpacity(0.12)
                            : Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedCategory == 'all'
                              ? primary.withOpacity(0.25)
                              : Colors.green.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        selectedCategory == 'all' ? 'Zoom Filter ON' : 'Showing All',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedCategory == 'all' ? primary : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: dividerColor),

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
                        : allItems
                        .where((item) =>
                    item.category.toLowerCase() ==
                        category.id.toLowerCase())
                        .length;

                    return Container(
                      color: surface,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withOpacity(0.14)
                                : onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.06),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        title: Text(
                          category.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primary : onSurface,
                          ),
                        ),
                        subtitle: Text(
                          category.id == 'all'
                              ? '$count places • Zoom to see more'
                              : '$count places',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.70),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: primary)
                            : Icon(Icons.chevron_right, color: onSurface.withOpacity(0.45)),
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