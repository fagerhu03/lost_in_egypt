import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lost_in_egypt/core/widgets/shimmer_loading_widget.dart';
import 'package:lost_in_egypt/core/utils/error_handler.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/full_screen_gallery.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
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

  void _onShowOnMap() {
    MapFocusService.instance.triggerFocus(widget.place);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.place.imagePaths.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.place.imagePaths.length,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenGallery(
                                      imageUrls: widget.place.imagePaths,
                                      initialIndex: index,
                                      title: widget.place.title,
                                    ),
                                  ),
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: widget.place.imagePaths[index],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ShimmerLoadingWidget.rectangular(height: 280),
                                errorWidget: (_, __, ___) => Container(color: Colors.grey.withOpacity(0.15)),
                              ),
                            );
                          },
                        )
                      : widget.place.imagePath.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.place.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerLoadingWidget.rectangular(height: 280),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey.withOpacity(0.15)),
                            )
                          : Container(color: primary.withOpacity(isDark ? 0.15 : 0.08)),
                  
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.transparent,
                              surface,
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (widget.place.imagePaths.length > 1)
                    Positioned(
                      bottom: 20,
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
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.title,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        Text(
                          " ${widget.place.rating}",
                          style: TextStyle(
                            color: onSurface.withOpacity(0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.place.reviews.isNotEmpty)
                           Text(
                             " (${widget.place.reviews.length}+ reviews)",
                             style: TextStyle(
                               color: onSurface.withOpacity(0.5),
                               fontSize: 12,
                             ),
                           ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                          onTap: _onShowOnMap,
                        ),
                        _buildActionButton(
                          icon: Icons.directions,
                          label: "Directions",
                          isPrimary: false,
                          primary: primary,
                          onSurface: onSurface,
                          isDark: isDark,
                          onTap: () {},
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

                    Divider(height: 40, thickness: 1, color: onSurface.withOpacity(0.10)),

                    Text(
                      "About",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : "Explore the ancient wonders and hidden gems of Egypt. This location offers a unique glimpse into the rich history and culture of the region.",
                      style: TextStyle(
                        height: 1.6,
                        color: onSurface.withOpacity(0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (widget.place.locationAddress.isNotEmpty)
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        text: widget.place.locationAddress,
                        iconColor: primary,
                        onSurface: onSurface,
                      ),

                    if (_distanceKm != null)
                      _buildInfoTile(
                        icon: Icons.near_me_outlined,
                        text: _formatDistance(_distanceKm!),
                        iconColor: Colors.blue,
                        onSurface: onSurface,
                      ),

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
                        text: "${widget.place.price.toStringAsFixed(0)} EGP Entry Fee",
                        iconColor: Colors.green,
                        onSurface: onSurface,
                      ),

                    if (_distanceKm != null && _distanceKm! > 1)
                      _buildInfoTile(
                        icon: Icons.local_taxi_outlined,
                        text: _estimateFare(_distanceKm!),
                        iconColor: Colors.amber.shade700,
                        onSurface: onSurface,
                      ),

                    if (widget.place.reviews.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(thickness: 1, color: onSurface.withOpacity(0.10)),
                      const SizedBox(height: 16),
                      Text(
                        "What Travelers Say",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.place.reviews.map((review) =>
                        _buildReviewCard(review, onSurface, primary, isDark),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(PlaceReview review, Color onSurface, Color primary, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(isDark ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(16),
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
                radius: 18,
                backgroundColor: primary.withOpacity(0.15),
                child: Text(
                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating.round() ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        )),
                        const SizedBox(width: 6),
                        Text(
                          review.relativeTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.6),
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
            const SizedBox(height: 12),
            Text(
              review.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: onSurface.withOpacity(0.85),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
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
      color: isPrimary ? Colors.transparent : onSurface.withOpacity(isDark ? 0.18 : 0.20),
    );
    final buttonShadow = isPrimary
        ? [BoxShadow(color: (isDark ? Colors.white : Colors.black).withOpacity(0.14), blurRadius: 10, offset: const Offset(0, 6))]
        : <BoxShadow>[];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: isPrimary ? null : border,
              boxShadow: buttonShadow,
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isPrimary ? Colors.white : primary),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? primary : onSurface.withOpacity(0.75),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
