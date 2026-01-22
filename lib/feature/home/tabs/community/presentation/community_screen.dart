import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/repositories/firebase_community_repository.dart';
import '../domain/entities/community_post.dart';
import './community_post_card.dart';
import 'post_detail_screen.dart';
import '../../../notification/notification_screen.dart';

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
  bool _isPosting = false;
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
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
  }

  Future<void> _pickLocation() async {
    List<Map<String, dynamic>> searchResults = [];
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder is crucial: It allows the dialog to rebuild
        // when we setDialogState (loading spinner, new results)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tag a Location"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // Fixed height so it doesn't jump
                child: Column(
                  children: [
                    // Search Input
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

                        // 1. Call your Repository to search Firestore
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

                    // Results List
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
                            final imagePath = place['image'] ?? '';

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
                                  child: (imagePath.startsWith('http'))
                                      ? Image.network(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(
                                            Icons.place,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(
                                            Icons.place,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                place['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                // 2. Update the parent screen state
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
    if (_selectedImages.length >= 4) return; // Limit to 4

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
    if (_postController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await _repository.addPost(
        _postController.text.trim(),
        _selectedImages,
        locationName: _selectedLocationName, // 👈 Pass location
        locationId: _selectedLocationId,
      );

      _postController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedLocationName = null; // Clear location
        _selectedLocationId = null;
      });
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      body: Stack(
        children: [
          // Background Color
          Container(color: const Color(0xFFFCFBE8)),

          // Background Pattern
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
                // 1. HEADER (Search + Profile)
                _buildSearchHeader(context),

                // 2. FILTER BAR
                _buildFilterBar(),

                Expanded(
                  child: Column(
                    children: [
                      // 3. COMPOSER (Write Post)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildComposer()],
                        ),
                      ),

                      // 4. FEED (Posts List)
                      Expanded(
                        child: StreamBuilder<List<CommunityPost>>(
                          stream: _repository.getPostsStream(sortBy: _sortBy),
                          builder: (context, snapshot) {
                            // 1. Loading State
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // 2. ⭐ ERROR STATE (This is what was missing!)
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

                            // Filter logic (Search)
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
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(post: post),
                                      ),
                                    );
                                  },
                                  child: CommunityPostCard(post: post),
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

  Widget _buildSearchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          // Search Bar (Kept as requested)
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
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
                  hintText: "Search posts...",
                  hintStyle: TextStyle(
                    color: Colors.grey, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500
                  ),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF7A6A55)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          // ⭐ PROFILE DROPDOWN (With Notification Badge Logic)
          StreamBuilder<int>(
            stream: _repository.getUnreadCountStream(),
            builder: (context, snapshot) {
              final int unreadCount = snapshot.data ?? 0;
              final String badgeText = unreadCount > 9 ? "9+" : "$unreadCount";

              return PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: const Color(0xffFFFDF4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                
                // The Trigger Icon (Profile Pic)
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack( // Stack for the badge on the profile pic itself (optional, but looks nice)
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                            ? NetworkImage(_profileImageUrl!) 
                            : null,
                        child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      // Optional: Small red dot on avatar if unread
                      if (unreadCount > 0)
                        Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        )
                    ],
                  ),
                ),

                // Menu Actions
                onSelected: (value) {
                  if (value == 'notifications') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                  } else if (value == 'logout') {
                     FirebaseAuth.instance.signOut();
                  }
                },

                itemBuilder: (BuildContext context) {
                  return [
                     const PopupMenuItem<String>(
                      enabled: false,
                      child: Text("My Account", style: TextStyle(fontFamily: "Marcellus", fontWeight: FontWeight.bold, color: Color(0xff4D5420))),
                    ),
                    const PopupMenuDivider(),
                    
                    // ⭐ NOTIFICATION CENTRE ITEM
                    PopupMenuItem<String>(
                      value: 'notifications',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notifications_outlined, color: Color(0xFF7A6A55), size: 20),
                              SizedBox(width: 10),
                              Text("Notification Centre", style: TextStyle(fontFamily: "Marcellus")),
                            ],
                          ),
                          // ⭐ THE BADGE
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                        ],
                      ),
                    ),
                    
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text("Sign Out", style: TextStyle(fontFamily: "Marcellus")),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
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
            color: isSelected ? Colors.white : const Color(0xFF7A6A55),
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
                  // 👇 FIX: Removed 'const' here because 'suffix' changes dynamically
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    border: InputBorder.none,
                    // Show chip if location is selected
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

              ElevatedButton(
                onPressed: _isPosting ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff714611),
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
