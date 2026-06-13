import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/widgets/shimmer_avatar.dart';
import '../../navigator/widget/account_menu_button.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../domain/entities/community_post.dart';
import '../data/community_post_action_service.dart';
import './community_post_card.dart';
import 'post_detail_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
import '../../../../../core/widgets/shimmer_loading_widget.dart';
import '../../map/data/places_api_service.dart';
import '../../../../../core/services/recommendation_service.dart';
import '../../../../../core/services/recommendation_mappings.dart';
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
  final List<File> _selectedImages = [];
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
    final user = _auth.currentUser;

    bool isPhoneVerified = false;
    try {
      final doc = await _firestore.collection('users').doc(user?.uid).get();
      if (doc.exists) {
        isPhoneVerified = doc.data()?['phoneVerified'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking phone verification: $e');
    }

    if (!isPhoneVerified) {
      if (!mounted) return;
      final bool? verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
      );
      if (verified == true) _handlePost();
    } else {
      _handlePost();
    }
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
                height: 400.h,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search places in Egypt...',
                        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search, color: onSurface.withValues(alpha: 0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: onSurface.withValues(alpha: 0.12))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: onSurface.withValues(alpha: 0.12))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: primary.withValues(alpha: 0.8))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    SizedBox(height: 10.h),
                    if (isLoading)
                      Padding(padding: EdgeInsets.all(20.r), child: CircularProgressIndicator(color: primary))
                    else if (searchResults.isEmpty)
                      Expanded(child: Center(child: Text('Type to search places...', style: TextStyle(color: onSurface.withValues(alpha: 0.55)))))
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (_, _) => Divider(height: 1.h, color: onSurface.withValues(alpha: 0.10)),
                          itemBuilder: (context, index) {
                            final place = searchResults[index];
                            final name = (place['displayName'] as Map<String, dynamic>?)?['text'] as String? ?? '';
                            final address = (place['formattedAddress'] as String?) ?? '';
                            final loc = place['location'] as Map<String, dynamic>?;
                            final lat = (loc?['latitude'] as num?)?.toDouble();
                            final lng = (loc?['longitude'] as num?)?.toDouble();
                            final placeId = (place['id'] as String?) ?? '';
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                              leading: Container(
                                width: 40.r, height: 40.r,
                                decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                                child: Icon(Icons.place_rounded, color: primary, size: 20.r),
                              ),
                              title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14.sp)),
                              subtitle: address.isNotEmpty ? Text(address, style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
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
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.6))))],
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
            SizedBox(height: 12.h),
            Container(width: 36.w, height: 4.h, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.r))),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text('Post Category', style: TextStyle(fontFamily: 'Marcellus', fontSize: 16.sp, color: onSurface, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 12.h),
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return ListTile(
                leading: Container(
                  width: 38.r, height: 38.r,
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
                  child: Icon(cat.$2, color: primary, size: 20.r),
                ),
                title: Text(cat.$3, style: TextStyle(fontFamily: 'Marcellus', color: onSurface)),
                trailing: isSelected ? Icon(Icons.check_rounded, color: primary) : null,
                onTap: () {
                  setState(() => _selectedCategory = isSelected ? null : cat.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: 8.h),
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
    final postCategory = _selectedCategory;
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
        final inferred = RecommendationMappings.inferKeysFromText(
          '${postLocationName ?? ''} ${postCategory ?? ''}',
        );
        RecommendationService.recordSignal(
          placeId: postLocationId,
          placeName: postLocationName,
          types: inferred['types']!,
          tags: inferred['tags']!,
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
            SizedBox(height: 12.h),
            Container(width: 36.w, height: 4.h, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.r))),
            SizedBox(height: 16.h),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Text('Sort Posts', style: TextStyle(fontFamily: 'Marcellus', fontSize: 16.sp, color: onSurface, fontWeight: FontWeight.bold))),
            SizedBox(height: 8.h),
            _sortTile(ctx, 'Newest', 'newest', Icons.access_time_rounded, primary, onSurface),
            _sortTile(ctx, 'Top Rated', 'popular', Icons.thumb_up_outlined, primary, onSurface),
            _sortTile(ctx, 'Most Discussed', 'most_discussed', Icons.chat_bubble_outline_rounded, primary, onSurface),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, String label, String value, IconData icon, Color primary, Color onSurface) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Container(
        width: 38.r, height: 38.r,
        decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(icon, color: primary, size: 20.r),
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
      color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
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
              child: Image.asset('assets/pattern_comp.png', fit: BoxFit.cover, repeat: ImageRepeat.repeat, errorBuilder: (_, _, _) => Container()),
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
                        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
                        child: _buildComposer(theme, surface, onSurface, primary, boxShadow),
                      ),
                      Expanded(
                        child: StreamBuilder<List<CommunityPost>>(
                          stream: _postsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                                itemBuilder: (_, _) => _buildShimmerSkeleton(surface, onSurface, isDark, boxShadow),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(child: Padding(padding: EdgeInsets.all(16.r), child: Text('Something went wrong:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
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
                              return Center(child: Text('No posts yet. Be the first!', style: TextStyle(color: onSurface.withValues(alpha: 0.75))));
                            }
                            if (filteredPosts.isEmpty) {
                              return Center(child: Text(_searchQuery.isNotEmpty ? 'No results for \'$_searchQuery\'' : 'No posts in this category yet.', style: TextStyle(color: onSurface.withValues(alpha: 0.75))));
                            }

                            final currentUid = _auth.currentUser?.uid ?? '';

                            return Stack(
                              children: [
                                ListView.separated(
                                  key: const PageStorageKey('community_list'),
                                  controller: _scrollController,
                                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                                  itemCount: filteredPosts.length + 3, // +3: challenge, leaderboard, trending
                                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
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
                                    top: 12.h,
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
                                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius: BorderRadius.circular(20.r),
                                            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14.r),
                                              SizedBox(width: 6.w),
                                              Text('New posts — tap to refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
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
    final searchBg = primary.withValues(alpha: isDark ? 0.25 : 0.18);
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
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
                          height: 44.h,
                          decoration: BoxDecoration(color: searchBg, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: borderColor), boxShadow: [shadow]),
                          child: TextField(
                            autofocus: true,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(color: isDark ? onSurface : Colors.white, fontFamily: 'Marcellus', fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Search posts...',
                              hintStyle: TextStyle(color: (isDark ? onSurface : Colors.white).withValues(alpha: 0.85), fontSize: 16.sp, fontFamily: 'Marcellus'),
                              prefixIcon: Icon(Icons.search, color: (isDark ? onSurface : Colors.white).withValues(alpha: 0.9)),
                              suffixIcon: IconButton(icon: Icon(Icons.close, color: (isDark ? onSurface : Colors.white).withValues(alpha: 0.7)), onPressed: () => setState(() { _searchExpanded = false; _searchQuery = ''; })),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                            ),
                          ),
                        )
                      : Row(
                          key: const ValueKey('title'),
                          children: [
                            Text('Community', style: TextStyle(fontFamily: 'Marcellus', fontSize: 24.sp, fontWeight: FontWeight.bold, color: onSurface)),
                          ],
                        ),
                ),
              ),
              if (!_searchExpanded) ...[
                IconButton(icon: Icon(Icons.search_rounded, color: onSurface.withValues(alpha: 0.8)), onPressed: () => setState(() => _searchExpanded = true)),
                IconButton(
                  icon: Icon(Icons.sort_rounded, color: onSurface.withValues(alpha: 0.8)),
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
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _activeCategory == cat.$1;
          return FilterChip(
            label: Text(cat.$2, style: TextStyle(fontFamily: 'Marcellus', fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primary, fontSize: 13.sp)),
            selected: isSelected,
            onSelected: (_) => setState(() => _activeCategory = cat.$1),
            selectedColor: primary,
            backgroundColor: Colors.transparent,
            showCheckmark: false,
            side: BorderSide(color: primary),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
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
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 15.r, color: primary),
              SizedBox(width: 6.w),
              Text('Trending', style: TextStyle(fontFamily: 'Marcellus', fontSize: 13.sp, color: onSurface, fontWeight: FontWeight.bold)),
              if (_activeHashtag != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _activeHashtag = null),
                  child: Text('Clear filter', style: TextStyle(color: primary, fontSize: 12.sp)),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 34.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (_, i) {
              final tag = tags[i];
              final isActive = _activeHashtag == tag.key;
              return GestureDetector(
                onTap: () => setState(() => _activeHashtag = isActive ? null : tag.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isActive ? primary : primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: primary.withValues(alpha: isActive ? 1.0 : 0.25)),
                  ),
                  child: Text(
                    '#${tag.key}  ${tag.value}',
                    style: TextStyle(
                      color: isActive ? Colors.white : primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 4.h),
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
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 6.w),
              Text('Top Explorers This Feed', style: TextStyle(fontFamily: 'Marcellus', fontSize: 13.sp, color: onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10.h),
          ...List.generate(top.length, (i) {
            final entry = top[i];
            final sample = entry.value.first;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Text(medals[i], style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 8.w),
                  ShimmerAvatar(
                    url: sample.userAvatar,
                    radius: 14.r,
                    iconSize: 14.r,
                    fallbackBackgroundColor: primary.withValues(alpha: 0.12),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sample.userName, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 13.sp), overflow: TextOverflow.ellipsis),
                        if (sample.userUsername.isNotEmpty)
                          Text('@${sample.userUsername}', style: TextStyle(color: primary, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12.r)),
                    child: Text('${entry.value.length} posts', style: TextStyle(color: primary, fontSize: 11.sp, fontWeight: FontWeight.w700)),
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
          margin: EdgeInsets.only(bottom: 12.h, top: 4.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD6A00F), Color(0xFFB8860B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [BoxShadow(color: const Color(0xFFD6A00F).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: () {
                _composerFocusNode.requestFocus();
                if (hashtag.isNotEmpty && !_postController.text.contains(hashtag)) {
                  _postController.text = '$hashtag ';
                  _postController.selection = TextSelection.fromPosition(TextPosition(offset: _postController.text.length));
                }
              },
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weekly Challenge', style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(height: 4.h),
                          Text(title, style: TextStyle(color: Colors.white, fontFamily: 'Marcellus', fontSize: 15.sp, fontWeight: FontWeight.bold)),
                          if (hashtag.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12.r)),
                              child: Text('Post Now', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: Colors.white54, size: 44.r),
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
        padding: EdgeInsets.all(isActive ? 12.r : 10.r),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isActive ? primary.withValues(alpha: 0.3) : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
          boxShadow: [shadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ShimmerAvatar(
                  url: _profileImageUrl,
                  radius: 18.r,
                  iconSize: 20.r,
                  fallbackBackgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  fallbackIconColor: onSurface.withValues(alpha: 0.75),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    focusNode: _composerFocusNode,
                    maxLines: isActive ? 4 : 1,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Share your Egypt experience...',
                      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.55)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (!isActive)
                  _isPosting
                      ? SizedBox(width: 20.w, height: 20.h, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
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
                padding: EdgeInsets.only(top: 8.h),
                child: Wrap(
                  spacing: 6.w,
                  children: [
                    if (_selectedLocationName != null)
                      Chip(
                        backgroundColor: primary.withValues(alpha: 0.10),
                        avatar: Icon(Icons.location_on_rounded, size: 14.r, color: primary),
                        label: Text(_selectedLocationName!, style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.w600)),
                        deleteIcon: Icon(Icons.close, size: 13.r, color: primary.withValues(alpha: 0.7)),
                        onDeleted: () => setState(() {
                          _selectedLocationName = null;
                          _selectedLocationId = null;
                          _selectedLocationLat = null;
                          _selectedLocationLng = null;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: primary.withValues(alpha: 0.20)),
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                      ),
                    if (_selectedCategory != null)
                      Chip(
                        backgroundColor: primary.withValues(alpha: 0.10),
                        avatar: Icon(Icons.label_rounded, size: 14.r, color: primary),
                        label: Text(_selectedCategory!, style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.w600)),
                        deleteIcon: Icon(Icons.close, size: 13.r, color: primary.withValues(alpha: 0.7)),
                        onDeleted: () => setState(() => _selectedCategory = null),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: primary.withValues(alpha: 0.20)),
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                      ),
                  ],
                ),
              ),

            // Image preview strip
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
                child: SizedBox(
                  height: 80.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (_, index) => Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 8.w),
                          width: 80.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2.h, right: 10.w,
                          child: Material(
                            color: Colors.black54, shape: const CircleBorder(), clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              customBorder: const CircleBorder(),
                              child: SizedBox(width: 20.w, height: 20.h, child: Icon(Icons.close, size: 12.r, color: Colors.white)),
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
              Divider(height: 16.h, color: onSurface.withValues(alpha: 0.08)),
              Row(
                children: [
                  _ComposerActionBtn(icon: Icons.photo_library_outlined, color: onSurface.withValues(alpha: 0.65), onTap: _pickImages, tooltip: 'Add photos'),
                  SizedBox(width: 4.w),
                  _ComposerActionBtn(
                    icon: Icons.location_on_outlined,
                    color: _selectedLocationName != null ? primary : onSurface.withValues(alpha: 0.65),
                    onTap: _pickLocation,
                    tooltip: 'Tag location',
                  ),
                  SizedBox(width: 4.w),
                  _ComposerActionBtn(
                    icon: Icons.label_outline_rounded,
                    color: _selectedCategory != null ? primary : onSurface.withValues(alpha: 0.65),
                    onTap: _showCategoryPicker,
                    tooltip: 'Category',
                  ),
                  const Spacer(),
                  _isPosting
                      ? SizedBox(width: 22.w, height: 22.h, child: CircularProgressIndicator(strokeWidth: 2.5, color: primary))
                      : GestureDetector(
                          onTap: _handlePostAction,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(20.r)),
                            child: Text('Post', style: TextStyle(color: Colors.white, fontFamily: 'Marcellus', fontWeight: FontWeight.bold, fontSize: 14.sp)),
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)), boxShadow: [shadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerLoadingWidget.circular(width: 40.w, height: 40.h),
            SizedBox(width: 12.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerLoadingWidget.rectangular(width: 120.w, height: 14.h),
              SizedBox(height: 6.h),
              ShimmerLoadingWidget.rectangular(width: 80.w, height: 10.h),
            ]),
          ]),
          SizedBox(height: 12.h),
          ShimmerLoadingWidget.rectangular(width: double.infinity, height: 14.h),
          SizedBox(height: 6.h),
          ShimmerLoadingWidget.rectangular(width: 200.w, height: 14.h),
          SizedBox(height: 12.h),
          ShimmerLoadingWidget.rectangular(width: double.infinity, height: 160.h),
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
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Icon(icon, size: 22.r, color: color),
          ),
        ),
      ),
    );
  }
}
