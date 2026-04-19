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

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;
  final bool isDetail;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onCommentTap,
    this.onTap,
    this.isDetail = false,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  int _currentImageIndex = 0;
  final FirebaseCommunityRepository _repo = FirebaseCommunityRepository();

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
          content: Text(
            "Are you sure? This cannot be undone.",
            style: TextStyle(color: onSurface.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _repo.deletePost(widget.post.id);
                  if (widget.isDetail && mounted) Navigator.pop(context);
                } catch (e) {
                  debugPrint("❌ Error deleting post: $e");
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .get();
      if (mounted) Navigator.pop(context); // close dialog

      if (doc.exists && mounted) {
        final profileUser = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        // If viewing own profile, redirect to Account screen
        if (profileUser.id == FirebaseAuth.instance.currentUser?.uid) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccountScreen(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UniversalProfileScreen(user: profileUser),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close dialog
      debugPrint("Error navigating to profile: $e");
    }
  }

  void _editPost() {
    final TextEditingController editController = TextEditingController(
      text: widget.post.content,
    );

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
            controller: editController,
            maxLines: 4,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  try {
                    await _repo.editPost(
                      widget.post.id,
                      editController.text.trim(),
                    );
                  } catch (e) {
                    debugPrint("❌ Error editing post: $e");
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

  void _reportPost() {
    UniversalReportDialog.show(
      context,
      reportType: ReportType.post,
      reportedItemId: widget.post.id,
      reportedItemOwnerId: widget.post.userId, // Can be empty if not passed
      repository: GetIt.I<ReportsRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final activeColor = primary;

    return RepaintBoundary(
      child: _buildCard(context, theme, isDark, surface, onSurface, primary, activeColor),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, bool isDark, Color surface, Color onSurface, Color primary, Color activeColor) {
    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.14)
          : Colors.black.withOpacity(0.14),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    );

    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(
      isDark ? 0.10 : 0.06,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [cardShadow],
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: ClipOval(
                    child: widget.post.userAvatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.post.userAvatar,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                            memCacheHeight: 80,
                            placeholder: (context, url) => Container(
                              width: 34,
                              height: 34,
                              color: onSurface.withOpacity(0.08),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 34,
                              height: 34,
                              color: onSurface.withOpacity(0.08),
                              child: Icon(Icons.person, size: 20, color: activeColor),
                            ),
                          )
                        : Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: onSurface.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, size: 20, color: activeColor),
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
                              onTap: _navigateToProfile,
                              child: Text(
                                widget.post.userName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          if (widget.post.isVerifiedGuide) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              color: Theme.of(context).colorScheme.primary,
                              size: 14,
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            widget.post.userFlag,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.post.timeAgo,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    final String myUid =
                        FirebaseAuth.instance.currentUser?.uid ?? "";
                    final bool amIOwner =
                        widget.post.userId.isNotEmpty &&
                        (widget.post.userId == myUid);

                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
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
                                if (amIOwner) ...[
                                  ListTile(
                                    leading: Icon(
                                      Icons.edit,
                                      color: o.withOpacity(0.8),
                                    ),
                                    title: Text(
                                      "Edit Post",
                                      style: TextStyle(color: o),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        _editPost,
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: const Text(
                                      "Delete Post",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        _deletePost,
                                      );
                                    },
                                  ),
                                ],
                                if (!amIOwner)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.flag,
                                      color: Colors.orange,
                                    ),
                                    title: Text(
                                      "Report Post",
                                      style: TextStyle(color: o),
                                    ),
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

            // NAV AREA
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: "Mako",
                    height: 1.4,
                  ),
                ),

                if (widget.post.locationName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                          Text(
                            widget.post.locationName!,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (widget.post.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: widget.isDetail ? 400 : 220,
                          width: double.infinity,
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          child: PageView.builder(
                            itemCount: widget.post.images.length,
                            onPageChanged: (index) =>
                                setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) => CachedNetworkImage(
                              imageUrl: widget.post.images[index],
                              fit: widget.isDetail
                                  ? BoxFit.contain
                                  : BoxFit.cover,
                              memCacheWidth: 600,
                              errorWidget: (c, e, s) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.post.images.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(widget.post.images.length, (
                              index,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 6,
                                width: _currentImageIndex == index ? 12 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? activeColor
                                      : onSurface.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ACTIONS ROW
            Row(
              children: [
                _ActionButton(
                  icon: widget.post.isLikedByMe
                      ? Icons.thumb_up
                      : Icons.thumb_up_alt_outlined,
                  value: widget.post.likes,
                  color: widget.post.isLikedByMe
                      ? activeColor
                      : onSurface.withOpacity(0.65),
                  onTap: () => _repo.togglePostLike(widget.post.id, true),
                ),
                const SizedBox(width: 14),
                _ActionButton(
                  icon: widget.post.isDislikedByMe
                      ? Icons.thumb_down
                      : Icons.thumb_down_alt_outlined,
                  value: widget.post.dislikes,
                  color: widget.post.isDislikedByMe
                      ? Colors.red.shade400
                      : onSurface.withOpacity(0.65),
                  onTap: () => _repo.togglePostLike(widget.post.id, false),
                ),
                const SizedBox(width: 14),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: widget.post.comments,
                  color: onSurface.withOpacity(0.65),
                  onTap: widget.onCommentTap,
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _repo.toggleSavePost(
                    widget.post.id,
                    widget.post.isSavedByMe,
                  ),
                  child: Icon(
                    widget.post.isSavedByMe
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.post.isSavedByMe
                        ? activeColor
                        : onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.value,
    required this.color,
    this.onTap,
  });

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
              Text(
                "$value",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
