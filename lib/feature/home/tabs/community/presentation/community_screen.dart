import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Ensure these imports match your project structure
import '../../navigator/widget/account_menu_button.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../domain/entities/community_post.dart';
import './community_post_card.dart';
import 'post_detail_screen.dart';
import '../../../../auth/phone_verif/phone_verification_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // State Variables
  String _searchQuery = "";
  String? _profileImageUrl;
  bool _isPosting = false; // ✅ NEW: Prevent duplicate posts
  String? _selectedLocationName;
  String? _selectedLocationId;

  // Filter & Image State
  String _sortBy = 'newest'; // 'newest' or 'popular'
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _postController.dispose();
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
          // Ensure existing posts by this user have correct flag
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

  // ✅ CRITICAL FIX: The Gatekeeper Logic
  // This checks for phone verification BEFORE allowing the post to happen.
  void _handlePostAction() async {
    // ✅ NEW: Prevent rapid/duplicate posts
    if (_isPosting) return;

    // 1. Basic validation (don't bother checking phone if text is empty)
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    // 🔒 CHECK: Is user phone-verified in Firestore?
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
      // 🛑 BLOCKED: Show Verification Screen
      final bool? verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneVerificationScreen(),
        ),
      );

      // If they came back and verified == true, let them post
      if (verified == true) {
        _handlePost(); // ✅ Proceed to actual posting
      }
    } else {
      // ✅ ALLOWED: User is already verified
      _handlePost(); // ✅ Proceed to actual posting
    }
  }

  Future<void> _pickLocation() async {
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tag a Location"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search places...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (val) async {
                        if (val.trim().length < 2) {
                          setDialogState(() => searchResults = []);
                          return;
                        }
                        setDialogState(() => isLoading = true);
                        final results = await _repository.searchPlaces(
                          val,
                        ); // Make sure this method exists in your repo
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
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (searchResults.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Type to search places...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = searchResults[index];
                            // Handle image (network or asset or fallback)
                            final imagePath = place['image'] ?? '';
                            Widget leadingImage;
                            if (imagePath.startsWith('http')) {
                              leadingImage = Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.place, color: Colors.grey),
                              );
                            } else {
                              leadingImage = Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.place, color: Colors.grey),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
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

  // ✅ Actual Logic to Upload Post
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
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      body: Stack(
        children: [
          Container(color: const Color(0xFFFCFBE8)),
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
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
                _buildSearchHeader(context),
                _buildFilterBar(),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildComposer()],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<CommunityPost>>(
                          stream: _repository.getPostsStream(sortBy: _sortBy),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
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
                                      .where(
                                        (p) => p.content.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ),
                                      )
                                      .toList();

                            if (allPosts.isEmpty) {
                              return const Center(
                                child: Text("No posts yet. Be the first!"),
                              );
                            }
                            if (filteredPosts.isEmpty) {
                              return Center(
                                child: Text("No results for '$_searchQuery'"),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: filteredPosts.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                return CommunityPostCard(
                                  post: post,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(post: post),
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

  // (Search Header and Filter Bar remain the same as your code)
  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff4D5420).withOpacity(0.50),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0D8C3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  hintText: "Search posts...",
                  hintStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
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

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip("Newest", "newest"),
          const SizedBox(width: 10),
          _filterChip("Top Rated", "popular"),
          const SizedBox(width: 10),
          _filterChip("Most Discussed", "most_discussed"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF714611) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF714611)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF714611),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _postController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    border: InputBorder.none,
                    suffix: _selectedLocationName != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Chip(
                              label: Text(
                                _selectedLocationName!,
                                style: const TextStyle(fontSize: 10),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 12),
                              onDeleted: () => setState(() {
                                _selectedLocationName = null;
                                _selectedLocationId = null;
                              }),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          // IMAGE PREVIEW
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
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImages.removeAt(index)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
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

          // ACTION BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF7A6A55),
                    ),
                    onPressed: _pickImages,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: _selectedLocationName != null
                          ? Colors.blue
                          : const Color(0xFF7A6A55),
                    ),
                    onPressed: _pickLocation,
                  ),
                ],
              ),

              // ✅ FIXED BUTTON: Calls _handlePostAction (The Gatekeeper) instead of _handlePost
              ElevatedButton(
                onPressed: _isPosting ? null : _handlePostAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714611),
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
                    : const Text("Post", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
