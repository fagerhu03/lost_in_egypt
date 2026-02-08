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
    return !MapConfig.excludedCategories
        .contains(item.category.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEF0), // ✅ same container color
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Text(
                      "Filter by Category",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedCategory == 'all'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedCategory == 'all'
                            ? 'Zoom Filter ON'
                            : 'Showing All',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedCategory == 'all'
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Category list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: MapConfig.categories.length,
                  itemBuilder: (context, index) {
                    final category = MapConfig.categories[index];
                    final isSelected =
                        category.id == selectedCategory;

                    final count = category.id == 'all'
                        ? allItems.where(_shouldShowItem).length
                        : allItems
                        .where(
                          (item) =>
                      item.category.toLowerCase() ==
                          category.id.toLowerCase(),
                    )
                        .length;

                    return Container(
                      color: const Color(0xFFFFFEF0), // same background
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              category.icon,
                              style:
                              const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        title: Text(
                          category.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          category.id == 'all'
                              ? '$count places • Zoom to see more'
                              : '$count places',
                          style:
                          const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context)
                              .primaryColor,
                        )
                            : const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () =>
                            onCategorySelected(category.id),
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