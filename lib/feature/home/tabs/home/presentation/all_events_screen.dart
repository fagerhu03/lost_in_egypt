import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/constants/event_categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/core/services/recommendation_mappings.dart';
import 'package:lost_in_egypt/core/widgets/app_error_widget.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/presentation/event_details_screen.dart';

class AllEventsScreen extends StatefulWidget {
  final List<EventModel> events;
  const AllEventsScreen({super.key, required this.events});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  int _limit = 10;
  static const int _pageSize = 10;

  // Loaded once on screen open. Used to rank events by personal taste; empty
  // map = unranked (chronological order falls through).
  Map<String, num> _tasteVector = {};

  @override
  void initState() {
    super.initState();
    _loadTasteVector();
  }

  Future<void> _loadTasteVector() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final raw = doc.data()?['tasteVector'];
      if (raw is Map) {
        final cast = <String, num>{};
        for (final e in raw.entries) {
          if (e.value is num) cast[e.key.toString()] = e.value as num;
        }
        setState(() => _tasteVector = cast);
      }
    } catch (_) {}
  }

  /// Dot-product score of the event's inferred canonical keys against the
  /// user's taste vector. Zero when vector is empty (no taste data yet).
  double _scoreEvent(EventModel e) {
    if (_tasteVector.isEmpty) return 0;
    final keys = RecommendationMappings.inferKeysFromText(
        '${e.title} ${e.description}');
    double score = 0;
    for (final k in keys['types']!) {
      score += (_tasteVector[k] ?? 0).toDouble();
    }
    for (final k in keys['tags']!) {
      score += (_tasteVector[k] ?? 0).toDouble();
    }
    return score;
  }

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('events')
      .orderBy('date', descending: false)
      .limit(_limit)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final bg = theme.scaffoldBackgroundColor;

    final shadow = BoxShadow(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Experiences',
          style: TextStyle(
            color: onSurface,
            fontFamily: 'Marcellus',
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        foregroundColor: onSurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          }
          if (snap.hasError) {
            return AppErrorWidget(
              message: 'Could not load events.\nCheck your connection and try again.',
              icon: Icons.event_busy_rounded,
              onRetry: () => setState(() {}),
            );
          }

          final rawDocs = snap.data?.docs ?? [];

          // Decode events once so we can both score and render without re-parsing
          final events = rawDocs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return EventModel.fromMap(data, d.id);
          }).toList();

          String? topPickId;
          if (_tasteVector.isNotEmpty && events.isNotEmpty) {
            final scored = events
                .map((e) => (event: e, score: _scoreEvent(e)))
                .toList()
              ..sort((a, b) => b.score.compareTo(a.score));
            events
              ..clear()
              ..addAll(scored.map((s) => s.event));
            if (scored.first.score > 0) topPickId = scored.first.event.id;
          }
          final docs = events;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 60, color: primary.withValues(alpha: 0.25)),
                  const SizedBox(height: 16),
                  Text(
                    'No events right now',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontFamily: 'Marcellus',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for upcoming events in Egypt.',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.35),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final hasMore = docs.length == _limit;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: docs.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == docs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _limit += _pageSize),
                      child: Text(
                        'Load more',
                        style: TextStyle(
                          color: primary,
                          fontFamily: 'Marcellus',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final event = docs[i];
              return _EventCard(
                event: event,
                isTopPick: event.id == topPickId,
                shadow: shadow,
                surface: surface,
                onSurface: onSurface,
                primary: primary,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final BoxShadow shadow;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final bool isDark;
  final bool isTopPick;

  const _EventCard({
    required this.event,
    required this.shadow,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.isDark,
    this.isTopPick = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryInfo = EventCategories.fromId(event.eventCategory);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [shadow],
        border: Border.all(
          color: isTopPick
              ? primary.withValues(alpha: 0.55)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          width: isTopPick ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(event: event),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with overlays
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 180.h,
                      width: double.infinity,
                      child: event.imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: event.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: onSurface.withValues(alpha: 0.06)),
                              errorWidget: (_, __, ___) =>
                                  _ImageError(primary: primary),
                            )
                          : event.imagePath.isNotEmpty
                              ? Image.asset(
                                  event.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _ImageError(primary: primary),
                                )
                              : _ImageError(primary: primary),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Top-left badges
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTopPick) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12.r, color: Colors.white),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Tailored pick',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Marcellus',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              categoryInfo.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location badge
                    if (event.venueName.isNotEmpty || event.city.isNotEmpty)
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 12.r, color: Colors.white),
                              SizedBox(width: 3.w),
                              Flexible(
                                child: Text(
                                  event.venueName.isNotEmpty ? event.venueName : event.city,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Recurring badge
                    if (event.isRecurring)
                      Positioned(
                        bottom: 10.h,
                        left: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 11.r, color: Colors.white),
                              SizedBox(width: 4.w),
                              Text(
                                event.recurrenceText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Marcellus',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    if (event.venueName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14.r,
                              color: onSurface.withValues(alpha: 0.5)),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              event.venueName,
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.55),
                                fontSize: 13.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 15.r),
                        SizedBox(width: 4.w),
                        Text(
                          event.rating.toStringAsFixed(1) + (event.reviewCount > 0 ? " (${event.reviewCount})" : ""),
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.7),
                            fontSize: 13.sp,
                          ),
                        ),
                        if (event.duration.isNotEmpty) ...[
                          SizedBox(width: 12.w),
                          Icon(Icons.access_time_outlined,
                              size: 14.r,
                              color: onSurface.withValues(alpha: 0.5)),
                          SizedBox(width: 4.w),
                          Text(
                            event.duration,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.55),
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                        if (event.price > 0) ...[
                          const Spacer(),
                          Text(
                            'EGP ${event.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final Color primary;
  const _ImageError({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: primary.withValues(alpha: 0.3), size: 40),
      ),
    );
  }
}
