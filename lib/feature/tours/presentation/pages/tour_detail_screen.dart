import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/utils/map_style_helper.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'full_screen_tour_map_screen.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../auth/data/models/user.dart';
import 'booking_confirmation_screen.dart';
import '../../../../core/widgets/universal_report_dialog.dart';
import '../../../admin/data/models/report_model.dart';
import '../../../admin/domain/repositories/reports_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/account_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../../feature/reviews/data/datasources/reviews_data_source.dart';
import '../../../../feature/reviews/data/models/review_model.dart';
import '../../../../core/services/recommendation_mappings.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../core/services/weather_controller.dart';
import '../../../../core/widgets/shimmer_loading_widget.dart';

class TourDetailScreen extends StatefulWidget {
  final TourEntity tour;

  const TourDetailScreen({super.key, required this.tour});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  TourEntity get tour => widget.tour;
  GoogleMapController? _meetingMapController;

  // "You might also enjoy" — fetched from sibling tours the first time the
  // screen builds. Empty list while loading or if engine returns nothing.
  List<TourEntity> _similarTours = [];
  bool _loadingSimilar = true;
  String? _mapStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MapStyleHelper.getStyle(context).then((style) {
      if (mounted) setState(() => _mapStyle = style);
    });
  }

  @override
  void initState() {
    super.initState();
    // Record a 'visit' signal — opening a tour detail screen reads as intent
    // (user is considering booking). Matches the place-detail pattern.
    final inferred = RecommendationMappings.inferKeysFromText(
      '${tour.title} ${tour.destinations.join(' ')} ${tour.description}',
    );
    RecommendationService.recordSignal(
      placeId: tour.id,
      placeName: tour.title,
      types: inferred['types']!,
      tags: inferred['tags']!,
      signalType: 'visit',
      source: 'tour_detail',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSimilarTours());
  }

  Future<void> _loadSimilarTours() async {
    try {
      // Fetch up to 30 sibling tours from Firestore. Filter out the current one
      // and any archived. This is the candidate pool the engine ranks against.
      final snap = await FirebaseFirestore.instance
          .collection('tours')
          .where('isArchived', isEqualTo: false)
          .limit(30)
          .get();
      final siblings = snap.docs
          .where((d) => d.id != tour.id)
          .map((d) {
            final m = d.data();
            return TourEntity(
              id: d.id,
              guideId: m['guideId'] as String? ?? '',
              title: m['title'] as String? ?? '',
              description: m['description'] as String? ?? '',
              destinations: List<String>.from(m['destinations'] ?? []),
              price: (m['price'] as num?)?.toDouble() ?? 0,
              meetingLatitude: (m['meetingLatitude'] as num?)?.toDouble() ?? 0,
              meetingLongitude: (m['meetingLongitude'] as num?)?.toDouble() ?? 0,
              meetingTime: (m['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
              frequency: m['frequency'] as String? ?? '',
              meetingLocationName: m['meetingLocationName'] as String? ?? '',
              images: List<String>.from(m['images'] ?? []),
              maxAttendees: (m['maxAttendees'] as num?)?.toInt() ?? 0,
              rating: (m['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
              createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList();
      if (siblings.isEmpty) {
        if (mounted) setState(() => _loadingSimilar = false);
        return;
      }

      final candidates = siblings.map((t) {
        final m = RecommendationMappings.inferKeysFromText(
          '${t.title} ${t.destinations.join(' ')} ${t.description}',
        );
        return <String, dynamic>{
          'placeId': t.id,
          'name': t.title,
          'types': m['types']!,
          'tags': m['tags']!,
          'rating': t.rating,
          'userRatingCount': t.reviewCount,
          'lat': t.meetingLatitude,
          'lng': t.meetingLongitude,
        };
      }).toList();

      final result = await RecommendationService.recommendPlaces(
        candidates: candidates,
        context: 'similar',
        limit: 4,
        // Small tour pool — don't exclude previously seen, or once the user
        // has opened a few tour details the "You might also enjoy" row
        // empties out and the section disappears entirely.
        excludeSeen: false,
        weather: WeatherController.weather.value,
      );
      if (!mounted) return;
      if (result == null || result.recommendations.isEmpty) {
        setState(() => _loadingSimilar = false);
        return;
      }
      final idToTour = {for (final t in siblings) t.id: t};
      final ordered = result.recommendations
          .map((r) => idToTour[r.placeId])
          .whereType<TourEntity>()
          .toList();
      setState(() {
        _similarTours = ordered;
        _loadingSimilar = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  @override
  void dispose() {
    _meetingMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            actions: [
              // Hide report button if the user is the guide who created the tour
              if (FirebaseAuth.instance.currentUser?.uid != tour.guideId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') {
                      UniversalReportDialog.show(
                        context,
                        reportType: ReportType.tour,
                        reportedItemId: tour.id,
                        reportedItemOwnerId: tour.guideId,
                        repository: GetIt.I<ReportsRepository>(),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(l10n.tourDetailReport),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tour.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
                  fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'],
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Hero(
                tag: 'tour_image_${tour.id}',
                child: tour.images.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ShimmerImage(
                            url: tour.images.first,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.image_not_supported,
                            fallbackBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          // Dark gradient overlay to ensure text visibility
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Price and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: CurrencyController.currency,
                        builder: (context, currency, _) {
                          return FutureBuilder<double>(
                            future: CurrencyService.instance.convertFromEGP(tour.price, currency),
                            builder: (context, snap) {
                              final label = snap.hasData
                                  ? CurrencyService.format(snap.data!, currency)
                                  : snap.hasError
                                      ? 'EGP ${tour.price.toStringAsFixed(0)} ΓÜá'
                                      : 'EGP ${tour.price.toStringAsFixed(0)}';
                              return Text(
                                label,
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 24.r),
                          SizedBox(width: 4.w),
                          Text(
                            tour.rating > 0 && !tour.rating.isNaN && !tour.rating.isInfinite
                              ? '${tour.rating.toStringAsFixed(1)} (${tour.reviewCount})'
                              : l10n.tourDetailNew,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Metadata Grid
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.calendar_month, l10n.tourDetailDateTime, DateFormat('MMM d, yyyy - h:mm a').format(tour.meetingTime)),
                        Divider(height: 24.h),
                        _buildInfoRow(context, Icons.people, l10n.createFieldMaxAttendees, l10n.tourDetailPeople(tour.maxAttendees)),
                        Divider(height: 24.h),
                        _buildInfoRow(context, Icons.location_on, l10n.tourDetailLocation, tour.meetingLocationName),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  Text(l10n.tourDetailAbout, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text(
                    tour.description,
                    style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
                  ),

                  SizedBox(height: 24.h),
                  Text(l10n.tourDetailDestinations, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: tour.destinations.map((dest) => Chip(
                      label: Text(dest),
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    )).toList(),
                  ),

                  // Map Preview
                  SizedBox(height: 24.h),
                  Text(l10n.tourDetailMeetupRoute, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(tour.meetingLatitude, tour.meetingLongitude),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('meeting_point'),
                              position: LatLng(tour.meetingLatitude, tour.meetingLongitude),
                              infoWindow: InfoWindow(title: tour.meetingLocationName, snippet: l10n.tourMapMeetingPoint),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          style: _mapStyle,
                          onMapCreated: (controller) {
                            _meetingMapController = controller;
                          },
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FullScreenTourMapScreen(tour: tour)),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, size: 20.r),
                                SizedBox(width: 4.w),
                                Text(l10n.tourDetailTapExpand, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Schedule Display
                  SizedBox(height: 24.h),
                  Text(l10n.tourDetailSchedule, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  _buildScheduleRow(context, tour.frequency),

                  // Image Gallery
                  if (tour.images.length > 1) ...[
                    SizedBox(height: 24.h),
                    Text(l10n.tourDetailGallery, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 140.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tour.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsetsDirectional.only(end: 12.w),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              clipBehavior: Clip.hardEdge,
                              child: InkWell(
                                onTap: () => _showGalleryViewer(context, tour.images, index),
                                child: Ink.image(
                                  image: CachedNetworkImageProvider(tour.images[index]),
                                  width: 160.w,
                                  height: 140.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),
                  Text(l10n.tourDetailYourGuide, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  _GuideInfoTile(guideId: tour.guideId),

                  SizedBox(height: 32.h),
                  const Divider(),
                  SizedBox(height: 16.h),
                  _ReviewsSection(tour: tour),

                  // ── You might also enjoy ─────────────────────────────────
                  if (_loadingSimilar || _similarTours.isNotEmpty) ...[
                    SizedBox(height: 32.h),
                    const Divider(),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 18.r, color: theme.colorScheme.primary),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.tourDetailYouMightEnjoy,
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 180.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _loadingSimilar ? 3 : _similarTours.length,
                        itemBuilder: (_, i) {
                          if (_loadingSimilar) {
                            return Padding(
                              padding: EdgeInsetsDirectional.only(end: 12.w),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: ShimmerLoadingWidget.rectangular(
                                    width: 220.w, height: 180.h),
                              ),
                            );
                          }
                          return Padding(
                            padding: EdgeInsetsDirectional.only(end: 12.w),
                            child: _SimilarTourCard(tour: _similarTours[i]),
                          );
                        },
                      ),
                    ),
                  ],

                  SizedBox(height: 100.h), // padding for bottom bar
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        ),
        child: FirebaseAuth.instance.currentUser?.uid == tour.guideId
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50.h),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                onPressed: null,
                child: Text(l10n.tourDetailYourTour, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50.h),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => BookingConfirmationScreen(tour: tour)),
                   );
                },
                child: Text(l10n.tourDetailBookNow, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // Weekday values stay English (parsed from `frequency`); only display localized.
  String _weekdayLabel(AppLocalizations l10n, String day) {
    switch (day) {
      case 'Mon':
        return l10n.weekdayMon;
      case 'Tue':
        return l10n.weekdayTue;
      case 'Wed':
        return l10n.weekdayWed;
      case 'Thu':
        return l10n.weekdayThu;
      case 'Fri':
        return l10n.weekdayFri;
      case 'Sat':
        return l10n.weekdaySat;
      case 'Sun':
        return l10n.weekdaySun;
      default:
        return day;
    }
  }

  Widget _buildScheduleRow(BuildContext context, String frequency) {
    final l10n = AppLocalizations.of(context);
    if (frequency == 'One-Time') {
      return Text(l10n.tourDetailOneTime, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)));
    }

    final days = frequency.split(', ');
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: allDays.map((day) {
        final isSelected = days.contains(day);
        return Chip(
          label: Text(_weekdayLabel(l10n, day)),
          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void _showGalleryViewer(BuildContext context, List<String> images, int initialIndex) {
  showDialog(
    context: context,
    builder: (_) => _GalleryViewerDialog(images: images, initialIndex: initialIndex),
  );
}

class _GalleryViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryViewerDialog({required this.images, required this.initialIndex});

  @override
  State<_GalleryViewerDialog> createState() => _GalleryViewerDialogState();
}

class _GalleryViewerDialogState extends State<_GalleryViewerDialog> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 40.h,
            right: 20.w,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 32.r),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Image counter
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.images.length}',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideInfoTile extends StatefulWidget {
  final String guideId;
  const _GuideInfoTile({required this.guideId});

  @override
  State<_GuideInfoTile> createState() => _GuideInfoTileState();
}

class _GuideInfoTileState extends State<_GuideInfoTile> {
  UserModel? _guide;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchGuide();
  }

  Future<void> _fetchGuide() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.guideId).get();
      if (doc.exists && mounted) {
        setState(() {
          _guide = UserModel.fromMap(doc.data()!, doc.id);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_guide == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.person),
        ),
        title: Text(l10n.tourDetailGuideNotFound),
      );
    }
    final guide = _guide!;
    final displayName = '${guide.firstName} ${guide.lastName}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ShimmerAvatar(
        url: guide.profileImageUrl,
        radius: 24.r,
        fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
      title: Text(displayName.isNotEmpty ? displayName : l10n.tourDetailYourGuide, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: guide.reviewCount > 0
          ? Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 14.r),
                SizedBox(width: 2.w),
                Text(l10n.tourDetailGuideRating(guide.rating.toStringAsFixed(1), guide.reviewCount), style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            )
          : Text(l10n.profileRoleVerifiedGuide, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: guide)),
        );
      },
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  final TourEntity tour;

  const _ReviewsSection({required this.tour});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  static const int _reviewPageSize = 3;
  int _reviewLimit = _reviewPageSize;

  TourEntity get tour => widget.tour;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.tourDetailReviews, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            if (currentUid != null && currentUid != tour.guideId)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('tourId', isEqualTo: tour.id)
                    .where('userId', isEqualTo: currentUid)
                    .where('status', isEqualTo: 'confirmed')
                    .get(),
                builder: (context, snapshot) {
                  final hasBooked = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  if (!hasBooked) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _showAddReviewDialog(context, tour.id),
                    icon: Icon(Icons.rate_review, size: 18.r),
                    label: Text(l10n.tourDetailWriteReview),
                  );
                },
              ),
          ],
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('tourId', isEqualTo: tour.id)
              .orderBy('createdAt', descending: true)
              .limit(_reviewLimit)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(l10n.tourDetailReviewsError);
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(l10n.tourDetailNoReviews, style: const TextStyle(fontStyle: FontStyle.italic)),
                ),
              );
            }

            final hasMore = docs.length == _reviewLimit;

            return Column(
              children: [
                ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                final reviewDoc = docs[index];
                final data = reviewDoc.data() as Map<String, dynamic>;
                final rating = (data['rating'] ?? 0.0).toDouble();
                final text = data['text'] ?? '';
                final userName = data['userName'] ?? l10n.tourDetailAnonymous;
                final userId = data['userId'] as String?;
                final userImage = data['userImage'] as String?;
                final isOwnReview = userId == currentUid;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _navigateToReviewerProfile(context, userId),
                        child: ShimmerAvatar(
                          url: userImage,
                          radius: 20.r,
                          iconSize: 20.r,
                          fallbackBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Review Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _navigateToReviewerProfile(context, userId),
                                    child: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating ? Icons.star : Icons.star_border,
                                      size: 14.r,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                SizedBox(width: 4.w),
                                // Action menu
                                _buildReviewActionMenu(context, reviewDoc.id, data, isOwnReview),
                              ],
                            ),
                            if (text.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14.sp)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
                ),
                if (hasMore)
                  TextButton.icon(
                    onPressed: () => setState(() => _reviewLimit += _reviewPageSize),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(l10n.tourDetailShowMore),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewActionMenu(BuildContext context, String reviewDocId, Map<String, dynamic> data, bool isOwnReview) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18.r, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditReviewDialog(context, tour.id, reviewDocId, data);
            break;
          case 'delete':
            _showDeleteReviewConfirmation(context, tour.id, reviewDocId, data);
            break;
          case 'report':
            UniversalReportDialog.show(
              context,
              reportType: ReportType.comment,
              reportedItemId: '${tour.id}_$reviewDocId',
              repository: GetIt.I<ReportsRepository>(),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        if (isOwnReview) ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [Icon(Icons.edit, size: 18.r), SizedBox(width: 8.w), Text(l10n.tourDetailEditReview)]),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [Icon(Icons.delete, size: 18.r, color: Colors.red), SizedBox(width: 8.w), Text(l10n.tourDetailDeleteReview, style: const TextStyle(color: Colors.red))]),
          ),
        ],
        if (!isOwnReview)
          PopupMenuItem(
            value: 'report',
            child: Row(children: [Icon(Icons.flag, size: 18.r, color: Colors.orange), SizedBox(width: 8.w), Text(l10n.tourDetailReportReview)]),
          ),
      ],
    );
  }

  void _navigateToReviewerProfile(BuildContext context, String? userId) async {
    if (userId == null) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (context.mounted) Navigator.pop(context);
      if (doc.exists && context.mounted) {
        final u = UserModel.fromMap(doc.data()!, doc.id);
        if (u.id == currentUid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: u)));
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showEditReviewDialog(BuildContext context, String tourId, String reviewDocId, Map<String, dynamic> oldData) {
    final l10n = AppLocalizations.of(context);
    double selectedRating = (oldData['rating'] ?? 5.0).toDouble();
    final textController = TextEditingController(text: oldData['text'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.tourDetailEditReview),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                         icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32.r,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.tourDetailUpdateHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    try {
                      Navigator.pop(context);
                      final oldRating = (oldData['rating'] ?? 0.0).toDouble();
                      final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final tourDoc = await transaction.get(tourRef);
                        if (!tourDoc.exists) return;

                        final tData = tourDoc.data()!;
                        final int count = (tData['reviewCount'] ?? 0) as int;
                        double currentAvg = (tData['rating'] ?? 0.0).toDouble();
                        if (currentAvg.isNaN || currentAvg.isInfinite) currentAvg = 0.0;

                        // Recalculate: remove old rating contribution, add new
                        double newAvg = count > 0 ? ((currentAvg * count) - oldRating + selectedRating) / count : selectedRating;
                        if (newAvg.isNaN || newAvg.isInfinite) newAvg = selectedRating;

                        transaction.update(
                            FirebaseFirestore.instance.collection('reviews').doc(reviewDocId), {
                          'rating': selectedRating,
                          'comment': textController.text.trim(),
                          'text': textController.text.trim(),
                        });

                        transaction.update(tourRef, {'rating': newAvg});
                      });
                    } catch (e) {
                      debugPrint('Error editing review: $e');
                    }
                  },
                  child: Text(l10n.tourDetailUpdate),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteReviewConfirmation(BuildContext context, String tourId, String reviewDocId, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.tourDetailDeleteReview),
          content: Text(l10n.tourDetailDeleteReviewBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  final oldRating = (data['rating'] ?? 0.0).toDouble();
                  final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);

                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final tourDoc = await transaction.get(tourRef);
                    if (!tourDoc.exists) return;

                    final tData = tourDoc.data()!;
                    final int count = (tData['reviewCount'] ?? 0) as int;
                    double currentAvg = (tData['rating'] ?? 0.0).toDouble();
                    if (currentAvg.isNaN || currentAvg.isInfinite) currentAvg = 0.0;

                    final newCount = count - 1;
                    double newAvg = newCount > 0 ? ((currentAvg * count) - oldRating) / newCount : 0.0;
                    if (newAvg.isNaN || newAvg.isInfinite) newAvg = 0.0;

                    transaction.delete(
                        FirebaseFirestore.instance.collection('reviews').doc(reviewDocId));
                    transaction.update(tourRef, {
                      'reviewCount': newCount,
                      'rating': newAvg,
                    });
                  });
                } catch (e) {
                  debugPrint('Error deleting review: $e');
                }
              },
              child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog(BuildContext context, String tourId) {
    final l10n = AppLocalizations.of(context);
    double selectedRating = 5.0;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.tourDetailWriteReview),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32.r,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.tourDetailShareHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    try {
                      Navigator.pop(context);

                      // Fetch real name from Firestore
                      String userName = 'Traveler';
                      String userImage = user.photoURL ?? '';
                      try {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users').doc(user.uid).get();
                        if (userDoc.exists) {
                          final d = userDoc.data()!;
                          final full = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
                          userName = full.isNotEmpty ? full : (d['username'] ?? 'Traveler');
                          userImage = d['profileImageUrl'] ?? userImage;
                        }
                      } catch (_) {}

                      // Get guideId from tour
                      final tourDoc = await FirebaseFirestore.instance
                          .collection('tours').doc(tourId).get();
                      final guideId = tourDoc.data()?['guideId'] as String? ?? '';

                      await ReviewsDataSourceImpl().submitReview(ReviewModel(
                        id: const Uuid().v4(),
                        tourId: tourId,
                        guideId: guideId,
                        touristId: user.uid,
                        rating: selectedRating,
                        comment: textController.text.trim(),
                        createdAt: DateTime.now(),
                        userName: userName,
                        userImage: userImage,
                      ));
                      final reviewSignal = selectedRating >= 4 ? 'visit' : selectedRating <= 2 ? 'dismiss' : null;
                      if (reviewSignal != null) {
                        final inferred = RecommendationMappings.inferKeysFromText(
                          '${widget.tour.title} ${widget.tour.destinations.join(' ')} ${widget.tour.description}',
                        );
                        RecommendationService.recordSignal(
                          placeId: tourId,
                          placeName: widget.tour.title,
                          types: inferred['types']!,
                          tags: inferred['tags']!,
                          signalType: reviewSignal,
                          source: 'review',
                        );
                      }
                    } catch (e) {
                      debugPrint('Error adding review: $e');
                    }
                  },
                  child: Text(l10n.tourDetailSubmit),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Compact card for the "You might also enjoy" row at the bottom of the
// tour detail screen. Smaller and simpler than TourCard — image + title +
// rating only. Pushes a fresh TourDetailScreen on tap.

class _SimilarTourCard extends StatelessWidget {
  final TourEntity tour;
  const _SimilarTourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
      ),
      child: Container(
        width: 220.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShimmerImage(
              url: tour.images.isNotEmpty ? tour.images.first : null,
              fit: BoxFit.cover,
              fallbackIcon: Icons.tour,
              fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              fallbackIconColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              fallbackIconSize: 36.r,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            if (tour.rating > 0)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12.r, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        tour.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 10.h,
              left: 10.w,
              right: 10.w,
              child: Text(
                tour.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                  height: 1.2,
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
}
