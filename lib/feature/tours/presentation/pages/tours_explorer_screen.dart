import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/recommendation_mappings.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/services/weather_controller.dart';
import '../../../../core/widgets/shimmer_image.dart';
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

  // Frequency values stay English (compared against `t.frequency`); display localized.
  String _frequencyLabel(AppLocalizations l10n, String f) {
    switch (f) {
      case 'Daily':
        return l10n.toursFreqDaily;
      case 'Weekly':
        return l10n.toursFreqWeekly;
      case 'Weekends':
        return l10n.toursFreqWeekends;
      case 'One-Time':
        return l10n.toursFreqOneTime;
      default:
        return f;
    }
  }

  void _showFilterSheet(BuildContext context, List<TourEntity> allTours) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);
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
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2.r))),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.toursFilters, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempPrice = RangeValues(0, maxPrice);
                            tempRating = 0;
                            tempFrequency = null;
                          });
                        },
                        child: Text(l10n.commonReset),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Price Range
                  Text(l10n.toursPriceRange, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 8.h),
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
                  SizedBox(height: 16.h),

                  // Minimum Rating
                  Text(l10n.toursMinRating, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      for (int i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setSheetState(() => tempRating = tempRating == i.toDouble() ? 0 : i.toDouble()),
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: 4.w),
                            child: Icon(
                              i <= tempRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32.r,
                            ),
                          ),
                        ),
                      if (tempRating > 0)
                        Text(' ${l10n.toursStarsPlus(tempRating.toInt())}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13.sp)),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Frequency
                  Text(l10n.toursFrequency, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: ['Daily', 'Weekly', 'Weekends', 'One-Time'].map((f) {
                      final isSelected = tempFrequency == f;
                      return ChoiceChip(
                        label: Text(_frequencyLabel(l10n, f)),
                        selected: isSelected,
                        selectedColor: primary.withValues(alpha: 0.2),
                        onSelected: (v) => setSheetState(() => tempFrequency = v ? f : null),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24.h),

                  // Apply
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
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
                      child: Text(l10n.toursApplyFilters, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.toursDiscoverTitle,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
            fontSize: 24.sp,
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.toursSearchHint,
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
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Sort + Active Filter Chips row
              SizedBox(
                height: 44.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    // Sort chip
                    PopupMenuButton<_SortOption>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      onSelected: (v) => setState(() => _sortOption = v),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: _SortOption.newest, child: Text(l10n.toursSortNewest)),
                        PopupMenuItem(value: _SortOption.cheapest, child: Text(l10n.toursSortCheapest)),
                        PopupMenuItem(value: _SortOption.priciest, child: Text(l10n.toursSortPriciest)),
                        PopupMenuItem(value: _SortOption.highestRated, child: Text(l10n.toursSortHighestRated)),
                        PopupMenuItem(value: _SortOption.mostPopular, child: Text(l10n.toursSortMostPopular)),
                      ],
                      child: Chip(
                        avatar: Icon(Icons.sort, size: 16.r, color: primary),
                        label: Text(_sortLabel(l10n), style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.w600)),
                        backgroundColor: primary.withValues(alpha: 0.08),
                        side: BorderSide(color: primary.withValues(alpha: 0.2)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Active filter chips
                    if (_activeFilters.contains('price'))
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: InputChip(
                          label: Text('EGP ${_priceRange.start.round()}-${_priceRange.end.round()}', style: TextStyle(fontSize: 12.sp)),
                          onDeleted: () => setState(() => _activeFilters.remove('price')),
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('rating'))
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: InputChip(
                          avatar: Icon(Icons.star, color: Colors.amber, size: 16.r),
                          label: Text('${_minRating.toInt()}+', style: TextStyle(fontSize: 12.sp)),
                          onDeleted: () => setState(() { _activeFilters.remove('rating'); _minRating = 0; }),
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                    if (_activeFilters.contains('frequency') && _selectedFrequency != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: InputChip(
                          label: Text(_frequencyLabel(l10n, _selectedFrequency!), style: TextStyle(fontSize: 12.sp)),
                          onDeleted: () => setState(() { _activeFilters.remove('frequency'); _selectedFrequency = null; }),
                          backgroundColor: primary.withValues(alpha: 0.08),
                          side: BorderSide(color: primary.withValues(alpha: 0.2)),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),

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
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Text(
                        l10n.toursFoundCount(_applyFiltersAndSort(allTours).length),
                        style: TextStyle(fontSize: 13.sp, color: onSurface.withValues(alpha: 0.5)),
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
        message: AppLocalizations.of(context).toursLoadError,
        onRetry: () => context.read<ExplorerToursCubit>().loadTours(),
      );
    }
    if (state is ExplorerToursLoaded) {
      final filtered = _applyFiltersAndSort(allTours);
      if (filtered.isEmpty) return _buildEmptyState(theme);
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
        itemCount: filtered.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: TourCard(tour: filtered[index]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _sortLabel(AppLocalizations l10n) {
    switch (_sortOption) {
      case _SortOption.newest: return l10n.toursSortLabelNewest;
      case _SortOption.cheapest: return l10n.toursSortLabelCheapest;
      case _SortOption.priciest: return l10n.toursSortLabelPriciest;
      case _SortOption.highestRated: return l10n.toursSortLabelTopRated;
      case _SortOption.mostPopular: return l10n.toursSortLabelPopular;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore, size: 80.r, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          SizedBox(height: 20.h),
          Text(l10n.toursEmptyTitle, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(
            _activeFilters.isNotEmpty
                ? l10n.toursEmptyFilters
                : l10n.toursEmptySearch,
            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          if (_activeFilters.isNotEmpty) ...[
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: () => setState(() { _activeFilters.clear(); _minRating = 0; _selectedFrequency = null; }),
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.toursClearFilters),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: ShimmerLoadingWidget.rectangular(height: 280.h),
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
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 6.h),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16.r, color: primary),
                SizedBox(width: 6.w),
                Text(
                  AppLocalizations.of(context).toursRecommended,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: loading ? 3 : tours.length,
              itemBuilder: (context, i) {
                if (loading) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: 12.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: ShimmerLoadingWidget.rectangular(
                        width: 220.w,
                        height: 180.h,
                      ),
                    ),
                  );
                }
                final tour = tours[i];
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: 12.w),
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
        width: 220.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
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
            ShimmerImage(
              url: tour.images.isNotEmpty ? tour.images.first : null,
              fit: BoxFit.cover,
              fallbackIcon: Icons.tour,
              fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              fallbackIconColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              fallbackIconSize: 36.r,
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
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12.r, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        tour.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Title + meeting location
            Positioned(
              bottom: 10.h,
              left: 10.w,
              right: 10.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tour.meetingLocationName.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.place,
                            size: 11.r, color: Colors.white70),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            tour.meetingLocationName,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.sp,
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
