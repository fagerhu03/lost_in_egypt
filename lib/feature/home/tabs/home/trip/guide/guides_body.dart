import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/widget/guide_card.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/widget/guide_trip_type_tab.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../navigator/widget/account_menu_button.dart';
import '../../../../../tours/presentation/widgets/tour_card.dart';
import '../../../../../tours/domain/entities/tour_entity.dart';
import '../../../../../../../core/di/service_locator.dart';
import '../../../../../auth/data/models/user.dart';
import '../../../../../tours/presentation/bloc/explorer_tours_cubit.dart';
import '../../../../../tours/presentation/bloc/explorer_tours_state.dart';

class GuideBodyScreen extends StatelessWidget {
  const GuideBodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExplorerToursCubit>()..loadTours(),
      child: const GuideBodyView(),
    );
  }
}

class GuideBodyView extends StatefulWidget {
  const GuideBodyView({super.key});

  @override
  State<GuideBodyView> createState() => _GuideBodyViewState();
}

enum _SortOption { newest, cheapest, priciest, highestRated, mostPopular }

class _GuideBodyViewState extends State<GuideBodyView> {
  String? _profileImageUrl;
  int _tabIndex = 0; // 0 for Tours, 1 for Guides

  // Shared Search & Sort
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.newest;

  // Filters for Tours
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minRating = 0;
  String? _selectedFrequency;

  // Active filters set
  final Set<String> _activeFilters = {};

