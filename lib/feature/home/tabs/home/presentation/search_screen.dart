import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
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

  // Cached full place list (loaded once)
  List<MapItem>? _allPlaces;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadPlaces();
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
      if (mounted) setState(() => _allPlaces = places);
    } catch (e) {
      debugPrint('Search: failed to load places: $e');
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

    results.sort((a, b) => b.importance.compareTo(a.importance));

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

      if (mounted) setState(() => _tourResults = all);
    } catch (e) {
      debugPrint('Search tours error: $e');
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
              color: onSurface.withOpacity(0.45),
              fontFamily: 'Marcellus',
              fontSize: 15,
            ),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: onSurface.withOpacity(0.5)),
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
              : totalCount == 0
                  ? _NoResults(query: _query, onSurface: onSurface)
                  : ListView.builder(
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
          color: active ? primary : primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : onSurface.withOpacity(0.7),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: place.imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: place.imagePath,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: onSurface.withOpacity(0.08)),
                          errorWidget: (_, __, ___) => _PlaceholderIcon(primary: primary),
                        )
                      : place.imagePath.isNotEmpty
                          ? Image.asset(place.imagePath, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _PlaceholderIcon(primary: primary))
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
                          color: onSurface.withOpacity(0.55),
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
                            color: onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.map_outlined, color: primary.withOpacity(0.7), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          'View on map',
                          style: TextStyle(
                            color: primary.withOpacity(0.8),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: tour.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: tour.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: onSurface.withOpacity(0.08)),
                          errorWidget: (_, __, ___) => _PlaceholderIcon(primary: primary, icon: Icons.tour),
                        )
                      : _PlaceholderIcon(primary: primary, icon: Icons.tour),
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
                          color: onSurface.withOpacity(0.55),
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
                              color: onSurface.withOpacity(0.7),
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
      color: primary.withOpacity(0.1),
      child: Icon(icon, color: primary.withOpacity(0.5), size: 28),
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
        color: color.withOpacity(0.12),
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
          Icon(Icons.search, size: 64, color: primary.withOpacity(0.25)),
          const SizedBox(height: 16),
          Text(
            'Search for a landmark or tour',
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'Marcellus',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try "Pyramids", "Luxor", "museum"…',
            style: TextStyle(
              color: onSurface.withOpacity(0.35),
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
          Icon(Icons.search_off, size: 56, color: onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 15,
              fontFamily: 'Marcellus',
            ),
          ),
        ],
      ),
    );
  }
}
