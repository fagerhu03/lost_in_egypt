import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/widget/search_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shimmer_loading_widget.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../domain/entities/tour_entity.dart';
import '../bloc/explorer_tours_cubit.dart';
import '../bloc/explorer_tours_state.dart';
import 'tour_detail_screen.dart';
import '../widgets/tour_card.dart';

class ToursExplorerScreen extends StatelessWidget {
  const ToursExplorerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExplorerToursCubit>()..loadTours(),
      child: const ToursExplorerView(),
    );
  }
}

class ToursExplorerView extends StatefulWidget {
  const ToursExplorerView({Key? key}) : super(key: key);

  @override
  State<ToursExplorerView> createState() => _ToursExplorerViewState();
}

enum _SortOption { newest, cheapest, priciest, highestRated, mostPopular }

class _ToursExplorerViewState extends State<ToursExplorerView> {
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.newest;

  // Filters
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minRating = 0;
  String? _selectedFrequency;
  final Set<String> _activeFilters = {};

  List<TourEntity> _applyFiltersAndSort(List<TourEntity> tours) {
    var filtered = tours.where((t) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!t.title.toLowerCase().contains(q) &&
            !t.destinations.any((d) => d.toLowerCase().contains(q)) &&
            !t.meetingLocationName.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Price filter
      if (_activeFilters.contains('price')) {
        if (t.price < _priceRange.start || t.price > _priceRange.end) return false;
      }
      // Rating filter
      if (_activeFilters.contains('rating')) {
        if (t.rating < _minRating) return false;
      }
      // Frequency filter
      if (_selectedFrequency != null && _activeFilters.contains('frequency')) {
        if (t.frequency != _selectedFrequency) return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortOption) {
      case _SortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.cheapest:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _SortOption.priciest:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _SortOption.highestRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.mostPopular:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    return filtered;
  }

  void _showFilterSheet(BuildContext context, List<TourEntity> allTours) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // Calculate actual max price from tours
    final maxPrice = allTours.isNotEmpty
        ? allTours.map((t) => t.price).reduce((a, b) => a > b ? a : b).ceilToDouble() + 10
        : 10000.0;

    // Local state for the sheet
    RangeValues tempPrice = _priceRange;
    double tempRating = _minRating;
    String? tempFrequency = _selectedFrequency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempPrice = RangeValues(0, maxPrice);
                            tempRating = 0;
                            tempFrequency = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price Range
                  Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EGP ${tempPrice.start.round()}', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                      Text('EGP ${tempPrice.end.round()}', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(tempPrice.start.clamp(0, maxPrice), tempPrice.end.clamp(0, maxPrice)),
                    min: 0,
                    max: maxPrice,
                    divisions: (maxPrice / 5).round().clamp(1, 200),
                    activeColor: primary,
                    labels: RangeLabels('${tempPrice.start.round()}', '${tempPrice.end.round()}'),
                    onChanged: (v) => setSheetState(() => tempPrice = v),
                  ),
                  const SizedBox(height: 16),

                  // Minimum Rating
                  Text('Minimum Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setSheetState(() => tempRating = tempRating == i.toDouble() ? 0 : i.toDouble()),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              i <= tempRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        ),
                      if (tempRating > 0)
                        Text(' ${tempRating.toInt()}+ stars', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Frequency
                  Text('Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Daily', 'Weekly', 'Weekends', 'One-Time'].map((f) {
                      final isSelected = tempFrequency == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        selectedColor: primary.withOpacity(0.2),
                        onSelected: (v) => setSheetState(() => tempFrequency = v ? f : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Apply
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          _priceRange = tempPrice;
                          _minRating = tempRating;
                          _selectedFrequency = tempFrequency;
                          _activeFilters.clear();
                          if (tempPrice.start > 0 || tempPrice.end < maxPrice) _activeFilters.add('price');
                          if (tempRating > 0) _activeFilters.add('rating');
                          if (tempFrequency != null) _activeFilters.add('frequency');
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Discover Tours',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Marcellus',
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<ExplorerToursCubit, ExplorerToursState>(
        builder: (context, state) {
          List<TourEntity> allTours = [];
          if (state is ExplorerToursLoaded) allTours = state.tours;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search destinations, guides...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Badge(
                        isLabelVisible: _activeFilters.isNotEmpty,
                        label: Text('${_activeFilters.length}'),
                        child: Icon(Icons.tune, color: onSurface),
                      ),
                      onPressed: () => _showFilterSheet(context, allTours),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Sort + Active Filter Chips row
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Sort chip
                    PopupMenuButton<_SortOption>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) => setState(() => _sortOption = v),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: _SortOption.newest, child: Text('Newest First')),
                        const PopupMenuItem(value: _SortOption.cheapest, child: Text('Cheapest First')),
                        const PopupMenuItem(value: _SortOption.priciest, child: Text('Priciest First')),
                        const PopupMenuItem(value: _SortOption.highestRated, child: Text('Highest Rated')),
                        const PopupMenuItem(value: _SortOption.mostPopular, child: Text('Most Popular')),
                      ],
                      child: Chip(
                        avatar: Icon(Icons.sort, size: 16, color: primary),
                        label: Text(_sortLabel(), style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600)),
                        backgroundColor: primary.withOpacity(0.08),
                        side: BorderSide(color: primary.withOpacity(0.2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Active filter chips
                    if (_activeFilters.contains('price'))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text('EGP ${_priceRange.start.round()}-${_priceRange.end.round()}', style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _activeFilters.remove('price')),
                          backgroundColor: primary.withOpacity(0.08),
                          side: BorderSide(color: primary.withOpacity(0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('rating'))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                          label: Text('${_minRating.toInt()}+', style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() { _activeFilters.remove('rating'); _minRating = 0; }),
                          backgroundColor: primary.withOpacity(0.08),
                          side: BorderSide(color: primary.withOpacity(0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('frequency') && _selectedFrequency != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(_selectedFrequency!, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() { _activeFilters.remove('frequency'); _selectedFrequency = null; }),
                          backgroundColor: primary.withOpacity(0.08),
                          side: BorderSide(color: primary.withOpacity(0.2)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Results count
              if (state is ExplorerToursLoaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_applyFiltersAndSort(allTours).length} tours found',
                        style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _buildBody(state, allTours, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ExplorerToursState state, List<TourEntity> allTours, ThemeData theme) {
    if (state is ExplorerToursLoading) return _buildShimmerLoading();
    if (state is ExplorerToursError) {
      return AppErrorWidget(
        message: 'Could not load tours.\nCheck your connection and try again.',
        onRetry: () => context.read<ExplorerToursCubit>().loadTours(),
      );
    }
    if (state is ExplorerToursLoaded) {
      final filtered = _applyFiltersAndSort(allTours);
      if (filtered.isEmpty) return _buildEmptyState(theme);
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TourCard(tour: filtered[index]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _sortLabel() {
    switch (_sortOption) {
      case _SortOption.newest: return 'Newest';
      case _SortOption.cheapest: return 'Cheapest';
      case _SortOption.priciest: return 'Priciest';
      case _SortOption.highestRated: return 'Top Rated';
      case _SortOption.mostPopular: return 'Popular';
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text('No tours found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _activeFilters.isNotEmpty
                ? 'Try adjusting your filters.'
                : 'Try adjusting your search query.',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          if (_activeFilters.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() { _activeFilters.clear(); _minRating = 0; _selectedFrequency = null; }),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const ShimmerLoadingWidget.rectangular(height: 280),
        ),
      ),
    );
  }
}
