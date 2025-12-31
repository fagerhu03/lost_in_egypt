import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/mock_home_data.dart';
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

              // ⭐ WHAT'S NEW (Dynamic Categories)
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

              // DYNAMIC CATEGORY GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: MockHomeRepository.categories.map((category) {
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
                    // 1. Loading State
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 2. Error State
                    if (snapshot.hasError) {
                      return const Center(child: Text("Something went wrong"));
                    }

                    // 3. Empty State
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No events found"));
                    }

                    // 4. Data Loaded
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        // Convert DB Map -> EventModel
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

  Widget _eventCard(String title, String imagePath) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          // Handle missing images gracefully
          onError: (exception, stackTrace) {
            // You can add a placeholder logic here if needed
          },
        ),
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.0), Colors.black45],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Marcellus",
          ),
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
