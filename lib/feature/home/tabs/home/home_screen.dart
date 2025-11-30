import 'package:flutter/material.dart';

import '../navigator/widget/search_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFCFBE8),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔍 SEARCH BAR
              const SearchHeader(),
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

              // ⭐ WHAT'S NEW TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "What's New",
                  style: TextStyle(
                    color: const Color(0xff4D5420),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ⭐ CATEGORY GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _categoryCard("assets/icons/hotel.png", "Hotels"),
                    _categoryCard("assets/icons/museum.png", "Museums"),
                    _categoryCard("assets/icons/restaurant.png", "Restaurants"),
                    _categoryCard("assets/icons/mosque.png", "Mosques"),
                    _categoryCard("assets/icons/beach.png", "Beaches"),
                    _categoryCard("assets/icons/adventure.png", "Adventure"),
                  ],
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
                      ),
                    ),
                    Text(
                      "see all >",
                      style: TextStyle(
                        color: Colors.brown.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ⭐ EVENTS HORIZONTAL SCROLL
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  children: [
                    _eventCard("Arabian Night", "assets/images/event1.jpg"),
                    _eventCard("Crimson Bar & Grill", "assets/images/event2.jpg"),
                    _eventCard("Temple Tour", "assets/images/event3.jpg"),
                  ],
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
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⭐ TRIP OPTIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _tripCard("Guide"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tripCard("Solo trip"),
                    ),
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

  // CATEGORY CARD
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
            ),
          ),
        ],
      ),
    );
  }

  // EVENT CARD
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
          ),
        ),
      ),
    );
  }

  // TRIP CARD
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
          ),
        ),
      ),
    );
  }
}
