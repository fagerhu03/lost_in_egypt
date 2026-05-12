import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class SavedPlacesSheet extends StatefulWidget {
  final List<MapItem> allItems;

  const SavedPlacesSheet({super.key, required this.allItems});

  @override
  State<SavedPlacesSheet> createState() => _SavedPlacesSheetState();
}

class _SavedPlacesSheetState extends State<SavedPlacesSheet> {
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final savedIds = List<String>.from(doc.data()?['savedPlaces'] ?? []);
        final reversedIds = savedIds.reversed.toList();
        final matchingPlaces = <MapItem>[];
        for (final id in reversedIds) {
          final match =
              widget.allItems.where((item) => item.id == id).firstOrNull;
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
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            // BottomSheet radius — not scaled per design convention
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(Icons.bookmarks_rounded, color: primary, size: 22.r),
                    SizedBox(width: 10.w),
                    Text(
                      'Saved Places',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Marcellus',
                        color: onSurface,
                      ),
                    ),
                    if (!_isLoading && _savedPlaces.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${_savedPlaces.length}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: onSurface.withValues(alpha: 0.10)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _savedPlaces.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border,
                                    size: 56.r,
                                    color: onSurface.withValues(alpha: 0.25)),
                                SizedBox(height: 14.h),
                                Text(
                                  'No saved places yet',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'Tap the heart on any place to save it.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: onSurface.withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            itemCount: _savedPlaces.length,
                            separatorBuilder: (ctx, i) => SizedBox(height: 8.h),
                            itemBuilder: (context, index) {
                              final place = _savedPlaces[index];
                              return Material(
                                color: isDark
                                    ? onSurface.withValues(alpha: 0.05)
                                    : surface,
                                borderRadius: BorderRadius.circular(16.r),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16.r),
                                  onTap: () => Navigator.pop(context, place),
                                  child: Padding(
                                    padding: EdgeInsets.all(10.r),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12.r),
                                          child: SizedBox(
                                            width: 70.r,
                                            height: 70.r,
                                            child: place.imagePaths.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: place.imagePaths.first,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (ctx, url, err) => Container(
                                                      color: primary.withValues(alpha: 0.08),
                                                      child: Icon(Icons.place,
                                                          color: primary.withValues(alpha: 0.4)),
                                                    ),
                                                  )
                                                : Container(
                                                    color: primary.withValues(alpha: 0.08),
                                                    child: Icon(Icons.place,
                                                        color: primary.withValues(alpha: 0.4)),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 14.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                place.title,
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 3.h),
                                              Text(
                                                place.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: primary,
                                                ),
                                              ),
                                              if (place.locationAddress.isNotEmpty) ...[
                                                SizedBox(height: 2.h),
                                                Text(
                                                  place.locationAddress,
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    color: onSurface.withValues(alpha: 0.45),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            color: onSurface.withValues(alpha: 0.3)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Keep old class name as alias so no other files break
typedef SavedPlacesScreen = SavedPlacesSheet;
