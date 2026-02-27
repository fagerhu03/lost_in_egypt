import 'package:flutter/material.dart';
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
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.18);

    if (searchResults.isEmpty && hasSearchText) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface.withOpacity(isDark ? 0.94 : 0.98),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: onSurface.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No places found',
              style: TextStyle(
                color: onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: surface.withOpacity(isDark ? 0.94 : 0.98),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: searchResults.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: onSurface.withOpacity(0.07),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categoryIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category.toUpperCase(),
                            style: TextStyle(
                              color: primary.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: onSurface.withOpacity(0.25),
                      size: 14,
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
