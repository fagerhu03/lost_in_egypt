import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

import './data/datasources/local_mock_data.dart';
import './data/models/map_item_models.dart'; 
import '../navigator/widget/search_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
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

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // --- IMAGE UPLOADER ---
  // Future<String> _uploadAssetImage(String assetPath, String filename) async {
  //   try {
  //     final byteData = await rootBundle.load(assetPath);
  //     final bytes = byteData.buffer.asUint8List();

  //     final ref = FirebaseStorage.instance.ref().child('seed_images/$filename');
  //     final uploadTask = await ref.putData(bytes);

  //     final url = await uploadTask.ref.getDownloadURL();
  //     print("✅ Image Uploaded: $url");
  //     return url;
  //   } catch (e) {
  //     print("❌ Image Upload Failed: $e");
  //     return ""; 
  //   }
  // }

  // // --- SEEDER FUNCTION ---
  // Future<void> _seedDatabase() async {
  //   final firestore = FirebaseFirestore.instance;
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Starting Upload... this may take a minute.")));

  //   try {
  //     // 1. PROCESS EVENTS
  //     for (var e in MockHomeRepository.events) {
  //       String imageUrl = await _uploadAssetImage(e.imagePath, "${e.id}.jpg");
  //       var data = e.toMap();
  //       data['imagePath'] = imageUrl; 
  //       await firestore.collection('events').doc(e.id).set(data);
  //     }

  //     // 2. PROCESS PLACES
  //     for (var p in MockHomeRepository.places) {
  //       String imageUrl = await _uploadAssetImage(p.imagePath, "${p.id}.jpg");
  //       var data = p.toMap();
  //       data['imagePath'] = imageUrl;
  //       await firestore.collection('places').doc(p.id).set(data);
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Images & Data linked in Cloud.")));
  //     }
  //   } catch (e) {
  //     print("Seeding Error: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFCFBE8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 SEARCH HEADER
              SearchHeader(
                profileImageUrl: _profileImageUrl,
                onSignOut: _handleSignOut,
              ),
              
              // 🔴 TEMPORARY SEEDER BUTTON (Delete after success)
              // Center(
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 10),
              //     child: ElevatedButton.icon(
              //       onPressed: _seedDatabase,
              //       icon: const Icon(Icons.public, color: Colors.white),
              //       label: const Text("Seed Maps Data", style: TextStyle(color: Colors.white)),
              //       style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              //     ),
              //   ),
              // ),
              
              const SizedBox(height: 12),

              // 🖼 HERO IMAGE
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/home_bridge.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ⭐ WHAT'S NEW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "What's New",
                  style: TextStyle(
                    color: const Color(0xff4D5420),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // CATEGORY GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: LocalMockData.categories.map((category) {
                    return _categoryCard(category.iconPath, category.title);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ EVENTS HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Events",
                      style: TextStyle(
                        color: const Color(0xff4D5420),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus",
                      ),
                    ),
                    Text(
                      "see all >",
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ⭐ REAL-TIME FIRESTORE EVENTS LIST
              SizedBox(
                height: 170,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("Something went wrong"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No events found"));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final event = EventModel.fromMap(data, docs[index].id);

                        return _eventCard(event.title, event.imagePath);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ PLAN YOUR TRIP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Plan your trip",
                  style: TextStyle(
                    color: const Color(0xff4D5420),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _tripCard("Guide")),
                    const SizedBox(width: 12),
                    Expanded(child: _tripCard("Solo trip")),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _categoryCard(String icon, String title) {
    return Container(
      width: 110,
      height: 95,
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, width: 35),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff4D5420),
              fontWeight: FontWeight.w600,
              fontFamily: "Marcellus",
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ UPDATED: Handles Caching & Shimmer for HTTP images
  Widget _eventCard(String title, String imagePath) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. THE IMAGE (Smart Loading)
            Positioned.fill(
              child: imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                         color: Colors.grey.shade300, 
                         child: const Icon(Icons.image_not_supported),
                      ),
                    ),
            ),

            // 2. GRADIENT OVERLAY (For Text Readability)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. TITLE
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripCard(String title) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xff4D5420),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: "Marcellus",
          ),
        ),
      ),
    );
  }
}