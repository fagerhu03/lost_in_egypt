import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/map_item_models.dart';
import '../data/models/event_review_model.dart';
import '../data/datasources/event_reviews_service.dart';
import 'widgets/add_event_review_sheet.dart';
import '../../community/data/community_post_action_service.dart';
import '../../../../../theme/theme.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:timezone/timezone.dart' as tz;

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isToggling = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.easeInOut,
    ));
    _loadLikeState();
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    setState(() {
      _isLiked = likedBy.contains(uid);
      _likeCount = likedBy.length;
    });
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isToggling) return;

    _isToggling = true;
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.event.id);

    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });

    if (!wasLiked) {
      _heartAnimController.forward(from: 0);
    }

    try {
      await eventRef.update({
        'likedBy': wasLiked
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
      debugPrint('Failed to toggle like: $e');
    }

    _isToggling = false;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkNavBar : theme.colorScheme.primary;
    final bg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = textColor.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image — takes its natural aspect ratio ──
                _buildHeroImage(bg),

                // ── Content ──
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with like pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.title,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          _buildLikePill(isDark, secondaryTextColor),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Venue subtitle
                      if (widget.event.venueName.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_city,
                                size: 16.r, color: primary),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                widget.event.venueName,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 12.h),
                      
                      // Live Rating Row
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('events').doc(widget.event.id).snapshots(),
                        builder: (context, snapshot) {
                          double rating = widget.event.rating;
                          int reviewCount = widget.event.reviewCount;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            rating = (data['rating'] ?? 0.0).toDouble();
                            reviewCount = (data['reviewCount'] ?? 0).toInt();
                          }
                          
                          if (reviewCount == 0 && rating == 0) {
                             return const SizedBox.shrink();
                          }
                          
                          return Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 20.r),
                              SizedBox(width: 6.w),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "($reviewCount reviews)",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // ── Date & Time Card (full width) ──
                      _buildSectionCard(
                        isDark: isDark,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Icon(Icons.calendar_today,
                                  color: primary, size: 24.r),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DATE & TIME",
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  (() {
                                    final cairoTime = tz.TZDateTime.from(widget.event.date, tz.getLocation('Africa/Cairo'));
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE, d MMMM yyyy').format(cairoTime),
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          "${DateFormat('hh:mm a').format(cairoTime)} (Cairo Time)",
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    );
                                  })(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // ── Location Card (full width, tappable) ──
                      GestureDetector(
                        onTap: () {
                          MapFocusService.instance
                              .triggerFocus(widget.event);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: _buildSectionCard(
                          isDark: isDark,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(Icons.location_on,
                                    color: primary, size: 24.r),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "LOCATION",
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      widget.event.locationAddress
                                              .isNotEmpty
                                          ? widget.event.locationAddress
                                          : (widget.event.venueName
                                                  .isNotEmpty
                                              ? widget.event.venueName
                                              : widget.event.city
                                                      .isNotEmpty
                                                  ? widget.event.city
                                                  : "Egypt"),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.event.city.isNotEmpty &&
                                        widget.event.locationAddress
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(top: 2.h),
                                        child: Text(
                                          widget.event.city,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_outlined,
                                        color: primary.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "Map",
                                      style: TextStyle(
                                        color: primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // ── Tags & Source row ──
                      if (widget.event.tags.isNotEmpty ||
                          widget.event.source.isNotEmpty)
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            // Category chip
                            if (widget.event.eventCategory.isNotEmpty)
                              _buildChip(
                                widget.event.eventCategory.toUpperCase(),
                                primary,
                              ),
                            // Source chip
                            if (widget.event.source.isNotEmpty &&
                                widget.event.source != 'curated')
                              _buildChip(
                                widget.event.source.toUpperCase(),
                                primary,
                              ),
                            // Other tags
                            ...widget.event.tags
                                .where((t) =>
                                    t != widget.event.eventCategory &&
                                    t != widget.event.source &&
                                    t != widget.event.city.toLowerCase())
                                .map((tag) =>
                                    _buildChip(tag.toUpperCase(), primary)),
                          ],
                        ),
                      if (widget.event.tags.isNotEmpty ||
                          widget.event.source.isNotEmpty)
                        SizedBox(height: 24.h),

                      // ── Divider ──
                      Divider(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                      ),
                      SizedBox(height: 16.h),

                      // ── Description ──
                      Text(
                        "About this Event",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        widget.event.description.isNotEmpty
                            ? widget.event.description
                            : "Join us for an unforgettable experience! This event brings together the best of culture, entertainment, and community in Egypt. Secure your tickets now and be part of something amazing.",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16.sp,
                          height: 1.6,
                        ),
                      ),

                      // ── Share row ──
                      SizedBox(height: 24.h),
                      Divider(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.share_outlined,
                              color: secondaryTextColor, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(
                            "Share this event",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (widget.event.ticketLink.isNotEmpty)
                            GestureDetector(
                              onTap: () =>
                                  _launchUrl(widget.event.ticketLink),
                              child: Row(
                                children: [
                                  Icon(Icons.open_in_new,
                                      color: primary, size: 18.r),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "View on ${widget.event.source.isNotEmpty ? widget.event.source[0].toUpperCase() + widget.event.source.substring(1) : 'Web'}",
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // ── Post to Community button ──
                      GestureDetector(
                        onTap: () {
                          CommunityPostActionService.instance.pendingPostContent.value =
                            "Anyone going to ${widget.event.title}? ✨";
                          CommunityPostActionService.instance.pendingEventId = widget.event.id;
                          CommunityPostActionService.instance.pendingEventName = widget.event.title;
                          MapFocusService.instance.tabSwitchNotifier.value = 1;
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.85),
                                primary,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_alt_rounded,
                                  color: Colors.white, size: 20.r),
                              SizedBox(width: 10.w),
                              Text(
                                "Post to Community",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white70, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // ── Reviews Section ──
                      _buildReviewsSection(isDark, primary, textColor, secondaryTextColor),
                      SizedBox(height: 120.h),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating back button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: 16.w,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, primary, bg, isDark),
    );
  }

  /// The image renders at its natural width-to-height ratio.
  /// A gradient at the bottom smoothly blends it into the page background.
  Widget _buildHeroImage(Color bg) {
    final imageWidget = widget.event.imagePath.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: widget.event.imagePath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            placeholder: (_, _) => Container(
              height: 300.h,
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              height: 300.h,
              color: Colors.grey.shade800,
              child: Center(
                child: Icon(Icons.event, color: Colors.white54, size: 64.r),
              ),
            ),
          )
        : Image.asset(
            widget.event.imagePath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, _, _) => Container(
              height: 300.h,
              color: Colors.grey.shade800,
              child: Center(
                child: Icon(Icons.event, color: Colors.white54, size: 64.r),
              ),
            ),
          );

    return Stack(
      children: [
        imageWidget,
        // Bottom fade into page background
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bg.withValues(alpha: 0.0),
                  bg,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLikePill(bool isDark, Color secondaryTextColor) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _isLiked
              ? Colors.red.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: _isLiked
                ? Colors.red.withValues(alpha: 0.25)
                : (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _heartScaleAnim,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.redAccent : secondaryTextColor,
                size: 22.r,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '$_likeCount',
              style: TextStyle(
                color: _isLiked ? Colors.redAccent : secondaryTextColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }

  Widget _buildChip(String label, Color primary) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, Color primary, Color bg, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price",
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.6),
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      widget.event.price > 0
                          ? "EGP ${widget.event.price.toStringAsFixed(0)}"
                          : "See Listing",
                      style: TextStyle(
                        color: primary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.event.ticketLink.isNotEmpty) {
                        _launchUrl(widget.event.ticketLink);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Tickets are not available online for this event.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.event.ticketLink.isNotEmpty
                          ? "Get Tickets"
                          : "RSVP Now",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark, Color primary, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Reviews",
              style: TextStyle(
                color: textColor,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
              ),
            ),
            TextButton.icon(
              onPressed: () => AddEventReviewSheet.show(context, widget.event),
              icon: Icon(Icons.add_comment, color: primary, size: 18.r),
              label: Text(
                "Write a Review",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        StreamBuilder<List<EventReviewModel>>(
          stream: EventReviewsService.getEventReviews(widget.event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text(
                    "No reviews yet. Be the first to review!",
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: reviews.length,
              separatorBuilder: (_, _) => Divider(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                height: 32.h,
              ),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor: primary.withValues(alpha: 0.2),
                          backgroundImage: review.userImage.isNotEmpty ? NetworkImage(review.userImage) : null,
                          child: review.userImage.isEmpty ? Icon(Icons.person, size: 20.r, color: primary) : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName.isNotEmpty ? review.userName : 'Explorer',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                DateFormat('MMM d, yyyy').format(review.createdAt),
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16.r,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        review.comment,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
