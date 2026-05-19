import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

import '../../navigator/widget/account_menu_button.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../domain/entities/community_post.dart';
import '../data/community_post_action_service.dart';
import './community_post_card.dart';
import 'post_detail_screen.dart';
import '../../../../../core/widgets/shimmer_loading_widget.dart';
import '../../map/data/places_api_service.dart';
import '../../../../../core/services/recommendation_service.dart';
import '../../../../../core/utils/snack_bar_utils.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final TextEditingController _postController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _searchExpanded = false;
  String? _profileImageUrl;
  bool _isPosting = false;
  String? _selectedLocationName;
  String? _selectedLocationId;
  double? _selectedLocationLat;
  double? _selectedLocationLng;
  String? _selectedCategory;

  String _sortBy = 'newest';
  String _activeCategory = 'all'; // all | photos | questions | guides | landmarks | tips
  List<File> _selectedImages = [];
  late Stream<List<CommunityPost>> _postsStream;

  bool _composerFocused = false;
  bool _isCurrentUserAdmin = false;
  String _currentUserFlag = '🇪🇬';
  String? _activeHashtag; // trending hashtag filter

  // New posts banner
  DateTime _lastSeenTimestamp = DateTime.now();
  bool _showNewPostsBanner = false;
  bool _isScrolledDown = false;

  @override
  void initState() {
    super.initState();
    _postsStream = _repository.getPostsStream(sortBy: _sortBy);
    _fetchUserProfile();
    _composerFocusNode.addListener(() {
      setState(() => _composerFocused = _composerFocusNode.hasFocus);
    });
    _scrollController.addListener(_onScroll);
    CommunityPostActionService.instance.pendingPostContent.addListener(_handlePendingPost);
    _checkPendingPost();
  }

  void _checkPendingPost() {
    final content = CommunityPostActionService.instance.pendingPostContent.value;
    if (content != null) {
      _postController.text = content;
      CommunityPostActionService.instance.pendingPostContent.value = null;
      _composerFocusNode.requestFocus();
    }
  }

  void _handlePendingPost() {
    if (mounted) {
      _checkPendingPost();
    }
  }

  void _onScroll() {
    final scrolledDown = _scrollController.offset > 100;
    if (scrolledDown != _isScrolledDown) {
      setState(() => _isScrolledDown = scrolledDown);
    }
  }

  @override
  void dispose() {
    CommunityPostActionService.instance.pendingPostContent.removeListener(_handlePendingPost);
    _postController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final d = doc.data()!;
          // Derive live flag from stored nationalityFlag or nationality string
          final storedFlag = d['nationalityFlag'] as String?;
          final nat = (d['nationality'] ?? '') as String;
          final liveFlag = (storedFlag != null && storedFlag.isNotEmpty)
              ? storedFlag
              : (nat.length >= 4 && nat.codeUnitAt(0) == 0xD83C ? nat.substring(0, 4) : '🇪🇬');
          setState(() {
            _profileImageUrl = d['profileImageUrl'] as String?;
            _isCurrentUserAdmin = d['role'] == 'admin';
            _currentUserFlag = liveFlag;
          });
          try {
            await _repository.refreshUserPostsFlag(user.uid);
          } catch (e) {
            debugPrint('Error refreshing post flags: $e');
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  void _handlePostAction() async {
    if (_isPosting) return;
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;
    _handlePost();
  }

  Future<void> _pickLocation() async {
    final placesService = GetIt.I<PlacesApiService>();
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;
        final primary = theme.colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              title: Text('Tag a Location', style: TextStyle(color: onSurface, fontFamily: 'Marcellus')),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search places in Egypt...',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.12))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.12))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary.withOpacity(0.8))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) async {
                        if (val.trim().length < 2) {
                          setDialogState(() => searchResults = []);
                          return;
                        }
                        setDialogState(() => isLoading = true);
                        final results = await placesService.textSearch(
                          query: '${val.trim()} Egypt',
                          maxResultCount: 8,
                        );
                        if (context.mounted) {
                          setDialogState(() {
                            searchResults = results;
                            isLoading = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: primary))
                    else if (searchResults.isEmpty)
                      Expanded(child: Center(child: Text('Type to search places...', style: TextStyle(color: onSurface.withOpacity(0.55)))))
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: onSurface.withOpacity(0.10)),
                          itemBuilder: (context, index) {
                            final place = searchResults[index];
                            final name = (place['displayName'] as Map<String, dynamic>?)?['text'] as String? ?? '';
                            final address = (place['formattedAddress'] as String?) ?? '';
                            final loc = place['location'] as Map<String, dynamic>?;
                            final lat = (loc?['latitude'] as num?)?.toDouble();
                            final lng = (loc?['longitude'] as num?)?.toDouble();
                            final placeId = (place['id'] as String?) ?? '';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.place_rounded, color: primary, size: 20),
                              ),
                              title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14)),
                              subtitle: address.isNotEmpty ? Text(address, style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              onTap: () {
                                setState(() {
                                  _selectedLocationName = name;
                                  _selectedLocationId = placeId;
                                  _selectedLocationLat = lat;
                                  _selectedLocationLng = lng;
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: onSurface.withOpacity(0.6))))],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) return;
    try {
      final List<XFile> picked = await _picker.pickMultiImage(limit: 4 - _selectedImages.length);
      if (picked.isNotEmpty) {
        setState(() => _selectedImages.addAll(picked.map((e) => File(e.path))));
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _showCategoryPicker() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    final categories = [
      ('photos', Icons.photo_library_outlined, 'Photos'),
      ('questions', Icons.help_outline_rounded, 'Questions'),
      ('guides', Icons.tour_outlined, 'Guides'),
      ('landmarks', Icons.account_balance_outlined, 'Landmarks'),
      ('tips', Icons.lightbulb_outline_rounded, "Traveler's Tips"),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Post Category', style: TextStyle(fontFamily: 'Marcellus', fontSize: 16, color: onSurface, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return ListTile(
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(cat.$2, color: primary, size: 20),
                ),
                title: Text(cat.$3, style: TextStyle(fontFamily: 'Marcellus', color: onSurface)),
                trailing: isSelected ? Icon(Icons.check_rounded, color: primary) : null,
                onTap: () {
                  setState(() => _selectedCategory = isSelected ? null : cat.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePost() async {
    setState(() => _isPosting = true);
    // Capture before setState clears them
    final postLocationId = _selectedLocationId;
    final postLocationName = _selectedLocationName;
    final eventId = CommunityPostActionService.instance.pendingEventId;
    final eventName = CommunityPostActionService.instance.pendingEventName;
    // Clear pending event data
    CommunityPostActionService.instance.pendingEventId = null;
    CommunityPostActionService.instance.pendingEventName = null;
    try {
      await _repository.addPost(
        _postController.text.trim(),
        _selectedImages,
        locationName: _selectedLocationName,
        locationId: _selectedLocationId,
        locationLat: _selectedLocationLat,
        locationLng: _selectedLocationLng,
        category: _selectedCategory ?? '',
        taggedEventId: eventId,
        taggedEventName: eventName,
      );
      if (postLocationId != null) {
        RecommendationService.recordSignal(
          placeId: postLocationId,
          placeName: postLocationName,
          signalType: 'post',
          source: 'community',
        );
      }
      _postController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedLocationName = null;
        _selectedLocationId = null;
        _selectedLocationLat = null;
        _selectedLocationLng = null;
        _selectedCategory = null;
      });
      if (mounted) _composerFocusNode.unfocus();
    } catch (e) {
      if (mounted) {
        showErrorSnackBarFromException(context, e);
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleSignOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSortBottomSheet() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Sort Posts', style: TextStyle(fontFamily: 'Marcellus', fontSize: 16, color: onSurface, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            _sortTile(ctx, 'Newest', 'newest', Icons.access_time_rounded, primary, onSurface),
            _sortTile(ctx, 'Top Rated', 'popular', Icons.thumb_up_outlined, primary, onSurface),
            _sortTile(ctx, 'Most Discussed', 'most_discussed', Icons.chat_bubble_outline_rounded, primary, onSurface),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, String label, String value, IconData icon, Color primary, Color onSurface) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(label, style: TextStyle(fontFamily: 'Marcellus', color: onSurface)),
      trailing: isSelected ? Icon(Icons.check_rounded, color: primary) : null,
      onTap: () {
        if (_sortBy != value) {
          setState(() {
            _sortBy = value;
            _postsStream = _repository.getPostsStream(sortBy: _sortBy);
          });
        }
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final patternOpacity = isDark ? 0.1 : 0.4;
    final boxShadow = BoxShadow(
      color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08),
      blurRadius: 14,
      offset: const Offset(0, 8),
      spreadRadius: 1,
    );

    return PopScope<Object?>(
      // Intercept back when a filter or search is active — clear it instead of navigating away
      canPop: _activeHashtag == null && !_searchExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            if (_searchExpanded) {
              _searchExpanded = false;
              _searchQuery = '';
            } else {
              _activeHashtag = null;
            }
          });
        }
      },
      child: Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: bg)),
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset('assets/pattern_comp.png', fit: BoxFit.cover, repeat: ImageRepeat.repeat, errorBuilder: (_, __, ___) => Container()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, surface, onSurface, primary, boxShadow),
                _buildCategoryChips(primary, onSurface, surface),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: _buildComposer(theme, surface, onSurface, primary, boxShadow),
                      ),
                      Expanded(
                        child: StreamBuilder<List<CommunityPost>>(
                          stream: _postsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, __) => _buildShimmerSkeleton(surface, onSurface, isDark, boxShadow),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Something went wrong:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
                            }

                            final allPosts = snapshot.data ?? [];

                            // Check for new posts banner
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              final hasNew = allPosts.any((p) {
                                final model = p as dynamic;
                                try {
                                  final ts = model.timestamp as DateTime?;
                                  return ts != null && ts.isAfter(_lastSeenTimestamp);
                                } catch (_) {
                                  return false;
                                }
                              });
                              if (hasNew && _isScrolledDown && !_showNewPostsBanner) {
                                setState(() => _showNewPostsBanner = true);
                              }
                            });

                            // Category filter
                            List<CommunityPost> categoryFiltered = _activeCategory == 'all'
                                ? allPosts
                                : allPosts.where((p) => p.category == _activeCategory).toList();

                            // Hashtag filter
                            List<CommunityPost> hashtagFiltered = _activeHashtag == null
                                ? categoryFiltered
                                : categoryFiltered.where((p) => p.content.toLowerCase().contains('#${_activeHashtag!.toLowerCase()}')).toList();

                            // Search filter
                            List<CommunityPost> filteredPosts = _searchQuery.isEmpty
                                ? hashtagFiltered
                                : hashtagFiltered.where((p) => p.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                            // Sort: pinned posts always first
                            filteredPosts = [
                              ...filteredPosts.where((p) => p.isPinned),
                              ...filteredPosts.where((p) => !p.isPinned),
                            ];

                            // Trending hashtags from current stream
                            final trendingTags = _extractTrendingHashtags(allPosts);

                            if (allPosts.isEmpty) {
                              return Center(child: Text('No posts yet. Be the first!', style: TextStyle(color: onSurface.withOpacity(0.75))));
                            }
                            if (filteredPosts.isEmpty) {
                              return Center(child: Text(_searchQuery.isNotEmpty ? 'No results for \'$_searchQuery\'' : 'No posts in this category yet.', style: TextStyle(color: onSurface.withOpacity(0.75))));
                            }

                            final currentUid = _auth.currentUser?.uid ?? '';

                            return Stack(
                              children: [
                                ListView.separated(
                                  key: const PageStorageKey('community_list'),
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  itemCount: filteredPosts.length + 3, // +3: challenge, leaderboard, trending
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index == 0) return _buildChallengeCard(context, primary, onSurface, surface);
                                    if (index == 1) return _buildLeaderboard(allPosts, primary, onSurface, surface, isDark);
                                    if (index == 2) return _buildTrendingHashtags(trendingTags, primary, onSurface);
                                    final post = filteredPosts[index - 3];
                                    return CommunityPostCard(
                                      key: ValueKey(post.id),
                                      post: post,
                                      isCurrentUserAdmin: _isCurrentUserAdmin,
                                      currentUserFlag: post.userId == currentUid ? _currentUserFlag : null,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                                    );
                                  },
                                ),
                                if (_showNewPostsBanner)
                                  Positioned(
                                    top: 12,
                                    left: 0, right: 0,
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
                                          setState(() {
                                            _showNewPostsBanner = false;
                                            _lastSeenTimestamp = DateTime.now();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                                              const SizedBox(width: 6),
                                              const Text('New posts — tap to refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Color surface, Color onSurface, Color primary, BoxShadow shadow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchBg = primary.withOpacity(isDark ? 0.25 : 0.18);
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(0.10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _searchExpanded
                      ? Container(
                          key: const ValueKey('search'),
                          height: 44,
                          decoration: BoxDecoration(color: searchBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor), boxShadow: [shadow]),
                          child: TextField(
                            autofocus: true,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(color: isDark ? onSurface : Colors.white, fontFamily: 'Marcellus', fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Search posts...',
                              hintStyle: TextStyle(color: (isDark ? onSurface : Colors.white).withOpacity(0.85), fontSize: 16, fontFamily: 'Marcellus'),
                              prefixIcon: Icon(Icons.search, color: (isDark ? onSurface : Colors.white).withOpacity(0.9)),
                              suffixIcon: IconButton(icon: Icon(Icons.close, color: (isDark ? onSurface : Colors.white).withOpacity(0.7)), onPressed: () => setState(() { _searchExpanded = false; _searchQuery = ''; })),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        )
                      : Row(
                          key: const ValueKey('title'),
                          children: [
                            Text('Community', style: TextStyle(fontFamily: 'Marcellus', fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
                          ],
                        ),
                ),
              ),
              if (!_searchExpanded) ...[
                IconButton(icon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.8)), onPressed: () => setState(() => _searchExpanded = true)),
                IconButton(
                  icon: Icon(Icons.sort_rounded, color: onSurface.withOpacity(0.8)),
                  tooltip: 'Sort',
                  onPressed: _showSortBottomSheet,
                ),
              ],
              AccountMenuButton(profileImageUrl: _profileImageUrl, onSignOut: _handleSignOut),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CATEGORY CHIPS ──────────────────────────────────────────────────────

  Widget _buildCategoryChips(Color primary, Color onSurface, Color surface) {
    final categories = [
      ('all', 'All'),
      ('photos', 'Photos'),
      ('questions', 'Questions'),
      ('guides', 'Guides'),
      ('landmarks', 'Landmarks'),
      ('tips', '💡 Tips'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _activeCategory == cat.$1;
          return FilterChip(
            label: Text(cat.$2, style: TextStyle(fontFamily: 'Marcellus', fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primary, fontSize: 13)),
            selected: isSelected,
            onSelected: (_) => setState(() => _activeCategory = cat.$1),
            selectedColor: primary,
            backgroundColor: Colors.transparent,
            showCheckmark: false,
            side: BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  // ─── TRENDING HASHTAGS HELPER ────────────────────────────────────────────

  List<MapEntry<String, int>> _extractTrendingHashtags(List<CommunityPost> posts) {
    final counts = <String, int>{};
    final regex = RegExp(r'#(\w+)');
    for (final post in posts) {
      for (final match in regex.allMatches(post.content)) {
        final tag = match.group(1)!.toLowerCase();
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).toList();
  }

  // ─── TRENDING HASHTAGS WIDGET ─────────────────────────────────────────────

  Widget _buildTrendingHashtags(List<MapEntry<String, int>> tags, Color primary, Color onSurface) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 15, color: primary),
              const SizedBox(width: 6),
              Text('Trending', style: TextStyle(fontFamily: 'Marcellus', fontSize: 13, color: onSurface, fontWeight: FontWeight.bold)),
              if (_activeHashtag != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _activeHashtag = null),
                  child: Text('Clear filter', style: TextStyle(color: primary, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tag = tags[i];
              final isActive = _activeHashtag == tag.key;
              return GestureDetector(
                onTap: () => setState(() => _activeHashtag = isActive ? null : tag.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? primary : primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withOpacity(isActive ? 1.0 : 0.25)),
                  ),
                  child: Text(
                    '#${tag.key}  ${tag.value}',
                    style: TextStyle(
                      color: isActive ? Colors.white : primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ─── LEADERBOARD WIDGET ───────────────────────────────────────────────────

  Widget _buildLeaderboard(List<CommunityPost> posts, Color primary, Color onSurface, Color surface, bool isDark) {
    // Group by userId — count posts
    final Map<String, List<CommunityPost>> byUser = {};
    for (final post in posts) {
      if (post.userId.isNotEmpty) {
        byUser.putIfAbsent(post.userId, () => []).add(post);
      }
    }
    if (byUser.isEmpty) return const SizedBox.shrink();
    final sorted = byUser.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top = sorted.take(3).toList();

    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏆', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text('Top Explorers This Feed', style: TextStyle(fontFamily: 'Marcellus', fontSize: 13, color: onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(top.length, (i) {
            final entry = top[i];
            final sample = entry.value.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(medals[i], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  sample.userAvatar.isNotEmpty
                      ? CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider(sample.userAvatar))
                      : CircleAvatar(radius: 14, backgroundColor: primary.withOpacity(0.12), child: Icon(Icons.person, size: 14, color: primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sample.userName, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                        if (sample.userUsername.isNotEmpty)
                          Text('@${sample.userUsername}', style: TextStyle(color: primary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                    child: Text('${entry.value.length} posts', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── CHALLENGE CARD ──────────────────────────────────────────────────────

  Widget _buildChallengeCard(BuildContext context, Color primary, Color onSurface, Color surface) {
    return FutureBuilder<QuerySnapshot>(
      future: GetIt.I<FirebaseFirestore>().collection('challenges').where('isActive', isEqualTo: true).limit(1).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final hashtag = data['challengeHashtag'] as String? ?? '';
        if (title.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12, top: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD6A00F), Color(0xFFB8860B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0xFFD6A00F).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                _composerFocusNode.requestFocus();
                if (hashtag.isNotEmpty && !_postController.text.contains(hashtag)) {
                  _postController.text = '$hashtag ';
                  _postController.selection = TextSelection.fromPosition(TextPosition(offset: _postController.text.length));
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Challenge', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Marcellus', fontSize: 15, fontWeight: FontWeight.bold)),
                          if (hashtag.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text('Post Now', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: Colors.white54, size: 44),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── COMPOSER ────────────────────────────────────────────────────────────

  Widget _buildComposer(ThemeData theme, Color surface, Color onSurface, Color primary, BoxShadow shadow) {
    final isDark = theme.brightness == Brightness.dark;
    final bool isActive = _composerFocused || _postController.text.isNotEmpty || _selectedImages.isNotEmpty || _selectedLocationName != null;

    return GestureDetector(
      onTap: () => _composerFocusNode.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isActive ? 12 : 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? primary.withOpacity(0.3) : (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
          boxShadow: [shadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                  backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) ? CachedNetworkImageProvider(_profileImageUrl!) : null,
                  child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) ? Icon(Icons.person, size: 20, color: onSurface.withOpacity(0.75)) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    focusNode: _composerFocusNode,
                    maxLines: isActive ? 4 : 1,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Share your Egypt experience...',
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.55)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (!isActive)
                  _isPosting
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                      : IconButton(
                          icon: Icon(Icons.send_rounded, color: primary),
                          onPressed: _handlePostAction,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
              ],
            ),

            // Tags row: location + category chips
            if (_selectedLocationName != null || _selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (_selectedLocationName != null)
                      Chip(
                        backgroundColor: primary.withOpacity(0.10),
                        avatar: Icon(Icons.location_on_rounded, size: 14, color: primary),
                        label: Text(_selectedLocationName!, style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600)),
                        deleteIcon: Icon(Icons.close, size: 13, color: primary.withOpacity(0.7)),
                        onDeleted: () => setState(() {
                          _selectedLocationName = null;
                          _selectedLocationId = null;
                          _selectedLocationLat = null;
                          _selectedLocationLng = null;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: primary.withOpacity(0.20)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    if (_selectedCategory != null)
                      Chip(
                        backgroundColor: primary.withOpacity(0.10),
                        avatar: Icon(Icons.label_rounded, size: 14, color: primary),
                        label: Text(_selectedCategory!, style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600)),
                        deleteIcon: Icon(Icons.close, size: 13, color: primary.withOpacity(0.7)),
                        onDeleted: () => setState(() => _selectedCategory = null),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: primary.withOpacity(0.20)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                  ],
                ),
              ),

            // Image preview strip
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (_, index) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: Material(
                            color: Colors.black54, shape: const CircleBorder(), clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              customBorder: const CircleBorder(),
                              child: const SizedBox(width: 20, height: 20, child: Icon(Icons.close, size: 12, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Action row — only visible when active
            if (isActive) ...[
              Divider(height: 16, color: onSurface.withOpacity(0.08)),
              Row(
                children: [
                  _ComposerActionBtn(icon: Icons.photo_library_outlined, color: onSurface.withOpacity(0.65), onTap: _pickImages, tooltip: 'Add photos'),
                  const SizedBox(width: 4),
                  _ComposerActionBtn(
                    icon: Icons.location_on_outlined,
                    color: _selectedLocationName != null ? primary : onSurface.withOpacity(0.65),
                    onTap: _pickLocation,
                    tooltip: 'Tag location',
                  ),
                  const SizedBox(width: 4),
                  _ComposerActionBtn(
                    icon: Icons.label_outline_rounded,
                    color: _selectedCategory != null ? primary : onSurface.withOpacity(0.65),
                    onTap: _showCategoryPicker,
                    tooltip: 'Category',
                  ),
                  const Spacer(),
                  _isPosting
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: primary))
                      : GestureDetector(
                          onTap: _handlePostAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Post', style: TextStyle(color: Colors.white, fontFamily: 'Marcellus', fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── SHIMMER ─────────────────────────────────────────────────────────────

  Widget _buildShimmerSkeleton(Color surface, Color onSurface, bool isDark, BoxShadow shadow) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)), boxShadow: [shadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ShimmerLoadingWidget.circular(width: 40, height: 40),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ShimmerLoadingWidget.rectangular(width: 120, height: 14),
              const SizedBox(height: 6),
              const ShimmerLoadingWidget.rectangular(width: 80, height: 10),
            ]),
          ]),
          const SizedBox(height: 12),
          const ShimmerLoadingWidget.rectangular(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          const ShimmerLoadingWidget.rectangular(width: 200, height: 14),
          const SizedBox(height: 12),
          const ShimmerLoadingWidget.rectangular(width: double.infinity, height: 160),
        ],
      ),
    );
  }
}

class _ComposerActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ComposerActionBtn({required this.icon, required this.color, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

