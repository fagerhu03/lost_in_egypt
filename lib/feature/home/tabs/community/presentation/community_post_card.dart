import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/community_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/data/models/user.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../data/repositories/firebase_community_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../account/presentation/account_screen.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import '../../map/data/datasources/map_focus_service.dart';
import '../../home/data/models/map_item_models.dart';
import '../../map/data/places_api_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/utils/snack_bar_utils.dart';
import '../../../../../core/services/recommendation_service.dart';

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
              style: TextStyle(color: onSurface.withOpacity(0.8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: onSurface.withOpacity(0.7))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.deletePost(widget.post.id);
                  if (widget.isDetail && mounted) Navigator.pop(context);
                } catch (e) {
                  showErrorSnackBarFromException(context, e);
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
      if (mounted) Navigator.pop(context);
      if (doc.exists && mounted) {
        final profileUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (profileUser.id == FirebaseAuth.instance.currentUser?.uid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalProfileScreen(user: profileUser)));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
              child: Text("Cancel", style: TextStyle(color: onSurface.withOpacity(0.7))),
            ),
            TextButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  try {
                    await _repo.editPost(widget.post.id, ctrl.text.trim());
                  } catch (e) {
                    showErrorSnackBarFromException(context, e);
                  }
                }
                Navigator.pop(ctx);
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('React to post', style: TextStyle(fontFamily: 'Marcellus', fontSize: 15, color: onSurface)),
              const SizedBox(height: 16),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD6A00F).withOpacity(0.18)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: const Color(0xFFD6A00F), width: 1.5)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              if (widget.post.myReaction != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _repo.reactToPost(widget.post.id, widget.post.myReaction!);
                  },
                  child: Text('Remove reaction', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
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
      fontSize: 15,
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
      if (mounted) Navigator.pop(context);
      if (snap.exists && mounted) {
        final uid = snap.data()?['uid'] as String?;
        if (uid != null) _navigateToProfile(uid);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
            style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        children: top.map((entry) {
          final isMyReaction = widget.post.myReaction == entry.key;
          return GestureDetector(
            onTap: () => _repo.reactToPost(widget.post.id, entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isMyReaction
                    ? primary.withOpacity(0.15)
                    : onSurface.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: isMyReaction
                    ? Border.all(color: primary.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isMyReaction ? primary : onSurface.withOpacity(0.7),
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
      color: isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.14),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    );
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isOwner = widget.post.userId.isNotEmpty && (widget.post.userId == currentUid);
    final String displayFlag = widget.currentUserFlag ?? widget.post.userFlag;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.post.isPinned
                  ? const Color(0xFFD6A00F).withOpacity(0.4)
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
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6A00F).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD6A00F).withOpacity(0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💡', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 6),
                        Text(
                          "Traveler's Tip",
                          style: TextStyle(
                            color: Color(0xFFD6A00F),
                            fontSize: 11,
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
                      child: ClipOval(
                        child: widget.post.userAvatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.post.userAvatar,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                memCacheHeight: 150,
                                memCacheWidth: 150,
                                placeholder: (_, __) => Container(width: 34, height: 34, color: onSurface.withOpacity(0.08)),
                                errorWidget: (_, __, ___) => Container(
                                  width: 34, height: 34,
                                  color: onSurface.withOpacity(0.08),
                                  child: Icon(Icons.person, size: 20, color: primary),
                                ),
                              )
                            : Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(color: onSurface.withOpacity(0.08), shape: BoxShape.circle),
                                child: Icon(Icons.person, size: 20, color: primary),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                    style: TextStyle(color: onSurface, fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                ),
                              ),
                              // Verified guide badge
                              if (widget.post.isVerifiedGuide) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.verified, color: primary, size: 14),
                              ],
                              // Admin badge
                              if (widget.post.isAdmin) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6A00F).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFD6A00F).withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_rounded, color: Color(0xFFD6A00F), size: 10),
                                      SizedBox(width: 2),
                                      Text('Admin', style: TextStyle(color: Color(0xFFD6A00F), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(displayFlag, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          if (widget.post.userUsername.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text('@${widget.post.userUsername}',
                                style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                          const SizedBox(height: 2),
                          Text(widget.post.timeAgo,
                              style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 12)),
                        ],
                      ),
                    ),

                    // ── More menu ──────────────────────────────────────
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded, color: onSurface.withOpacity(0.6)),
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
                                        leading: Icon(Icons.edit, color: o.withOpacity(0.8)),
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
                                    const SizedBox(height: 10),
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

                const SizedBox(height: 10),

                // ── Content area ─────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostContent(onSurface, primary),

                    // Location tag
                    if (widget.post.locationName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withOpacity(0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 14, color: primary),
                                const SizedBox(width: 4),
                                Text(widget.post.locationName!,
                                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                if (widget.post.locationLat != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.open_in_new_rounded, size: 11, color: primary.withOpacity(0.7)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Images
                    if (widget.post.images.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: widget.isDetail ? 600 : 400),
                              child: PageView.builder(
                                itemCount: widget.post.images.length,
                                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                                itemBuilder: (_, i) => Image.network(
                                  widget.post.images[i],
                                  fit: BoxFit.fitWidth,
                                  errorBuilder: (c, e, s) => Container(height: 220, color: Colors.grey.shade200, child: const Icon(Icons.error)),
                                ),
                              ),
                            ),
                          ),
                          if (widget.post.images.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(widget.post.images.length, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 6,
                                    width: _currentImageIndex == i ? 12 : 6,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == i ? primary : onSurface.withOpacity(0.20),
                                      borderRadius: BorderRadius.circular(3),
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

                const SizedBox(height: 10),

                // ── Actions row ──────────────────────────────────────────
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: widget.post.isLikedByMe ? Icons.favorite : Icons.favorite_border_rounded,
                      value: widget.post.likes,
                      color: widget.post.isLikedByMe ? Colors.red.shade400 : onSurface.withOpacity(0.65),
                      onTap: () {
                        if (!widget.post.isLikedByMe && widget.post.locationId != null) {
                          RecommendationService.recordSignal(
                            placeId: widget.post.locationId!,
                            placeName: widget.post.locationName ?? '',
                            signalType: 'like',
                            source: 'community',
                          );
                        }
                        _repo.togglePostLike(widget.post.id, true);
                      },
                    ),
                    const SizedBox(width: 12),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      value: widget.post.comments,
                      color: onSurface.withOpacity(0.65),
                      onTap: widget.onCommentTap,
                    ),
                    const SizedBox(width: 12),
                    // Emoji react button
                    GestureDetector(
                      onTap: () => _showReactionPicker(surface, onSurface),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.post.myReaction != null
                              ? primary.withOpacity(0.12)
                              : onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: widget.post.myReaction != null
                              ? Border.all(color: primary.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.post.myReaction ?? '😊',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 13,
                              color: widget.post.myReaction != null
                                  ? primary
                                  : onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Share
                    InkWell(
                      onTap: _sharePost,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Icon(Icons.ios_share_rounded, size: 19, color: onSurface.withOpacity(0.6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bookmark
                    InkWell(
                      onTap: () => _repo.toggleSavePost(widget.post.id, widget.post.isSavedByMe),
                      child: Icon(
                        widget.post.isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
                        color: widget.post.isSavedByMe ? primary : onSurface.withOpacity(0.65),
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
            top: -6,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD6A00F),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: const Color(0xFFD6A00F).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded, size: 10, color: Colors.white),
                  SizedBox(width: 3),
                  Text('Pinned', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
