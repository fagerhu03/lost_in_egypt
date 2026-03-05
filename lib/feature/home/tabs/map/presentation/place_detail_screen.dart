import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class PlaceDetailSheet extends StatefulWidget {
  final MapItem place;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;
  final VoidCallback onDirections;
  final ValueChanged<double>? onScrollExtentChanged;
  final VoidCallback? onSavedToggled;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.onClose,
    required this.onShowOnMap,
    required this.onDirections,
    this.onScrollExtentChanged,
    this.onSavedToggled,
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  int _currentImageIndex = 0;
  bool _isSaved = false;
  String? _userId;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _calculateDistance();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      if (doc.exists && mounted) {
        final savedPlaces = List<String>.from(doc.data()?['savedPlaces'] ?? []);
        setState(() {
          _isSaved = savedPlaces.contains(widget.place.id);
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final distMeters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        widget.place.coordinate.latitude, widget.place.coordinate.longitude,
      );
      if (mounted) {
        setState(() {
          _distanceKm = distMeters / 1000;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save places.')),
      );
      return;
    }

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'savedPlaces': FieldValue.arrayUnion([widget.place.id])
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'savedPlaces': FieldValue.arrayRemove([widget.place.id])
        });
      }
      widget.onSavedToggled?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  String _estimateFare(double km) {
    // Egyptian taxi fare: ~10 EGP base + ~5 EGP/km
    final fare = (10 + km * 5).round();
    final fareHigh = (fare * 1.5).round();
    return '~$fare–$fareHigh EGP by taxi';
  }

  String _getOpeningStatus() {
    if (widget.place.openingHoursText.isNotEmpty) {
      return widget.place.isCurrentlyOpen ? 'Open Now' : 'Closed';
    }
    return '';
  }

  String _getTodayHours() {
    if (widget.place.openingHoursText.isEmpty) return '';
    final lines = widget.place.openingHoursText.split('\n');
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = weekdays[DateTime.now().weekday - 1];
    for (final line in lines) {
      if (line.contains(today)) {
        return line.replaceFirst('$today: ', '').trim();
      }
    }
    return lines.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final sheetShadow = isDark
        ? BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          )
        : BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, -10),
          );

    final borderColor = (isDark ? Colors.white : Colors.black)
        .withOpacity(isDark ? 0.10 : 0.06);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.onScrollExtentChanged?.call(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.55,
        minChildSize: 0.2,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.2, 0.55, 0.95],
        builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
            boxShadow: [sheetShadow],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Image Carousel
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: widget.place.imagePaths.isNotEmpty
                        ? PageView.builder(
                            itemCount: widget.place.imagePaths.length,
                            onPageChanged: (index) => setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) {
                              return Image.network(
                                widget.place.imagePaths[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: onSurface.withOpacity(0.06),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primary,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (c, e, s) => Container(
                                  color: onSurface.withOpacity(0.06),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported_outlined,
                                            color: onSurface.withOpacity(0.35), size: 50),
                                        const SizedBox(height: 8),
                                        Text('Photo not available',
                                            style: TextStyle(
                                                color: onSurface.withOpacity(0.4),
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : widget.place.imagePath.isNotEmpty
                            ? Image.network(
                                widget.place.imagePath,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: onSurface.withOpacity(0.06),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primary,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (c, e, s) => Container(
                                  color: onSurface.withOpacity(0.06),
                                  child: const Center(child: Icon(Icons.broken_image)),
                                ),
                              )
                            : Container(
                                color: primary.withOpacity(isDark ? 0.15 : 0.08),
                                child: Center(
                                  child: Icon(Icons.place,
                                      color: primary.withOpacity(0.4), size: 64),
                                ),
                              ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.55),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: Colors.white),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (widget.place.imagePaths.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.place.imagePaths.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 8 : 6,
                            height: _currentImageIndex == index ? 8 : 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.place.title,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category + rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                primary.withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: primary.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            widget.place.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        Text(
                          " ${widget.place.rating}",
                          style: TextStyle(
                            color: onSurface.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.map_outlined,
                          label: "Show on Map",
                          isPrimary: true,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {
                            _sheetController.animateTo(
                              0.2,
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            widget.onShowOnMap();
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: "Directions",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: widget.onDirections,
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: "Share",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _buildActionButton(
                          icon: _isSaved ? Icons.favorite : Icons.favorite_border,
                          label: _isSaved ? "Saved" : "Save",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: _toggleSave,
                          iconColor: _isSaved ? Colors.red : primary,
                        ),
                      ],
                    ),

                    Divider(
                      height: 40,
                      thickness: 1,
                      color: onSurface.withOpacity(0.10),
                    ),

                    // About
                    Text(
                      "About",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : "Explore the ancient wonders and hidden gems of Egypt. "
                              "This location offers a unique glimpse into the rich "
                              "history and culture of the region.",
                      style: TextStyle(
                        height: 1.6,
                        color: onSurface.withOpacity(0.85),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info tiles
                    if (widget.place.locationAddress.isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        text: widget.place.locationAddress,
                        iconColor: primary,
                        onSurface: onSurface,
                      ),

                    // Distance from user
                    if (_distanceKm != null)
                      _buildInfoTile(
                        icon: Icons.near_me_outlined,
                        text: _formatDistance(_distanceKm!),
                        iconColor: Colors.blue,
                        onSurface: onSurface,
                      ),

                    // Real opening hours
                    if (_getOpeningStatus().isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.access_time,
                        text: '${_getOpeningStatus()} • ${_getTodayHours()}',
                        iconColor: widget.place.isCurrentlyOpen ? Colors.green : Colors.red,
                        onSurface: onSurface,
                      ),

                    if (widget.place.price > 0)
                      _buildInfoTile(
                        icon: Icons.confirmation_number_outlined,
                        text:
                            "${widget.place.price.toStringAsFixed(0)} EGP Entry Fee",
                        iconColor: Colors.green,
                        onSurface: onSurface,
                      ),

                    // Estimated taxi fare
                    if (_distanceKm != null && _distanceKm! > 1)
                      _buildInfoTile(
                        icon: Icons.local_taxi_outlined,
                        text: _estimateFare(_distanceKm!),
                        iconColor: Colors.amber.shade700,
                        onSurface: onSurface,
                      ),

                    // Reviews section
                    if (widget.place.reviews.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(
                        thickness: 1,
                        color: onSurface.withOpacity(0.10),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "What Travelers Say",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.place.reviews.take(3).map((review) =>
                        _buildReviewCard(review, onSurface, primary, isDark),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ));
  }

  Widget _buildReviewCard(PlaceReview review, Color onSurface, Color primary, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(isDark ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onSurface.withOpacity(isDark ? 0.10 : 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primary.withOpacity(0.15),
                child: Text(
                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating.round() ? Icons.star : Icons.star_border,
                          size: 12,
                          color: Colors.amber,
                        )),
                        const SizedBox(width: 6),
                        Text(
                          review.relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.text.length > 200 ? '${review.text.substring(0, 200)}...' : review.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    required Color primary,
    required Color onSurface,
    required bool isDark,
    Color? iconColor,
  }) {
    final bg = isPrimary ? primary : Colors.transparent;

    final border = Border.all(
      color: isPrimary
          ? Colors.transparent
          : onSurface.withOpacity(isDark ? 0.18 : 0.20),
    );

    final buttonShadow = isPrimary
        ? [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(0.14),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            )
          ]
        : <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: isPrimary ? null : border,
              boxShadow: buttonShadow,
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isPrimary ? Colors.white : primary),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? primary : onSurface.withOpacity(0.70),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}