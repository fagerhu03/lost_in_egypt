import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../domain/entities/community_post.dart';
import '../data/model/community_post_model.dart';
import './community_post_card.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../../auth/data/models/user.dart';
import '../../account/presentation/account_screen.dart';
import 'package:lost_in_egypt/feature/auth/presentation/phone_verif/phone_verification_screen.dart';

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
  String? _replyingToMentionName;
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
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  void _handleReply(String rootThreadId, String mentionedUserName) {
    setState(() {
      _replyingToCommentId   = rootThreadId;
      _replyingToUserName    = mentionedUserName;
      _replyingToMentionName = mentionedUserName;
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
      _replyingToMentionName = null;
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
          title: Text('Edit Comment', style: TextStyle(color: onSurface)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primary)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: onSurface.withOpacity(0.6)))),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty && text != currentText) {
                  await _repository.editComment(widget.post.id, commentId, text);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Save', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
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
          title: Text("Delete Comment", style: TextStyle(color: onSurface)),
          content: Text(
            "Are you sure you want to delete this comment?",
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
              onPressed: () {
                Navigator.pop(ctx);
                _repository.deleteComment(widget.post.id, commentId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
      margin: EdgeInsets.only(bottom: 10, top: isReply ? 0 : 6),
      padding: EdgeInsets.fromLTRB(12, 10, 12, isReply ? 8 : 10),
      decoration: BoxDecoration(
        color: isHighlighted ? primary.withOpacity(0.1) : surface,
        borderRadius: BorderRadius.circular(12),
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
                child: avatar.isNotEmpty
                    ? CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatar))
                    : CircleAvatar(radius: 12, backgroundColor: onSurface.withOpacity(0.08), child: Icon(Icons.person, size: 14, color: primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToProfile(ownerId),
                  child: Row(
                    children: [
                      if (uname.isNotEmpty)
                        Text('@$uname', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold))
                      else
                        Text(displayName, style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text((data['userFlag'] ?? '🇪🇬') as String, style: const TextStyle(fontSize: 10)),
                      if (ts != null) ...[
                        const SizedBox(width: 6),
                        Text(_timeAgo(ts), style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 14, color: onSurface.withOpacity(0.45)),
                color: surface,
                surfaceTintColor: Colors.transparent,
                onSelected: (val) {
                  if (val == 'edit') _editComment(commentId, text);
                  if (val == 'delete') _deleteComment(commentId);
                  if (val == 'report') UniversalReportDialog.show(context, reportType: ReportType.comment, reportedItemId: '${widget.post.id}_$commentId', reportedItemOwnerId: ownerId, repository: GetIt.I<ReportsRepository>());
                },
                itemBuilder: (_) => [
                  if (ownerId == _currentUid) ...[
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  if (ownerId != _currentUid) const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, color: Colors.orange, size: 16), SizedBox(width: 8), Text('Report', style: TextStyle(color: Colors.orange))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Comment text — @mention colored
          _buildCommentText(text, onSurface, primary),
          const SizedBox(height: 8),
          // Action row: like, dislike, reply
          Row(
            children: [
              _commentAction(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                '${likes.length}',
                isLiked ? primary : onSurface.withOpacity(0.45),
                () => _repository.toggleCommentLike(widget.post.id, commentId, true),
              ),
              const SizedBox(width: 12),
              _commentAction(
                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                dislikes.isNotEmpty ? '${dislikes.length}' : '',
                isDisliked ? Colors.red.shade400 : onSurface.withOpacity(0.45),
                () => _repository.toggleCommentLike(widget.post.id, commentId, false),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final mention = uname.isNotEmpty ? uname : displayName;
                  _handleReply(rootThreadId, mention);
                },
                child: Text('Reply', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
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
    final baseStyle = TextStyle(fontSize: 14, color: onSurface.withOpacity(0.92));
    final highlightStyle = TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.bold);
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              if (label.isNotEmpty) ...[const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold))],
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
            const SizedBox(height: 20),
            Divider(color: onSurface.withOpacity(0.10)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(header, style: TextStyle(fontFamily: 'Marcellus', fontSize: 15, fontWeight: FontWeight.bold, color: onSurface)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                      width: 130,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: onSurface.withOpacity(0.08)),
                      ),
                      child: hasImage
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(images[0], height: 90, width: 130, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 90, color: onSurface.withOpacity(0.06))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.85))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(children: [Icon(Icons.thumb_up_outlined, size: 11, color: primary), const SizedBox(width: 3), Text('$likeCount', style: TextStyle(fontSize: 11, color: primary))]),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(title, maxLines: 5, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.88), height: 1.35)),
                                  const Spacer(),
                                  Row(children: [Icon(Icons.thumb_up_outlined, size: 11, color: primary), const SizedBox(width: 3), Text('$likeCount', style: TextStyle(fontSize: 11, color: primary))]),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
    final dividerColor = onSurface.withOpacity(0.12);
    final borderColor = (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);
    final cardShadow = BoxShadow(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 6));

    return Scaffold(
      backgroundColor: bg,
      // ── Comment input pinned at bottom ──────────────────────────────────
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply pill
          if (_replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: primary.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Replying to @${_replyingToUserName ?? ''}', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  GestureDetector(onTap: _cancelReply, child: Icon(Icons.close, size: 16, color: onSurface.withOpacity(0.6))),
                ],
              ),
            ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: dividerColor)),
              boxShadow: [BoxShadow(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Current user avatar
                  _currentUserAvatar != null && _currentUserAvatar!.isNotEmpty
                      ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(_currentUserAvatar!))
                      : CircleAvatar(radius: 14, backgroundColor: onSurface.withOpacity(0.08), child: Icon(Icons.person, size: 16, color: primary)),
                  const SizedBox(width: 8),
                  // Text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: onSurface.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.10))),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: TextStyle(color: onSurface, fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null ? 'Write a reply...' : 'Write a comment...',
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Emoji button
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: onSurface.withOpacity(0.55), size: 22),
                    onPressed: () => _focusNode.requestFocus(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Send button — filled gold circle
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _commentController,
                    builder: (_, val, __) {
                      final hasText = val.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: hasText ? _submitComment : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: hasText ? primary : onSurface.withOpacity(0.12)),
                          child: Icon(Icons.send_rounded, color: hasText ? Colors.white : onSurface.withOpacity(0.35), size: 18),
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
                    authorAvatar.isNotEmpty
                        ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(authorAvatar))
                        : CircleAvatar(radius: 14, backgroundColor: onSurface.withOpacity(0.08), child: Icon(Icons.person, size: 16, color: primary)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(authorName, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ],
                );
              },
            ),
          ),

          // ── Main post body ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: primary))));
              }

              final rawComments = snapshot.data!.docs;

              if (rawComments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No comments yet. Be the first!', textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.5))),
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
              for (var r in rootComments) collectIds(r.id);
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
                          padding: const EdgeInsets.only(left: 20, bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _expandedThreadIds.add(rootId)),
                            child: Text('View ${children.length} ${children.length == 1 ? 'reply' : 'replies'}  ▸', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(width: 20),
                              Container(width: 2, decoration: BoxDecoration(color: primary.withOpacity(0.4), borderRadius: BorderRadius.circular(1))),
                              const SizedBox(width: 12),
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
                          padding: const EdgeInsets.only(left: 20, bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _expandedThreadIds.remove(rootId)),
                            child: Text('Hide replies  ▴', style: TextStyle(fontSize: 12, color: primary.withOpacity(0.7), fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...treeWidgets,
                    if (rawComments.length == _commentLimit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TextButton(onPressed: _loadMoreComments, child: Text('View More Comments', style: TextStyle(color: primary, fontWeight: FontWeight.bold))),
                      ),
                  ]),
                ),
              );
            },
          ),

          // ── Related posts strip ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Comments ($commentCount)', style: TextStyle(fontFamily: 'Marcellus', fontWeight: FontWeight.bold, color: onSurface, fontSize: 15)),
              const Spacer(),
              Icon(Icons.remove_red_eye_outlined, size: 14, color: onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('$viewCount', style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CommentsSectionHeader old) =>
      old.commentCount != commentCount || old.viewCount != viewCount;
}