  late Stream<QuerySnapshot> _guidesStream;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _guidesStream = FirebaseFirestore.instance
        .collection('users')
        .where('isVerifiedGuide', isEqualTo: true)
        .snapshots();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _profileImageUrl = doc.data()?['profileImageUrl']);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ==== Filter & Sort Logic for Tours ====
  List<TourEntity> _applyToursFiltersAndSort(List<TourEntity> tours) {
    var filtered = tours.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!t.title.toLowerCase().contains(q) &&
            !t.destinations.any((d) => d.toLowerCase().contains(q)) &&
            !t.meetingLocationName.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_tabIndex == 0) {
        if (_activeFilters.contains('price')) {
          if (t.price < _priceRange.start || t.price > _priceRange.end) return false;
        }
        if (_activeFilters.contains('rating')) {
          if (t.rating < _minRating) return false;
        }
        if (_selectedFrequency != null && _activeFilters.contains('frequency')) {
          if (t.frequency != _selectedFrequency) return false;
        }
      }
      return true;
    }).toList();

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

  // ==== Filter & Sort Logic for Guides ====
  List<UserModel> _applyGuidesFiltersAndSort(List<UserModel> guides) {
    var filtered = guides.where((g) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = '${g.firstName} ${g.lastName}'.toLowerCase();
        if (!name.contains(q) && !g.bio.toLowerCase().contains(q)) return false;
      }
      if (_activeFilters.contains('rating')) {
        if (g.rating < _minRating) return false;
      }
      return true;
    }).toList();

    switch (_sortOption) {
      case _SortOption.newest:
      case _SortOption.cheapest:
      case _SortOption.priciest:
        // Guides don't have price, fallback to rating
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
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

  void _showFilterSheet(BuildContext context, double maxTourPrice) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
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
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempPrice = RangeValues(0, maxTourPrice);
                            tempRating = 0;
                            tempFrequency = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_tabIndex == 0) ...[
                    // Price Range (Tours only)
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
                      values: RangeValues(tempPrice.start.clamp(0, maxTourPrice), tempPrice.end.clamp(0, maxTourPrice)),
                      min: 0,
                      max: maxTourPrice,
                      divisions: (maxTourPrice / 5).round().clamp(1, 200),
                      activeColor: primary,
                      labels: RangeLabels('${tempPrice.start.round()}', '${tempPrice.end.round()}'),
                      onChanged: (v) => setSheetState(() => tempPrice = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Minimum Rating (Both)
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

                  if (_tabIndex == 0) ...[
                    // Frequency (Tours only)
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
                  ],

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
                          if (_tabIndex == 0 && (tempPrice.start > 0 || tempPrice.end < maxTourPrice)) _activeFilters.add('price');
                          if (tempRating > 0) _activeFilters.add('rating');
                          if (_tabIndex == 0 && tempFrequency != null) _activeFilters.add('frequency');
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
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    
    final baseBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final maxTourPrice = 10000.0; // Assume 10000 max

    return Scaffold(
      backgroundColor: baseBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.7 : 0.5,
              child: Image.asset('assets/pattern_comp.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(color: (isDark ? AppColors.darkPatternOverlay : AppColors.lightPatternOverlay).withOpacity(isDark ? 0.85 : 0.40)),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Search & Header bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.chevron_left_rounded, color: isDark ? AppColors.darkText : const Color(0xFF7A4B1D)),
                      ),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(isDark ? 0.25 : 0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(color: isDark ? onSurface : Colors.white, fontFamily: "Marcellus", fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: _tabIndex == 0 ? "Search tours..." : "Search guides...",
                              hintStyle: TextStyle(color: (isDark ? onSurface : Colors.white).withOpacity(0.85), fontFamily: "Marcellus"),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: (isDark ? onSurface : Colors.white).withOpacity(0.85)),
                              prefixIconConstraints: const BoxConstraints(minWidth: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Button
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: IconButton(
                          icon: Badge(
                            isLabelVisible: _activeFilters.isNotEmpty,
                            label: Text('${_activeFilters.length}'),
                            child: Icon(Icons.tune, color: primary),
                          ),
                          onPressed: () => _showFilterSheet(context, maxTourPrice),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AccountMenuButton(profileImageUrl: _profileImageUrl, onSignOut: _handleSignOut),
                    ],
                  ),
                ),

                // ── Active Filter Chips Row ──
                if (_activeFilters.isNotEmpty || _sortOption != _SortOption.newest)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        PopupMenuButton<_SortOption>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (v) => setState(() => _sortOption = v),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: _SortOption.newest, child: Text('Newest First')),
                            const PopupMenuItem(value: _SortOption.highestRated, child: Text('Top Rated')),
                            const PopupMenuItem(value: _SortOption.mostPopular, child: Text('Most Popular')),
                            if (_tabIndex == 0) ...[
                              const PopupMenuItem(value: _SortOption.cheapest, child: Text('Cheapest First')),
                              const PopupMenuItem(value: _SortOption.priciest, child: Text('Priciest First')),
                            ],
                          ],
                          child: Chip(
                            avatar: Icon(Icons.sort, size: 16, color: primary),
                            label: Text(_sortLabel(), style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600)),
                            backgroundColor: primary.withOpacity(0.08),
                            side: BorderSide(color: primary.withOpacity(0.2)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_activeFilters.contains('price') && _tabIndex == 0)
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
                        if (_activeFilters.contains('frequency') && _selectedFrequency != null && _tabIndex == 0)
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

                // ── Tabs Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tabIndex = 0;
                              // Ensure sort option is valid for tours
                            }),
                            child: GuideTripTypeTab(title: 'Tours', selected: _tabIndex == 0),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tabIndex = 1;
                              if (_sortOption == _SortOption.cheapest || _sortOption == _SortOption.priciest) {
                                _sortOption = _SortOption.highestRated;
                              }
                            }),
                            child: GuideTripTypeTab(title: 'Guides', selected: _tabIndex == 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Results List ──
                Expanded(
                  child: _tabIndex == 0 ? _buildToursList() : _buildGuidesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildEmptyState(String queryType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text('No $queryType found', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your search query or filters.'),
        ],
      ),
    );
  }

  Widget _buildToursList() {
    return BlocBuilder<ExplorerToursCubit, ExplorerToursState>(
      builder: (context, state) {
        if (state is ExplorerToursLoading) return const Center(child: CircularProgressIndicator());
        if (state is ExplorerToursError) return const Center(child: Text('Error loading tours.'));
        if (state is ExplorerToursLoaded) {
          final filtered = _applyToursFiltersAndSort(state.tours);
          if (filtered.isEmpty) return _buildEmptyState('tours');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => TourCard(tour: filtered[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGuidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _guidesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('Error loading guides.'));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No guides available.'));

        final allGuides = docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        final filteredGuides = _applyGuidesFiltersAndSort(allGuides);

        if (filteredGuides.isEmpty) return _buildEmptyState('guides');

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          itemCount: filteredGuides.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final user = filteredGuides[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: user)));
              },
              child: GuideCard(guide: user),
            );
          },
        );
      },
    );
  }
}