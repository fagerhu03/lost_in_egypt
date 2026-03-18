import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class SavedPlacesScreen extends StatefulWidget {
  final List<MapItem> allItems;

  const SavedPlacesScreen({super.key, required this.allItems});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  bool _isLoading = true;
  List<MapItem> _savedPlaces = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedPlaces();
  }

  Future<void> _fetchSavedPlaces() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final savedIds = List<String>.from(doc.data()?['savedPlaces'] ?? []);
        // Reverse so most recently saved is first (arrayUnion appends to end)
        final reversedIds = savedIds.reversed.toList();
        final matchingPlaces = <MapItem>[];
        for (final id in reversedIds) {
          final match = widget.allItems.where((item) => item.id == id).firstOrNull;
          if (match != null) matchingPlaces.add(match);
        }
        if (mounted) {
          setState(() {
            _savedPlaces = matchingPlaces;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching saved places: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Saved Places', style: TextStyle(fontFamily: 'Marcellus')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPlaces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No saved places yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on a place to save it here.',
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _savedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _savedPlaces[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: surface,
                      elevation: isDark ? 0 : 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context, place);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: onSurface.withOpacity(0.05),
                                  image: place.imagePaths.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(place.imagePaths.first),
                                          fit: BoxFit.cover,
                                        )
                                      : place.imagePath.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(place.imagePath),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: place.imagePaths.isEmpty && place.imagePath.isEmpty
                                    ? Icon(Icons.place, color: primary.withOpacity(0.5))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      place.category.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: onSurface.withOpacity(0.5)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
