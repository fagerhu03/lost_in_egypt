import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../navigator/widget/account_menu_button.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../domain/entities/community_post.dart';
import './community_post_card.dart';
import 'post_detail_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
import '../../../../../core/widgets/shimmer_loading_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final TextEditingController _postController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  String _searchQuery = "";
  String? _profileImageUrl;
  bool _isPosting = false;
  String? _selectedLocationName;
  String? _selectedLocationId;

  String _sortBy = 'newest';
  List<File> _selectedImages = [];
  late Stream<List<CommunityPost>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _repository.getPostsStream(sortBy: _sortBy);
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _postController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _profileImageUrl = doc.data()?['profileImageUrl'];
          });
          try {
            await _repository.refreshUserPostsFlag(user.uid);
          } catch (e) {
            debugPrint('Error refreshing post flags: $e');
          }
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
  }

  void _handlePostAction() async {
    if (_isPosting) return;
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    bool isPhoneVerified = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists) {
        isPhoneVerified = doc.data()?['phoneVerified'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking phone verification: $e');
    }

    if (!isPhoneVerified) {
      final bool? verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneVerificationScreen(),
        ),
      );

      if (verified == true) {
        _handlePost();
      }
    } else {
      _handlePost();
    }
  }

  Future<void> _pickLocation() async {
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                "Tag a Location",
                style: TextStyle(color: onSurface),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: "Search places...",
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.7)),
                        filled: true,
                        fillColor: isDark
                            ? surface.withOpacity(0.7)
                            : surface.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: onSurface.withOpacity(0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: onSurface.withOpacity(0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) async {
                        if (val.trim().length < 2) {
                          setDialogState(() => searchResults = []);
                          return;
                        }
                        setDialogState(() => isLoading = true);
                        final results = await _repository.searchPlaces(val);
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
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else if (searchResults.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            "Type to search places...",
                            style: TextStyle(color: onSurface.withOpacity(0.55)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (c, i) => Divider(
                            height: 1,
                            color: onSurface.withOpacity(0.10),
                          ),
                          itemBuilder: (context, index) {
                            final place = searchResults[index];
                            final imagePath = place['image'] ?? '';
                            Widget leadingImage;
                            if (imagePath.startsWith('http')) {
                              leadingImage = CachedNetworkImage(
                                imageUrl: imagePath,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (_, __, ___) =>
                                    Icon(Icons.place, color: onSurface.withOpacity(0.6)),
                              );
                            } else {
                              leadingImage = Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.place, color: onSurface.withOpacity(0.6)),
                              );
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: leadingImage,
                                ),
                              ),
                              title: Text(
                                place['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedLocationName = place['title'];
                                  _selectedLocationId = place['id'];
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: onSurface.withOpacity(0.6)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) return;
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        limit: 4 - _selectedImages.length,
      );
      if (picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked.map((e) => File(e.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _handlePost() async {
    setState(() => _isPosting = true);
    try {
      await _repository.addPost(
        _postController.text.trim(),
        _selectedImages,
        locationName: _selectedLocationName,
        locationId: _selectedLocationId,
      );

      _postController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedLocationName = null;
        _selectedLocationId = null;
      });
      if (mounted) _composerFocusNode.unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

    // pattern opacity: 0.4 light / 0.2 dark
    final patternOpacity = isDark ? 0.1 : 0.4;

    // shadow: dark in light / light in dark
    final boxShadow = BoxShadow(
      color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08),
      blurRadius: 14,
      offset: const Offset(0, 8),
      spreadRadius: 1,
    );

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: bg)),
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSearchHeader(context, surface, onSurface, primary, boxShadow),
                _buildFilterBar(primary, onSurface, surface),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildComposer(theme, surface, onSurface, primary, boxShadow),
                          ],
                        ),
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
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Something went wrong:\n${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              );
                            }

                            final allPosts = snapshot.data ?? [];
                            final filteredPosts = _searchQuery.isEmpty
                                ? allPosts
                                : allPosts
                                .where((p) => p.content
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                                .toList();

                            if (allPosts.isEmpty) {
                              return Center(
                                child: Text(
                                  "No posts yet. Be the first!",
                                  style: TextStyle(color: onSurface.withOpacity(0.75)),
                                ),
                              );
                            }
                            if (filteredPosts.isEmpty) {
                              return Center(
                                child: Text(
                                  "No results for '$_searchQuery'",
                                  style: TextStyle(color: onSurface.withOpacity(0.75)),
                                ),
                              );
                            }

                            return ListView.separated(
                              key: const PageStorageKey('community_list'),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filteredPosts.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                return CommunityPostCard(
                                  key: ValueKey(post.id),
                                  post: post,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostDetailScreen(post: post),
                                      ),
                                    );
                                  },
                                );
                              },
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
    );
  }

  // --- WIDGETS ---

  Widget _buildSearchHeader(
      BuildContext context,
      Color surface,
      Color onSurface,
      Color primary,
      BoxShadow shadow,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchBg = primary.withOpacity(isDark ? 0.25 : 0.18);
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(0.10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [shadow],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: isDark ? onSurface : Colors.white,
                  fontFamily: "Marcellus",
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Search posts...",
                  hintStyle: TextStyle(
                    color: (isDark ? onSurface : Colors.white).withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: (isDark ? onSurface : Colors.white).withOpacity(0.9),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AccountMenuButton(
            profileImageUrl: _profileImageUrl,
            onSignOut: _handleSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(Color primary, Color onSurface, Color surface) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip("Newest", "newest", primary, onSurface, surface),
          const SizedBox(width: 10),
          _filterChip("Top Rated", "popular", primary, onSurface, surface),
          const SizedBox(width: 10),
          _filterChip("Most Discussed", "most_discussed", primary, onSurface, surface),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label,
      String value,
      Color primary,
      Color onSurface,
      Color surface,
      ) {
    final isSelected = _sortBy == value;

    return Material(
      color: isSelected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          if (_sortBy != value) {
            setState(() {
              _sortBy = value;
              _postsStream = _repository.getPostsStream(sortBy: _sortBy);
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : primary,
              fontWeight: FontWeight.bold,
              fontFamily: "Marcellus",
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(
      ThemeData theme,
      Color surface,
      Color onSurface,
      Color primary,
      BoxShadow shadow,
      ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
        boxShadow: [shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                backgroundImage:
                (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                    : null,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? Icon(Icons.person, size: 20, color: onSurface.withOpacity(0.75))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _postController,
                  focusNode: _composerFocusNode,
                  maxLines: null,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.55)),
                    border: InputBorder.none,
                    suffix: _selectedLocationName != null
                        ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        backgroundColor: primary.withOpacity(0.12),
                        label: Text(
                          _selectedLocationName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: onSurface.withOpacity(0.9),
                          ),
                        ),
                        deleteIcon: Icon(Icons.close, size: 12, color: onSurface.withOpacity(0.7)),
                        onDeleted: () => setState(() {
                          _selectedLocationName = null;
                          _selectedLocationId = null;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined, color: onSurface.withOpacity(0.75)),
                    onPressed: _pickImages,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: _selectedLocationName != null
                          ? primary
                          : onSurface.withOpacity(0.75),
                    ),
                    onPressed: _pickLocation,
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isPosting ? null : _handlePostAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isPosting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Post",
                  style: TextStyle(color: Colors.white, fontFamily: "Marcellus"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton(Color surface, Color onSurface, bool isDark, BoxShadow shadow) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: [shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerLoadingWidget.circular(width: 40, height: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoadingWidget.rectangular(width: 120, height: 14),
                  const SizedBox(height: 6),
                  const ShimmerLoadingWidget.rectangular(width: 80, height: 10),
                ],
              ),
            ],
          ),
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