import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/community_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/data/models/user.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../../account/presentation/account_screen.dart';
import '../../../../../core/widgets/shimmer_avatar.dart';
import '../../../../../core/widgets/shimmer_image.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import '../../map/data/datasources/map_focus_service.dart';
import '../../home/data/models/map_item_models.dart';
import '../../map/data/places_api_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/utils/snack_bar_utils.dart';
import '../../../../../core/services/recommendation_service.dart';
import '../../home/presentation/event_details_screen.dart';
import '../../../../../core/services/recommendation_mappings.dart';

// Available emoji reactions
const List<String> _kReactions = ['❤️', '😮', '😄', '🔥', '👏'];

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;
  final bool isDetail;
  final bool isCurrentUserAdmin;
  /// Pass the live flag for the current user's own posts to override stale stored value.
  final String? currentUserFlag;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onCommentTap,
    this.onTap,
    this.isDetail = false,
    this.isCurrentUserAdmin = false,
    this.currentUserFlag,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  int _currentImageIndex = 0;
  bool _isExpanded = false;
  final FirebaseCommunityRepository _repo = FirebaseCommunityRepository();

  // ─── DELETE ───────────────────────────────────────────────────────────────

  void _deletePost() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final onSurface = theme.colorScheme.onSurface;
        final surface = theme.colorScheme.surface;
        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          title: Text("Delete Post", style: TextStyle(color: onSurface)),
          content: Text("Are you sure? This cannot be undone.",
              style: TextStyle(color: onSurface.withValues(alpha: 0.8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.deletePost(widget.post.id);
                  if (widget.isDetail && mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) showErrorSnackBarFromException(context, e);
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ─── PROFILE NAV ──────────────────────────────────────────────────────────

  Future<void> _navigateToProfile([String? userId]) async {
    final targetId = userId ?? widget.post.userId;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(targetId).get();
      if (!mounted) return;
      Navigator.pop(context);
      if (doc.exists) {
        final profileUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (profileUser.id == FirebaseAuth.instance.currentUser?.uid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: profileUser)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorSnackBarFromException(context, e);
    }
  }

  // ─── EDIT ─────────────────────────────────────────────────────────────────

  void _editPost() {
    final ctrl = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final onSurface = theme.colorScheme.onSurface;
        final surface = theme.colorScheme.surface;
        final primary = theme.colorScheme.primary;
        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          title: Text("Edit Post", style: TextStyle(color: onSurface)),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  try {
                    await _repo.editPost(widget.post.id, ctrl.text.trim());
                  } catch (e) {
                    if (mounted) showErrorSnackBarFromException(context, e);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text("Save", style: TextStyle(color: primary)),
            ),
          ],
        );
      },
    );
  }

  // ─── REPORT ───────────────────────────────────────────────────────────────

  void _reportPost() {
    UniversalReportDialog.show(
      context,
      reportType: ReportType.post,
      reportedItemId: widget.post.id,
      reportedItemOwnerId: widget.post.userId,
      repository: GetIt.I<ReportsRepository>(),
    );
  }

  // ─── SHARE ────────────────────────────────────────────────────────────────

  void _sharePost() {
    final handle = widget.post.userUsername.isNotEmpty
        ? '@${widget.post.userUsername}'
        : widget.post.userName;
    final snippet = widget.post.content.length > 120
        ? '${widget.post.content.substring(0, 120)}…'
        : widget.post.content;
    Share.share('$handle on Lost in Egypt:\n\n"$snippet"');
  }

  // ─── REACTION PICKER ──────────────────────────────────────────────────────

  void _showReactionPicker(Color surface, Color onSurface) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('React to post', style: TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'], fontSize: 15.sp, color: onSurface)),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _kReactions.map((emoji) {
                  final isSelected = widget.post.myReaction == emoji;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _repo.reactToPost(widget.post.id, emoji);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD6A00F).withValues(alpha: 0.18)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: const Color(0xFFD6A00F), width: 1.5)
                            : null,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
                    ),
                  );
                }).toList(),
              ),
              if (widget.post.myReaction != null) ...[
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _repo.reactToPost(widget.post.id, widget.post.myReaction!);
                  },
                  child: Text('Remove reaction', style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 13.sp)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── RICH TEXT (mentions + hashtags) ──────────────────────────────────────

  Widget _buildRichContent(String content, Color onSurface, Color primary) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(@\w+|#\w+)');
    int last = 0;
    final baseStyle = TextStyle(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 15.sp,
      fontFamily: 'Mako',
      height: 1.4,
    );
    final highlightStyle = baseStyle.copyWith(color: primary, fontWeight: FontWeight.w800);

    for (final match in regex.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start), style: baseStyle));
      }
      final token = match.group(0)!;
      if (token.startsWith('@')) {
        final username = token.substring(1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _navigateToProfileByUsername(username),
            child: Text(token, style: highlightStyle),
          ),
        ));
      } else {
        // Hashtag — tap to search
        spans.add(TextSpan(text: token, style: highlightStyle));
      }
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last), style: baseStyle));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _navigateToProfileByUsername(String username) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      if (!mounted) return;
      Navigator.pop(context);
      if (snap.exists) {
        final uid = snap.data()?['uid'] as String?;
        if (uid != null) _navigateToProfile(uid);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // ─── POST CONTENT ─────────────────────────────────────────────────────────

  Widget _buildPostContent(Color onSurface, Color primary) {
    const int threshold = 120;
    final content = widget.post.content;
    final needsTruncation = !widget.isDetail && content.length > threshold;

    if (!needsTruncation) return _buildRichContent(content, onSurface, primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRichContent(
          _isExpanded ? content : '${content.substring(0, threshold)}...',
          onSurface,
          primary,
        ),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? 'Show less' : 'Read more',
            style: TextStyle(color: primary, fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ─── REACTIONS DISPLAY ────────────────────────────────────────────────────

  Widget _buildReactionsRow(Color primary, Color onSurface) {
    if (widget.post.reactionCounts.isEmpty) return const SizedBox.shrink();
    final sorted = widget.post.reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Wrap(
        spacing: 6.w,
        children: top.map((entry) {
          final isMyReaction = widget.post.myReaction == entry.key;
          return GestureDetector(
            onTap: () => _repo.reactToPost(widget.post.id, entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isMyReaction
                    ? primary.withValues(alpha: 0.15)
                    : onSurface.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20.r),
                border: isMyReaction
                    ? Border.all(color: primary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: TextStyle(fontSize: 13.sp)),
                  SizedBox(width: 4.w),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isMyReaction ? primary : onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── MAP FALLBACK ─────────────────────────────────────────────────────────

  PlaceModel _fallbackPlace(double lat, double lng) => PlaceModel(
        id: widget.post.locationId ?? widget.post.locationName!,
        title: widget.post.locationName!,
        coordinate: GeoPoint(lat, lng),
        category: 'place',
        imagePath: '',
        locationAddress: widget.post.locationName!,
        rating: 0,
        price: 0,
        duration: '',
        weather: '',
        description: '',
      );

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final cardShadow = BoxShadow(
      color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.14),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    );
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isOwner = widget.post.userId.isNotEmpty && (widget.post.userId == currentUid);
    final String displayFlag = widget.currentUserFlag ?? widget.post.userFlag;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: widget.post.isPinned
                  ? const Color(0xFFD6A00F).withValues(alpha: 0.4)
                  : borderColor,
              width: widget.post.isPinned ? 1.5 : 1.0,
            ),
            boxShadow: [cardShadow],
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tourist tip banner ───────────────────────────────────
                if (widget.post.category == 'tips')
                  Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6A00F).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFD6A00F).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💡', style: TextStyle(fontSize: 12.sp)),
                        SizedBox(width: 6.w),
                        Text(
                          "Traveler's Tip",
                          style: TextStyle(
                            color: const Color(0xFFD6A00F),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Header ───────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(),
                      child: ShimmerAvatar(
                        url: widget.post.userAvatar,
                        radius: 17.r,
                        iconSize: 20.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => _navigateToProfile(),
                                  child: Text(
                                    widget.post.userName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurface, fontWeight: FontWeight.w800, fontSize: 14.sp),
                                  ),
                                ),
                              ),
                              // Verified guide badge
                              if (widget.post.isVerifiedGuide) ...[
                                SizedBox(width: 4.w),
                                Icon(Icons.verified, color: primary, size: 14.r),
                              ],
                              // Admin badge
                              if (widget.post.isAdmin) ...[
                                SizedBox(width: 4.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6A00F).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: const Color(0xFFD6A00F).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_rounded, color: const Color(0xFFD6A00F), size: 10.r),
                                      SizedBox(width: 2.w),
                                      Text('Admin', style: TextStyle(color: const Color(0xFFD6A00F), fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                    ],
                                  ),
                                ),
                              ],
                              SizedBox(width: 6.w),
                              Text(displayFlag, style: TextStyle(fontSize: 13.sp)),
                            ],
                          ),
                          if (widget.post.userUsername.isNotEmpty) ...[
                            SizedBox(height: 1.h),
                            Text('@${widget.post.userUsername}',
                                style: TextStyle(color: primary, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                          ],
                          SizedBox(height: 2.h),
                          Text(widget.post.timeAgo,
                              style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 12.sp)),
                        ],
                      ),
                    ),

                    // ── More menu ──────────────────────────────────────
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded, color: onSurface.withValues(alpha: 0.6)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          backgroundColor: surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) {
                            final t = Theme.of(ctx);
                            final s = t.colorScheme.surface;
                            final o = t.colorScheme.onSurface;
                            return SafeArea(
                              child: Container(
                                color: s,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isOwner) ...[
                                      ListTile(
                                        leading: Icon(Icons.edit, color: o.withValues(alpha: 0.8)),
                                        title: Text("Edit Post", style: TextStyle(color: o)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          Future.delayed(const Duration(milliseconds: 100), _editPost);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Colors.red),
                                        title: const Text("Delete Post", style: TextStyle(color: Colors.red)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          Future.delayed(const Duration(milliseconds: 100), _deletePost);
                                        },
                                      ),
                                    ],
                                    // Admin pin/unpin
                                    if (widget.isCurrentUserAdmin) ...[
                                      ListTile(
                                        leading: Icon(
                                          widget.post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                          color: const Color(0xFFD6A00F),
                                        ),
                                        title: Text(
                                          widget.post.isPinned ? 'Unpin Post' : 'Pin Post',
                                          style: const TextStyle(color: Color(0xFFD6A00F)),
                                        ),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _repo.pinPost(widget.post.id, pin: !widget.post.isPinned);
                                        },
                                      ),
                                    ],
                                    if (!isOwner)
                                      ListTile(
                                        leading: const Icon(Icons.flag, color: Colors.orange),
                                        title: Text("Report Post", style: TextStyle(color: o)),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _reportPost();
                                        },
                                      ),
                                    SizedBox(height: 10.h),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // ── Content area ─────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostContent(onSurface, primary),

                    // Location tag
                    if (widget.post.locationName != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: GestureDetector(
                          onTap: () async {
                            final lat = widget.post.locationLat;
                            final lng = widget.post.locationLng;
                            if (lat == null || lng == null) return;
                            final locationId = widget.post.locationId ?? '';
                            PlaceModel item;
                            if (locationId.isNotEmpty) {
                              if (!mounted) return;
                              final nav = Navigator.of(context);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                final svc = GetIt.I<PlacesApiService>();
                                final details = await svc.getPlaceDetails(locationId);
                                nav.pop();
                                item = details != null
                                    ? PlaceModel.fromPlacesApi(details, svc.apiKey)
                                    : _fallbackPlace(lat, lng);
                              } catch (_) {
                                nav.pop();
                                item = _fallbackPlace(lat, lng);
                              }
                            } else {
                              item = _fallbackPlace(lat, lng);
                            }
                            MapFocusService.instance.triggerFocus(item);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: primary.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 14.r, color: primary),
                                SizedBox(width: 4.w),
                                Text(widget.post.locationName!,
                                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                                if (widget.post.locationLat != null) ...[
                                  SizedBox(width: 4.w),
                                  Icon(Icons.open_in_new_rounded, size: 11.r, color: primary.withValues(alpha: 0.7)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Tagged Event chip ─────────────────────────────────
                    if (widget.post.taggedEventId != null &&
                        widget.post.taggedEventName != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: GestureDetector(
                          onTap: () async {
                            final eventId = widget.post.taggedEventId!;
                            if (!mounted) return;
                            final nav = Navigator.of(context);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventId)
                                  .get();
                              nav.pop();
                              if (doc.exists && mounted) {
                                final event = EventModel.fromMap(
                                    doc.data() as Map<String, dynamic>, doc.id);
                                nav.push(MaterialPageRoute(
                                  builder: (_) => EventDetailsScreen(event: event),
                                ));
                              }
                            } catch (_) {
                              nav.pop();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withValues(alpha: 0.18),
                                  primary.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.35), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_rounded,
                                    size: 14.r, color: primary),
                                SizedBox(width: 5.w),
                                Text(
                                  widget.post.taggedEventName!,
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 10.r,
                                    color: primary.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Images
                    if (widget.post.images.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: widget.isDetail ? 600.h : 400.h),
                              child: PageView.builder(
                                itemCount: widget.post.images.length,
                                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                                itemBuilder: (_, i) => ShimmerImage(
                                  url: widget.post.images[i],
                                  fit: BoxFit.fitWidth,
                                  height: widget.isDetail ? 600.h : 400.h,
                                ),
                              ),
                            ),
                          ),
                          if (widget.post.images.length > 1)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(widget.post.images.length, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                                    height: 6.h,
                                    width: _currentImageIndex == i ? 12.w : 6.w,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == i ? primary : onSurface.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // Reactions display
                    _buildReactionsRow(primary, onSurface),
                  ],
                ),

                SizedBox(height: 10.h),

                // ── Actions row ──────────────────────────────────────────
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: widget.post.isLikedByMe ? Icons.favorite : Icons.favorite_border_rounded,
                      value: widget.post.likes,
                      color: widget.post.isLikedByMe ? Colors.red.shade400 : onSurface.withValues(alpha: 0.65),
                      onTap: () {
                        if (!widget.post.isLikedByMe && widget.post.locationId != null) {
                          final inferred = RecommendationMappings.inferKeysFromText(
                            widget.post.locationName ?? '',
                          );
                          RecommendationService.recordSignal(
                            placeId: widget.post.locationId!,
                            placeName: widget.post.locationName ?? '',
                            types: inferred['types']!,
                            tags: inferred['tags']!,
                            signalType: 'like',
                            source: 'community',
                          );
                        }
                        _repo.togglePostLike(widget.post.id, true);
                      },
                    ),
                    SizedBox(width: 12.w),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      value: widget.post.comments,
                      color: onSurface.withValues(alpha: 0.65),
                      onTap: widget.onCommentTap,
                    ),
                    SizedBox(width: 12.w),
                    // Emoji react button
                    GestureDetector(
                      onTap: () => _showReactionPicker(surface, onSurface),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: widget.post.myReaction != null
                              ? primary.withValues(alpha: 0.12)
                              : onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20.r),
                          border: widget.post.myReaction != null
                              ? Border.all(color: primary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.post.myReaction ?? '😊',
                              style: TextStyle(fontSize: 15.sp),
                            ),
                            SizedBox(width: 3.w),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 13.r,
                              color: widget.post.myReaction != null
                                  ? primary
                                  : onSurface.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Share
                    InkWell(
                      onTap: _sharePost,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                        child: Icon(Icons.ios_share_rounded, size: 19.r, color: onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Bookmark
                    InkWell(
                      onTap: () => _repo.toggleSavePost(widget.post.id, widget.post.isSavedByMe),
                      child: Icon(
                        widget.post.isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
                        color: widget.post.isSavedByMe ? primary : onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Pin indicator (top-right corner)
        if (widget.post.isPinned)
          Positioned(
            top: -6.h,
            right: 14.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A00F),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [BoxShadow(color: const Color(0xFFD6A00F).withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded, size: 10.r, color: Colors.white),
                  SizedBox(width: 3.w),
                  Text('Pinned', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
          child: Row(
            children: [
              Icon(icon, size: 20.r, color: color),
              SizedBox(width: 6.w),
              Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
