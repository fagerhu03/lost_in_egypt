import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../domain/entities/community_post.dart';
import '../data/model/community_post_model.dart';
import './community_post_card.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../../core/utils/error_handler.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../../auth/data/models/user.dart';
import '../../account/presentation/account_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';
import '../../../../../core/widgets/shimmer_avatar.dart';
import '../../../../../core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final String? highlightCommentId;
  const PostDetailScreen({super.key, required this.post, this.highlightCommentId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  late final String _currentUid = _auth.currentUser?.uid ?? "";

  Future<void> _navigateToProfile(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (mounted) Navigator.pop(context); // close dialog

      if (doc.exists && mounted) {
        final profileUser = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        // If viewing own profile, redirect to Account screen
        if (profileUser.id == _auth.currentUser?.uid) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountScreen()),
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
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};
  bool _hasScrolledToHighlight = false;

  String? _replyingToCommentId;
  String? _replyingToUserName;
  final Set<String> _expandedThreadIds = {};

  late Stream<DocumentSnapshot> _postStream;
  late Stream<QuerySnapshot> _commentsStream;
  int _commentLimit = 15;

  late Future<List<QueryDocumentSnapshot>> _relatedPostsFuture;
  String? _currentUserAvatar;

  static final Set<String> _viewedPostIds = {};

  @override
  void initState() {
    super.initState();
    _postStream = _firestore
        .collection('community_posts')
        .doc(widget.post.id)
        .snapshots();
    _initCommentsStream();
    _incrementViewCount();
    _relatedPostsFuture = _loadRelatedPosts();
    _loadCurrentUserAvatar();
  }

  Future<void> _loadCurrentUserAvatar() async {
    if (_currentUid.isEmpty) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUid).get();
      if (doc.exists && mounted) {
        setState(() => _currentUserAvatar = doc.data()?['profileImageUrl']);
      }
    } catch (_) {}
  }

  void _incrementViewCount() {
    final postId = widget.post.id;
    if (_viewedPostIds.contains(postId)) return;
    _viewedPostIds.add(postId);
    _firestore.collection('community_posts').doc(postId).update({
      'views': FieldValue.increment(1),
    }).catchError((_) {});
  }

  Future<List<QueryDocumentSnapshot>> _loadRelatedPosts() async {
    try {
      final locationId = widget.post.locationId;
      Query query;
      if (locationId != null && locationId.isNotEmpty) {
        query = _firestore
            .collection('community_posts')
            .where('locationId', isEqualTo: locationId)
            .limit(6);
      } else {
        query = _firestore
            .collection('community_posts')
            .orderBy('likesCount', descending: true)
            .limit(6);
      }
      final snapshot = await query.get();
      return snapshot.docs.where((d) => d.id != widget.post.id).take(5).toList();
    } catch (_) {
      return [];
    }
  }

  void _initCommentsStream() {
    _commentsStream = _firestore
        .collection('community_posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .limit(_commentLimit)
        .snapshots();
  }

  void _loadMoreComments() {
    setState(() {
      _commentLimit += 15;
      _initCommentsStream();
    });
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Phone verification gate (same as community_screen.dart _handlePostAction)
    bool isPhoneVerified = false;
    try {
      final doc = await _firestore.collection('users').doc(_currentUid).get();
      if (doc.exists) {
        isPhoneVerified = doc.data()?['phoneVerified'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking phone verification: $e');
    }

    if (!isPhoneVerified) {
      if (!mounted) return;
      final bool? verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
      );
      if (verified != true) return;
    }

    String? finalReplyToId = _replyingToCommentId;
    if (_replyingToUserName != null && !text.startsWith("@$_replyingToUserName")) {
      finalReplyToId = null;
    }

    _commentController.clear();
    _focusNode.unfocus();
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });

    try {
      await _repository.addComment(widget.post.id, text, replyToId: finalReplyToId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
        );
      }
    }
  }

  void _handleReply(String rootThreadId, String mentionedUserName) {
    setState(() {
      _replyingToCommentId   = rootThreadId;
      _replyingToUserName    = mentionedUserName;
      final tag = "@$mentionedUserName ";
      if (!_commentController.text.startsWith(tag)) {
        _commentController.text = "$tag${_commentController.text}";
        _commentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _commentController.text.length),
        );
      }
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId   = null;
      _replyingToUserName    = null;
      _commentController.clear();
    });
  }

  void _editComment(String commentId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;
        final primary = theme.colorScheme.primary;
        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          title: Text(AppLocalizations.of(ctx).commentEditTitle, style: TextStyle(color: onSurface)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: primary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).commonCancel, style: TextStyle(color: onSurface.withValues(alpha: 0.6)))),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty && text != currentText) {
                  await _repository.editComment(widget.post.id, commentId, text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(ctx).commonSave, style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;

        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          title: Text(AppLocalizations.of(ctx).commentDeleteTitle, style: TextStyle(color: onSurface)),
          content: Text(
            AppLocalizations.of(ctx).commentDeleteConfirm,
            style: TextStyle(color: onSurface.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(ctx).commonCancel,
                style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _repository.deleteComment(widget.post.id, commentId);
              },
              child: Text(AppLocalizations.of(ctx).commonDelete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _scrollToHighlight() {
    if (_hasScrolledToHighlight || widget.highlightCommentId == null) return;
    final key = _commentKeys[widget.highlightCommentId];
    if (key != null && key.currentContext != null) {
      _hasScrolledToHighlight = true;
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── TIME AGO HELPER ────────────────────────────────────────────────────
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // ─── BUILD COMMENT ITEM ─────────────────────────────────────────────────
  Widget _buildCommentItem(
    QueryDocumentSnapshot doc,
    int depth,
    String rootThreadId,
    Color surface,
    Color onSurface,
    Color primary,
    Color borderColor,
    BoxShadow cardShadow,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final commentId = doc.id;
    final ownerId = (data['userId'] ?? '') as String;
    final List likes = (data['likes'] is List) ? (data['likes'] as List) : [];
    final List dislikes = (data['dislikes'] is List) ? (data['dislikes'] as List) : [];
    final isLiked = likes.contains(_currentUid);
    final isDisliked = dislikes.contains(_currentUid);
    final isHighlighted = commentId == widget.highlightCommentId;
    final text = (data['text'] ?? '') as String;
    final isReply = depth > 0;
    final avatar = (data['userAvatar'] ?? '') as String;
    final uname = (data['userUsername'] ?? '') as String;
    final displayName = (data['userName'] ?? 'User') as String;
    final ts = data['timestamp'] as Timestamp?;

    final commentKey = _commentKeys.putIfAbsent(commentId, () => GlobalKey());

    return Container(
      key: commentKey,
      margin: EdgeInsets.only(bottom: 10.h, top: isReply ? 0 : 6.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, isReply ? 8.h : 10.h),
      decoration: BoxDecoration(
        color: isHighlighted ? primary.withValues(alpha: 0.1) : surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isHighlighted ? primary : borderColor, width: isHighlighted ? 1.5 : 1.0),
        boxShadow: isReply ? [] : [cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name + @handle + timestamp + menu
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(ownerId),
                child: ShimmerAvatar(
                  url: avatar,
                  radius: 12.r,
                  iconSize: 14.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(ownerId),
                  child: Row(
                    children: [
                      if (uname.isNotEmpty)
                        Text('@$uname', style: TextStyle(color: primary, fontSize: 12.sp, fontWeight: FontWeight.bold))
                      else
                        Text(displayName, style: TextStyle(color: onSurface, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4.w),
                      Text((data['userFlag'] ?? '🇪🇬') as String, style: TextStyle(fontSize: 10.sp)),
                      if (ts != null) ...[
                        SizedBox(width: 6.w),
                        Text(_timeAgo(ts), style: TextStyle(color: onSurface.withValues(alpha: 0.45), fontSize: 11.sp)),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 14.r, color: onSurface.withValues(alpha: 0.45)),
                color: surface,
                surfaceTintColor: Colors.transparent,
                onSelected: (val) {
                  if (val == 'edit') _editComment(commentId, text);
                  if (val == 'delete') _deleteComment(commentId);
                  if (val == 'report') UniversalReportDialog.show(context, reportType: ReportType.comment, reportedItemId: '${widget.post.id}_$commentId', reportedItemOwnerId: ownerId, repository: GetIt.I<ReportsRepository>());
                },
                itemBuilder: (_) => [
                  if (ownerId == _currentUid) ...[
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16.r), SizedBox(width: 8.w), Text(AppLocalizations.of(context).commonEdit)])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 16.r), SizedBox(width: 8.w), Text(AppLocalizations.of(context).commonDelete, style: const TextStyle(color: Colors.red))])),
                  ],
                  if (ownerId != _currentUid) PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, color: Colors.orange, size: 16.r), SizedBox(width: 8.w), Text(AppLocalizations.of(context).commonReport, style: const TextStyle(color: Colors.orange))])),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          // Comment text — @mention colored
          _buildCommentText(text, onSurface, primary),
          SizedBox(height: 8.h),
          // Action row: like, dislike, reply
          Row(
            children: [
              _commentAction(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                '${likes.length}',
                isLiked ? primary : onSurface.withValues(alpha: 0.45),
                () => _repository.toggleCommentLike(widget.post.id, commentId, true),
              ),
              SizedBox(width: 12.w),
              _commentAction(
                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                dislikes.isNotEmpty ? '${dislikes.length}' : '',
                isDisliked ? Colors.red.shade400 : onSurface.withValues(alpha: 0.45),
                () => _repository.toggleCommentLike(widget.post.id, commentId, false),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final mention = uname.isNotEmpty ? uname : displayName;
                  _handleReply(rootThreadId, mention);
                },
                child: Text(AppLocalizations.of(context).commentReply, style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentText(String text, Color onSurface, Color primary) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(@\w+|#\w+)');
    final baseStyle = TextStyle(fontSize: 14.sp, color: onSurface.withValues(alpha: 0.92));
    final highlightStyle = TextStyle(fontSize: 14.sp, color: primary, fontWeight: FontWeight.bold);
    int last = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: baseStyle));
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
        spans.add(TextSpan(text: token, style: highlightStyle));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    if (spans.isEmpty) return Text(text, style: baseStyle);
    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _navigateToProfileByUsername(String username) async {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final snap = await FirebaseFirestore.instance.collection('usernames').doc(username.toLowerCase()).get();
      if (mounted) Navigator.pop(context);
      if (snap.exists && mounted) {
        final uid = snap.data()?['uid'] as String?;
        if (uid != null) _navigateToProfile(uid);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _commentAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              Icon(icon, size: 14.r, color: color),
              if (label.isNotEmpty) ...[SizedBox(width: 4.w), Text(label, style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.bold))],
            ],
          ),
        ),
      ),
    );
  }

  // ─── RELATED POSTS STRIP ────────────────────────────────────────────────
  Widget _buildRelatedPostsStrip(Color surface, Color onSurface, Color primary, bool isDark) {
    final locationName = widget.post.locationName;
    final header = (locationName != null && locationName.isNotEmpty) ? 'More from $locationName' : 'Trending Posts';

    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _relatedPostsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final docs = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Divider(color: onSurface.withValues(alpha: 0.10)),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(header, style: TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'], fontSize: 15.sp, fontWeight: FontWeight.bold, color: onSurface)),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 160.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: docs.length,
                separatorBuilder: (_, _) => SizedBox(width: 10.w),
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final images = List<String>.from(d['images'] ?? []);
                  final content = (d['content'] as String? ?? '');
                  final title = content.length > 70 ? '${content.substring(0, 70)}...' : content;
                  final likeCount = (d['likesCount'] as int?) ?? 0;
                  final hasImage = images.isNotEmpty;
                  return GestureDetector(
                    onTap: () {
                      final post = CommunityPostModel.fromSnapshot(docs[i]);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
                    },
                    child: Container(
                      width: 130.w,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                      ),
                      child: hasImage
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerImage(
                                  url: images[0],
                                  height: 90.h,
                                  width: 130.w,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 4.h),
                                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: onSurface.withValues(alpha: 0.85))),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: Row(children: [Icon(Icons.thumb_up_outlined, size: 11.r, color: primary), SizedBox(width: 3.w), Text('$likeCount', style: TextStyle(fontSize: 11.sp, color: primary))]),
                                ),
                              ],
                            )
                          : Padding(
                              padding: EdgeInsets.all(10.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(title, maxLines: 5, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: onSurface.withValues(alpha: 0.88), height: 1.35)),
                                  const Spacer(),
                                  Row(children: [Icon(Icons.thumb_up_outlined, size: 11.r, color: primary), SizedBox(width: 3.w), Text('$likeCount', style: TextStyle(fontSize: 11.sp, color: primary))]),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final dividerColor = onSurface.withValues(alpha: 0.12);
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);
    final cardShadow = BoxShadow(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08), blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 6));

    return Scaffold(
      backgroundColor: bg,
      // ── Comment input pinned at bottom ──────────────────────────────────
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply pill
          if (_replyingToCommentId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 14.r, color: primary),
                  SizedBox(width: 6.w),
                  Expanded(child: Text(AppLocalizations.of(context).commentReplyingTo(_replyingToUserName ?? ''), style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  GestureDetector(onTap: _cancelReply, child: Icon(Icons.close, size: 16.r, color: onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: dividerColor)),
              boxShadow: [BoxShadow(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Current user avatar
                  ShimmerAvatar(
                    url: _currentUserAvatar,
                    radius: 14.r,
                    iconSize: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: onSurface.withValues(alpha: 0.10))),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: TextStyle(color: onSurface, fontSize: 14.sp),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null ? AppLocalizations.of(context).commentWriteReply : AppLocalizations.of(context).commentWriteComment,
                          hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.45), fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // Emoji button
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: onSurface.withValues(alpha: 0.55), size: 22.r),
                    onPressed: () => _focusNode.requestFocus(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                  ),
                  // Send button — filled gold circle
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _commentController,
                    builder: (_, val, _) {
                      final hasText = val.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: hasText ? _submitComment : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36.r, height: 36.r,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: hasText ? primary : onSurface.withValues(alpha: 0.12)),
                          child: Icon(Icons.send_rounded, color: hasText ? Colors.white : onSurface.withValues(alpha: 0.35), size: 18.r),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: BackButton(color: onSurface),
            title: StreamBuilder<DocumentSnapshot>(
              stream: _postStream,
              builder: (context, snap) {
                String authorName = widget.post.userName;
                String authorAvatar = widget.post.userAvatar;
                if (snap.hasData && snap.data!.exists) {
                  final d = snap.data!.data() as Map<String, dynamic>;
                  authorName = (d['userName'] as String?) ?? authorName;
                  authorAvatar = (d['userAvatar'] as String?) ?? authorAvatar;
                }
                return Row(
                  children: [
                    ShimmerAvatar(
                      url: authorAvatar,
                      radius: 14.r,
                      iconSize: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(child: Text(authorName, style: TextStyle(color: onSurface, fontSize: 15.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ],
                );
              },
            ),
          ),

          // ── Main post body ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _postStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return CommunityPostCard(post: widget.post, isDetail: true);
                  }
                  return CommunityPostCard(post: CommunityPostModel.fromSnapshot(snapshot.data!), isDetail: true);
                },
              ),
            ),
          ),

          // ── Comments header (sticky) ─────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CommentsSectionHeader(
              bg: bg,
              onSurface: onSurface,
              primary: primary,
              dividerColor: dividerColor,
              commentCount: widget.post.comments,
              viewCount: widget.post.views,
            ),
          ),

          // ── Comments list ───────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _commentsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24.r), child: Center(child: CircularProgressIndicator(color: primary))));
              }

              final rawComments = snapshot.data!.docs;

              if (rawComments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: Text(AppLocalizations.of(context).commentsEmpty, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withValues(alpha: 0.5))),
                  ),
                );
              }

              // Build thread map (same logic as before)
              final Map<String, List<QueryDocumentSnapshot>> childrenMap = {};
              final List<QueryDocumentSnapshot> rootComments = [];
              final List<QueryDocumentSnapshot> legacyReplies = [];

              for (var doc in rawComments) {
                final data = doc.data() as Map<String, dynamic>;
                final replyToId = data['replyToId'] as String?;
                final text = (data['text'] ?? '') as String;
                if (replyToId != null && replyToId.isNotEmpty) {
                  childrenMap.putIfAbsent(replyToId, () => []).add(doc);
                } else if (text.trimLeft().startsWith('@')) {
                  legacyReplies.add(doc);
                } else {
                  rootComments.add(doc);
                }
              }

              for (var reply in legacyReplies) {
                final data = reply.data() as Map<String, dynamic>;
                final text = (data['text'] ?? '') as String;
                bool matched = false;
                for (var doc in rawComments) {
                  if (doc.id == reply.id) continue;
                  final pName = (doc.data() as Map<String, dynamic>)['userName'] as String?;
                  if (pName != null && text.trimLeft().startsWith('@$pName')) {
                    childrenMap.putIfAbsent(doc.id, () => []).add(reply);
                    matched = true;
                    break;
                  }
                }
                if (!matched) rootComments.add(reply);
              }

              final allHandledIds = <String>{};
              allHandledIds.addAll(rootComments.map((d) => d.id));
              void collectIds(String parentId) {
                for (var c in childrenMap[parentId] ?? []) {
                  allHandledIds.add(c.id);
                  collectIds(c.id);
                }
              }
              for (var r in rootComments) {
                collectIds(r.id);
              }
              for (var doc in rawComments) {
                if (!allHandledIds.contains(doc.id)) {
                  rootComments.add(doc);
                  allHandledIds.add(doc.id);
                  collectIds(doc.id);
                }
              }

              // Flatten to 2 levels
              for (final root in rootComments) {
                final queue = List<QueryDocumentSnapshot>.from(childrenMap[root.id] ?? []);
                final flat = <QueryDocumentSnapshot>[];
                while (queue.isNotEmpty) {
                  final item = queue.removeAt(0);
                  flat.add(item);
                  queue.addAll(childrenMap[item.id] ?? []);
                }
                if (flat.isNotEmpty) childrenMap[root.id] = flat;
              }

              // Tree widget builder
              Widget buildTree(QueryDocumentSnapshot node) {
                final rootId = node.id;
                final children = childrenMap[rootId] ?? [];
                final isExpanded = _expandedThreadIds.contains(rootId);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCommentItem(node, 0, rootId, surface, onSurface, primary, borderColor, cardShadow),
                    if (children.isNotEmpty) ...[
                      if (!isExpanded)
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 20.w, bottom: 8.h),
                          child: GestureDetector(
                            onTap: () => setState(() => _expandedThreadIds.add(rootId)),
                            child: Text(AppLocalizations.of(context).commentViewReplies(children.length), style: TextStyle(fontSize: 12.sp, color: primary, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 20.w),
                              Container(width: 2.w, decoration: BoxDecoration(color: primary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1.r))),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: children.map((c) => _buildCommentItem(c, 1, rootId, surface, onSurface, primary, borderColor, cardShadow)).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 20.w, bottom: 8.h),
                          child: GestureDetector(
                            onTap: () => setState(() => _expandedThreadIds.remove(rootId)),
                            child: Text(AppLocalizations.of(context).commentHideReplies, style: TextStyle(fontSize: 12.sp, color: primary.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              }

              if (!_hasScrolledToHighlight && widget.highlightCommentId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final hId = widget.highlightCommentId!;
                  if (!rootComments.any((r) => r.id == hId)) {
                    for (final root in rootComments) {
                      if ((childrenMap[root.id] ?? []).any((d) => d.id == hId)) {
                        setState(() => _expandedThreadIds.add(root.id));
                        break;
                      }
                    }
                  }
                  _scrollToHighlight();
                });
              }

              final treeWidgets = rootComments.map(buildTree).toList();

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...treeWidgets,
                    if (rawComments.length == _commentLimit)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: TextButton(onPressed: _loadMoreComments, child: Text(AppLocalizations.of(context).commentsViewMore, style: TextStyle(color: primary, fontWeight: FontWeight.bold))),
                      ),
                  ]),
                ),
              );
            },
          ),

          // ── Related posts strip ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildRelatedPostsStrip(surface, onSurface, primary, isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky comments section header delegate ─────────────────────────────────
class _CommentsSectionHeader extends SliverPersistentHeaderDelegate {
  final Color bg;
  final Color onSurface;
  final Color primary;
  final Color dividerColor;
  final int commentCount;
  final int viewCount;

  const _CommentsSectionHeader({
    required this.bg,
    required this.onSurface,
    required this.primary,
    required this.dividerColor,
    required this.commentCount,
    required this.viewCount,
  });

  @override
  double get minExtent => 44.h;
  @override
  double get maxExtent => 44.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, height: 1.h),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(AppLocalizations.of(context).commentsHeader(commentCount), style: TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'], fontWeight: FontWeight.bold, color: onSurface, fontSize: 15.sp)),
              const Spacer(),
              Icon(Icons.remove_red_eye_outlined, size: 14.r, color: onSurface.withValues(alpha: 0.5)),
              SizedBox(width: 4.w),
              Text('$viewCount', style: TextStyle(fontSize: 12.sp, color: onSurface.withValues(alpha: 0.5))),
            ],
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CommentsSectionHeader old) =>
      old.commentCount != commentCount || old.viewCount != viewCount;
}
