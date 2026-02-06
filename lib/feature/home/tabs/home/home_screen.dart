import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../navigator/widget/account_menu_button.dart';
import './data/datasources/local_mock_data.dart';
import './data/models/map_item_models.dart';
import '../navigator/widget/search_header.dart';
//import 'dart:convert';

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFCFBE8),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 HERO IMAGE + SEARCH
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/home_bridge.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.08),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: SearchHeader(onSignOut: () {})),
                      const SizedBox(width: 12),
                      AccountMenuButton(
                        profileImageUrl: _profileImageUrl,
                        onSignOut: _handleSignOut,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xffFCFBE8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ⭐ WHAT'S NEW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "What's New",
                style: TextStyle(
                  color: const Color(0xff714611),
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
                      color: const Color(0xff714611),
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

            // ⭐ REAL-TIME EVENTS LIST
            SizedBox(
              height: 170,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .limit(5)
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
                  color: const Color(0xff714611),
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
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _categoryCard(String icon, String title) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, width: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff714611),
              fontWeight: FontWeight.w600,
              fontFamily: "Marcellus",
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(String title, String imagePath) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
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
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff714611),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: "Marcellus",
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripCard(String title) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xff714611),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: "Marcellus",
          ),
        ),
      ),
    );
  }
}