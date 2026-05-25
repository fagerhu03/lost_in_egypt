import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/core/services/recommendation_mappings.dart';
import 'package:lost_in_egypt/core/widgets/app_error_widget.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/map_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/tour_detail_screen.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';

enum _Tab { all, places, tours }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  _Tab _tab = _Tab.all;

  // Results
  List<MapItem> _placeResults = [];
  List<TourEntity> _tourResults = [];
  bool _loading = false;
  String? _error;

  // Cached full place list (loaded once)
  List<MapItem>? _allPlaces;

  // User's taste vector — loaded once on screen open. Empty when missing/cold-start.
  Map<String, num> _tasteVector = {};
  // True when current results have been re-ranked through the taste vector.
  bool _personalised = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadPlaces();
    _loadTasteVector();
  }

  Future<void> _loadTasteVector() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final raw = doc.data()?['tasteVector'];
      if (raw is Map) {
        final cast = <String, num>{};
        for (final e in raw.entries) {
          if (e.value is num) cast[e.key.toString()] = e.value as num;
        }
        setState(() => _tasteVector = cast);
      }
    } catch (_) {}
  }

  /// Dot-product score of inferred canonical keys against the user's taste
  /// vector. Returns 0 when the vector is empty (cold-start users).
  double _tasteScore(String text) {
    if (_tasteVector.isEmpty) return 0;
    final keys = RecommendationMappings.inferKeysFromText(text);
    double s = 0;
    for (final k in keys['types']!) {
      s += (_tasteVector[k] ?? 0).toDouble();
    }
    for (final k in keys['tags']!) {
      s += (_tasteVector[k] ?? 0).toDouble();
    }
    return s;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    try {
      final repo = GetIt.instance<MapRepository>();
      final places = await repo.fetchAllMapItemsLimited();
      if (mounted) setState(() { _allPlaces = places; _error = null; });
    } catch (e) {
      debugPrint('Search: failed to load places: $e');
      if (mounted) setState(() => _error = 'Could not load places.\nCheck your connection.');
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _query = value.toLowerCase().trim());
      if (_query.isNotEmpty) _runSearch();
    });
    if (value.isEmpty) {
      setState(() {
        _query = '';
        _placeResults = [];
        _tourResults = [];
      });
    }
  }

  Future<void> _runSearch() async {
    if (_query.isEmpty) return;
    setState(() => _loading = true);

    await Future.wait([
      _searchPlaces(),
      _searchTours(),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _searchPlaces() async {
    if (_allPlaces == null) return;
    final results = _allPlaces!.where((p) {
      return p.title.toLowerCase().contains(_query) ||
          p.locationAddress.toLowerCase().contains(_query) ||
          p.category.toLowerCase().contains(_query) ||
          p.tags.any((t) => t.toLowerCase().contains(_query)) ||
          p.description.toLowerCase().contains(_query);
    }).take(30).toList();

    if (_tasteVector.isNotEmpty) {
      // Composite ordering: taste score dominates, importance breaks ties.
      results.sort((a, b) {
        final ta = _tasteScore('${a.title} ${a.category} ${a.tags.join(' ')}');
        final tb = _tasteScore('${b.title} ${b.category} ${b.tags.join(' ')}');
        if (tb != ta) return tb.compareTo(ta);
        return b.importance.compareTo(a.importance);
      });
      _personalised = true;
    } else {
      results.sort((a, b) => b.importance.compareTo(a.importance));
      _personalised = false;
    }

    if (mounted) setState(() => _placeResults = results);
  }

  Future<void> _searchTours() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tours')
          .limit(200)
          .get();

      final all = snap.docs.map((d) {
        final data = d.data();
        return TourEntity(
          id: d.id,
          guideId: data['guideId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          destinations: (data['destinations'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          price: (data['price'] ?? 0).toDouble(),
          meetingLatitude: (data['meetingLatitude'] ?? 30.0444).toDouble(),
          meetingLongitude: (data['meetingLongitude'] ?? 31.2357).toDouble(),
          meetingTime: (data['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          frequency: data['frequency'] ?? '',
          meetingLocationName: data['meetingLocationName'] ?? '',
          images: (data['images'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          maxAttendees: (data['maxAttendees'] ?? 10).toInt(),
          rating: (data['rating'] ?? 0).toDouble(),
          reviewCount: (data['reviewCount'] ?? 0).toInt(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).where((t) {
        return t.title.toLowerCase().contains(_query) ||
            t.description.toLowerCase().contains(_query) ||
            t.meetingLocationName.toLowerCase().contains(_query) ||
            t.destinations.any((d) => d.toLowerCase().contains(_query));
      }).take(20).toList();

      if (_tasteVector.isNotEmpty) {
        all.sort((a, b) {
          final ta = _tasteScore(
              '${a.title} ${a.destinations.join(' ')} ${a.description}');
          final tb = _tasteScore(
              '${b.title} ${b.destinations.join(' ')} ${b.description}');
          return tb.compareTo(ta);
        });
      }

      if (mounted) setState(() { _tourResults = all; _error = null; });
    } catch (e) {
      debugPrint('Search tours error: $e');
      if (mounted) setState(() => _error = 'Could not load tours.\nCheck your connection.');
    }
  }

  void _onPlaceTap(MapItem place) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapFocusService.instance.triggerFocus(place);
    });
  }

  void _onTourTap(TourEntity tour) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    final showPlaces = _tab == _Tab.all || _tab == _Tab.places;
    final showTours = _tab == _Tab.all || _tab == _Tab.tours;

    final placeList = showPlaces ? _placeResults : <MapItem>[];
    final tourList = showTours ? _tourResults : <TourEntity>[];
    final totalCount = placeList.length + tourList.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          style: TextStyle(color: onSurface, fontFamily: 'Marcellus'),
          decoration: InputDecoration(
            hintText: 'Search landmarks, tours, destinations…',
            hintStyle: TextStyle(
              color: onSurface.withValues(alpha: 0.45),
              fontFamily: 'Marcellus',
              fontSize: 15,
            ),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: onSurface.withValues(alpha: 0.5)),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabBar(
            selected: _tab,
            primary: primary,
            onSurface: onSurface,
            isDark: isDark,
            onSelect: (t) => setState(() => _tab = t),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _EmptyPrompt(primary: primary, onSurface: onSurface)
          : _loading
              ? Center(child: CircularProgressIndicator(color: primary))
              : _error != null && totalCount == 0
                  ? AppErrorWidget(
                      message: _error!,
                      onRetry: () { setState(() => _error = null); _runSearch(); },
                    )
                  : totalCount == 0
                  ? _NoResults(query: _query, onSurface: onSurface)
                  : Column(
                      children: [
                        if (_personalised)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 14, color: primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Personalised by your taste',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Marcellus',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: placeList.length + tourList.length,
                            itemBuilder: (context, i) {
                              if (i < placeList.length) {
                                return _PlaceResultTile(
                                  place: placeList[i],
                                  isDark: isDark,
                                  surface: surface,
                                  onSurface: onSurface,
                                  primary: primary,
                                  onTap: () => _onPlaceTap(placeList[i]),
                                );
                              }
                              final tour = tourList[i - placeList.length];
                              return _TourResultTile(
                                tour: tour,
                                isDark: isDark,
                                surface: surface,
                                onSurface: onSurface,
                                primary: primary,
                                onTap: () => _onTourTap(tour),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final _Tab selected;
  final Color primary;
  final Color onSurface;
  final bool isDark;
  final ValueChanged<_Tab> onSelect;

  const _TabBar({
    required this.selected,
    required this.primary,
    required this.onSurface,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _chip('All', _Tab.all),
          const SizedBox(width: 8),
          _chip('Places', _Tab.places),
          const SizedBox(width: 8),
          _chip('Tours', _Tab.tours),
        ],
      ),
    );
  }

  Widget _chip(String label, _Tab tab) {
    final active = selected == tab;
    return GestureDetector(
      onTap: () => onSelect(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primary : primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontFamily: 'Marcellus',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Place tile ───────────────────────────────────────────────────────────────

class _PlaceResultTile extends StatelessWidget {
  final MapItem place;
  final bool isDark;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final VoidCallback onTap;

  const _PlaceResultTile({
    required this.place,
    required this.isDark,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 64,
                height: 64,
                child: place.imagePath.startsWith('http')
                    ? ShimmerImage(
                        url: place.imagePath,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(10),
                        fallbackBackgroundColor: onSurface.withValues(alpha: 0.08),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: place.imagePath.isNotEmpty
                            ? Image.asset(place.imagePath, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _PlaceholderIcon(primary: primary))
                            : _PlaceholderIcon(primary: primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Marcellus',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _TypeBadge(label: 'Landmark', color: primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (place.locationAddress.isNotEmpty)
                      Text(
                        place.locationAddress,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.map_outlined, color: primary.withValues(alpha: 0.7), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          'View on map',
                          style: TextStyle(
                            color: primary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tour tile ────────────────────────────────────────────────────────────────

class _TourResultTile extends StatelessWidget {
  final TourEntity tour;
  final bool isDark;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final VoidCallback onTap;

  const _TourResultTile({
    required this.tour,
    required this.isDark,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCode = CurrencyController.currency.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 64,
                height: 64,
                child: tour.images.isNotEmpty
                    ? ShimmerImage(
                        url: tour.images.first,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(10),
                        fallbackIcon: Icons.tour,
                        fallbackBackgroundColor: onSurface.withValues(alpha: 0.08),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _PlaceholderIcon(primary: primary, icon: Icons.tour),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tour.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Marcellus',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _TypeBadge(label: 'Tour', color: Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tour.meetingLocationName.isNotEmpty)
                      Text(
                        tour.meetingLocationName,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FutureBuilder<double>(
                          future: CurrencyService.instance
                              .convertFromEGP(tour.price, currencyCode),
                          builder: (_, snap) {
                            final label = snap.hasData
                                ? CurrencyService.format(snap.data!, currencyCode)
                                : snap.hasError
                                    ? 'EGP ${tour.price.toStringAsFixed(0)} ⚠'
                                    : 'EGP ${tour.price.toStringAsFixed(0)}';
                            return Text(
                              label,
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                        if (tour.rating > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            tour.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _PlaceholderIcon extends StatelessWidget {
  final Color primary;
  final IconData icon;

  const _PlaceholderIcon({
    required this.primary,
    this.icon = Icons.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(alpha: 0.1),
      child: Icon(icon, color: primary.withValues(alpha: 0.5), size: 28),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final Color primary;
  final Color onSurface;

  const _EmptyPrompt({required this.primary, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'Search for a landmark or tour',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: 16,
              fontFamily: 'Marcellus',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try "Pyramids", "Luxor", "museum"…',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.35),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final Color onSurface;

  const _NoResults({required this.query, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: 15,
              fontFamily: 'Marcellus',
            ),
          ),
        ],
      ),
    );
  }
}
