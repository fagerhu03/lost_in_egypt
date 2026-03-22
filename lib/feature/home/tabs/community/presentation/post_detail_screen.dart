import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities/community_post.dart';
import '../data/model/community_post_model.dart';
import './community_post_card.dart';
import '../data/repositories/firebase_community_repository.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/universal_profile_screen.dart';
import '../../../../auth/data/models/user.dart';
import '../../account/presentation/account_screen.dart';

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
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _navigateToProfile(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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

  @override
  void initState() {
    super.initState();
    _postStream = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.post.id)
        .snapshots();
    _initCommentsStream();
  }

  void _initCommentsStream() {
    _commentsStream = FirebaseFirestore.instance
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
    
    String? finalReplyToId = _replyingToCommentId;
    if (_replyingToUserName != null && !text.startsWith("@$_replyingToUserName")) {
      finalReplyToId = null; // User removed the tag
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

  Widget _buildReplyBanner(Color surface, Color onSurface, Color primary) {
    if (_replyingToCommentId == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primary.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.reply, size: 14, color: primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Replying to @${_replyingToUserName ?? ''}",
              style: TextStyle(
                fontSize: 12,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(Icons.close, size: 16, color: onSurface.withOpacity(0.6)),
          ),
        ],
      ),
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
    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.12),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: onSurface),
        title: Text("Thread", style: TextStyle(color: onSurface)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              children: [
                // MAIN POST (live updates)
                StreamBuilder<DocumentSnapshot>(
                  stream: _postStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return CommunityPostCard(post: widget.post, isDetail: true);
                    }
                    final livePost =
                    CommunityPostModel.fromSnapshot(snapshot.data!);
                    return CommunityPostCard(post: livePost, isDetail: true);
                  },
                ),

                const SizedBox(height: 14),
                Divider(color: dividerColor, height: 24),

                Text(
                  "Comments",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 10),

                // COMMENTS LIST
                StreamBuilder<QuerySnapshot>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: primary),
                      );
                    }

                    final rawComments = snapshot.data!.docs;

                    if (rawComments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No comments yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withOpacity(0.55)),
                        ),
                      );
                    }

                    // 1. Build a map of children for each comment ID
                    final Map<String, List<QueryDocumentSnapshot>> childrenMap = {};
                    final List<QueryDocumentSnapshot> rootComments = [];
                    final List<QueryDocumentSnapshot> legacyReplies = [];

                    for (var doc in rawComments) {
                      final data = doc.data() as Map<String, dynamic>;
                      final replyToId = data['replyToId'] as String?;
                      final text = (data['text'] ?? "") as String;
                      
                      if (replyToId != null && replyToId.isNotEmpty) {
                        childrenMap.putIfAbsent(replyToId, () => []).add(doc);
                      } else if (text.trimLeft().startsWith("@")) {
                        legacyReplies.add(doc);
                      } else {
                        rootComments.add(doc);
                      }
                    }

                    // 2. Handle legacy text-based replies (fallback mapping)
                    for (var reply in legacyReplies) {
                      final data = reply.data() as Map<String, dynamic>;
                      final text = (data['text'] ?? "") as String;
                      bool matched = false;
                      
                      // Try to match with any existing comment
                      for (var doc in rawComments) {
                        if (doc.id == reply.id) continue;
                        final pData = doc.data() as Map<String, dynamic>;
                        final pName = pData['userName'] as String?;
                        if (pName != null && text.trimLeft().startsWith("@$pName")) {
                          childrenMap.putIfAbsent(doc.id, () => []).add(reply);
                          matched = true;
                          break; 
                        }
                      }
                      
                      if (!matched) {
                        rootComments.add(reply); // Treat as root if no parent matched
                      }
                    }

                    // 3. Move orphans (replies whose parent wasn't loaded) to root
                    final allHandledIds = <String>{};
                    allHandledIds.addAll(rootComments.map((d) => d.id));
                    void collectIds(String parentId) {
                      final children = childrenMap[parentId] ?? [];
                      for (var c in children) {
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

                    // 4. Flatten to max 2 levels: BFS-merge all descendants of
                    //    each root into a single flat list (chronological order).
                    for (final root in rootComments) {
                      final queue = List<QueryDocumentSnapshot>.from(childrenMap[root.id] ?? []);
                      final flat  = <QueryDocumentSnapshot>[];
                      while (queue.isNotEmpty) {
                        final item = queue.removeAt(0);
                        flat.add(item);
                        queue.addAll(childrenMap[item.id] ?? []);
                      }
                      if (flat.isNotEmpty) childrenMap[root.id] = flat;
                    }

                    Widget buildCommentItem(QueryDocumentSnapshot doc, int depth, String rootThreadId) {
                      final data = doc.data() as Map<String, dynamic>;
                      final commentId = doc.id;
                      final ownerId = (data['userId'] ?? "") as String;

                      final List likes = (data['likes'] is List) ? (data['likes'] as List) : [];
                      final List dislikes = (data['dislikes'] is List) ? (data['dislikes'] as List) : [];

                      final isLiked = likes.contains(_currentUid);
                      final isDisliked = dislikes.contains(_currentUid);
                      final isHighlighted = commentId == widget.highlightCommentId;

                      final text = (data['text'] ?? "") as String;
                      final isReply = depth > 0;

                      final commentKey = _commentKeys.putIfAbsent(commentId, () => GlobalKey());

                      return Container(
                        key: commentKey,
                        margin: EdgeInsets.only(bottom: 12, top: isReply ? 0 : 8),
                        padding: EdgeInsets.all(isReply ? 10 : 12),
                        decoration: BoxDecoration(
                          color: isHighlighted ? primary.withOpacity(0.1) : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isHighlighted ? primary : borderColor, width: isHighlighted ? 1.5 : 1.0),
                          boxShadow: isReply ? [] : [cardShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _navigateToProfile(ownerId),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: isReply ? 10 : 12,
                                        backgroundColor: onSurface.withOpacity(0.08),
                                        backgroundImage: (data['userAvatar'] != null && data['userAvatar'] != "")
                                            ? NetworkImage(data['userAvatar'])
                                            : null,
                                        child: (data['userAvatar'] == null || data['userAvatar'] == "")
                                            ? Icon(Icons.person, size: isReply ? 12 : 14, color: primary)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (data['userName'] ?? 'User') as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isReply ? 12 : 13,
                                              color: onSurface,
                                            ),
                                          ),
                                          if ((data['userUsername'] ?? '').toString().isNotEmpty)
                                            Text(
                                              '@${data['userUsername']}',
                                              style: TextStyle(
                                                fontSize: isReply ? 9 : 10,
                                                color: primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (data['userFlag'] ?? '🇪🇬') as String,
                                  style: TextStyle(fontSize: isReply ? 10 : 12),
                                ),
                                const Spacer(),

                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: onSurface.withOpacity(0.55),
                                      ),
                                      color: surface,
                                      surfaceTintColor: Colors.transparent,
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteComment(commentId);
                                        } else if (value == 'report') {
                                          UniversalReportDialog.show(
                                            context,
                                            reportType: ReportType.comment,
                                            reportedItemId: '${widget.post.id}_$commentId',
                                            reportedItemOwnerId: ownerId,
                                            repository: GetIt.I<ReportsRepository>(),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (ownerId == _currentUid)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 16),
                                                SizedBox(width: 8),
                                                Text("Delete", style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        if (ownerId != _currentUid)
                                          const PopupMenuItem(
                                            value: 'report',
                                            child: Row(
                                              children: [
                                                Icon(Icons.flag, color: Colors.orange, size: 16),
                                                SizedBox(width: 8),
                                                Text("Report Comment", style: TextStyle(color: Colors.orange)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: isReply ? 13 : 14,
                                color: onSurface.withOpacity(0.92),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // LIKE
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _repository.toggleCommentLike(widget.post.id, commentId, true),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                            size: 14,
                                            color: isLiked ? primary : onSurface.withOpacity(0.45),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${likes.length}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isLiked ? primary : onSurface.withOpacity(0.45),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // DISLIKE
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _repository.toggleCommentLike(widget.post.id, commentId, false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                            size: 14,
                                            color: isDisliked ? Colors.red.shade400 : onSurface.withOpacity(0.45),
                                          ),
                                          const SizedBox(width: 4),
                                          if (dislikes.isNotEmpty)
                                            Text(
                                              "${dislikes.length}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDisliked ? Colors.red.shade400 : onSurface.withOpacity(0.45),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // REPLY
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final uname = (data['userUsername'] ?? '') as String;
                                      final mention = uname.isNotEmpty ? uname : (data['userName'] ?? 'User') as String;
                                      _handleReply(rootThreadId, mention);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        "Reply",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    // 5. Tree builder — max 2 levels with collapse/expand
                    Widget buildTree(QueryDocumentSnapshot node, int depth) {
                      final rootId     = node.id;
                      final children   = childrenMap[rootId] ?? [];
                      final isExpanded = _expandedThreadIds.contains(rootId);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildCommentItem(node, 0, rootId),

                          if (children.isNotEmpty) ...[
                            if (!isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _expandedThreadIds.add(rootId)),
                                  child: Text(
                                    "View ${children.length} ${children.length == 1 ? 'reply' : 'replies'}  ▸",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(width: 20),
                                    Container(width: 2, color: dividerColor),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: children
                                            .map((c) => buildCommentItem(c, 1, rootId))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _expandedThreadIds.remove(rootId)),
                                  child: Text(
                                    "Hide replies  ▴",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primary.withOpacity(0.7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    }

                    final List<Widget> threadWidgets = rootComments.map((r) => buildTree(r, 0)).toList();

                    if (!_hasScrolledToHighlight && widget.highlightCommentId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final hId = widget.highlightCommentId!;
                        // Auto-expand the thread containing the highlighted comment
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...threadWidgets,
                        if (rawComments.length == _commentLimit)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: TextButton(
                              onPressed: _loadMoreComments,
                              child: Text(
                                "View More Comments",
                                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // COMMENT INPUT
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReplyBanner(surface, onSurface, primary),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(top: BorderSide(color: dividerColor)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: TextStyle(color: onSurface),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? "Write a reply..."
                              : "Write a comment...",
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: primary),
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}