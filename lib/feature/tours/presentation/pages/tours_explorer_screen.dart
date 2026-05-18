import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/recommendation_mappings.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/services/weather_controller.dart';
import '../../../../core/widgets/shimmer_loading_widget.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../domain/entities/tour_entity.dart';
import '../bloc/explorer_tours_cubit.dart';
import '../bloc/explorer_tours_state.dart';
import 'tour_detail_screen.dart';
import '../widgets/tour_card.dart';

class ToursExplorerScreen extends StatelessWidget {
  const ToursExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExplorerToursCubit>()..loadTours(),
      child: const ToursExplorerView(),
    );
  }
}

class ToursExplorerView extends StatefulWidget {
  const ToursExplorerView({super.key});

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

  // Personalised tour carousel — fetched once when tours load
  List<TourEntity> _recommendedTours = [];
  bool _loadingRecs = true;
  bool _recsLoadAttempted = false;

  /// Builds the rec engine candidate payload from a tour. Uses keyword inference
  /// over `title + destinations + description` so the engine has canonical
  /// types/tags to score against the user's tasteVector.
  Map<String, dynamic> _candidateForTour(TourEntity t) {
    final text = '${t.title} ${t.destinations.join(' ')} ${t.description}';
    final inferred = RecommendationMappings.inferKeysFromText(text);
    return {
      'placeId': t.id,
      'name': t.title,
      'types': inferred['types']!,
      'tags': inferred['tags']!,
      'rating': t.rating,
      'userRatingCount': t.reviewCount,
      'lat': t.meetingLatitude,
      'lng': t.meetingLongitude,
    };
  }

  Future<void> _loadRecommendations(List<TourEntity> allTours) async {
    if (_recsLoadAttempted) return;
    _recsLoadAttempted = true;
    if (allTours.length < 2) {
      if (mounted) setState(() => _loadingRecs = false);
      return;
    }
    final candidates = allTours.map(_candidateForTour).toList();
    // Tours pool is small and finite (a handful per city). DON'T exclude
    // previously-seen — otherwise after a user opens 2-3 tour details there's
    // nothing left to recommend.
    final result = await RecommendationService.recommendPlaces(
      candidates: candidates,
      context: 'tours',
      limit: 6,
      excludeSeen: false,
      weather: WeatherController.weather.value,
    );
    if (!mounted) return;
    if (result == null || result.recommendations.isEmpty) {
      setState(() => _loadingRecs = false);
      return;
    }
    final idToTour = {for (final t in allTours) t.id: t};
    final ordered = result.recommendations
        .map((r) => idToTour[r.placeId])
        .whereType<TourEntity>()
        .toList();
    setState(() {
      _recommendedTours = ordered;
      _loadingRecs = false;
    });
  }

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
                        Text(' ${tempRating.toInt()}+ stars', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
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
                        selectedColor: primary.withValues(alpha: 0.2),
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

          // Kick off rec fetch once, the first time we have tours
          if (state is ExplorerToursLoaded && !_recsLoadAttempted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadRecommendations(allTours);
            });
          }

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
                        backgroundColor: primary.withValues(alpha: 0.08),
                        side: BorderSide(color: primary.withValues(alpha: 0.2)),
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
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('rating'))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          avatar: const Icon(Icons.star, color: Colors.amber, size: 16),
                          label: Text('${_minRating.toInt()}+', style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() { _activeFilters.remove('rating'); _minRating = 0; }),
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('frequency') && _selectedFrequency != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(_selectedFrequency!, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() { _activeFilters.remove('frequency'); _selectedFrequency = null; }),
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Recommended for You — personalised tour carousel
              if (state is ExplorerToursLoaded &&
                  (_loadingRecs || _recommendedTours.isNotEmpty))
                _RecommendedToursCarousel(
                  tours: _recommendedTours,
                  loading: _loadingRecs,
                  primary: primary,
                  onSurface: onSurface,
                ),

              // Results count
              if (state is ExplorerToursLoaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_applyFiltersAndSort(allTours).length} tours found',
                        style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
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
          Icon(Icons.travel_explore, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          const Text('No tours found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _activeFilters.isNotEmpty
                ? 'Try adjusting your filters.'
                : 'Try adjusting your search query.',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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

// ── Recommended for You carousel ──────────────────────────────────────────────
//
// Personalised horizontal scroll above the standard tour list. Compact 220×180
// cards (image + title + rating). Shows 3 skeleton cards while loading; hides
// completely if the engine has nothing to suggest (e.g. brand-new user with no
// taste signals yet) so we don't waste vertical space.

class _RecommendedToursCarousel extends StatelessWidget {
  final List<TourEntity> tours;
  final bool loading;
  final Color primary;
  final Color onSurface;

  const _RecommendedToursCarousel({
    required this.tours,
    required this.loading,
    required this.primary,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: primary),
                const SizedBox(width: 6),
                Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Marcellus',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: loading ? 3 : tours.length,
              itemBuilder: (context, i) {
                if (loading) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const ShimmerLoadingWidget.rectangular(
                        width: 220,
                        height: 180,
                      ),
                    ),
                  );
                }
                final tour = tours[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _RecommendedTourCard(tour: tour),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedTourCard extends StatelessWidget {
  final TourEntity tour;
  const _RecommendedTourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
      ),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (tour.images.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tour.images.first,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                errorWidget: (_, _, _) => Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  child: Icon(Icons.tour,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      size: 36),
                ),
              )
            else
              Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                child: Icon(Icons.tour,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    size: 36),
              ),
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            // Rating pill
            if (tour.rating > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        tour.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Title + meeting location
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Marcellus',
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tour.meetingLocationName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            tour.meetingLocationName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
