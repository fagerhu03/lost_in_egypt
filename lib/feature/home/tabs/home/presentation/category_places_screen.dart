import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../theme/theme.dart';
import '../data/datasources/local_places_service.dart';
import '../data/models/map_item_models.dart';
import './place_details_screen.dart';

enum SortMode {
  nameAsc,
  nameDesc,
  topRated,
  mostVisited,
  nearest,
}

class CategoryPlacesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const CategoryPlacesScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen>
    with TickerProviderStateMixin {
  List<PlaceModel> _filteredPlaces = [];
  List<PlaceModel> _displayedPlaces = [];
  List<PlaceModel> _allPlaces = [];

  static const int _pageSize = 10;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;

  String _searchQuery = '';
  SortMode _sortMode = SortMode.nameAsc;
  Position? _currentPosition;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Staggered animation
  final List<AnimationController> _animControllers = [];
  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    for (final c in _animControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _buildAnimations(int count) {
    // Dispose old ones
    for (final c in _animControllers) {
      c.dispose();
    }
    _animControllers.clear();
    _fadeAnims.clear();
    _slideAnims.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _animControllers.add(controller);
      _fadeAnims.add(CurvedAnimation(parent: controller, curve: Curves.easeOut));
      _slideAnims.add(Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)));

      // Stagger each card by 80ms
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted && i < _animControllers.length) {
          _animControllers[i].forward();
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchPlaces() async {
    try {
      final places =
          await LocalPlacesService.getPlacesByCategory(widget.categoryId);
      if (mounted) {
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLocationAndSort() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _sortMode = SortMode.nameAsc;
        if (mounted) setState(() => _isLoading = false);
        _applyFilters();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _sortMode = SortMode.nameAsc;
          if (mounted) setState(() => _isLoading = false);
          _applyFilters();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _sortMode = SortMode.nameAsc;
        if (mounted) setState(() => _isLoading = false);
        _applyFilters();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
    } catch (e) {
      debugPrint("Location error: $e");
      _sortMode = SortMode.nameAsc;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    List<PlaceModel> filtered = List.from(_allPlaces);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered =
          filtered.where((p) => p.title.toLowerCase().contains(q)).toList();
    }

    switch (_sortMode) {
      case SortMode.nameAsc:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortMode.nameDesc:
        filtered.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortMode.topRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortMode.mostVisited:
        filtered
            .sort((a, b) => b.userRatingCount.compareTo(a.userRatingCount));
        break;
      case SortMode.nearest:
        if (_currentPosition != null) {
          filtered.sort((a, b) {
            final distA = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude,
                a.coordinate.latitude, a.coordinate.longitude);
            final distB = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude,
                b.coordinate.latitude, b.coordinate.longitude);
            return distA.compareTo(distB);
          });
        }
        break;
    }

    setState(() {
      _filteredPlaces = filtered;
      _displayedPlaces = filtered.take(_pageSize).toList();
    });
    _buildAnimations(_displayedPlaces.length);
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    if (_displayedPlaces.length >= _filteredPlaces.length) return;

    setState(() => _isLoadingMore = true);

    final oldLen = _displayedPlaces.length;
    final nextBatch = _filteredPlaces.skip(oldLen).take(_pageSize).toList();

    // Build animations for new items
    for (int i = 0; i < nextBatch.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _animControllers.add(controller);
      _fadeAnims
          .add(CurvedAnimation(parent: controller, curve: Curves.easeOut));
      _slideAnims.add(Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)));

      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted && (oldLen + i) < _animControllers.length) {
          _animControllers[oldLen + i].forward();
        }
      });
    }

    setState(() {
      _displayedPlaces.addAll(nextBatch);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final primary = isDark ? AppColors.darkNavBar : theme.colorScheme.primary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor =
        textColor.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryTitle,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.9),
            fontSize: 22,
            fontFamily: "Marcellus",
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Sort ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search places...",
                      hintStyle:
                          TextStyle(color: secondaryTextColor, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: primary, size: 20),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: PopupMenuButton<SortMode>(
                    icon: Icon(Icons.tune_rounded, color: primary, size: 22),
                    tooltip: "Sort",
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (mode) {
                      if (mode == SortMode.nearest &&
                          _currentPosition == null) {
                        _sortMode = mode;
                        _fetchLocationAndSort();
                      } else {
                        _sortMode = mode;
                        _applyFilters();
                      }
                    },
                    itemBuilder: (context) => [
                      _sortMenuItem(SortMode.nameAsc, "Name (A → Z)", Icons.sort_by_alpha),
                      _sortMenuItem(SortMode.nameDesc, "Name (Z → A)", Icons.sort_by_alpha),
                      _sortMenuItem(SortMode.topRated, "Top Rated", Icons.star_rounded),
                      _sortMenuItem(SortMode.mostVisited, "Most Reviews", Icons.people_alt_rounded),
                      _sortMenuItem(SortMode.nearest, "Nearest", Icons.near_me_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _hasError
                    ? _buildEmptyState(
                        Icons.error_outline, "Something went wrong.",
                        secondaryTextColor)
                    : _displayedPlaces.isEmpty
                        ? _buildEmptyState(
                            Icons.search_off_rounded, "No places found.",
                            secondaryTextColor)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 4, bottom: 32),
                            itemCount: _displayedPlaces.length +
                                (_displayedPlaces.length <
                                        _filteredPlaces.length
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index >= _displayedPlaces.length) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: primary, strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              final place = _displayedPlaces[index];

                              // Wrap in animation
                              if (index < _fadeAnims.length) {
                                return FadeTransition(
                                  opacity: _fadeAnims[index],
                                  child: SlideTransition(
                                    position: _slideAnims[index],
                                    child: _buildPlaceCard(
                                        place, primary, textColor,
                                        secondaryTextColor, surface, isDark),
                                  ),
                                );
                              }
                              return _buildPlaceCard(place, primary, textColor,
                                  secondaryTextColor, surface, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortMode> _sortMenuItem(
      SortMode mode, String label, IconData icon) {
    final isActive = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : null,
              )),
          if (isActive) ...[
            const Spacer(),
            Icon(Icons.check_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 16, fontFamily: "Marcellus")),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    PlaceModel place,
    Color primary,
    Color textColor,
    Color secondaryTextColor,
    Color surface,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlaceDetailsScreen(place: place)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Image ──
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: place.imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: place.imagePath,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: primary.withValues(alpha: 0.08),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: primary, strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: primary.withValues(alpha: 0.06),
                            child: Icon(Icons.image_not_supported_outlined,
                                color: secondaryTextColor, size: 36),
                          ),
                        )
                      : Image.asset(place.imagePath, fit: BoxFit.cover),
                ),

                // Gradient overlay at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rating pill — top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          place.rating > 0
                              ? place.rating.toStringAsFixed(1)
                              : "N/A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // City chip — bottom left, overlapping image edge
                if (place.locationAddress.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: primary),
                          const SizedBox(width: 3),
                          Text(
                            place.locationAddress,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Text Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    place.title,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.92),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Review count + description row
                  Row(
                    children: [
                      if (place.userRatingCount > 0) ...[
                        Icon(Icons.people_alt_outlined,
                            size: 13, color: secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          place.userRatingCount > 1000
                              ? '${(place.userRatingCount / 1000).toStringAsFixed(1)}k reviews'
                              : '${place.userRatingCount} reviews',
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        if (place.description.isNotEmpty)
                          Text("  •  ",
                              style: TextStyle(
                                  color: secondaryTextColor, fontSize: 12)),
                      ],
                      if (place.description.isNotEmpty)
                        Expanded(
                          child: Text(
                            place.description,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),

                  // Distance indicator
                  if (_sortMode == SortMode.nearest &&
                      _currentPosition != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 13, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          "${(Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, place.coordinate.latitude, place.coordinate.longitude) / 1000).toStringAsFixed(1)} km away",
                          style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
